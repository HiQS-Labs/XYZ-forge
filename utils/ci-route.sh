#!/usr/bin/env bash
# Classify a CI invocation as docs-only, fast, or full — and, since GH-35, answer a second,
# deliberately separate question: which local test-selection TIER the change belongs to.
# Pull-request paths are read from stdin.
#
#   route=docs|fast|full  — the CI job shape (GH-509 semantics, unchanged)
#   tier=1|2|3            — the local gate selection (GH-35): 1 docs, 2 subsystem, 3 full
#
# The two answers are kept separate on purpose (GH-35 review guardrail): test selection is
# deterministic policy owned by this registry; resource policy (worker count, nice) is
# validate.sh's business and never changes WHICH tests run. The tier fails closed — unknown
# paths, any test/* change, and every kernel/containment/gate surface are tier 3.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── GH-35 Tier-2 subsystem registry ──────────────────────────────────────────────────────────────
# The ONE mapping from changed paths to the focused suites that cover them, consumed by
# githooks/pre-push and validate.sh (--tier 2 / --subsystem). Extending it is a deliberate
# three-part act: name the subsystem in SUBSYSTEMS, add its path patterns to subsystem_of(),
# and list its suites in SUBSYSTEM_TESTS_<name>. Every listed suite must exist in test/ AND
# be registered in validate.sh's TESTS array — test/gh35-test-tiers.sh enforces both, because
# a registry naming a suite that never runs is a green lie (the releases-skill lesson).
SUBSYSTEMS="hq releases telemetry ate swe-diagram pdda agent2agent standup"
SUBSYSTEM_TESTS_hq="hq.sh hq-park.sh hq-park-synthesis.sh hq-dispatch.sh hq-next.sh hq-locator.sh hq-hardening.sh hq-promote.sh hq-marathon-scan.sh hq-rollup.sh hq-marathon-live.sh roadmap-dashboard.sh"
SUBSYSTEM_TESTS_releases="gh32-releases-app.sh gh32-releases-artifacts.sh gh53-releases-merge-resolve.sh gh54-merged-dump-refusals.sh gh57-live-merge-resolve.sh gh69-roadmap-shadow.sh gh32-release-target-advisory.sh gh39-releases-project-sync.sh releases-skill.sh gh284-p3-release-milestone.sh gh284-p4-release-lanes.sh litmus-release.sh nightwatch-release.sh meter-release.sh ballast-release.sh gh57-releases-fuzz.sh"
SUBSYSTEM_TESTS_telemetry="xyz-completion.sh gh358-lock-instrumentation.sh archive-telemetry.sh"
SUBSYSTEM_TESTS_ate="ate-run-variations.sh"
SUBSYSTEM_TESTS_swe_diagram="swe-diagram.sh"
SUBSYSTEM_TESTS_pdda="pdda-roadmap-coverage.sh pdda-repo-contract.sh pdda-local-checks.sh gh400-acceptance-fidelity.sh gh400-source-url.sh gh422-backfill-source-url.sh gh425-source-url-slug.sh"
SUBSYSTEM_TESTS_agent2agent="agent2agent.sh"
SUBSYSTEM_TESTS_standup="gh77-standup-triage.sh"

subsystem_of() {  # <path> -> subsystem name, or nothing when unmapped
  case "$1" in
    utils/hq/*|skills/hq/*)                                                                printf '%s\n' hq ;;
    utils/py/releases_app.py|skills/releases/*|utils/release-lanes.sh)                     printf '%s\n' releases ;;
    utils/telemetry/*)                                                                     printf '%s\n' telemetry ;;
    utils/ate/*|utils/fuzzing/*)                                                           printf '%s\n' ate ;;
    utils/swe-diagram/*)                                                                   printf '%s\n' swe-diagram ;;
    utils/pdda/*|utils/pdda-local-checks.sh|utils/pdda-catchup.sh|utils/pdda-doc-ready.sh) printf '%s\n' pdda ;;
    skills/agent2agent/*)                                                                  printf '%s\n' agent2agent ;;
    skills/standup/*)                                                                      printf '%s\n' standup ;;
  esac
}

event_name="${1:-}"

case "$event_name" in
  # Registry listing — the drift guard and `validate.sh --subsystem` read this instead of
  # re-deriving the mapping. A registered suite missing from disk fails LOUDLY here: a silent
  # skip would turn `--tier 2 --subsystem <name>` into a zero-test gate that exits green.
  subsystems)
    want="${2:-}"
    for s in $SUBSYSTEMS; do
      _tests="SUBSYSTEM_TESTS_${s//-/_}"
      for t in ${!_tests}; do
        [[ -f "$ROOT/test/$t" ]] || { echo "ci-route: subsystem $s registers missing test test/$t" >&2; exit 2; }
      done
    done
    found=0
    for s in $SUBSYSTEMS; do
      [ -z "$want" ] || [ "$want" = "$s" ] || continue
      found=1
      _tests="SUBSYSTEM_TESTS_${s//-/_}"
      if [ -n "$want" ]; then printf '%s\n' "${!_tests}"
      else printf '%s\t%s\n' "$s" "${!_tests}"; fi
    done
    if [ "$found" -eq 0 ]; then
      echo "ci-route: unknown subsystem: '${want}' (known: $(printf '%s' "$SUBSYSTEMS" | tr ' ' ','))" >&2
      exit 2
    fi
    exit 0
    ;;
  workflow_dispatch|schedule)
    # Deliberate, operator-initiated, and rare. These are the only unconditional full routes left:
    # a manual dispatch is someone asking for the whole gate, and answering it with a routed subset
    # would be answering a different question than the one asked.
    printf '%s\n' \
      'docs_only=false' \
      'pdda_needed=true' \
      'full_required=true' \
      'changed_tests=' \
      'route=full' \
      'tier=3' \
      'tier2_subsystems=' \
      'tier2_tests=' \
      'tier_reason=operator-initiated full run'
    exit 0
    ;;
  # GH-509 Phase 3 — `push` used to sit in the branch above, and that was 72% of the bill.
  #
  # Measured over 60 runs in ~24h: 37 pushes to `development`, EVERY ONE a full route, ~396 of ~551
  # billed minutes. Phase 1 routed pull requests and cut their average from ~16 min to 6.1 — it
  # worked, and it worked on the other 28%. The audit that opened this issue had already found the
  # same split (61/100 runs were pushes) and then exempted it.
  #
  # Pushes now classify from their pushed range exactly as a PR classifies from its diff. The caller
  # supplies the paths on stdin; a caller that cannot compute a range supplies NOTHING, and the
  # zero-path branch at the bottom of this file fails closed to full. That is deliberate reuse: the
  # fail-closed path is already tested, so a force-push or a new branch does not need its own.
  push|pull_request) ;;
  *)
    printf 'ci-route: unsupported event: %s\n' "${event_name:-<empty>}" >&2
    exit 2
    ;;
esac

docs_only=true
pdda_needed=false
full_required=false
changed_tests=""
tier2_subsystems=""
tier2_tests=""
test_touched=""
unmapped=""
path_count=0

# Existence checks below are deliberately CWD-relative, not ROOT-relative: classification
# answers "which tests does THE REPO BEING CLASSIFIED have", and a push is classified with
# its own repo as the working directory (test/ci-route.sh's rename fixture depends on this —
# a deleted test must fail closed against the pushed repo, an edited one must not).

add_changed_test() {
  local candidate="$1"
  [[ -f "test/$candidate" ]] || return 0
  case ",$changed_tests," in
    *",$candidate,"*) return 0 ;;
  esac
  changed_tests="${changed_tests:+$changed_tests,}$candidate"
}

add_tier2_test() {  # <suite> — only suites that exist; a subsystem with none runnable on disk
  local candidate="$1"     # escalates to tier 3 at the end, never a zero-test green
  [[ -f "test/$candidate" ]] || return 0
  case ",$tier2_tests," in
    *",$candidate,"*) return 0 ;;
  esac
  tier2_tests="${tier2_tests:+$tier2_tests,}$candidate"
}

while IFS= read -r path || [[ -n "$path" ]]; do
  [[ -n "$path" ]] || continue
  path_count=$((path_count + 1))

  # Docs surfaces (GH-35 Phase 1 widened the GH-509 list): evidence, transcripts, notes, and
  # governance levers (*.txt anywhere, decisions/, .pdda-* levers, .xyz-launch-artifact).
  # skills/**/SKILL.md lands here via *.md — explanatory markdown is a docs change; the
  # skill's CODE paths route through the subsystem registry instead.
  case "$path" in
    *.md|*.txt|PROJECT/*|docs/*|relay-system/*|decisions/*|.pdda-*|.xyz-launch-artifact)
      pdda_needed=true
      ;;
    *)
      docs_only=false
      ;;
  esac

  # These surfaces own the coordination kernel, containment boundary, frozen twins,
  # worktree safety, or CI gate itself. They require the full suite before merge.
  # (GH-35 moved utils/pdda/** and skills/agent2agent code off this list and into the
  # subsystem registry, per the issue's Tier-2 mapping; their focused suites run instead.)
  case "$path" in
    .github/workflows/*|validate.sh|utils/ci-route.sh|test/ci-route.sh|test/ci-workflow.sh)
      full_required=true
      ;;
    bin/tick|bin/validate-relay-block|src/*)
      full_required=true
      ;;
    relay-automation/*|skills/relay-automation/*|skills/relay-xyz/*)
      full_required=true
      ;;
    utils/py/*)
      # releases_app.py is subsystem code with a focused suite (GH-35), not an
      # authoritative twin; every other file under utils/py/ is kernel surface.
      [[ "$path" == "utils/py/releases_app.py" ]] || full_required=true
      ;;
    test/*worktree*|test/*containment*|test/tick-*|test/relay-*|test/agent2agent.sh|test/marathon*.sh)
      full_required=true
      ;;
    test/gh308-*|test/mktemp-trap-guard.sh|test/path-integrity.sh)
      full_required=true
      ;;
  esac

  # A change to a test is a change to the routing contract's own evidence: tier 3 always
  # (GH-35 review guardrail — the contract must not be weakened unnoticed), while route stays
  # fast so CI keeps running the edited suite as a changed-area test (GH-509 behavior).
  case "$path" in
    test/*) test_touched=true ;;
  esac

  # Tier-2 membership: only explicitly registered subsystem paths qualify; every other
  # non-doc path fails closed to tier 3.
  case "$path" in
    *.md|*.txt|PROJECT/*|docs/*|relay-system/*|decisions/*|.pdda-*|.xyz-launch-artifact)
      : # docs — neither disqualifies tier 1 nor joins a subsystem
      ;;
    *)
      sub="$(subsystem_of "$path" || true)"
      if [ -n "$sub" ]; then
        case " $tier2_subsystems " in
          *" $sub "*) ;;
          *) tier2_subsystems="${tier2_subsystems:+$tier2_subsystems }$sub" ;;
        esac
      else
        unmapped="$path"
      fi
      # PDDA-adjacent implementation still gets the PDDA gate even on tier 2.
      case "$path" in
        utils/pdda/*|utils/pdda-local-checks.sh|utils/pdda-catchup.sh|utils/pdda-doc-ready.sh)
          pdda_needed=true
          ;;
      esac
      ;;
  esac

  case "$path" in
    test/*.sh)
      if [[ -f "$path" ]]; then
        add_changed_test "${path#test/}"
      else
        # A deleted/renamed regression cannot be exercised as a changed-area test.
        # Fail closed so test removal is reviewed against the complete inventory.
        full_required=true
      fi
      ;;
    *.sh|*.js|*.py)
      stem="${path##*/}"
      stem="${stem%.*}"
      add_changed_test "$stem.sh"
      normalized_stem="$(printf '%s' "$stem" | tr '_' '-')"
      add_changed_test "$normalized_stem.sh"
      ;;
  esac
done

# An empty or unreadable PR diff is not proof that the change is documentation-only.
if [[ "$path_count" -eq 0 ]]; then
  docs_only=false
  pdda_needed=true
  full_required=true
fi

if [[ "$full_required" == true ]]; then
  pdda_needed=true
  route=full
elif [[ "$docs_only" == true ]]; then
  route=docs
else
  route=fast
fi

# ── GH-35 tier resolution — fail closed ──────────────────────────────────────────────────────────
# tier 3 unless proven otherwise. Kernel/gate surfaces and docs-only are decided above; the
# remaining candidates must have EVERY non-doc path mapped to a subsystem and touch no test.
tier=3
tier_reason=""
if [[ "$full_required" == true ]]; then
  tier_reason="kernel/gate surface (route=full)"
elif [[ "$docs_only" == true ]]; then
  tier=1
  tier_reason="docs-only"
elif [[ "$test_touched" == true ]]; then
  tier_reason="test change — the routing contract's own evidence stays on the full gate"
elif [[ -n "$unmapped" ]]; then
  tier_reason="unmapped path: $unmapped"
else
  tier=2
  tier_reason="subsystems: $tier2_subsystems"
  for s in $tier2_subsystems; do
    _tests="SUBSYSTEM_TESTS_${s//-/_}"
    for t in ${!_tests}; do
      add_tier2_test "$t"
    done
  done
  # A subsystem whose suites are missing on disk (partial checkout, stripped fixture) must
  # escalate rather than hand back a tier-2 gate with nothing to run.
  if [[ -z "$tier2_tests" ]]; then
    tier=3
    tier_reason="subsystems [$tier2_subsystems] have no runnable tests here — failing closed"
  fi
fi

printf '%s\n' \
  "docs_only=$docs_only" \
  "pdda_needed=$pdda_needed" \
  "full_required=$full_required" \
  "changed_tests=$changed_tests" \
  "route=$route" \
  "tier=$tier" \
  "tier2_subsystems=$tier2_subsystems" \
  "tier2_tests=$tier2_tests" \
  "tier_reason=$tier_reason"
