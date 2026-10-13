**SINGLE-MODEL — NOT RECONCILED** (only codex answered; 1 of 2 requested advisor(s) failed — this is one model's read, not a cross-model consult. Do not treat any claim below as cross-verified.)

**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-6-astra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
OpenAI Codex v0.153.4
--------
workdir: /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-68346-vx81h0en
model: gpt-6-astra
provider: openai
approval: never
sandbox: read-only
reasoning effort: low
reasoning summaries: none
session id: 01a0de18-5133-7e23-9e28-5d90ca7cfd5e
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Consult: should gh549 and gh436 leave the Small tier?

**Advisory only.** Do not edit files. Answer from the repository, and cite `file:line` for every claim.

## Background

XYZ-forge's gate now has three tiers (GH-831, merged in #834). After each merge, the hosted reconcile
(`utils/py/wave_reconcile.py`, `select_qualification_gate` and `qualify_landings`) classifies the landing's
changes with `utils/ci-route.sh`:

- **Tier 1** means docs, the ledger dumps (`releases.db`/`.sql`, `harnesses.*`) and non-core skill files. See
  `is_docs_surface()` in `utils/ci-route.sh`. The reconcile runs only the Small list,
  `SUBSYSTEM_TESTS_small` (73 suites), through `validate.sh --sequential --subsystem small`.
- **Anything else** runs the full registry, which includes every Small suite. Medium merges also run the full
  registry at the reconcile (operator decision O7).

Promotion always runs the full registry (O8).

The operator defined Small as "PDDA, PRS and canaries", where PRS is the RELEASES ledger and the post-merge
reconcile tools. Decision O2 in `PROJECT/2-WORKING/GH-831-THREE-TIER-GATE.md` kept `gh549-work-events.sh`
and `gh436-merge-cleanup.sh` in Small.

**Measured cost** (issue #835; hosted sequential run on macOS, commit `f832ef5a`):

| Suite | Hosted | Local, 4-wide |
|---|---|---|
| `gh549-work-events.sh` | 8.0 min | 5.9 min |
| `gh436-merge-cleanup.sh` | 4.4 min | 3.7 min |

Together they are about 12 of Small's ~18 hosted minutes. Without them, Small would take about 7 minutes.

## The question

Should `gh549-work-events.sh` and `gh436-merge-cleanup.sh` move from Small to Large? Large means the full
registry only: they stay registered and still run for every non-tier-1 landing and at promotion.

The deciding test: **can a tier-1 landing break what either suite checks?**

- If neither suite reads anything a tier-1 landing can change, it adds cost to Small without protecting it.
  Any change to its code is tier 2 or 3, so it gets the full run anyway.
- If a suite does read something tier-1-routable, it earns its place. Examples: the committed `releases.sql`
  or `releases.db`, a `SKILL.md`, a non-core skill script, a PROJECT doc, or ledger rows the reconcile writes.

## Please

1. For each suite, list what it reads or executes from the tracked tree. Read `test/gh549-work-events.sh` and
   `test/gh436-merge-cleanup.sh` and follow what they call. Mark each input tier-1-routable or not, using
   `is_docs_surface()` and `subsystem_of()`.
   - Pay attention to fixtures that copy the real `releases.sql`/`releases.db`, or read skill markdown such as
     `skills/2-daily/merge-cleanup/SKILL.md` (docs by rule 1), or any file under `skills/` that
     `is_docs_surface()` treats as docs.
   - Note whether a suite builds its own synthetic ledger instead.
2. Give a verdict for **each suite separately**: move to Large, keep in Small, or keep with a cheaper
   alternative. Name the concrete input that decides it.
3. Name the risk of moving it. Which tier-1 landing could then qualify while one of these suites would have
   failed on that commit? How would it be caught later: at the next full-run landing, or at promotion?
4. Is there a cheaper option than moving? Examples: a known slow section to trim, or splitting the part that
   reads tier-1 inputs from the part that doesn't. The repository rule forbids **new** test suites (AGENTS.md,
   *No new tests*), so no new suites. Editing an existing suite to keep it truthful or faster is allowed.
5. Anything in `SUBSYSTEM_TESTS_small` that this reasoning says is also misplaced, in either direction?

Keep it tight. End with a one-line recommendation.

codex
I’ll trace both suites’ tracked inputs and routing rules, then give a separate verdict for each.

exec
/bin/zsh -lc 'cat ROUTER.md GUIDING-PRINCIPLES.md >/dev/null; nl -ba utils/ci-route.sh | head -240; nl -ba test/gh549-work-events.sh; nl -ba test/gh436-merge-cleanup.sh' in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-68346-vx81h0en
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# Classify a CI invocation as docs-only, fast, or full — and, since GH-35, answer a second,
     3	# deliberately separate question: which local test-selection TIER the change belongs to.
     4	# Pull-request paths are read from stdin.
     5	#
     6	#   route=docs|fast|full  — the CI job shape (GH-509 semantics, unchanged)
     7	#   tier=1|2|3            — the local gate selection (GH-35): 1 docs, 2 subsystem, 3 full
     8	#
     9	# The two answers are kept separate on purpose (GH-35 review guardrail): test selection is
    10	# deterministic policy owned by this registry; resource policy (worker count, nice) is
    11	# validate.sh's business and never changes WHICH tests run. The tier fails closed — unknown
    12	# paths, any test/* change, and every kernel/containment/gate surface are tier 3.
    13	set -euo pipefail
    14	
    15	ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    16	
    17	# ── GH-35 Tier-2 subsystem registry ──────────────────────────────────────────────────────────────
    18	# The ONE mapping from changed paths to the focused suites that cover them, consumed by
    19	# githooks/pre-push and validate.sh (--tier 2 / --subsystem). Extending it is a deliberate
    20	# three-part act: name the subsystem in SUBSYSTEMS, add its path patterns to subsystem_of(),
    21	# and list its suites in SUBSYSTEM_TESTS_<name>. Every listed suite must exist in test/ AND
    22	# be registered in validate.sh's TESTS array — test/gh35-test-tiers.sh enforces both, because
    23	# a registry naming a suite that never runs is a green lie (the releases-skill lesson).
    24	SUBSYSTEMS="hq releases telemetry ate swe-diagram pdda agent-chorus standup skills-army-hq small"
    25	SUBSYSTEM_TESTS_hq="hq.sh hq-park.sh hq-park-synthesis.sh hq-dispatch.sh hq-next.sh hq-locator.sh hq-hardening.sh hq-promote.sh hq-marathon-scan.sh hq-rollup.sh hq-marathon-live.sh gh238-hq-releases-mode.sh gh239-hq-status-releases-mode.sh"
    26	SUBSYSTEM_TESTS_releases="gh32-releases-app.sh gh103-timeline-exporter.sh gh32-releases-artifacts.sh gh53-releases-merge-resolve.sh gh54-merged-dump-refusals.sh gh57-live-merge-resolve.sh gh69-roadmap-shadow.sh gh32-release-target-advisory.sh gh39-releases-project-sync.sh gh153-releases-sidebar-rollup.sh releases-skill.sh gh284-p3-release-milestone.sh gh284-p4-release-lanes.sh litmus-release.sh nightwatch-release.sh meter-release.sh ballast-release.sh gh57-releases-fuzz.sh gh257-roadmap-ledger-fixes.sh gh269-roadmap-retired.sh gh549-work-events.sh gh567-roadmap-dashboard-retired.sh gh568-releases-md-retired.sh gh646-status-label.sh"
    27	SUBSYSTEM_TESTS_telemetry="xyz-completion.sh gh358-lock-instrumentation.sh archive-telemetry.sh gh496-telemetry-isolation.sh"
    28	SUBSYSTEM_TESTS_ate="ate-run-variations.sh gh298-ate-gen4-ci-smoke.sh gh-gen4-phase1-domain-oracles.sh gh-gen4-phase2-adaptive-ate.sh gh-gen4-phase3-fuzz-engine.sh gh-gen4-phase4-repro-synth.sh gh-gen4-phase5-campaign.sh gh478-runaway-guard.sh gh712-jev-triage.sh synthetic/gh102-telemetry-schema.sh gh142-ate-exit-contract.sh"
    29	SUBSYSTEM_TESTS_swe_diagram="swe-diagram.sh"
    30	SUBSYSTEM_TESTS_pdda="gh649-pdda-migration.sh pdda-changelog.sh pdda-install-startup-docs.sh pdda-roadmap-coverage.sh pdda-repo-contract.sh pdda-local-checks.sh gh400-acceptance-fidelity.sh gh400-source-url.sh gh422-backfill-source-url.sh gh425-source-url-slug.sh wave-reconcile.sh gh202-wave-reconcile-issue-state.sh gh232-wave-reconcile-multiphase.sh gh358-wave-reconcile-vendored-paths.sh gh496-phase2-reconciliation-views.sh"
    31	SUBSYSTEM_TESTS_agent_chorus="agent-chorus.sh agent-chorus-bridge.sh gh233-agent-chorus-concurrency.sh"
    32	SUBSYSTEM_TESTS_standup="gh77-standup-triage.sh"
    33	SUBSYSTEM_TESTS_skills_army_hq="skills-army-hq.sh gh620-skills-army-mini-sync.sh gh589-xyz-mini-sync.sh gh589-consult-no-tick.sh gh589-skill-viewer.sh"
    34	# GH-831 D2: Small — the PDDA and PRS (releases/reconcile) suites plus the canaries. The hosted
    35	# reconcile qualifies a tier-1 landing with `validate.sh --sequential --subsystem small`, and
    36	# utils/py/wave_reconcile.py replays old receipts against THIS line at the tested commit, so keep
    37	# it one literal line. subsystem_of() claims no paths for small: it is a gate, not an area.
    38	SUBSYSTEM_TESTS_small="gh308-frozen-twin-guard.sh gh777-inventory-ratchet.sh gh400-acceptance-fidelity.sh gh400-source-url.sh litmus-release.sh gh422-backfill-source-url.sh gh425-source-url-slug.sh gh448-driver-lock-resolver.sh nightwatch-release.sh meter-release.sh ballast-release.sh gh549-work-events.sh gh646-status-label.sh gh1-fixture-guard.sh gh1-adoption-guard.sh gh139-pipe-grep-guard.sh gh168-wave-reconcile-scope.sh gh184-no-tracked-scratch.sh gh202-wave-reconcile-issue-state.sh gh232-wave-reconcile-multiphase.sh releases-skill.sh gh103-timeline-exporter.sh gh75-dashboard.sh gh32-releases-app.sh gh32-releases-artifacts.sh gh53-releases-merge-resolve.sh gh54-merged-dump-refusals.sh gh57-releases-fuzz.sh gh57-live-merge-resolve.sh gh69-roadmap-shadow.sh gh351-manifest-unship.sh gh360-scoped-receipt-chain-rebuild.sh gh349-releases-roadmap-vendored.sh gh429-wave-reconcile-vendored-observe.sh gh358-wave-reconcile-vendored-paths.sh gh32-release-target-advisory.sh gh39-releases-project-sync.sh relay-target-root.sh relay-target-root-paths.sh relay-target-root-relayfile.sh relay-target-root-newfile.sh gh649-pdda-migration.sh pdda-changelog.sh pdda-install-startup-docs.sh pdda-roadmap-coverage.sh pdda-repo-contract.sh pdda-local-checks.sh gh784-marathon-qa-gate.sh gh284-p3-release-milestone.sh gh284-p4-release-lanes.sh mktemp-trap-guard.sh gh567-roadmap-dashboard-retired.sh gh257-roadmap-ledger-fixes.sh gh269-roadmap-retired.sh gh568-releases-md-retired.sh gh454-reconciler-defects.sh gh424-roadmap-status-marker.sh gh421-auto-wave-reconcile.sh gh491-roadmap-section-validation.sh gh492-roadmap-state-sweep.sh gh605-work-state.sh gh605-board-policy.sh gh436-merge-cleanup.sh gh645-merge-cleanup-xyz-tools.sh gh674-merge-cleanup-hosted-lookup.sh gh527-issue-url-repair.sh gh153-releases-sidebar-rollup.sh security-scan.sh sentinel-network-guard.sh gh107-timeline-json-seam.sh wave-reconcile.sh gh496-phase2-reconciliation-views.sh gh306-registry-bidirectional.sh"
    39	
    40	subsystem_of() {  # <path> -> subsystem name, or nothing when unmapped
    41	  case "$1" in
    42	    utils/hq/*|skills/*/hq/*)                                                                printf '%s\n' hq ;;
    43	    utils/py/releases_app.py|utils/py/work_connectors/*|skills/*/releases/*|utils/release-lanes.sh|releases.sql|releases.db|utils/releases-merge-resolve.sh|utils/leaderboard.sh|test/gh549-work-events.sh|test/gh646-status-label.sh|test/gh646_status_label.py) printf '%s\n' releases ;;
    44	    utils/telemetry/*|test/gh496-telemetry-isolation.sh)                                  printf '%s\n' telemetry ;;
    45	    utils/ate/*|utils/fuzzing/*|utils/py/telemetry_schema.py|utils/py/domain_oracles.py|utils/py/adaptive_ate.py|utils/py/calibrate_tier1.py|utils/py/fuzz_engine.py|utils/py/repro_synth.py|utils/py/gen4_campaign.py|utils/py/proc_group.py|utils/py/ate_runaway_sweep.py) printf '%s\n' ate ;;
    46	    utils/swe-diagram/*)                                                                   printf '%s\n' swe-diagram ;;
    47	    utils/pdda/*|utils/pdda-local-checks.sh|utils/pdda-catchup.sh|utils/pdda-doc-ready.sh|utils/py/wave_reconcile.py) printf '%s\n' pdda ;;
    48	    skills/*/agent-chorus/*)                                                                 printf '%s\n' agent-chorus ;;
    49	    skills/*/standup/*)                                                                      printf '%s\n' standup ;;
    50	    skills/*/skills-army-hq/*|skills/*/push-to-skills-army-mini/*|mini/skills-army-*|docs/SPIN-OFF-REPOSITORY-PLAYBOOK.md|utils/py/xyz_mini_sync.py|test/test_deploy_skills.py|test/skills-army-hq.sh|test/gh620-skills-army-mini-sync.sh) printf '%s\n' skills-army-hq ;;
    51	  esac
    52	}
    53	
    54	# Docs surfaces: route=docs and tier 1 when nothing else is touched (GH-509, widened by GH-35 and
    55	# GH-487). GH-831 D4 adds skill files and the ledger. Precedence, in order:
    56	#   1. text, evidence and governance paths, as before (skills/**/SKILL.md lands here via *.md);
    57	#   2. the ledger/data dumps and their generated views — docs even though subsystem_of() claims
    58	#      releases.db/.sql, so a ledger-only push qualifies through the Small run;
    59	#   3. the non-text files of core skills (relay, relay-xyz, relay-automation, merge-cleanup, express,
    60	#      jog) are NOT docs; their markdown is, by rule 1, as before — the full-gate list below still
    61	#      catches every relay-xyz and relay-automation file;
    62	#   4. any other skills/** path is docs unless subsystem_of() claims it for an area.
    63	is_docs_surface() {
    64	  case "$1" in
    65	    *.md|*.txt|PROJECT/*|docs/*|relay-system/*|decisions/*|.pdda-*|.xyz-launch-artifact|TESTS-RESULTS/*) return 0 ;;
    66	    releases.db|releases.sql|harnesses.db|harnesses.sql|LEADERBOARD.html|RELEASES-PREVIEW.html) return 0 ;;
    67	    skills/*/relay/*|skills/*/relay-xyz/*|skills/*/relay-automation/*|skills/*/merge-cleanup/*|skills/*/express/*|skills/*/jog/*) return 1 ;;
    68	    skills/*) [ -z "$(subsystem_of "$1" || true)" ] ;;
    69	    *) return 1 ;;
    70	  esac
    71	}
    72	
    73	event_name="${1:-}"
    74	
    75	case "$event_name" in
    76	  # Registry listing — the drift guard and `validate.sh --subsystem` read this instead of
    77	  # re-deriving the mapping. A registered suite missing from disk fails LOUDLY here: a silent
    78	  # skip would turn `--tier 2 --subsystem <name>` into a zero-test gate that exits green.
    79	  subsystems)
    80	    want="${2:-}"
    81	    for s in $SUBSYSTEMS; do
    82	      _tests="SUBSYSTEM_TESTS_${s//-/_}"
    83	      for t in ${!_tests}; do
    84	        [[ -f "$ROOT/test/$t" ]] || { echo "ci-route: subsystem $s registers missing test test/$t" >&2; exit 2; }
    85	      done
    86	    done
    87	    found=0
    88	    for s in $SUBSYSTEMS; do
    89	      [ -z "$want" ] || [ "$want" = "$s" ] || continue
    90	      found=1
    91	      _tests="SUBSYSTEM_TESTS_${s//-/_}"
    92	      if [ -n "$want" ]; then printf '%s\n' "${!_tests}"
    93	      else printf '%s\t%s\n' "$s" "${!_tests}"; fi
    94	    done
    95	    if [ "$found" -eq 0 ]; then
    96	      echo "ci-route: unknown subsystem: '${want}' (known: $(printf '%s' "$SUBSYSTEMS" | tr ' ' ','))" >&2
    97	      exit 2
    98	    fi
    99	    exit 0
   100	    ;;
   101	  workflow_dispatch|schedule)
   102	    # Deliberate, operator-initiated, and rare. These are the only unconditional full routes left:
   103	    # a manual dispatch is someone asking for the whole gate, and answering it with a routed subset
   104	    # would be answering a different question than the one asked.
   105	    printf '%s\n' \
   106	      'docs_only=false' \
   107	      'pdda_needed=true' \
   108	      'full_required=true' \
   109	      'changed_tests=' \
   110	      'route=full' \
   111	      'tier=3' \
   112	      'tier2_subsystems=' \
   113	      'tier2_tests=' \
   114	      'tier_reason=operator-initiated full run'
   115	    exit 0
   116	    ;;
   117	  # GH-509 Phase 3 — `push` used to sit in the branch above, and that was 72% of the bill.
   118	  #
   119	  # Measured over 60 runs in ~24h: 37 pushes to `development`, EVERY ONE a full route, ~396 of ~551
   120	  # billed minutes. Phase 1 routed pull requests and cut their average from ~16 min to 6.1 — it
   121	  # worked, and it worked on the other 28%. The audit that opened this issue had already found the
   122	  # same split (61/100 runs were pushes) and then exempted it.
   123	  #
   124	  # Pushes now classify from their pushed range exactly as a PR classifies from its diff. The caller
   125	  # supplies the paths on stdin; a caller that cannot compute a range supplies NOTHING, and the
   126	  # zero-path branch at the bottom of this file fails closed to full. That is deliberate reuse: the
   127	  # fail-closed path is already tested, so a force-push or a new branch does not need its own.
   128	  push|pull_request) ;;
   129	  *)
   130	    printf 'ci-route: unsupported event: %s\n' "${event_name:-<empty>}" >&2
   131	    exit 2
   132	    ;;
   133	esac
   134	
   135	_validate_checked=0
   136	_validate_is_append_only=0
   137	_validate_added_tests=()
   138	
   139	check_validate_append_only() {
   140	  [ "$_validate_checked" -eq 1 ] && return 0
   141	  _validate_checked=1
   142	
   143	  [[ -f "validate.sh" ]] || return 0
   144	  bash -n "validate.sh" >/dev/null 2>&1 || return 0
   145	
   146	  local explicit_base="${CI_BASE:-${BASE_SHA:-${BEFORE_SHA:-}}}"
   147	  local base_content="" head_content=""
   148	
   149	  if [ -n "$explicit_base" ]; then
   150	    # When an explicit base is set, we MUST use it and NEVER fall back
   151	    if [ -z "${explicit_base//0/}" ]; then
   152	      return 0
   153	    fi
   154	    if ! git cat-file -e "${explicit_base}^{commit}" 2>/dev/null; then
   155	      return 0
   156	    fi
   157	    base_content="$(git show "${explicit_base}:validate.sh" 2>/dev/null)" || return 0
   158	    head_content="$(cat validate.sh 2>/dev/null)" || return 0
   159	  else
   160	    local diff_rc=0
   161	    git diff --no-renames --quiet HEAD -- validate.sh 2>/dev/null || diff_rc=$?
   162	    if [ "$diff_rc" -eq 0 ]; then
   163	      # Working tree is clean: compare HEAD~1 to HEAD
   164	      if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
   165	        base_content="$(git show "HEAD~1:validate.sh" 2>/dev/null)" || return 0
   166	        head_content="$(git show "HEAD:validate.sh" 2>/dev/null)" || return 0
   167	      else
   168	        return 0
   169	      fi
   170	    elif [ "$diff_rc" -eq 1 ]; then
   171	      # Working tree has modifications: compare HEAD to working tree
   172	      base_content="$(git show "HEAD:validate.sh" 2>/dev/null)" || return 0
   173	      head_content="$(cat validate.sh 2>/dev/null)" || return 0
   174	    else
   175	      # diff command failed (e.g. exit 128 / corruption) -> fail closed immediately
   176	      return 0
   177	    fi
   178	  fi
   179	
   180	  [ -n "$base_content" ] && [ -n "$head_content" ] || return 0
   181	
   182	  local py_out
   183	  if py_out="$(python3 -c '
   184	import sys, re
   185	base_content = sys.argv[1]
   186	head_content = sys.argv[2]
   187	
   188	def parse_validate(content):
   189	    lines = content.splitlines()
   190	    in_tests = False
   191	    array_lines = []
   192	    skeleton = []
   193	    start_re = re.compile(r"^\s*TESTS=\(\s*$")
   194	    end_re = re.compile(r"^\s*\)\s*$")
   195	    for l in lines:
   196	        if not in_tests:
   197	            if start_re.match(l):
   198	                in_tests = True
   199	                skeleton.append("TESTS=(")
   200	            else:
   201	                skeleton.append(l)
   202	        else:
   203	            if end_re.match(l):
   204	                in_tests = False
   205	                skeleton.append(")")
   206	            else:
   207	                array_lines.append(l)
   208	    if in_tests:
   209	        return None, None
   210	    return skeleton, array_lines
   211	
   212	base_skel, base_arr = parse_validate(base_content)
   213	head_skel, head_arr = parse_validate(head_content)
   214	
   215	if base_skel is None or head_skel is None or base_skel != head_skel:
   216	    sys.exit(1)
   217	
   218	it = iter(head_arr)
   219	if not all(line in it for line in base_arr):
   220	    sys.exit(1)
   221	
   222	test_re = re.compile(r"^\s*\"([a-zA-Z0-9._-]+\.sh)\"(?:\s*#.*)?$")
   223	comment_re = re.compile(r"^\s*(?:#.*)?$")
   224	
   225	base_it = iter(base_arr)
   226	curr_base = next(base_it, None)
   227	added_tests = []
   228	has_added = False
   229	
   230	for h_line in head_arr:
   231	    if curr_base is not None and h_line == curr_base:
   232	        curr_base = next(base_it, None)
   233	    else:
   234	        has_added = True
   235	        m = test_re.match(h_line)
   236	        if m:
   237	            added_tests.append(m.group(1))
   238	        elif comment_re.match(h_line):
   239	            pass
   240	        else:
     1	#!/usr/bin/env bash
     2	# gh549-work-events.sh — GH-549: the work-state event stream at the single ledger write seam.
     3	#
     4	# Proves:
     5	#   1. Migration 008 creates work_events + connector_cursors and stamps version 8.
     6	#   2. work_events is append-only: UPDATE and DELETE are both refused by name.
     7	#   3. work_events is in the canonical dump but NOT in the business-digest view of it.
     8	#   4. connector_cursors is in NEITHER — it is device-local, written after the transaction.
     9	#   5. Real ledger verbs emit the right event: roadmap add -> parked, rate -> rated,
    10	#      update --status-marker 🚧 -> in_flight.
    11	#   6. The extractor registry is TOTAL: every op reachable from a perform_write caller is
    12	#      either mapped or allowlisted, and an unclassified op raises.
    13	#   7. `check --rebuild` round-trips work_events (dump -> DB) without loss.
    14	#   8. RED CONTROL A: emitting work_events ABOVE dump_text's include_receipts guard puts it
    15	#      inside business_digest and makes `check` report receipt-chain. Proves the placement is
    16	#      what protects the chain.
    17	#   9. RED CONTROL B: adding connector_cursors to dump_text makes a post-transaction cursor
    18	#      advance fail dump-divergence, while the SHIPPED code stays clean under the identical
    19	#      advance. Proves cursors must stay out of the dump (Codex plan-QA r1 blocker).
    20	set -uo pipefail
    21	
    22	ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    23	. "$ROOT/test/lib/fixture-guard.sh"
    24	require_forge_root releases.db   # GH-708: forge-root only — witnessed skip in a vendored .xyz/
    25	APP="$ROOT/utils/py/releases_app.py"
    26	
    27	. "$ROOT/test/lib/fixture-guard.sh"
    28	
    29	PASS=0; FAIL=0
    30	ok()  { PASS=$((PASS + 1)); echo "  ok  - $1"; }
    31	bad() { FAIL=$((FAIL + 1)); echo "  FAIL- $1"; }
    32	
    33	WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh549-work-events.XXXXXX")"
    34	fixture_guard_init "$WORK"
    35	cleanup() { rm -rf "$WORK"; }
    36	trap cleanup EXIT
    37	
    38	[ -f "$APP" ] || { echo "releases_app.py missing at $APP" >&2; exit 1; }
    39	
    40	# ── a real ledger fixture: a git checkout (the writer lock needs a git common-dir, GH-448) ──
    41	FX="$WORK/ledger"; mkdir -p "$FX"
    42	require_fixture "$FX" "gh549 ledger fixture"
    43	( cd "$FX" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
    44	cp "$ROOT/releases.db" "$ROOT/releases.sql" "$FX/" 2>/dev/null || {
    45	  echo "gh549: no ledger to copy from $ROOT" >&2; exit 1; }
    46	app() { python3 "$APP" --root "$FX" "$@"; }
    47	
    48	echo "GH-549 work-state event stream:"
    49	
    50	echo "1. migration 008"
    51	app migrate >/dev/null 2>&1
    52	VER="$(sqlite3 "$FX/releases.db" "SELECT version FROM schema_migrations WHERE version=8;" 2>/dev/null)"
    53	[ "$VER" = "8" ] && ok "schema_migrations carries version 8" || bad "version 8 not stamped (got '$VER')"
    54	OBJ="$(sqlite3 "$FX/releases.db" "SELECT group_concat(name,',') FROM sqlite_master WHERE name IN ('work_events','connector_cursors','work_events_no_update','work_events_no_delete') ORDER BY name;" 2>/dev/null)"
    55	case "$OBJ" in
    56	  *work_events*) ok "work_events, connector_cursors and both triggers exist" ;;
    57	  *) bad "expected objects missing (got '$OBJ')" ;;
    58	esac
    59	for t in work_events_no_update work_events_no_delete; do
    60	  # capture-then-match: a pipe into grep -q loses the producer's exit status (gh139)
    61	  TRG="$(sqlite3 "$FX/releases.db" "SELECT 1 FROM sqlite_master WHERE type='trigger' AND name='$t';")"
    62	  [ "$TRG" = "1" ] && ok "trigger $t present" || bad "trigger $t missing"
    63	done
    64	
    65	echo "2. work_events is append-only (witnessed refusals)"
    66	RID="$(sqlite3 "$FX/releases.db" "SELECT id FROM repos LIMIT 1;")"
    67	sqlite3 "$FX/releases.db" "INSERT INTO work_events(global_id,repo_id,gh_number,txn_id,event,payload,at) VALUES ('wev-01M25ZRSCSHSA1SRZVK8ZPQJBS',$RID,1,'txn-t','probe',NULL,'2026-09-10T00:00:00Z');" 2>/dev/null
    68	U="$(sqlite3 "$FX/releases.db" "UPDATE work_events SET event='x' WHERE txn_id='txn-t';" 2>&1)"
    69	case "$U" in *"append-only"*) ok "UPDATE refused: work_events is append-only" ;;
    70	  *) bad "UPDATE was NOT refused (got '$U')" ;; esac
    71	D="$(sqlite3 "$FX/releases.db" "DELETE FROM work_events WHERE txn_id='txn-t';" 2>&1)"
    72	case "$D" in *"append-only"*) ok "DELETE refused: work_events is append-only" ;;
    73	  *) bad "DELETE was NOT refused (got '$D')" ;; esac
    74	sqlite3 "$FX/releases.db" "DROP TRIGGER work_events_no_delete; DELETE FROM work_events WHERE txn_id='txn-t'; CREATE TRIGGER work_events_no_delete BEFORE DELETE ON work_events BEGIN SELECT RAISE(ABORT,'work_events is append-only'); END;" 2>/dev/null
    75	
    76	echo "5. real verbs emit the right events"
    77	app roadmap add --issue-num 9901 --issue-url "https://example.invalid/9901" \
    78	    --title "gh549 fixture" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
    79	app roadmap rate --issue-num 9901 --rated 10/20/30/40 >/dev/null 2>&1
    80	app roadmap update --issue-num 9901 --status-marker "🚧" >/dev/null 2>&1
    81	EV="$(sqlite3 "$FX/releases.db" "SELECT group_concat(event,',') FROM (SELECT event FROM work_events WHERE gh_number=9901 ORDER BY id);")"
    82	[ -n "$EV" ] || bad "no events emitted at all — the fixture proves nothing"
    83	[ "$EV" = "parked,rated,in_flight" ] \
    84	  && ok "roadmap add/rate/update emitted parked,rated,in_flight" \
    85	  || bad "wrong event sequence (got '$EV')"
    86	app check >/dev/null 2>&1 && ok "check is clean after three emitting writes" || bad "check failed after emission"
    87	
    88	echo "6. dump placement (the load-bearing decision), with rows present"
    89	ROWS="$(sqlite3 "$FX/releases.db" "SELECT count(*) FROM work_events;")"
    90	[ "${ROWS:-0}" -gt 0 ] || bad "no work_events rows - the placement probe would pass vacuously"
    91	cat > "$WORK/place.py" <<'PYPROBE'
    92	import sys, os, sqlite3
    93	sys.path.insert(0, os.path.join(os.environ["GH549_ROOT"], "utils", "py"))
    94	import releases_app as R
    95	conn = sqlite3.connect(sys.argv[1]); conn.row_factory = sqlite3.Row
    96	full = R.dump_text(conn, 0)
    97	biz  = R.dump_text(conn, 0, include_receipts=False, include_generation=False)
    98	print("full_we=%s biz_we=%s full_cc=%s" % ("work_events" in full, "work_events" in biz,
    99	                                           "connector_cursors" in full))
   100	PYPROBE
   101	PLACE="$(GH549_ROOT="$ROOT" python3 "$WORK/place.py" "$FX/releases.db")"
   102	case "$PLACE" in
   103	  "full_we=True biz_we=False full_cc=False")
   104	    ok "work_events is in the canonical dump but NOT in the business-digest view"
   105	    ok "connector_cursors is in neither — device-local by design" ;;
   106	  *) bad "dump placement wrong: $PLACE" ;;
   107	esac
   108	
   109	echo "7. the extractor registry is total"
   110	cat > "$WORK/cov.py" <<'PYPROBE'
   111	import sys, os, re
   112	root = os.environ["GH549_ROOT"]
   113	sys.path.insert(0, os.path.join(root, "utils", "py"))
   114	import releases_app as R
   115	src = open(os.path.join(root, "utils", "py", "releases_app.py"), encoding="utf-8").read()
   116	# Derive the op inventory from source rather than hardcoding a count (Codex plan-QA r4):
   117	# every literal passed as perform_write's `op` argument.
   118	ops = set(re.findall(r'perform_write\(\s*root,\s*conn,\s*"([a-z0-9-]+)"', src))
   119	ops |= set(re.findall(r'perform_write\([^,]+,\s*conn,\s*"([a-z0-9-]+)"', src))
   120	unclassified = []
   121	for op in sorted(ops):
   122	    try:
   123	        R.extractor_for(op)
   124	    except KeyError:
   125	        unclassified.append(op)
   126	print("ops=%d unclassified=%s" % (len(ops), ",".join(unclassified) or "none"))
   127	PYPROBE
   128	COV="$(GH549_ROOT="$ROOT" python3 "$WORK/cov.py")"
   129	case "$COV" in
   130	  *"unclassified=none"*) ok "every derived op is mapped or allowlisted ($COV)" ;;
   131	  *) bad "unclassified ops found: $COV" ;;
   132	esac
   133	cat > "$WORK/raises.py" <<'PYPROBE'
   134	import sys, os
   135	sys.path.insert(0, os.path.join(os.environ["GH549_ROOT"], "utils", "py"))
   136	import releases_app as R
   137	try:
   138	    R.extractor_for("a-brand-new-verb")
   139	    print("NO")
   140	except KeyError:
   141	    print("YES")
   142	PYPROBE
   143	RAISES="$(GH549_ROOT="$ROOT" python3 "$WORK/raises.py")"
   144	[ "$RAISES" = "YES" ] && ok "an unclassified op raises, so a new verb cannot silently drop a state" \
   145	                      || bad "unclassified op did not raise"
   146	
   147	# Snapshot BEFORE the rebuild: a merge-rebuild receipt re-anchors the chain, and the chain
   148	# rule tolerates re-anchors — so a fixture taken after step 8 would absorb control A's break
   149	# and the control would pass vacuously.
   150	PRISTINE="$WORK/pristine"; mkdir -p "$PRISTINE"
   151	require_fixture "$PRISTINE" "gh549 pre-rebuild ledger snapshot"
   152	cp "$FX/releases.db" "$FX/releases.sql" "$PRISTINE/"
   153	# GH-695: $PRISTINE is a copy of the LIVE ledger, whose work_events grows with every reconcile. The
   154	# legs that drive the real github_board connector replay every event past the cursor through the
   155	# mock -- one subprocess each -- inside CONNECTOR_WINDOW_S (5s). With the cursor deleted, the replay
   156	# crossed the window at ~124 rows (green at 101) and leg 17 went red on development with no code
   157	# change; leg 26 followed at ~133. Pin every real-mock fixture's cursor to the pristine ledger's tail
   158	# so a leg replays exactly the events it emits itself: the assertions are "the connector moves a card",
   159	# never "it can drain N months of history in 5s". A red-variant copy re-seeds to the SAME tail so its
   160	# re-replay covers the leg's own events again. Stub-connector legs keep their plain DELETE (fast).
   161	PRISTINE_TAIL="$(sqlite3 "$PRISTINE/releases.db" "SELECT COALESCE(MAX(id),0) FROM work_events;")"
   162	seed_cursor_tail() {  # <releases.db>  -> cursor for github_board = $PRISTINE_TAIL (insert or reset)
   163	  sqlite3 "$1" "INSERT INTO connector_cursors(connector,last_event_id,updated_at) VALUES('github_board',$PRISTINE_TAIL,'2026-09-18T00:00:00Z') ON CONFLICT(connector) DO UPDATE SET last_event_id=$PRISTINE_TAIL;"
   164	}
   165	
   166	echo "8. rebuild round-trips work_events"
   167	BEFORE="$(sqlite3 "$FX/releases.db" "SELECT count(*) FROM work_events;")"
   168	app check --rebuild >/dev/null 2>&1
   169	AFTER="$(sqlite3 "$FX/releases.db" "SELECT count(*) FROM work_events;")"
   170	[ "$BEFORE" -gt 0 ] || bad "fixture had zero events — round-trip proves nothing"
   171	[ "$BEFORE" = "$AFTER" ] && ok "check --rebuild preserved all $AFTER work_events rows" \
   172	                         || bad "rebuild lost rows ($BEFORE -> $AFTER)"
   173	
   174	echo "9. RED CONTROL A — work_events above the include_receipts guard breaks the chain"
   175	MUTA="$WORK/mutA.py"
   176	python3 - "$APP" "$MUTA" <<'PYMUT'
   177	import sys
   178	src = open(sys.argv[1], encoding="utf-8").read()
   179	anchor = '        if _table_exists(conn, "work_events"):'
   180	tail = '    return "\\n".join(out) + "\\n"'
   181	assert anchor in src, "MUTA: work_events emit anchor not found - the control would be a no-op"
   182	assert tail in src, "MUTA: dump_text return anchor not found - the control would be a no-op"
   183	i = src.index(anchor)
   184	j = src.index(tail, i)
   185	block = src[i:j]
   186	dedented = "\n".join(l[4:] if l.startswith("    ") else l for l in block.split("\n"))
   187	out = src[:i] + src[j:]
   188	k = out.index("    if include_receipts:")
   189	mutated = out[:k] + dedented + out[k:]
   190	assert mutated != src, "MUTA: mutation produced an identical file"
   191	open(sys.argv[2], "w", encoding="utf-8").write(mutated)
   192	PYMUT
   193	FXA="$WORK/ledgerA"; mkdir -p "$FXA"; require_fixture "$FXA" "gh549 red-control-A fixture"
   194	( cd "$FXA" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
   195	cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXA/"
   196	python3 "$MUTA" --root "$FXA" roadmap add --issue-num 9902 --issue-url "https://example.invalid/9902" \
   197	    --title "red A one" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/y.md" >/dev/null 2>&1
   198	python3 "$MUTA" --root "$FXA" roadmap add --issue-num 9903 --issue-url "https://example.invalid/9903" \
   199	    --title "red A two" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/z.md" >/dev/null 2>&1
   200	MUTA_OUT="$(python3 "$MUTA" --root "$FXA" check 2>&1)"
   201	[ -n "$MUTA_OUT" ] || bad "  control A produced no output at all — it proves nothing"
   202	case "$MUTA_OUT" in
   203	  *"rule=receipt-chain"*) ok "mutated placement makes check report receipt-chain (the red fires)" ;;
   204	  *) bad "RED CONTROL A did not fire — the placement is not what protects the chain" ;;
   205	esac
   206	
   207	echo "10. RED CONTROL B — connector_cursors in the dump breaks the dump comparison"
   208	MUTB="$WORK/mutB.py"
   209	python3 - "$APP" "$MUTB" <<'PYMUT'
   210	import sys
   211	src = open(sys.argv[1], encoding="utf-8").read()
   212	anchor = '        if _table_exists(conn, "work_events"):'
   213	assert anchor in src, "MUTB: anchor not found - the control would be a no-op"
   214	add = ('        if _table_exists(conn, "connector_cursors"):\n'
   215	       '            _emit(w, "connector_cursors",\n'
   216	       '                  ["connector", "last_event_id", "last_attempt_at", "last_error", "updated_at"],\n'
   217	       '                  _rows(conn, "SELECT connector, last_event_id, last_attempt_at, last_error, "\n'
   218	       '                              "updated_at FROM connector_cursors ORDER BY connector"))\n')
   219	mutated = src.replace(anchor, add + anchor, 1)
   220	assert mutated != src, "MUTB: mutation produced an identical file"
   221	open(sys.argv[2], "w", encoding="utf-8").write(mutated)
   222	PYMUT
   223	FXB="$WORK/ledgerB"; mkdir -p "$FXB"; require_fixture "$FXB" "gh549 red-control-B fixture"
   224	( cd "$FXB" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
   225	cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXB/"
   226	python3 "$MUTB" --root "$FXB" roadmap add --issue-num 9904 --issue-url "https://example.invalid/9904" \
   227	    --title "red B" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/d.md" >/dev/null 2>&1
   228	python3 "$MUTB" --root "$FXB" check >/dev/null 2>&1 \
   229	  && ok "  baseline: mutated build is clean before any cursor exists" \
   230	  || bad "  baseline: mutated build was already dirty — the next assertion would prove nothing"
   231	# a connector advancing its cursor, exactly as the dispatcher will, AFTER the transaction
   232	sqlite3 "$FXB/releases.db" "INSERT INTO connector_cursors(connector,last_event_id,last_attempt_at,last_error,updated_at) VALUES ('github_board',1,'2026-09-10T00:00:00Z',NULL,'2026-09-10T00:00:00Z');"
   233	MUTB_OUT="$(python3 "$MUTB" --root "$FXB" check 2>&1)"
   234	[ -n "$MUTB_OUT" ] || bad "  control B produced no output at all — it proves nothing"
   235	case "$MUTB_OUT" in
   236	  *"rule=dump-divergence"*) ok "cursor in the dump + post-transaction advance => dump-divergence (the red fires)" ;;
   237	  *) bad "RED CONTROL B did not fire — cursors could be tracked without breaking check" ;;
   238	esac
   239	if python3 "$APP" --root "$FXB" check >/dev/null 2>&1; then
   240	  ok "SHIPPED code is clean under the identical cursor advance (the fix holds)"
   241	else
   242	  bad "shipped code also failed — the fix does not hold"
   243	fi
   244	
   245	echo "11. shared nested-block config resolution (device_config.resolve_device_block)"
   246	# Absent config is a silent no-op; a malformed file must be distinguishable from it. That
   247	# distinction is the whole reason profile_resolve.py re-opens the file by hand today.
   248	cat > "$WORK/cfgprobe.py" <<'PYPROBE'
   249	import sys, os, json, tempfile
   250	sys.path.insert(0, os.path.join(os.environ["GH549_ROOT"], "utils", "py"))
   251	import device_config as D
   252	
   253	DEF = {"owner": "", "number": 0, "repos": [], "on": False}
   254	
   255	def probe(path):
   256	    os.environ["XYZ_DEVICE_CONFIG_PATH"] = path
   257	    return D.resolve_device_block("work_connectors", DEF, "XYZ_WC")
   258	
   259	tmp = tempfile.mkdtemp()
   260	missing = os.path.join(tmp, "nope.json")
   261	cfg, err = probe(missing)
   262	print("absent_err=%s absent_defaults=%s" % (err is None, cfg == DEF))
   263	
   264	bad = os.path.join(tmp, "bad.json")
   265	open(bad, "w").write("{not json")
   266	cfg, err = probe(bad)
   267	print("malformed_err=%s" % (err is not None))
   268	
   269	empty = os.path.join(tmp, "empty.json")
   270	open(empty, "w").write("")
   271	cfg, err = probe(empty)
   272	print("empty_is_absent=%s" % (err is None))
   273	
   274	good = os.path.join(tmp, "good.json")
   275	json.dump({"work_connectors": {"owner": "someone", "number": 7, "repos": "o/n"}}, open(good, "w"))
   276	cfg, err = probe(good)
   277	print("file_tier=%s list_coerced=%s" % (cfg["owner"] == "someone" and cfg["number"] == 7,
   278	                                        cfg["repos"] == ["o/n"]))
   279	
   280	os.environ["XYZ_WC_OWNER"] = "envwins"
   281	os.environ["XYZ_WC_NUMBER"] = "42"
   282	cfg, err = probe(good)
   283	print("env_wins=%s int_coerced=%s" % (cfg["owner"] == "envwins", cfg["number"] == 42))
   284	PYPROBE
   285	CFGOUT="$(GH549_ROOT="$ROOT" python3 "$WORK/cfgprobe.py" 2>&1)"
   286	[ -n "$CFGOUT" ] || bad "config probe produced no output"
   287	case "$CFGOUT" in *"absent_err=True absent_defaults=True"*)
   288	  ok "an absent config is a silent no-op returning the defaults" ;;
   289	  *) bad "absent config not handled: $CFGOUT" ;; esac
   290	case "$CFGOUT" in *"malformed_err=True"*)
   291	  ok "a malformed config reports an error instead of looking absent" ;;
   292	  *) bad "malformed config was indistinguishable from absent: $CFGOUT" ;; esac
   293	case "$CFGOUT" in *"empty_is_absent=True"*)
   294	  ok "an empty config file counts as absent, not malformed" ;;
   295	  *) bad "empty file misclassified: $CFGOUT" ;; esac
   296	case "$CFGOUT" in *"file_tier=True list_coerced=True"*)
   297	  ok "the file tier resolves, and a bare string where a list belongs is coerced" ;;
   298	  *) bad "file tier wrong: $CFGOUT" ;; esac
   299	case "$CFGOUT" in *"env_wins=True int_coerced=True"*)
   300	  ok "the env tier outranks the file and coerces to the default's type" ;;
   301	  *) bad "env tier wrong: $CFGOUT" ;; esac
   302	
   303	# board_sync must behave identically after being migrated onto the shared resolver.
   304	BS="$(XYZ_DEVICE_CONFIG_PATH=/dev/null python3 "$ROOT/utils/py/board_sync.py" config 2>&1)"
   305	case "$BS" in
   306	  *'"project_owner"'*) ok "board_sync config still resolves through the shared block resolver" ;;
   307	  *) bad "board_sync config broke after the migration: $BS" ;;
   308	esac
   309	
   310	echo "12. connector dispatch: concurrent, bounded, isolated"
   311	# Three stub connectors. Each reads its batch as JSON on stdin and reports on stdout, exactly
   312	# as a real connector does; none of them touches the database.
   313	cat > "$WORK/stub_ok.py" <<'PYSTUB'
   314	import json, sys
   315	b = json.load(sys.stdin)
   316	print("advanced_to: %d" % max(e["id"] for e in b["events"]))
   317	PYSTUB
   318	cat > "$WORK/stub_fail.py" <<'PYSTUB'
   319	import json, sys
   320	json.load(sys.stdin)
   321	sys.stderr.write("deliberate connector failure\n")
   322	sys.exit(3)
   323	PYSTUB
   324	cat > "$WORK/stub_slow.py" <<'PYSTUB'
   325	import json, sys, time
   326	b = json.load(sys.stdin)
   327	time.sleep(5)
   328	print("advanced_to: %d" % max(e["id"] for e in b["events"]))
   329	PYSTUB
   330	
   331	cat > "$WORK/dispatch_probe.py" <<'PYPROBE'
   332	import json, os, sqlite3, sys, time
   333	root = os.environ["GH549_ROOT"]
   334	sys.path.insert(0, os.path.join(root, "utils", "py"))
   335	import work_connectors as WC
   336	
   337	db  = sys.argv[1]
   338	work = sys.argv[2]
   339	mode = sys.argv[3]
   340	os.environ["XYZ_WORK_CONNECTORS_REGISTRY"] = json.dumps({
   341	    "s_ok":   os.path.join(work, "stub_ok.py"),
   342	    "s_fail": os.path.join(work, "stub_fail.py"),
   343	    "s_slow": os.path.join(work, "stub_slow.py"),
   344	    "s_slow2": os.path.join(work, "stub_slow.py"),
   345	})
   346	cfg = {"enabled": True}
   347	
   348	if mode == "isolation":
   349	    # one failing, one succeeding: the good one must still advance, the bad one must not
   350	    res = WC.dispatch(db, "2026-09-10T00:00:00Z",
   351	                      connectors={"s_ok": cfg, "s_fail": cfg}, window_s=30)
   352	    c = sqlite3.connect(db)
   353	    rows = dict(c.execute("SELECT connector, last_event_id FROM connector_cursors").fetchall())
   354	    errs = dict(c.execute("SELECT connector, last_error IS NOT NULL FROM connector_cursors").fetchall())
   355	    print("ok_advanced=%s fail_stuck=%s fail_recorded=%s" % (
   356	        rows.get("s_ok", 0) > 0, rows.get("s_fail", 0) == 0, bool(errs.get("s_fail"))))
   357	
   358	elif mode == "concurrency":
   359	    # two 5s sleepers under one 30s window: concurrent launch finishes in ~5s, serial in ~10s
   360	    t0 = time.monotonic()
   361	    WC.dispatch(db, "2026-09-10T00:00:00Z",
   362	                connectors={"s_slow": cfg, "s_slow2": cfg}, window_s=30)
   363	    print("elapsed=%.2f" % (time.monotonic() - t0))
   364	
   365	elif mode == "window":
   366	    # the same two sleepers under a 2s TOTAL window: both are killed, neither advances,
   367	    # and the whole call still returns in about one window rather than two.
   368	    #
   369	    # Reset the cursors first. The concurrency run above advanced them to the last event, so
   370	    # without this there would be nothing pending, dispatch would return {} in 0.00s, and both
   371	    # assertions would pass for the wrong reason.
   372	    c = sqlite3.connect(db)
   373	    c.execute("DELETE FROM connector_cursors WHERE connector IN ('s_slow','s_slow2')")
   374	    c.commit()
   375	    pending = c.execute("SELECT count(*) FROM work_events").fetchone()[0]
   376	    c.close()
   377	    if not pending:
   378	        print("elapsed=0 advanced=NO-EVENTS")
   379	        raise SystemExit(0)
   380	    t0 = time.monotonic()
   381	    res = WC.dispatch(db, "2026-09-10T00:00:00Z",
   382	                      connectors={"s_slow": cfg, "s_slow2": cfg}, window_s=2)
   383	    print("elapsed=%.2f dispatched=%d advanced=%s" % (time.monotonic() - t0, len(res),
   384	                                                      [v[0] for v in res.values()]))
   385	PYPROBE
   386	
   387	FXC="$WORK/ledgerC"; mkdir -p "$FXC"; require_fixture "$FXC" "gh549 dispatch fixture"
   388	( cd "$FXC" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
   389	cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXC/"
   390	EVN="$(sqlite3 "$FXC/releases.db" "SELECT count(*) FROM work_events;")"
   391	[ "${EVN:-0}" -gt 0 ] || bad "  dispatch fixture has no events — every dispatch assertion would be vacuous"
   392	
   393	ISO="$(GH549_ROOT="$ROOT" python3 "$WORK/dispatch_probe.py" "$FXC/releases.db" "$WORK" isolation 2>&1)"
   394	case "$ISO" in
   395	  *"ok_advanced=True fail_stuck=True fail_recorded=True"*)
   396	    ok "two connectors, one failing: the good one advanced, the bad one did not, its error was recorded" ;;
   397	  *) bad "connector isolation wrong: $ISO" ;;
   398	esac
   399	
   400	CONC="$(GH549_ROOT="$ROOT" python3 "$WORK/dispatch_probe.py" "$FXC/releases.db" "$WORK" concurrency 2>&1)"
   401	CSEC="$(printf '%s' "$CONC" | sed -n 's/.*elapsed=\([0-9.]*\).*/\1/p')"
   402	if [ -n "$CSEC" ] && python3 -c "import sys; sys.exit(0 if float('$CSEC') < 8.0 else 1)"; then
   403	  ok "two 5s connectors finished in ${CSEC}s — launched concurrently, not serially"
   404	else
   405	  bad "dispatch is serial: two 5s connectors took ${CSEC:-?}s (serial would be ~10s)"
   406	fi
   407	
   408	WIN="$(GH549_ROOT="$ROOT" python3 "$WORK/dispatch_probe.py" "$FXC/releases.db" "$WORK" window 2>&1)"
   409	case "$WIN" in
   410	  *"dispatched=2"*) : ;;
   411	  *) bad "  the window probe dispatched nothing — both window assertions would be vacuous ($WIN)" ;;
   412	esac
   413	WSEC="$(printf '%s' "$WIN" | sed -n 's/.*elapsed=\([0-9.]*\).*/\1/p')"
   414	if [ -n "$WSEC" ] && python3 -c "import sys; sys.exit(0 if 1.5 < float('$WSEC') < 6.0 else 1)"; then
   415	  ok "two hung connectors cost ONE ${WSEC}s window, not one timeout each"
   416	else
   417	  bad "the window is not one total deadline: ${WSEC:-?}s (expected ~2s, serial would be ~4s)"
   418	fi
   419	case "$WIN" in
   420	  *"advanced=[None, None]"*) ok "a connector killed at the deadline does not advance its cursor" ;;
   421	  *) bad "a timed-out connector advanced anyway: $WIN" ;;
   422	esac
   423	
   424	echo "13. dispatch never changes a host verb's exit code"
   425	FXD="$WORK/ledgerD"; mkdir -p "$FXD"; require_fixture "$FXD" "gh549 host-rc fixture"
   426	( cd "$FXD" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
   427	cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXD/"
   428	cat > "$WORK/devcfg.json" <<'PYCFG'
   429	{"work_connectors": {"github_board": {"enabled": true, "project_owner": "nobody", "project_number": 1}}}
   430	PYCFG
   431	XYZ_DEVICE_CONFIG_PATH="$WORK/devcfg.json" XYZ_CONNECTOR_WINDOW_S=2 \
   432	  python3 "$APP" --root "$FXD" roadmap add --issue-num 9920 --issue-url "https://example.invalid/9920" \
   433	  --title "host rc" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/rc.md" >/dev/null 2>&1
   434	RC=$?
   435	[ "$RC" -eq 0 ] && ok "a ledger verb exits 0 even with a connector configured that cannot succeed" \
   436	                || bad "connector failure changed the host exit code (rc=$RC)"
   437	ROW="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM roadmap_items WHERE gh_number=9920;")"
   438	[ "$ROW" = "1" ] && ok "and the ledger row is committed regardless" || bad "ledger row missing after dispatch"
   439	python3 "$APP" --root "$FXD" check >/dev/null 2>&1 \
   440	  && ok "and check is clean after a dispatching write" || bad "check dirty after a dispatching write"
   441	
   442	echo "14. work emit — one row, real txn_id, its own receipt"
   443	FXE="$WORK/ledgerE"; mkdir -p "$FXE"; require_fixture "$FXE" "gh549 work-emit fixture"
   444	( cd "$FXE" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
   445	cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXE/"
   446	EB="$(sqlite3 "$FXE/releases.db" "SELECT count(*) FROM work_events;")"
   447	XYZ_DEVICE_CONFIG_PATH=/dev/null python3 "$APP" --root "$FXE" work emit \
   448	  --event pr_merged --gh-number 549 --payload-json '{"pr":548}' >/dev/null 2>&1
   449	EA="$(sqlite3 "$FXE/releases.db" "SELECT count(*) FROM work_events;")"
   450	[ "$((EA - EB))" = "1" ] \
   451	  && ok "one work emit creates EXACTLY one row (not zero, not two)" \
   452	  || bad "work emit wrote $((EA - EB)) rows, expected 1"
   453	ROW="$(sqlite3 "$FXE/releases.db" "SELECT event||'|'||gh_number||'|'||(length(txn_id)>8) FROM work_events ORDER BY id DESC LIMIT 1;")"
   454	case "$ROW" in
   455	  "pr_merged|549|1") ok "the row carries the real transaction id minted inside perform_write" ;;
   456	  *) bad "work emit row wrong: $ROW" ;;
   457	esac
   458	RCPT="$(sqlite3 "$FXE/releases.db" "SELECT op FROM op_receipts ORDER BY id DESC LIMIT 1;")"
   459	[ "$RCPT" = "work-emit" ] \
   460	  && ok "and it went through perform_write — its own receipt is on the chain" \
   461	  || bad "no work-emit receipt (last op was '$RCPT') — it bypassed the single write path"
   462	XYZ_DEVICE_CONFIG_PATH=/dev/null python3 "$APP" --root "$FXE" check >/dev/null 2>&1 \
   463	  && ok "check is clean after work emit" || bad "check dirty after work emit"
   464	
   465	echo "15. work reconcile — replay, idempotence, reset"
   466	cat > "$WORK/stub_ok2.py" <<'PYSTUB'
   467	import json, sys
   468	b = json.load(sys.stdin)
   469	print("advanced_to: %d" % max(e["id"] for e in b["events"]))
   470	PYSTUB
   471	cat > "$WORK/recon_cfg.json" <<'PYCFG'
   472	{"work_connectors": {"github_board": {"enabled": true, "project_owner": "someone", "project_number": 1}}}
   473	PYCFG
   474	REG="{\"github_board\":\"$WORK/stub_ok2.py\"}"
   475	NOCFG="$(XYZ_DEVICE_CONFIG_PATH=/dev/null python3 "$APP" --root "$FXE" work reconcile 2>&1)"
   476	case "$NOCFG" in
   477	  *"no connectors enabled"*) ok "unconfigured reconcile is a no-op that says so" ;;
   478	  *) bad "unconfigured reconcile did something: $NOCFG" ;;
   479	esac
   480	R1="$(XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG" \
   481	      python3 "$APP" --root "$FXE" work reconcile 2>&1)"
   482	case "$R1" in
   483	  *"replayed through event"*) ok "reconcile replays the events after the cursor" ;;
   484	  *) bad "reconcile did not replay: $R1" ;;
   485	esac
   486	R2="$(XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG" \
   487	      python3 "$APP" --root "$FXE" work reconcile 2>&1)"
   488	case "$R2" in
   489	  *"nothing to replay"*) ok "a second run is idempotent — the cursor is current" ;;
   490	  *) bad "reconcile was not idempotent: $R2" ;;
   491	esac
   492	R3="$(XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG" \
   493	      python3 "$APP" --root "$FXE" work reconcile --reset 2>&1)"
   494	case "$R3" in
   495	  *"replayed through event"*) ok "--reset replays from the beginning (the rebuild recovery path)" ;;
   496	  *) bad "--reset did not replay: $R3" ;;
   497	esac
   498	# Red control: an overshot cursor IN THE TABLE skips real events. This is why a connector is
   499	# never trusted to set that number itself — the guard below is what keeps it from doing so.
   500	LAST="$(sqlite3 "$FXE/releases.db" "SELECT max(id) FROM work_events;")"
   501	[ -n "$LAST" ] && [ "$LAST" -gt 0 ] \
   502	  || bad "fixture guard: no work_events rows — the overshoot control would be vacuous"
   503	sqlite3 "$FXE/releases.db" "UPDATE connector_cursors SET last_event_id = $((LAST + 5)) WHERE connector='github_board';"
   504	R4="$(XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG" \
   505	      python3 "$APP" --root "$FXE" work reconcile 2>&1)"
   506	case "$R4" in
   507	  *"nothing to replay"*) ok "red control: an overshot cursor skips real events — which is why replay is cursor-driven, not scan-driven" ;;
   508	  *) bad "an overshot cursor still replayed: $R4" ;;
   509	esac
   510	
   511	echo "15b. a connector cannot advance its own cursor out of the batch it was handed (impl QA r1)"
   512	# The child's stdout is untrusted input. Reset the cursor so there IS a real batch to dispatch,
   513	# then have the stub report a number beyond it. The old behaviour stored that number verbatim,
   514	# permanently skipping every event up to it.
   515	sqlite3 "$FXE/releases.db" "DELETE FROM connector_cursors WHERE connector='github_board';"
   516	cat > "$WORK/stub_overshoot.py" <<'PYSTUB'
   517	import json, sys
   518	b = json.load(sys.stdin)
   519	print("advanced_to: %d" % (max(e["id"] for e in b["events"]) + 5))
   520	PYSTUB
   521	REG_OVER="{\"github_board\":\"$WORK/stub_overshoot.py\"}"
   522	BATCH="$(sqlite3 "$FXE/releases.db" "SELECT count(*) FROM work_events;")"
   523	[ "$BATCH" -gt 0 ] || bad "fixture guard: nothing to dispatch — the overshoot guard test would be vacuous"
   524	R5="$(XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG_OVER" \
   525	      python3 "$APP" --root "$FXE" work reconcile 2>&1)"
   526	case "$R5" in
   527	  *"overshoots the dispatched batch"*) ok "an overshooting connector is REFUSED, with the reason named" ;;
   528	  *) bad "overshoot was not refused: $R5" ;;
   529	esac
   530	CUR="$(sqlite3 "$FXE/releases.db" "SELECT last_event_id FROM connector_cursors WHERE connector='github_board';")"
   531	[ "$CUR" = "0" ] \
   532	  && ok "and its cursor did NOT move — the batch stays replayable" \
   533	  || bad "the cursor advanced to $CUR despite the refusal"
   534	ERRTXT="$(sqlite3 "$FXE/releases.db" "SELECT last_error FROM connector_cursors WHERE connector='github_board';")"
   535	case "$ERRTXT" in
   536	  *overshoot*) ok "the refusal is recorded on the cursor row, not just printed" ;;
   537	  *) bad "no overshoot error persisted (last_error=$ERRTXT)" ;;
   538	esac
   539	# A backwards report is equally a failed run: it would replay events already acknowledged.
   540	XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG" \
   541	  python3 "$APP" --root "$FXE" work reconcile >/dev/null 2>&1
   542	cat > "$WORK/stub_back.py" <<'PYSTUB'
   543	import json, sys
   544	json.load(sys.stdin)
   545	print("advanced_to: 1")
   546	PYSTUB
   547	REG_BACK="{\"github_board\":\"$WORK/stub_back.py\"}"
   548	sqlite3 "$FXE/releases.db" "DELETE FROM connector_cursors WHERE connector='github_board';"
   549	XYZ_DEVICE_CONFIG_PATH=/dev/null python3 "$APP" --root "$FXE" work emit \
   550	  --event pr_merged --gh-number 552 --payload-json '{"pr":559}' >/dev/null 2>&1
   551	sqlite3 "$FXE/releases.db" "INSERT INTO connector_cursors(connector,last_event_id,updated_at) VALUES('github_board',2,'x') ON CONFLICT(connector) DO UPDATE SET last_event_id=2;"
   552	R6="$(XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG_BACK" \
   553	      python3 "$APP" --root "$FXE" work reconcile 2>&1)"
   554	case "$R6" in
   555	  *"does not move the cursor forward"*) ok "a backwards report is refused too, so acknowledged events are not replayed" ;;
   556	  *) bad "a backwards advanced_to was accepted: $R6" ;;
   557	esac
   558	
   559	echo "15c. red control — the bounds guard is load-bearing"
   560	# Strip the guard and the same overshoot lands. Without this, 15b would pass against a build
   561	# that never had the check, because a stub COULD legitimately report the batch maximum.
   562	# releases_app.py puts its OWN directory first on sys.path before importing work_connectors, so
   563	# PYTHONPATH cannot shadow the module. Mutate a full copy of utils/py and run the copy's app.
   564	GUARDED="$WORK/wc_guarded"; rm -rf "$GUARDED"; mkdir -p "$GUARDED"
   565	cp -R "$ROOT/utils/py/." "$GUARDED/"
   566	python3 - "$GUARDED/work_connectors/__init__.py" <<'PYMUT'
   567	import io, sys
   568	p = sys.argv[1]
   569	s = io.open(p, encoding="utf-8").read()
   570	anchor = "        elif advanced > batch_max:"
   571	assert anchor in s, "red control found no anchor to mutate — the guard moved; fix this control"
   572	s = s.replace(anchor, "        elif False:", 1)
   573	io.open(p, "w", encoding="utf-8").write(s)
   574	PYMUT
   575	[ $? -eq 0 ] || bad "red control mutation failed"
   576	grep -q "elif False:" "$GUARDED/work_connectors/__init__.py" \
   577	  || bad "red control: the mutation did not land in the copy the app will import"
   578	sqlite3 "$FXE/releases.db" "DELETE FROM connector_cursors WHERE connector='github_board';"
   579	MAXID="$(sqlite3 "$FXE/releases.db" "SELECT max(id) FROM work_events;")"
   580	XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG_OVER" \
   581	  python3 "$GUARDED/releases_app.py" --root "$FXE" work reconcile >/dev/null 2>&1
   582	CUR2="$(sqlite3 "$FXE/releases.db" "SELECT last_event_id FROM connector_cursors WHERE connector='github_board';")"
   583	[ "$CUR2" = "$((MAXID + 5))" ] \
   584	  && ok "red control: without the guard the overshoot IS stored ($CUR2 > $MAXID) — the guard is what stops it" \
   585	  || bad "red control did not reproduce the defect (cursor=$CUR2, expected $((MAXID + 5)))"
   586	sqlite3 "$FXE/releases.db" "DELETE FROM connector_cursors WHERE connector='github_board';"
   587	
   588	echo "16. the merge emitter keys on the issue, never the PR"
   589	MC="$ROOT/skills/2-daily/merge-cleanup/scripts/merge_cleanup.py"
   590	cat > "$WORK/mcprobe.py" <<'PYPROBE'
   591	import sys, os
   592	sys.path.insert(0, os.path.join(os.environ["GH549_ROOT"], "skills", "2-daily", "merge-cleanup", "scripts"))
   593	import merge_cleanup as M
   594	print("linked=%s" % M.linked_issues({"title": "feat: x", "body": "Closes #549 and fixes #402"}))
   595	print("none=%s" % M.linked_issues({"title": "chore", "body": "no refs at all"}))
   596	print("dry=%s" % M.emit_pr_merged(".", {"number": 1, "title": "t", "body": "Closes #1"}, dry_run=True))
   597	PYPROBE
   598	MCOUT="$(GH549_ROOT="$ROOT" python3 "$WORK/mcprobe.py" 2>&1)"
   599	case "$MCOUT" in
   600	  *"linked=[549, 402]"*) ok "a merged PR's closed issues are what get the event" ;;
   601	  *) bad "linked-issue extraction wrong: $MCOUT" ;;
   602	esac
   603	case "$MCOUT" in
   604	  *"none=[]"*) ok "a PR that closes nothing emits nothing — no card for a non-work-item" ;;
   605	  *) bad "a PR with no linked issue still produced one: $MCOUT" ;;
   606	esac
   607	case "$MCOUT" in
   608	  *"dry=0"*) ok "a dry run emits nothing" ;;
   609	  *) bad "dry run emitted an event: $MCOUT" ;;
   610	esac
   611	python3 - "$MC" <<'PYORDER'
   612	import ast, sys
   613	src = open(sys.argv[1], encoding="utf-8").read()
   614	tree = ast.parse(src)
   615	fn = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "land_prs")
   616	post = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "run_post_merge_reconcile")
   617	wait = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "wait_for_hosted_reconcile")
   618	lines = {}
   619	for node in ast.walk(fn):
   620	    if not isinstance(node, ast.Call):
   621	        continue
   622	    name = node.func.attr if isinstance(node.func, ast.Attribute) else getattr(node.func, "id", "")
   623	    if name in {"execute_pr_merge", "run_post_merge_reconcile", "emit_pr_merged", "commit_and_push_phase5_writes"}:
   624	        lines.setdefault(name, node.lineno)
   625	    if name == "run_git" and any(
   626	        isinstance(a, ast.Constant) and a.value == "--ff-only" for a in ast.walk(node)
   627	    ):
   628	        lines.setdefault("landing_fast_forward", node.lineno)
   629	assert lines["execute_pr_merge"] < lines["landing_fast_forward"] < lines["run_post_merge_reconcile"] < lines["emit_pr_merged"] < lines["commit_and_push_phase5_writes"], lines
   630	post_calls = {
   631	    node.func.attr if isinstance(node.func, ast.Attribute) else getattr(node.func, "id", "")
   632	    for node in ast.walk(post) if isinstance(node, ast.Call)
   633	}
   634	wait_calls = {
   635	    node.func.attr if isinstance(node.func, ast.Attribute) else getattr(node.func, "id", "")
   636	    for node in ast.walk(wait) if isinstance(node, ast.Call)
   637	}
   638	assert {"wait_for_hosted_reconcile", "run_local_wave_reconcile"} <= post_calls, post_calls
   639	assert {"_gh", "sleep"} <= wait_calls, wait_calls
   640	assert '"--workflow", "wave-reconcile.yml"' in src
   641	assert 'expected_heads = {head for head in (merged_head, pr_head) if head}' in src
   642	assert 'str(run.get("headSha") or "") in expected_heads' in src
   643	assert 'HOSTED_WAIT_ENV = "MERGE_CLEANUP_HOSTED_WAIT_S"' in src
   644	PYORDER
   645	[ $? -eq 0 ] \
   646	  && ok "merge-cleanup waits for hosted reconciliation before emission, then commits and pushes the event" \
   647	  || bad "merge-cleanup Phase 5 durability order drifted"
   648	
   649	echo "17. the VENDORED github_board connector, through normal config, offline (impl QA r2)"
   650	# The registry names work_connectors.github_board. Round 2 found the module did not exist, so
   651	# every ordinary configured run failed to import instead of touching a board. This leg drives the
   652	# real vendored connector -- NO XYZ_WORK_CONNECTORS_REGISTRY overlay anywhere -- against the
   653	# offline mock, which is the only path a real user ever takes.
   654	MOCK="$ROOT/utils/py/mock_gh_board.py"
   655	[ -f "$ROOT/utils/py/work_connectors/github_board.py" ] \
   656	  || bad "the registry's github_board module does not exist — every configured run would fail to import"
   657	python3 "$MOCK" --reset --state "$WORK/mock17.json" >/dev/null 2>&1
   658	python3 "$MOCK" --seed  --state "$WORK/mock17.json" >/dev/null 2>&1
   659	cat > "$WORK/board_cfg.json" <<'PYCFG'
   660	{"board_sync": {"project_owner": "noelsaw1", "project_number": 3,
   661	                "repos": ["HiQS-Labs/XYZ-forge"], "status_field": "Status",
   662	                "in_progress": "In progress"},
   663	 "work_connectors": {"github_board": {"enabled": true, "project_owner": "noelsaw1",
   664	                     "project_number": 3, "repos": ["HiQS-Labs/XYZ-forge"],
   665	                     "status_map": {"pr_merged": "Done", "rated": ""}}}}
   666	PYCFG
   667	FXB="$WORK/fx_board"; rm -rf "$FXB"; mkdir -p "$FXB"
   668	( cd "$FXB" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
   669	cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXB/"
   670	seed_cursor_tail "$FXB/releases.db"   # GH-695: replay only this leg's own event (see the helper)
   671	TAIL17="$PRISTINE_TAIL"
   672	XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$APP" --root "$FXB" work emit \
   673	  --event pr_merged --gh-number 405 --payload-json '{"pr":559}' >/dev/null 2>&1
   674	NEV="$(sqlite3 "$FXB/releases.db" "SELECT count(*) FROM work_events WHERE event='pr_merged';")"
   675	[ "$NEV" -gt 0 ] || bad "fixture guard: no pr_merged event to feed the connector — leg 17 would be vacuous"
   676	B4="$(python3 "$MOCK" --dump --state "$WORK/mock17.json" 2>/dev/null | python3 -c "
   677	import json,sys
   678	d=json.load(sys.stdin)
   679	# The mock stores status as an option id under field_values, keyed by the Status field id --
   680	# resolve it back to the column NAME, so this asserts the column and not an opaque id.
   681	f=d.get('fields',{}).get('Status',{})
   682	names={o['id']:o['name'] for o in f.get('options',[])}
   683	it=next((i for i in d.get('items',[]) if i.get('number')==405), None)
   684	print('absent' if it is None else names.get(next(iter((it.get('field_values') or {}).values()), None),'unset'))" 2>/dev/null)"
   685	R17="$(XYZ_DEVICE_CONFIG_PATH="$WORK/board_cfg.json" XYZ_BOARD_SYNC_GH_BIN="$MOCK" \
   686	       XYZ_MOCK_BOARD_STATE="$WORK/mock17.json" XYZ_BOARD_SYNC_STATE_PATH="$WORK/sync17.json" \
   687	       python3 "$APP" --root "$FXB" work reconcile 2>&1)"
   688	case "$R17" in
   689	  *"replayed through event"*) ok "the vendored connector runs from normal config with no registry overlay" ;;
   690	  *) bad "the vendored connector did not complete: $R17" ;;
   691	esac
   692	AFTER="$(python3 "$MOCK" --dump --state "$WORK/mock17.json" 2>/dev/null | python3 -c "
   693	import json,sys
   694	d=json.load(sys.stdin)
   695	# The mock stores status as an option id under field_values, keyed by the Status field id --
   696	# resolve it back to the column NAME, so this asserts the column and not an opaque id.
   697	f=d.get('fields',{}).get('Status',{})
   698	names={o['id']:o['name'] for o in f.get('options',[])}
   699	it=next((i for i in d.get('items',[]) if i.get('number')==405), None)
   700	print('absent' if it is None else names.get(next(iter((it.get('field_values') or {}).values()), None),'unset'))" 2>/dev/null)"
   701	[ "$AFTER" = "Done" ] \
   702	  && ok "and it MOVED THE CARD to the configured column (was '$B4', now '$AFTER')" \
   703	  || bad "the card did not reach the configured column (was '$B4', now '$AFTER')"
   704	CUR17="$(sqlite3 "$FXB/releases.db" "SELECT last_event_id FROM connector_cursors WHERE connector='github_board';")"
   705	NEW17="$(sqlite3 "$FXB/releases.db" "SELECT MAX(id) FROM work_events;")"
   706	[ -n "$CUR17" ] && [ "$CUR17" -gt "$TAIL17" ] && [ "$CUR17" = "$NEW17" ] \
   707	  && ok "and its cursor advanced past the seeded tail to this leg's own event ($TAIL17 -> $CUR17)" \
   708	  || bad "the cursor did not advance to this leg's event (seeded $TAIL17, now '$CUR17', newest $NEW17)"
   709	# The column mapping is user config, not code: an empty mapping means 'do not place this one'.
   710	python3 - "$ROOT" <<'PYMAP'
   711	import sys, os
   712	sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py"))
   713	from work_connectors.github_board import column_for, DEFAULT_STATUS_MAP
   714	m = dict(DEFAULT_STATUS_MAP); m.update({"pr_merged": "Shipped", "rated": ""})
   715	assert column_for("pr_merged", m) == "Shipped", "a user override did not win"
   716	assert column_for("rated", m) is None, "an empty mapping did not disable the transition"
   717	assert column_for("no_such_event", m) is None, "an unknown event was not skipped"
   718	print("mapping-ok")
   719	PYMAP
   720	[ $? -eq 0 ] \
   721	  && ok "the event -> column mapping is user config: an override wins and an empty value disables it" \
   722	  || bad "the status_map override contract is broken"
   723	
   724	echo "18. XYZ_WORK_CONNECTORS=0 is a GLOBAL kill switch, not just a hot-path one (impl QA r2)"
   725	# Round 2 found the switch was checked only in _dispatch_work_connectors, so `work reconcile`,
   726	# which calls dispatch() directly, sailed past it. The check now lives in load_connectors, which
   727	# is the one function both paths go through. The stub writes a sentinel file if it ever runs.
   728	cat > "$WORK/stub_sentinel.py" <<'PYSTUB'
   729	import json, os, sys
   730	b = json.load(sys.stdin)
   731	open(os.environ["GH549_SENTINEL"], "w").write("ran")
   732	print("advanced_to: %d" % max(e["id"] for e in b["events"]))
   733	PYSTUB
   734	SENT="$WORK/killswitch.sentinel"; rm -f "$SENT"
   735	sqlite3 "$FXB/releases.db" "DELETE FROM connector_cursors;"
   736	REG_SENT="{\"github_board\":\"$WORK/stub_sentinel.py\"}"
   737	KS="$(GH549_SENTINEL="$SENT" XYZ_WORK_CONNECTORS=0 XYZ_DEVICE_CONFIG_PATH="$WORK/board_cfg.json" \
   738	      XYZ_WORK_CONNECTORS_REGISTRY="$REG_SENT" python3 "$APP" --root "$FXB" work reconcile 2>&1)"
   739	[ ! -f "$SENT" ] \
   740	  && ok "with the switch off, work reconcile spawned NO connector child" \
   741	  || bad "the kill switch did not stop reconcile — the connector ran anyway"
   742	CUR18="$(sqlite3 "$FXB/releases.db" "SELECT count(*) FROM connector_cursors;")"
   743	[ "$CUR18" = "0" ] \
   744	  && ok "and no cursor was written" \
   745	  || bad "the kill switch left $CUR18 cursor row(s) behind"
   746	case "$KS" in
   747	  *"no connectors enabled"*|*"XYZ_WORK_CONNECTORS=0"*) ok "and it says why, rather than looking like an empty config" ;;
   748	  *) bad "the switch was silent about itself: $KS" ;;
   749	esac
   750	# Red control: the same command with the switch OFF must run the child. Without this, leg 18
   751	# would pass against a build where the connector was broken for some entirely other reason.
   752	rm -f "$SENT"
   753	KS2="$(GH549_SENTINEL="$SENT" XYZ_DEVICE_CONFIG_PATH="$WORK/board_cfg.json" \
   754	       XYZ_WORK_CONNECTORS_REGISTRY="$REG_SENT" python3 "$APP" --root "$FXB" work reconcile 2>&1)"
   755	[ -f "$SENT" ] \
   756	  && ok "red control: without the switch the SAME command does run the child — the switch is what stopped it" \
   757	  || bad "red control: the child did not run even with the switch off ($KS2)"
   758	
   759	echo "19. two overlapping dispatches are serialized, and a cursor never goes backwards (impl QA r3)"
   760	# perform_write releases the WriterLock BEFORE dispatching, deliberately -- a governance writer
   761	# must not hold it across network time. The consequence round 3 found is that two ledger writes
   762	# can dispatch overlapping batches: A reads cursor 0 and takes event 1, B reads cursor 0 and takes
   763	# events 1 and 2, and whichever finishes LAST decides the board. If A finishes last the card is
   764	# set back to event 1's column and the cursor regresses -- a projection stuck at a stale state.
   765	FXC="$WORK/fx_conc"; rm -rf "$FXC"; mkdir -p "$FXC"
   766	( cd "$FXC" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
   767	cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXC/"
   768	sqlite3 "$FXC/releases.db" "DELETE FROM connector_cursors;"
   769	for N in 601 602; do
   770	  XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$APP" --root "$FXC" work emit \
   771	    --event pr_merged --gh-number "$N" --payload-json '{"pr":559}' >/dev/null 2>&1
   772	done
   773	NCONC="$(sqlite3 "$FXC/releases.db" "SELECT count(*) FROM work_events;")"
   774	[ "$NCONC" -ge 2 ] || bad "fixture guard: need >=2 events to overlap two dispatches, have $NCONC"
   775	cat > "$WORK/stub_slow.py" <<'PYSTUB'
   776	import json, os, sys, time
   777	b = json.load(sys.stdin)
   778	with open(os.environ["GH549_RUNLOG"], "a") as fh:
   779	    fh.write("start %d\n" % os.getpid())
   780	# A two-party readiness barrier (impl QA r4). Without it the red control could pass by scheduling
   781	# luck: if the second process is not scheduled until the first has already persisted its advance,
   782	# it sees the new cursor and runs no child even with the lock removed, and the red assertion fails
   783	# spuriously. Here each child announces arrival and waits for a peer, so the overlap the control
   784	# claims to observe is FORCED rather than hoped for. A child that waits alone (the serialized
   785	# case, where the second never gets this far) simply times out and proceeds -- that path is the
   786	# positive assertion, which wants exactly one child.
   787	bar = os.environ.get("GH549_BARRIER")
   788	if bar:
   789	    with open(bar, "a") as fh:
   790	        fh.write("%d\n" % os.getpid())
   791	    deadline = time.monotonic() + float(os.environ.get("GH549_BARRIER_WAIT", "6"))
   792	    while time.monotonic() < deadline:
   793	        try:
   794	            if len(open(bar).read().split()) >= 2:
   795	                break
   796	        except Exception:
   797	            pass
   798	        time.sleep(0.05)
   799	time.sleep(1.5)
   800	with open(os.environ["GH549_RUNLOG"], "a") as fh:
   801	    fh.write("end %d\n" % os.getpid())
   802	print("advanced_to: %d" % max(e["id"] for e in b["events"]))
   803	PYSTUB
   804	REG_SLOW="{\"github_board\":\"$WORK/stub_slow.py\"}"
   805	RUNLOG="$WORK/conc_runs.log"
   806	
   807	# Two `work reconcile` processes fired together. Under the lock the second WAITS, then reads the
   808	# cursor the first advanced and finds nothing left -- so exactly ONE child ever runs.
   809	: > "$RUNLOG"
   810	sqlite3 "$FXC/releases.db" "DELETE FROM connector_cursors;"
   811	for i in 1 2; do
   812	  GH549_RUNLOG="$RUNLOG" XYZ_CONNECTOR_LOCK_WAIT_S=15 XYZ_CONNECTOR_WINDOW_S=30 \
   813	    XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG_SLOW" \
   814	    python3 "$APP" --root "$FXC" work reconcile >/dev/null 2>&1 &
   815	done
   816	wait
   817	STARTS="$(grep -c '^start ' "$RUNLOG" 2>/dev/null | head -1)"; STARTS="${STARTS:-0}"
   818	[ "$STARTS" = "1" ] \
   819	  && ok "two concurrent dispatches ran exactly ONE child — the second saw the advanced cursor" \
   820	  || bad "the connector lock did not serialize: $STARTS children ran"
   821	MAXID2="$(sqlite3 "$FXC/releases.db" "SELECT max(id) FROM work_events;")"
   822	CURC="$(sqlite3 "$FXC/releases.db" "SELECT last_event_id FROM connector_cursors WHERE connector='github_board';")"
   823	[ "$CURC" = "$MAXID2" ] \
   824	  && ok "and the cursor finished at the NEWEST event ($CURC), not an older batch's" \
   825	  || bad "the cursor finished at $CURC, expected $MAXID2"
   826	
   827	# Red control: without the lock the SAME two commands both dispatch the same batch.
   828	GUARD2="$WORK/wc_nolock"; rm -rf "$GUARD2"; mkdir -p "$GUARD2"
   829	cp -R "$ROOT/utils/py/." "$GUARD2/"
   830	python3 - "$GUARD2/work_connectors/__init__.py" <<'PYMUT2'
   831	import io, sys
   832	p = sys.argv[1]
   833	s = io.open(p, encoding="utf-8").read()
   834	anchor = "                fcntl.flock(self.fh.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)"
   835	assert anchor in s, "red control found no flock call to remove — the lock moved; fix this control"
   836	s = s.replace(anchor, "                pass  # lock removed by the red control", 1)
   837	io.open(p, "w", encoding="utf-8").write(s)
   838	PYMUT2
   839	[ $? -eq 0 ] || bad "red control mutation failed"
   840	grep -q "lock removed by the red control" "$GUARD2/work_connectors/__init__.py" \
   841	  || bad "red control: the mutation did not land in the copy the app will import"
   842	: > "$RUNLOG"
   843	BARRIER="$WORK/conc_barrier"; : > "$BARRIER"
   844	sqlite3 "$FXC/releases.db" "DELETE FROM connector_cursors;"
   845	for i in 1 2; do
   846	  GH549_RUNLOG="$RUNLOG" GH549_BARRIER="$BARRIER" GH549_BARRIER_WAIT=8 \
   847	    XYZ_CONNECTOR_LOCK_WAIT_S=15 XYZ_CONNECTOR_WINDOW_S=40 \
   848	    XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG_SLOW" \
   849	    python3 "$GUARD2/releases_app.py" --root "$FXC" work reconcile >/dev/null 2>&1 &
   850	done
   851	wait
   852	STARTS2="$(grep -c '^start ' "$RUNLOG" 2>/dev/null | head -1)"; STARTS2="${STARTS2:-0}"
   853	[ "$STARTS2" -ge 2 ] \
   854	  && ok "red control: without the lock BOTH dispatches ran the same batch ($STARTS2 children) — the lock is what stops it" \
   855	  || bad "red control did not reproduce the overlap ($STARTS2 children)"
   856	
   857	# The cursor is monotonic in the store itself, independent of the lock — the second line of
   858	# defence, so an out-of-order persist can never re-deliver acknowledged events.
   859	sqlite3 "$FXC/releases.db" "DELETE FROM connector_cursors;"
   860	python3 - "$ROOT" "$FXC/releases.db" <<'PYMONO'
   861	import sys, os
   862	sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py"))
   863	import work_connectors as W
   864	db = sys.argv[2]
   865	W._persist(db, {"github_board": (9, None)}, "t1")
   866	W._persist(db, {"github_board": (4, None)}, "t2")   # an older batch persisting late
   867	import sqlite3
   868	c = sqlite3.connect(db)
   869	got = c.execute("SELECT last_event_id FROM connector_cursors WHERE connector='github_board'").fetchone()[0]
   870	assert got == 9, "cursor regressed to %s" % got
   871	print("monotonic-ok")
   872	PYMONO
   873	[ $? -eq 0 ] \
   874	  && ok "a late older persist cannot lower the cursor (9 stays 9)" \
   875	  || bad "the cursor is not monotonic — an older batch lowered it"
   876	sqlite3 "$FXC/releases.db" "DELETE FROM connector_cursors;"
   877	
   878	echo "20. the connector lock fails CLOSED, and --reset is inside it (impl QA r4)"
   879	# r4 graded the old fail-open fallback High: a lock we cannot take used to dispatch anyway, which
   880	# silently re-enabled the round-3 race on exactly the paths nobody exercises. Point the lock at a
   881	# path that cannot be created and assert the batch is DEFERRED, not dispatched unserialized.
   882	: > "$RUNLOG"
   883	sqlite3 "$FXC/releases.db" "DELETE FROM connector_cursors;"
   884	NOLOCKDIR="$WORK/nolock"; rm -rf "$NOLOCKDIR"; mkdir -p "$NOLOCKDIR"
   885	cp "$FXC/releases.db" "$NOLOCKDIR/releases.db"
   886	python3 - "$ROOT" "$NOLOCKDIR/releases.db" "$WORK/stub_slow.py" "$RUNLOG" <<'PYFAILCLOSED'
   887	import os, sys
   888	root, db, stub, runlog = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
   889	sys.path.insert(0, os.path.join(root, "utils", "py"))
   890	os.environ["GH549_RUNLOG"] = runlog
   891	os.environ["XYZ_WORK_CONNECTORS_REGISTRY"] = '{"github_board": "%s"}' % stub
   892	import work_connectors as W
   893	# A lock path that cannot be opened: its parent is a FILE, so open() raises ENOTDIR.
   894	blocker = db + "-blocked"
   895	open(blocker, "w").write("x")
   896	real = W._ConnectorLock          # captured BEFORE the rebind, or the subclass recurses into itself
   897	class Blocked(real):
   898	    def __init__(self, db_path):
   899	        real.__init__(self, db_path)
   900	        self.path = os.path.join(blocker, "impossible.lock")
   901	W._ConnectorLock = Blocked
   902	try:
   903	    out = W.dispatch(db, "t", connectors={"github_board": {"enabled": True}}, window_s=20)
   904	finally:
   905	    W._ConnectorLock = real
   906	assert out == {}, "an unopenable lock still dispatched: %r" % (out,)
   907	print("fail-closed-ok")
   908	PYFAILCLOSED
   909	[ $? -eq 0 ] \
   910	  && ok "a lock that cannot be opened DEFERS the batch instead of dispatching unserialized" \
   911	  || bad "the lock failed open — the round-3 race is reachable again"
   912	STARTS3="$(grep -c '^start ' "$RUNLOG" 2>/dev/null | head -1)"; STARTS3="${STARTS3:-0}"
   913	[ "$STARTS3" = "0" ] \
   914	  && ok "and no connector child ran at all under the unopenable lock" \
   915	  || bad "$STARTS3 child(ren) ran despite the lock being unavailable"
   916	NLC="$(sqlite3 "$NOLOCKDIR/releases.db" "SELECT count(*) FROM connector_cursors;" 2>/dev/null)"
   917	[ "$NLC" = "0" ] \
   918	  && ok "and no cursor moved, so the batch stays replayable" \
   919	  || bad "the deferred batch still wrote $NLC cursor row(s)"
   920	
   921	# --reset now happens inside the lock, so "replay from zero" cannot be undone by an in-flight
   922	# dispatch persisting its advance after the delete.
   923	sqlite3 "$FXC/releases.db" "DELETE FROM connector_cursors;"
   924	XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG" \
   925	  python3 "$APP" --root "$FXC" work reconcile >/dev/null 2>&1
   926	PRE="$(sqlite3 "$FXC/releases.db" "SELECT last_event_id FROM connector_cursors WHERE connector='github_board';")"
   927	[ -n "$PRE" ] && [ "$PRE" -gt 0 ] || bad "fixture guard: cursor not advanced before the reset probe"
   928	RS="$(XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG" \
   929	      python3 "$APP" --root "$FXC" work reconcile --reset 2>&1)"
   930	case "$RS" in
   931	  *"replayed through event"*) ok "--reset still replays from zero with the delete inside the lock" ;;
   932	  *) bad "--reset stopped replaying after the lock change: $RS" ;;
   933	esac
   934	
   935	echo "21. work backfill — projects existing ledger state, idempotent, through the one seam (GH-564)"
   936	FXD="$WORK/fx_backfill"; rm -rf "$FXD"; mkdir -p "$FXD"
   937	( cd "$FXD" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
   938	cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXD/"
   939	appd() { XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$APP" --root "$FXD" "$@"; }
   940	# One row per mapping cell. Built through the verbs, never by SQL.
   941	for N in 9911 9912 9913 9914 9915; do
   942	  appd roadmap add --issue-num $N --issue-url "https://example.invalid/$N" --title "cell $N" \
   943	       --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
   944	done
   945	appd roadmap update --issue-num 9911 --section "Completed" >/dev/null 2>&1
   946	appd roadmap update --issue-num 9912 --status-marker "🚧" >/dev/null 2>&1
   947	appd roadmap rate   --issue-num 9913 --rated 10/20/30/40 >/dev/null 2>&1
   948	appd roadmap update --issue-num 9915 --section "Deferred · vision" --status-marker "🚧" >/dev/null 2>&1
   949	CELLS="$(sqlite3 "$FXD/releases.db" "SELECT gh_number||':'||section||':'||status_marker FROM roadmap_items WHERE gh_number IN ('9911','9912','9913','9914','9915') ORDER BY gh_number;")"
   950	case "$CELLS" in
   951	  *"9911:Completed:🆕"*"9915:Deferred"*) ok "fixture rows built through the verbs, one per mapping cell" ;;
   952	  *) bad "fixture guard: mapping cells not as intended: $CELLS" ;;
   953	esac
   954	# 21a — dry-run writes nothing.
   955	EV0="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM work_events;")"
   956	RC0="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM op_receipts;")"
   957	DRY="$(appd work backfill --dry-run 2>&1)"
   958	EV1="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM work_events;")"
   959	RC1="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM op_receipts;")"
   960	[ "$EV0" = "$EV1" ] && [ "$RC0" = "$RC1" ] \
   961	  && ok "21a dry-run: zero events and zero receipts written" \
   962	  || bad "21a dry-run wrote (events $EV0->$EV1, receipts $RC0->$RC1)"
   963	case "$DRY" in *"would emit"*"0 written"*) ok "21a dry-run prints the plan and says 0 written" ;; *) bad "21a dry-run output: $DRY" ;; esac
   964	# 21a red: strip the dry-run return in a copy → it writes.
   965	DRYC="$WORK/app_nodry"; rm -rf "$DRYC"; mkdir -p "$DRYC"; cp -R "$ROOT/utils/py/." "$DRYC/"
   966	python3 - "$DRYC/releases_app.py" <<'PYMUT'
   967	import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
   968	a='            print("dry-run: %d row(s), %d would emit, 0 written"'
   969	assert s.count(a)==1, "21a red: backfill dry-run anchor must be unique"
   970	i=s.index(a); j=s.rfind("        if args.dry_run:\n", 0, i)
   971	assert j>0 and i-j<200, "21a red: the if is not right above the print"
   972	s=s[:j]+"        if False:\n"+s[j+len("        if args.dry_run:\n"):]
   973	io.open(p,"w",encoding="utf-8").write(s)
   974	PYMUT
   975	[ $? -eq 0 ] || bad "21a red control mutation failed"
   976	FXD2="$WORK/fx_backfill_red"; rm -rf "$FXD2"; cp -R "$FXD" "$FXD2"
   977	XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$DRYC/releases_app.py" --root "$FXD2" work backfill --dry-run >/dev/null 2>&1
   978	EVR="$(sqlite3 "$FXD2/releases.db" "SELECT count(*) FROM work_events;")"
   979	[ "$EVR" -gt "$EV0" ] && ok "21a red: without the dry-run return, --dry-run DOES write ($EV0 -> $EVR)" \
   980	                       || bad "21a red control did not reproduce (events $EV0 -> $EVR)"
   981	# 21b — the mapping, per cell.
   982	appd work backfill >/dev/null 2>&1
   983	bf_latest() { sqlite3 "$FXD/releases.db" "SELECT event FROM work_events WHERE gh_number=$1 AND payload LIKE '%\"source\": \"backfill\"%' ORDER BY id DESC LIMIT 1;"; }
   984	[ "$(bf_latest 9911)" = "completed" ] && ok "21b Completed/🆕 -> completed (section wins; NOT pr_merged)" || bad "21b 9911 got '$(bf_latest 9911)'"
   985	[ "$(bf_latest 9912)" = "in_flight" ] && ok "21b 🚧 -> in_flight" || bad "21b 9912 got '$(bf_latest 9912)'"
   986	[ "$(bf_latest 9913)" = "rated" ]     && ok "21b rated 🆕 -> rated" || bad "21b 9913 got '$(bf_latest 9913)'"
   987	[ "$(bf_latest 9914)" = "parked" ]    && ok "21b unrated 🆕 -> parked" || bad "21b 9914 got '$(bf_latest 9914)'"
   988	[ -z "$(bf_latest 9915)" ]            && ok "21g Deferred + 🚧 -> skipped (Deferred is checked first)" || bad "21g 9915 emitted '$(bf_latest 9915)'"
   989	PM="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM work_events WHERE event='pr_merged' AND payload LIKE '%backfill%';")"
   990	[ "$PM" = "0" ] && ok "21b backfill never emits pr_merged" || bad "21b backfill emitted $PM pr_merged event(s)"
   991	# 21g red: reorder the copy so Completed/marker run before the Deferred check.
   992	MAPC="$WORK/app_map"; rm -rf "$MAPC"; mkdir -p "$MAPC"; cp -R "$ROOT/utils/py/." "$MAPC/"
   993	python3 - "$MAPC/releases_app.py" <<'PYMUT'
   994	import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
   995	a='    if sec.lower().startswith("deferred"):\n        return None\n    if sec.lower().startswith("completed"):\n        return "completed"\n'
   996	assert a in s, "21g red: precedence anchor missing"
   997	s=s.replace(a,'    if sec.lower().startswith("completed"):\n        return "completed"\n    if marker == "\\U0001F6A7":\n        return "in_flight"\n    if sec.lower().startswith("deferred"):\n        return None\n',1)
   998	io.open(p,"w",encoding="utf-8").write(s)
   999	PYMUT
  1000	[ $? -eq 0 ] || bad "21g red control mutation failed"
  1001	FXD3="$WORK/fx_backfill_map"; rm -rf "$FXD3"; cp -R "$FXD" "$FXD3"
  1002	XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$MAPC/releases_app.py" --root "$FXD3" work backfill >/dev/null 2>&1
  1003	R9915="$(sqlite3 "$FXD3/releases.db" "SELECT event FROM work_events WHERE gh_number=9915 ORDER BY id DESC LIMIT 1;")"
  1004	[ "$R9915" = "in_flight" ] && ok "21g red: with the order swapped, Deferred/🚧 DOES emit in_flight — the order is load-bearing" \
  1005	                            || bad "21g red did not reproduce (got '$R9915')"
  1006	# 21c — second run emits zero.
  1007	EVA="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM work_events;")"
  1008	OUT2="$(appd work backfill 2>&1 | tail -1)"
  1009	EVB="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM work_events;")"
  1010	[ "$EVA" = "$EVB" ] && ok "21c a second backfill emits zero ($OUT2)" || bad "21c second run emitted $((EVB-EVA)) ($OUT2)"
  1011	# 21c red: strip the suppression in the copy → duplicates.
  1012	IDC="$WORK/app_noidem"; rm -rf "$IDC"; mkdir -p "$IDC"; cp -R "$ROOT/utils/py/." "$IDC/"
  1013	python3 - "$IDC/releases_app.py" <<'PYMUT'
  1014	import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
  1015	a='unless_latest_in=(event,), only_source="backfill")'
  1016	assert a in s, "21c red: suppression anchor missing"; s=s.replace(a,')',1)
  1017	s=s.replace('_emit_work_event(root, conn, event, gh, payload,\n                                 )','_emit_work_event(root, conn, event, gh, payload)',1)
  1018	io.open(p,"w",encoding="utf-8").write(s)
  1019	PYMUT
  1020	[ $? -eq 0 ] || bad "21c red control mutation failed"
  1021	python3 -m py_compile "$IDC/releases_app.py" || bad "21c red: mutated copy does not compile"
  1022	FXD4="$WORK/fx_backfill_idem"; rm -rf "$FXD4"; cp -R "$FXD" "$FXD4"
  1023	XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$IDC/releases_app.py" --root "$FXD4" work backfill >/dev/null 2>&1
  1024	EVD="$(sqlite3 "$FXD4/releases.db" "SELECT count(*) FROM work_events;")"
  1025	[ "$EVD" -gt "$EVA" ] && ok "21c red: without the transactional guard a second backfill DUPLICATES ($EVA -> $EVD)" \
  1026	                       || bad "21c red did not reproduce ($EVA -> $EVD)"
  1027	# 21d — receipts and check.
  1028	NBF="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM work_events WHERE payload LIKE '%\"source\": \"backfill\"%';")"
  1029	NRC="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM op_receipts WHERE op='work-emit';")"
  1030	ORPH21="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM work_events w WHERE w.payload LIKE '%backfill%' AND NOT EXISTS (SELECT 1 FROM op_receipts r WHERE r.txn_id = w.txn_id AND r.op = 'work-emit');")"
  1031	[ "$NBF" -gt 0 ] && [ "$ORPH21" = "0" ] && ok "21d every backfill event ($NBF) has its own work-emit receipt, joined on txn_id (0 orphans)" \
  1032	                                          || bad "21d $ORPH21 of $NBF backfill events have no receipt"
  1033	appd check >/dev/null 2>&1 && ok "21d releases check is clean after backfill" || bad "21d check dirty after backfill"
  1034	# 21e — two concurrent backfills, exactly one event per row.
  1035	FXE2="$WORK/fx_backfill_conc"; rm -rf "$FXE2"; cp -R "$FXD" "$FXE2"
  1036	sqlite3 "$FXE2/releases.db" "DROP TRIGGER work_events_no_delete; DELETE FROM work_events WHERE payload LIKE '%backfill%'; CREATE TRIGGER work_events_no_delete BEFORE DELETE ON work_events BEGIN SELECT RAISE(ABORT,'work_events is append-only'); END;" 2>/dev/null
  1037	NROWS="$(sqlite3 "$FXE2/releases.db" "SELECT count(*) FROM roadmap_items WHERE gh_number IS NOT NULL AND gh_number!='' AND section NOT LIKE 'Deferred%';")"
  1038	for i in 1 2; do XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$APP" --root "$FXE2" work backfill >/dev/null 2>&1 & done; wait
  1039	NBF2="$(sqlite3 "$FXE2/releases.db" "SELECT count(*) FROM work_events WHERE payload LIKE '%\"source\": \"backfill\"%';")"
  1040	[ "$NBF2" = "$NROWS" ] && ok "21e two concurrent backfills produced exactly one event per row ($NBF2 = $NROWS), not two" \
  1041	                        || bad "21e concurrent backfills produced $NBF2 events for $NROWS rows"
  1042	# 21e red: move the decision BEFORE perform_write in a copy → duplicates under the same race.
  1043	RACE="$WORK/app_race"; rm -rf "$RACE"; mkdir -p "$RACE"; cp -R "$ROOT/utils/py/." "$RACE/"
  1044	python3 - "$RACE/releases_app.py" <<'PYMUT'
  1045	import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
  1046	a='''        if not suppress:
  1047	            return
  1048	        latest = _latest_event(c, gh_number, only_source=only_source, exclude_source=exclude_source)
  1049	        if latest in suppress:
  1050	            raise _AlreadyRecorded(latest)'''
  1051	assert a in s, "21e red: mutate anchor missing"
  1052	s=s.replace(a,'        return',1)
  1053	b='''    terminal_set = set(terminal)
  1054	'''
  1055	assert b in s, "21e red: terminal anchor missing"
  1056	s=s.replace(b,'''    terminal_set = set(terminal)
  1057	    if suppress:
  1058	        _pre = _latest_event(conn, gh_number, only_source=only_source, exclude_source=exclude_source)
  1059	        if _pre in suppress:
  1060	            raise _AlreadyRecorded(_pre)
  1061	        import time as _t; _t.sleep(0.4)
  1062	''',1)
  1063	io.open(p,"w",encoding="utf-8").write(s)
  1064	PYMUT
  1065	[ $? -eq 0 ] || bad "21e red control mutation failed"
  1066	FXE3="$WORK/fx_backfill_race"; rm -rf "$FXE3"; cp -R "$FXE2" "$FXE3"
  1067	sqlite3 "$FXE3/releases.db" "DROP TRIGGER work_events_no_delete; DELETE FROM work_events WHERE payload LIKE '%backfill%'; CREATE TRIGGER work_events_no_delete BEFORE DELETE ON work_events BEGIN SELECT RAISE(ABORT,'work_events is append-only'); END;" 2>/dev/null
  1068	for i in 1 2; do XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$RACE/releases_app.py" --root "$FXE3" work backfill >/dev/null 2>&1 & done; wait
  1069	NBF3="$(sqlite3 "$FXE3/releases.db" "SELECT count(*) FROM work_events WHERE payload LIKE '%\"source\": \"backfill\"%';")"
  1070	[ "$NBF3" -gt "$NROWS" ] && ok "21e red: with the read moved outside the transaction, the race DUPLICATES ($NBF3 > $NROWS)" \
  1071	                          || bad "21e red did not reproduce ($NBF3 vs $NROWS)"
  1072	
  1073	echo "22. review_ready from open non-draft PRs, inside reconcile, fail-soft (GH-564)"
  1074	WRAP="$ROOT/test/lib/gh-prlist-wrapper.sh"
  1075	[ -x "$WRAP" ] || bad "fixture guard: $WRAP missing or not executable"
  1076	FXR="$WORK/fx_rr"; rm -rf "$FXR"; mkdir -p "$FXR"
  1077	( cd "$FXR" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
  1078	cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXR/"
  1079	seed_cursor_tail "$FXR/releases.db"   # GH-695
  1080	python3 "$MOCK" --reset --state "$WORK/mock22.json" >/dev/null 2>&1; python3 "$MOCK" --seed --state "$WORK/mock22.json" >/dev/null 2>&1
  1081	cat > "$WORK/rr_cfg.json" <<'PYCFG'
  1082	{"board_sync": {"project_owner": "noelsaw1", "project_number": 3, "repos": ["HiQS-Labs/XYZ-forge"], "status_field": "Status", "in_progress": "In progress"},
  1083	 "work_connectors": {"github_board": {"enabled": true, "project_owner": "noelsaw1", "project_number": 3,
  1084	                     "repos": ["HiQS-Labs/XYZ-forge"], "status_map": {"review_ready": "Todo"}}}}
  1085	PYCFG
  1086	prs3() { cat > "$WORK/prs.json" <<'PYJ'
  1087	[{"number": 700, "isDraft": false, "title": "feat: x", "body": "Closes #405"},
  1088	 {"number": 701, "isDraft": true,  "title": "wip",     "body": "Closes #9902"},
  1089	 {"number": 702, "isDraft": false, "title": "chore",   "body": "no linked issue"}]
  1090	PYJ
  1091	}
  1092	prs3
  1093	CALLS="$WORK/prlist_calls.log"; : > "$CALLS"
  1094	rr() { GH549_PRLIST_JSON="$WORK/prs.json" GH549_PRLIST_CALLS="$CALLS" GH549_MOCK="$MOCK" \
  1095	       XYZ_DEVICE_CONFIG_PATH="$WORK/rr_cfg.json" XYZ_BOARD_SYNC_GH_BIN="$WRAP" \
  1096	       XYZ_MOCK_BOARD_STATE="${MOCKSTATE:-$WORK/mock22.json}" XYZ_BOARD_SYNC_STATE_PATH="$WORK/sync22.json" "$@"; }
  1097	mock_col() { python3 "$MOCK" --dump --state "$1" 2>/dev/null | python3 -c "
  1098	import json,sys; d=json.load(sys.stdin); f=d.get('fields',{}).get('Status',{}); names={o['id']:o['name'] for o in f.get('options',[])}
  1099	it=next((i for i in d.get('items',[]) if i.get('number')==$2), None)
  1100	print('absent' if it is None else names.get(next(iter((it.get('field_values') or {}).values()), None),'unset'))"; }
  1101	R22="$(rr python3 "$APP" --root "$FXR" work reconcile 2>&1)"
  1102	RR405="$(sqlite3 "$FXR/releases.db" "SELECT event FROM work_events WHERE gh_number=405 ORDER BY id DESC LIMIT 1;")"
  1103	[ "$RR405" = "review_ready" ] && ok "22a an open non-draft PR closing #405 emitted review_ready" || bad "22a got '$RR405': $R22"
  1104	COL405="$(mock_col "$WORK/mock22.json" 405)"
  1105	[ "$COL405" = "Todo" ] && ok "22a and the card reached the configured review_ready column" || bad "22a card column: $COL405"
  1106	[ -z "$(sqlite3 "$FXR/releases.db" "SELECT event FROM work_events WHERE gh_number=9902;")" ] && ok "22b a DRAFT PR emitted nothing" || bad "22b draft PR emitted"
  1107	[ -z "$(sqlite3 "$FXR/releases.db" "SELECT event FROM work_events WHERE gh_number=702;")" ] && ok "22b a PR closing nothing emitted nothing" || bad "22b closes-nothing PR emitted"
  1108	grep -q -- '--repo HiQS-Labs/XYZ-forge' "$CALLS" && ok "22g the scan passed --repo from the connector's identity, not the CWD" || bad "22g no --repo in: $(cat "$CALLS")"
  1109	: > "$CALLS"; ( cd "$WORK" && rr python3 "$APP" --root "$FXR" work reconcile >/dev/null 2>&1 )
  1110	grep -q -- '--repo HiQS-Labs/XYZ-forge' "$CALLS" && ok "22g ...and still does from a directory with no git checkout" || bad "22g from no-git CWD: $(cat "$CALLS")"
  1111	# 22c — idempotent.
  1112	N405A="$(sqlite3 "$FXR/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=405 AND event='review_ready';")"
  1113	rr python3 "$APP" --root "$FXR" work reconcile >/dev/null 2>&1
  1114	N405B="$(sqlite3 "$FXR/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=405 AND event='review_ready';")"
  1115	[ "$N405A" = "$N405B" ] && [ "$N405A" = "1" ] && ok "22c a second reconcile emits no second review_ready" || bad "22c review_ready count $N405A -> $N405B"
  1116	# 21f — interleave, both directions, on a fresh fixture.
  1117	FXI="$WORK/fx_interleave"; rm -rf "$FXI"; mkdir -p "$FXI"
  1118	( cd "$FXI" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
  1119	cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXI/"; seed_cursor_tail "$FXI/releases.db"   # GH-695
  1120	python3 "$MOCK" --reset --state "$WORK/mock21f.json" >/dev/null 2>&1; python3 "$MOCK" --seed --state "$WORK/mock21f.json" >/dev/null 2>&1
  1121	prs21f() { cat > "$WORK/prs.json" <<'PYJ'
  1122	[{"number": 710, "isDraft": false, "title": "feat: y", "body": "Closes #9920"}]
  1123	PYJ
  1124	}
  1125	rr python3 "$APP" --root "$FXI" roadmap add --issue-num 9920 --issue-url "https://example.invalid/9920" --title "interleave" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
  1126	prs21f
  1127	MOCKSTATE="$WORK/mock21f.json" rr python3 "$APP" --root "$FXI" work backfill  >/dev/null 2>&1   # 9920 -> parked, source=backfill
  1128	MOCKSTATE="$WORK/mock21f.json" rr python3 "$APP" --root "$FXI" work reconcile >/dev/null 2>&1   # 405 -> review_ready (latest non-backfill was None)
  1129	SEQ="$(sqlite3 "$FXI/releases.db" "SELECT group_concat(event,',') FROM (SELECT event FROM work_events WHERE gh_number=9920 ORDER BY id);")"
  1130	case "$SEQ" in *",review_ready") ok "21f fixture: backfill then reconcile gives ...,review_ready ($SEQ)" ;; *) bad "21f fixture guard: unexpected sequence '$SEQ'" ;; esac
  1131	NBI="$(sqlite3 "$FXI/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9920;")"
  1132	MOCKSTATE="$WORK/mock21f.json" rr python3 "$APP" --root "$FXI" work backfill  >/dev/null 2>&1   # own latest is unchanged -> must skip
  1133	NBI2="$(sqlite3 "$FXI/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9920;")"
  1134	[ "$NBI" = "$NBI2" ] && ok "21f backfill after a review_ready does NOT re-emit — it compares against its OWN last projection" || bad "21f backfill re-emitted ($NBI -> $NBI2)"
  1135	MOCKSTATE="$WORK/mock21f.json" rr python3 "$APP" --root "$FXI" work reconcile >/dev/null 2>&1   # latest non-backfill is review_ready -> must skip
  1136	NBI3="$(sqlite3 "$FXI/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9920;")"
  1137	[ "$NBI2" = "$NBI3" ] && ok "21f reconcile after a backfill does NOT re-emit review_ready — it ignores backfill rows" || bad "21f reconcile re-emitted ($NBI2 -> $NBI3)"
  1138	# A completed issue with an open PR must stay put.
  1139	rr python3 "$APP" --root "$FXI" roadmap add --issue-num 9903 --issue-url "https://example.invalid/9903" --title "done" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
  1140	rr python3 "$APP" --root "$FXI" roadmap update --issue-num 9903 --section "Completed" >/dev/null 2>&1
  1141	MOCKSTATE="$WORK/mock21f.json" rr python3 "$APP" --root "$FXI" work backfill >/dev/null 2>&1
  1142	cat > "$WORK/prs.json" <<'PYJ'
  1143	[{"number": 703, "isDraft": false, "title": "late pr", "body": "Closes #9903"}]
  1144	PYJ
  1145	MOCKSTATE="$WORK/mock21f.json" rr python3 "$APP" --root "$FXI" work reconcile >/dev/null 2>&1
  1146	[ -z "$(sqlite3 "$FXI/releases.db" "SELECT event FROM work_events WHERE gh_number=9903 AND event='review_ready';")" ] \
  1147	  && ok "21f an open PR against a COMPLETED issue does not pull it back to review_ready" || bad "21f completed issue got review_ready"
  1148	# 21f red (i): drop only_source → the mutated backfill sees the global latest (review_ready) and re-emits.
  1149	SRC="$WORK/app_nosrc"; rm -rf "$SRC"; mkdir -p "$SRC"; cp -R "$ROOT/utils/py/." "$SRC/"
  1150	python3 - "$SRC/releases_app.py" <<'PYMUT'
  1151	import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
  1152	a='unless_latest_in=(event,), only_source="backfill")'
  1153	assert a in s, "21f red(i): only_source anchor missing"; s=s.replace(a,'unless_latest_in=(event,))',1)
  1154	io.open(p,"w",encoding="utf-8").write(s)
  1155	PYMUT
  1156	[ $? -eq 0 ] || bad "21f red(i) mutation failed"
  1157	FXR2="$WORK/fx_rr_nosrc"; rm -rf "$FXR2"; cp -R "$FXI" "$FXR2"
  1158	BFX="$(sqlite3 "$FXR2/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9920 AND payload LIKE '%backfill%';")"
  1159	MOCKSTATE="$WORK/mock21f.json" rr python3 "$SRC/releases_app.py" --root "$FXR2" work backfill >/dev/null 2>&1
  1160	BFY="$(sqlite3 "$FXR2/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9920 AND payload LIKE '%backfill%';")"
  1161	[ "$BFY" -gt "$BFX" ] && ok "21f red(i): with the global latest, backfill DOES re-emit after review_ready ($BFX -> $BFY) — the ping-pong" \
  1162	                       || bad "21f red(i) did not reproduce ($BFX -> $BFY)"
  1163	# 21f red (iii): drop exclude_source in reconcile → it re-emits review_ready after a backfill.
  1164	EXC="$WORK/app_noexc"; rm -rf "$EXC"; mkdir -p "$EXC"; cp -R "$ROOT/utils/py/." "$EXC/"
  1165	python3 - "$EXC/releases_app.py" <<'PYMUT'
  1166	import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
  1167	a='                                 exclude_source="backfill",\n'
  1168	assert a in s, "21f red(iii): exclude_source anchor missing"; s=s.replace(a,'',1)
  1169	io.open(p,"w",encoding="utf-8").write(s)
  1170	PYMUT
  1171	[ $? -eq 0 ] || bad "21f red(iii) mutation failed"
  1172	FXR7="$WORK/fx_rr_noexc"; rm -rf "$FXR7"; mkdir -p "$FXR7"
  1173	( cd "$FXR7" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
  1174	cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXR7/"; seed_cursor_tail "$FXR7/releases.db"   # GH-695
  1175	rr python3 "$APP" --root "$FXR7" roadmap add --issue-num 9920 --issue-url "https://example.invalid/9920" --title "interleave" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
  1176	prs21f
  1177	MOCKSTATE="$WORK/mock21f.json" rr python3 "$APP" --root "$FXR7" work reconcile >/dev/null 2>&1   # review_ready
  1178	MOCKSTATE="$WORK/mock21f.json" rr python3 "$APP" --root "$FXR7" work backfill  >/dev/null 2>&1   # rated (backfill) now global latest
  1179	RRX="$(sqlite3 "$FXR7/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9920 AND event='review_ready';")"
  1180	MOCKSTATE="$WORK/mock21f.json" rr python3 "$EXC/releases_app.py" --root "$FXR7" work reconcile >/dev/null 2>&1
  1181	RRY="$(sqlite3 "$FXR7/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9920 AND event='review_ready';")"
  1182	[ "$RRY" -gt "$RRX" ] && ok "21f red(iii): with backfill rows visible, reconcile DOES re-emit review_ready ($RRX -> $RRY)" \
  1183	                       || bad "21f red(iii) did not reproduce ($RRX -> $RRY)"
  1184	# 21f red (ii): drop completed from the suppression set.
  1185	SUP="$WORK/app_nosup"; rm -rf "$SUP"; mkdir -p "$SUP"; cp -R "$ROOT/utils/py/." "$SUP/"
  1186	python3 - "$SUP/releases_app.py" <<'PYMUT'
  1187	import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
  1188	a='terminal=("completed", "pr_merged"))'
  1189	assert a in s, "21f red(ii): terminal anchor missing"; s=s.replace(a,'terminal=("pr_merged",))',1)
  1190	io.open(p,"w",encoding="utf-8").write(s)
  1191	PYMUT
  1192	[ $? -eq 0 ] || bad "21f red(ii) mutation failed"
  1193	FXR3="$WORK/fx_rr_nosup"; rm -rf "$FXR3"; cp -R "$FXI" "$FXR3"
  1194	cat > "$WORK/prs.json" <<'PYJ'
  1195	[{"number": 703, "isDraft": false, "title": "late pr", "body": "Closes #9903"}]
  1196	PYJ
  1197	MOCKSTATE="$WORK/mock21f.json" rr python3 "$SUP/releases_app.py" --root "$FXR3" work reconcile >/dev/null 2>&1
  1198	[ -n "$(sqlite3 "$FXR3/releases.db" "SELECT event FROM work_events WHERE gh_number=9903 AND event='review_ready';")" ] \
  1199	  && ok "21f red(ii): without completed in the suppression set the card IS pulled back" || bad "21f red(ii) did not reproduce"
  1200	# 22a/22b red: source mutations.
  1201	EVN="$WORK/app_evname"; rm -rf "$EVN"; mkdir -p "$EVN"; cp -R "$ROOT/utils/py/." "$EVN/"
  1202	python3 - "$EVN/releases_app.py" <<'PYMUT'
  1203	import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
  1204	a='_emit_work_event(root, conn, "review_ready", n, {"pr": pr.get("number")},'
  1205	assert a in s, "22a red: event-name anchor missing"; s=s.replace(a,'_emit_work_event(root, conn, "updated", n, {"pr": pr.get("number")},',1)
  1206	b='        if not isinstance(pr, dict) or pr.get("isDraft"):\n            continue'
  1207	assert b in s, "22b red: isDraft anchor missing"; s=s.replace(b,'        if not isinstance(pr, dict):\n            continue',1)
  1208	c='        for n in _linked_issues(pr):'
  1209	assert c in s, "22b red: linked_issues anchor missing"; s=s.replace(c,'        for n in [pr.get("number")]:',1)
  1210	io.open(p,"w",encoding="utf-8").write(s)
  1211	PYMUT
  1212	[ $? -eq 0 ] || bad "22a/22b red mutation failed"
  1213	prs3
  1214	FXR4="$WORK/fx_rr_red"; rm -rf "$FXR4"; mkdir -p "$FXR4"
  1215	( cd "$FXR4" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
  1216	cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXR4/"; seed_cursor_tail "$FXR4/releases.db"   # GH-695
  1217	python3 "$MOCK" --reset --state "$WORK/mock22r.json" >/dev/null 2>&1; python3 "$MOCK" --seed --state "$WORK/mock22r.json" >/dev/null 2>&1
  1218	MOCKSTATE="$WORK/mock22r.json" rr python3 "$EVN/releases_app.py" --root "$FXR4" work reconcile >/dev/null 2>&1
  1219	[ -z "$(sqlite3 "$FXR4/releases.db" "SELECT 1 FROM work_events WHERE gh_number=405 AND event='review_ready';")" ] \
  1220	  && ok "22a red: with the event name swapped, 405 does NOT get review_ready" || bad "22a red did not reproduce"
  1221	[ -n "$(sqlite3 "$FXR4/releases.db" "SELECT 1 FROM work_events WHERE gh_number=701;")" ] \
  1222	  && ok "22b red: without the isDraft filter, the draft PR DOES emit (for its own number, since linked_issues is bypassed in the same copy)" || bad "22b red (draft) did not reproduce"
  1223	[ -n "$(sqlite3 "$FXR4/releases.db" "SELECT 1 FROM work_events WHERE gh_number=702;")" ] \
  1224	  && ok "22b red: with linked_issues bypassed, the closes-nothing PR DOES emit for its own number" || bad "22b red (linked) did not reproduce"
  1225	# 22d — gh fails → reconcile still replays, exit 0.
  1226	prs3; : > "$CALLS"
  1227	seed_cursor_tail "$FXR/releases.db"   # GH-695: re-replay this leg's own events, not the ledger
  1228	R22D="$(GH549_PRLIST_RC=1 rr python3 "$APP" --root "$FXR" work reconcile 2>&1)"; RC22D=$?
  1229	[ "$RC22D" = "0" ] && ok "22d with gh pr list failing, reconcile exits 0" || bad "22d rc=$RC22D: $R22D"
  1230	case "$R22D" in *"review-ready scan skipped"*"exited 1"*) ok "22d ...and says why" ;; *) bad "22d no reason printed: $R22D" ;; esac
  1231	case "$R22D" in *"replayed through event"*) ok "22d ...and still replayed" ;; *) bad "22d did not replay: $R22D" ;; esac
  1232	# 22f — one emission raises → the other lands, dispatch runs, rc 0. Red: remove the except → rc≠0.
  1233	EMF="$WORK/app_emitfail"; rm -rf "$EMF"; mkdir -p "$EMF"; cp -R "$ROOT/utils/py/." "$EMF/"
  1234	python3 - "$EMF/releases_app.py" <<'PYMUT'
  1235	import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
  1236	a='                     exclude_source=None, terminal=()):\n'
  1237	assert s.count(a)==1, "22f: emit signature anchor must be unique"
  1238	s=s.replace(a, a+'    if gh_number == 9904 and event == "review_ready":\n        raise RuntimeError("injected emission failure for 9904")\n',1)
  1239	io.open(p,"w",encoding="utf-8").write(s)
  1240	PYMUT
  1241	[ $? -eq 0 ] || bad "22f injection failed"
  1242	cat > "$WORK/prs.json" <<'PYJ'
  1243	[{"number": 704, "isDraft": false, "title": "a", "body": "Closes #9904"},
  1244	 {"number": 705, "isDraft": false, "title": "b", "body": "Closes #9905"}]
  1245	PYJ
  1246	FXR5="$WORK/fx_rr_emitfail"; rm -rf "$FXR5"; mkdir -p "$FXR5"
  1247	( cd "$FXR5" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
  1248	cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXR5/"; seed_cursor_tail "$FXR5/releases.db"   # GH-695
  1249	python3 "$MOCK" --reset --state "$WORK/mock22f.json" >/dev/null 2>&1; python3 "$MOCK" --seed --state "$WORK/mock22f.json" >/dev/null 2>&1
  1250	R22F="$(MOCKSTATE="$WORK/mock22f.json" rr python3 "$EMF/releases_app.py" --root "$FXR5" work reconcile 2>&1)"; RC22F=$?
  1251	[ "$RC22F" = "0" ] && ok "22f one emission raising: reconcile still exits 0" || bad "22f rc=$RC22F: $R22F"
  1252	[ -n "$(sqlite3 "$FXR5/releases.db" "SELECT 1 FROM work_events WHERE gh_number=9905 AND event='review_ready';")" ] \
  1253	  && ok "22f ...the OTHER issue's event still landed" || bad "22f 9905 did not land: $R22F"
  1254	case "$R22F" in *"GH-9904: FAILED"*) ok "22f ...and the failure was named" ;; *) bad "22f failure not reported: $R22F" ;; esac
  1255	CUR22F="$(sqlite3 "$FXR5/releases.db" "SELECT last_event_id FROM connector_cursors WHERE connector='github_board';")"
  1256	[ -n "$CUR22F" ] && [ "$CUR22F" -gt "$PRISTINE_TAIL" ] && ok "22f ...and dispatch still ran (cursor $PRISTINE_TAIL -> $CUR22F)" || bad "22f dispatch did not run (cursor '$CUR22F', seeded $PRISTINE_TAIL)"
  1257	python3 - "$EMF/releases_app.py" <<'PYMUT'
  1258	import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
  1259	a='            except (SystemExit, Exception) as exc:    # noqa: BLE001 — one issue must not stop the scan\n'
  1260	assert s.count(a)==1, "22f red: except anchor must be unique"; s=s.replace(a,'            except _AlreadyRecorded:\n                raise\n            except () as exc:\n',1)
  1261	io.open(p,"w",encoding="utf-8").write(s)
  1262	PYMUT
  1263	[ $? -eq 0 ] || bad "22f red mutation failed"
  1264	python3 -m py_compile "$EMF/releases_app.py" || bad "22f red: mutated copy does not compile"
  1265	FXR6="$WORK/fx_rr_emitfail_red"; rm -rf "$FXR6"; cp -R "$FXR5" "$FXR6"; seed_cursor_tail "$FXR6/releases.db"   # GH-695
  1266	MOCKSTATE="$WORK/mock22f.json" rr python3 "$EMF/releases_app.py" --root "$FXR6" work reconcile >/dev/null 2>&1; RC22FR=$?
  1267	[ "$RC22FR" != "0" ] && ok "22f red: without the per-emission except, the verb FAILS (rc=$RC22FR)" || bad "22f red did not reproduce (rc=0)"
  1268	# 22e — kill switch: no gh call at all.
  1269	prs3; : > "$CALLS"
  1270	XYZ_WORK_CONNECTORS=0 rr python3 "$APP" --root "$FXR" work reconcile >/dev/null 2>&1
  1271	[ ! -s "$CALLS" ] && ok "22e XYZ_WORK_CONNECTORS=0: the scan made no gh call" || bad "22e gh was called under the kill switch: $(cat "$CALLS")"
  1272	rr python3 "$APP" --root "$FXR" work reconcile >/dev/null 2>&1
  1273	[ -s "$CALLS" ] && ok "22e red: without the switch the SAME command calls gh" || bad "22e red: gh not called"
  1274	
  1275	echo "23. completed is a mapped column, user-overridable (GH-564)"
  1276	python3 - "$ROOT" <<'PYMAP'
  1277	import sys, os
  1278	sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py"))
  1279	from work_connectors.github_board import column_for, DEFAULT_STATUS_MAP
  1280	assert column_for("completed", DEFAULT_STATUS_MAP) == "Done", "completed not mapped to Done"
  1281	m = dict(DEFAULT_STATUS_MAP); m["completed"] = ""
  1282	assert column_for("completed", m) is None, "empty override did not disable completed"
  1283	print("ok")
  1284	PYMAP
  1285	[ $? -eq 0 ] && ok "23 completed -> Done by default; a user's empty override disables it" || bad "23 completed mapping contract broken"
  1286	MAPR="$WORK/gb_nocompleted"; rm -rf "$MAPR"; mkdir -p "$MAPR"; cp -R "$ROOT/utils/py/." "$MAPR/"
  1287	python3 - "$MAPR/work_connectors/github_board.py" <<'PYMUT'
  1288	import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
  1289	a='    "completed": "Done",\n'
  1290	assert a in s, "23 red: completed anchor missing"; s=s.replace(a,"",1)
  1291	io.open(p,"w",encoding="utf-8").write(s)
  1292	PYMUT
  1293	[ $? -eq 0 ] || bad "23 red mutation failed"
  1294	R23="$(python3 - "$MAPR" <<'PYMAP'
  1295	import sys, os
  1296	sys.path.insert(0, sys.argv[1])
  1297	from work_connectors.github_board import column_for, DEFAULT_STATUS_MAP
  1298	print("mapped" if column_for("completed", DEFAULT_STATUS_MAP) else "unmapped")
  1299	PYMAP
  1300	)"
  1301	[ "$R23" = "unmapped" ] && ok "23 red: with the key deleted, completed is unmapped — the entry is load-bearing" || bad "23 red did not reproduce ($R23)"
  1302	
  1303	
  1304	echo "24. the producer-scoped lookup has no row cap (impl QA r1), and every backfill event has ITS OWN receipt"
  1305	FXK="$WORK/fx_cap"; rm -rf "$FXK"; mkdir -p "$FXK"
  1306	( cd "$FXK" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
  1307	cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXK/"
  1308	appk() { XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$APP" --root "$FXK" "$@"; }
  1309	appk roadmap add --issue-num 9930 --issue-url "https://example.invalid/9930" --title "cap" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
  1310	appk work backfill >/dev/null 2>&1                                    # one backfill row for 9930
  1311	# Bury it under 60 newer non-backfill rows for the same issue, through the real verb.
  1312	for i in $(seq 1 60); do appk work emit --event updated --gh-number 9930 --payload-json "{\"n\":$i}" >/dev/null 2>&1; done
  1313	DEPTH="$(sqlite3 "$FXK/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9930;")"
  1314	[ "$DEPTH" -ge 61 ] || bad "fixture guard: only $DEPTH rows for 9930 — the cap probe would be vacuous"
  1315	python3 - "$ROOT" "$FXK/releases.db" <<'PYPROBE'
  1316	import sys, os, sqlite3
  1317	sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py"))
  1318	import releases_app as R
  1319	c = sqlite3.connect(sys.argv[2])
  1320	own = R._latest_event(c, 9930, only_source="backfill")
  1321	assert own == "parked", "backfill's own latest hidden behind newer rows: %r" % (own,)
  1322	other = R._latest_event(c, 9930, exclude_source="backfill")
  1323	assert other == "updated", "exclude view wrong: %r" % (other,)
  1324	print("views-ok")
  1325	PYPROBE
  1326	[ $? -eq 0 ] && ok "24 backfill's own latest is still found under 60 newer rows from another producer" || bad "24 the lookup lost the producer row"
  1327	NB0="$(sqlite3 "$FXK/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9930 AND payload LIKE '%backfill%';")"
  1328	appk work backfill >/dev/null 2>&1
  1329	NB1="$(sqlite3 "$FXK/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9930 AND payload LIKE '%backfill%';")"
  1330	[ "$NB0" = "$NB1" ] && ok "24 ...so a backfill after 60 unrelated events still emits nothing" || bad "24 duplicate under depth ($NB0 -> $NB1)"
  1331	# Red: reinstate a LIMIT below the depth in a copy → the own-row is hidden and backfill duplicates.
  1332	CAPC="$WORK/app_cap"; rm -rf "$CAPC"; mkdir -p "$CAPC"; cp -R "$ROOT/utils/py/." "$CAPC/"
  1333	python3 - "$CAPC/releases_app.py" <<'PYMUT'
  1334	import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
  1335	a='                           ORDER BY id DESC""", (gh_number,))\n    for event, payload in rows:'
  1336	assert s.count(a)==1, "24 red: lookup anchor must be unique"
  1337	s=s.replace(a,'                           ORDER BY id DESC LIMIT 50""", (gh_number,))\n    for event, payload in rows:',1)
  1338	io.open(p,"w",encoding="utf-8").write(s)
  1339	PYMUT
  1340	[ $? -eq 0 ] || bad "24 red mutation failed"
  1341	FXK2="$WORK/fx_cap_red"; rm -rf "$FXK2"; cp -R "$FXK" "$FXK2"
  1342	XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$CAPC/releases_app.py" --root "$FXK2" work backfill >/dev/null 2>&1
  1343	NB2="$(sqlite3 "$FXK2/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9930 AND payload LIKE '%backfill%';")"
  1344	[ "$NB2" -gt "$NB0" ] && ok "24 red: with LIMIT 50 restored, the own-row is hidden and backfill DUPLICATES ($NB0 -> $NB2)" || bad "24 red did not reproduce ($NB0 -> $NB2)"
  1345	# Per-event receipts (impl QA r1 [Should]): every NEW backfill event's txn_id must have its own
  1346	# work-emit receipt — a join, not an aggregate count that unrelated receipts could satisfy.
  1347	FXP="$WORK/fx_rcpt"; rm -rf "$FXP"; cp -R "$FXD" "$FXP"
  1348	BEFORE_IDS="$(sqlite3 "$FXP/releases.db" "SELECT coalesce(max(id),0) FROM work_events;")"
  1349	appp() { XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$APP" --root "$FXP" "$@"; }
  1350	appp roadmap add --issue-num 9931 --issue-url "https://example.invalid/9931" --title "rcpt" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
  1351	appp roadmap add --issue-num 9932 --issue-url "https://example.invalid/9932" --title "rcpt" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
  1352	appp work backfill >/dev/null 2>&1
  1353	ORPHANS="$(sqlite3 "$FXP/releases.db" "SELECT count(*) FROM work_events w WHERE w.id > $BEFORE_IDS AND w.payload LIKE '%backfill%' AND NOT EXISTS (SELECT 1 FROM op_receipts r WHERE r.txn_id = w.txn_id AND r.op = 'work-emit');")"
  1354	NEWBF="$(sqlite3 "$FXP/releases.db" "SELECT count(*) FROM work_events WHERE id > $BEFORE_IDS AND payload LIKE '%backfill%';")"
  1355	[ "$NEWBF" -ge 2 ] || bad "fixture guard: expected >=2 new backfill events, got $NEWBF"
  1356	[ "$ORPHANS" = "0" ] && ok "24 every one of the $NEWBF new backfill events has its OWN work-emit receipt (join on txn_id)" || bad "24 $ORPHANS backfill event(s) have no receipt of their own"
  1357	# Red: a copy that bypasses perform_write and INSERTs the event directly → orphan detected.
  1358	BYP="$WORK/app_bypass"; rm -rf "$BYP"; mkdir -p "$BYP"; cp -R "$ROOT/utils/py/." "$BYP/"
  1359	python3 - "$BYP/releases_app.py" <<'PYMUT'
  1360	import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
  1361	a='''                _emit_work_event(root, conn, event, gh, payload,
  1362	                                 unless_latest_in=(event,), only_source="backfill")'''
  1363	assert s.count(a)==1, "24 red(bypass): backfill emit anchor must be unique"
  1364	s=s.replace(a,'''                conn.execute("INSERT INTO work_events(global_id, repo_id, gh_number, txn_id, event, payload, at) VALUES (?, ?, ?, ?, ?, ?, ?)",
  1365	                             (new_gid("wev-"), _repo_id_for_event(conn), gh, "bypass-%d" % gh, event, json.dumps(payload), now_iso()))
  1366	                conn.commit()''',1)
  1367	io.open(p,"w",encoding="utf-8").write(s)
  1368	PYMUT
  1369	[ $? -eq 0 ] || bad "24 red(bypass) mutation failed"
  1370	FXP2="$WORK/fx_rcpt_red"; rm -rf "$FXP2"; cp -R "$FXD" "$FXP2"
  1371	B2="$(sqlite3 "$FXP2/releases.db" "SELECT coalesce(max(id),0) FROM work_events;")"
  1372	XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$APP" --root "$FXP2" roadmap add --issue-num 9933 --issue-url "https://example.invalid/9933" --title "rcpt" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
  1373	XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$BYP/releases_app.py" --root "$FXP2" work backfill >/dev/null 2>&1
  1374	ORPH2="$(sqlite3 "$FXP2/releases.db" "SELECT count(*) FROM work_events w WHERE w.id > $B2 AND w.payload LIKE '%backfill%' AND NOT EXISTS (SELECT 1 FROM op_receipts r WHERE r.txn_id = w.txn_id AND r.op = 'work-emit');")"
  1375	[ "$ORPH2" -gt 0 ] && ok "24 red: a copy that bypasses perform_write leaves $ORPH2 receipt-less event(s) — the join catches it" || bad "24 red(bypass) did not reproduce"
  1376	
  1377	
  1378	echo "25. a non-object payload on an older row cannot break the producer views (impl QA r2)"
  1379	FXN="$WORK/fx_nonobj"; rm -rf "$FXN"; cp -R "$FXK" "$FXN"
  1380	appn() { XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$APP" --root "$FXN" "$@"; }
  1381	# Legitimate rows through the real verb: a list, a null and a string payload, all newer than 9930's backfill row.
  1382	appn work emit --event updated --gh-number 9930 --payload-json '[]'      >/dev/null 2>&1
  1383	appn work emit --event updated --gh-number 9930 --payload-json 'null'    >/dev/null 2>&1
  1384	appn work emit --event updated --gh-number 9930 --payload-json '"text"'  >/dev/null 2>&1
  1385	# `null` decodes to None and is stored as SQL NULL, not the text 'null' — count it that way.
  1386	NONOBJ="$(sqlite3 "$FXN/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9930 AND event='updated' AND (payload='[]' OR payload IS NULL OR payload='\"text\"');")"
  1387	[ "$NONOBJ" -ge 3 ] || bad "fixture guard: expected >=3 non-object payload rows, got $NONOBJ"
  1388	python3 - "$ROOT" "$FXN/releases.db" <<'PYPROBE'
  1389	import sys, os, sqlite3
  1390	sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py"))
  1391	import releases_app as R
  1392	c = sqlite3.connect(sys.argv[2])
  1393	assert R._latest_event(c, 9930, only_source="backfill") == "parked", "own view broke on a non-object payload"
  1394	assert R._latest_event(c, 9930, exclude_source="backfill") == "updated", "exclude view broke on a non-object payload"
  1395	print("views-ok")
  1396	PYPROBE
  1397	[ $? -eq 0 ] && ok "25 both producer views survive list/null/string payloads above the backfill row" || bad "25 a non-object payload broke a producer view"
  1398	NB0="$(sqlite3 "$FXN/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9930 AND payload LIKE '%backfill%';")"
  1399	OUT25="$(appn work backfill 2>&1)"; RC25=$?
  1400	NB1="$(sqlite3 "$FXN/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9930 AND payload LIKE '%backfill%';")"
  1401	[ "$RC25" = "0" ] && [ "$NB0" = "$NB1" ] && ok "25 backfill exits 0 and skips 9930 (still its own latest) with non-object rows present" || bad "25 backfill rc=$RC25, 9930 backfill rows $NB0 -> $NB1: $(echo "$OUT25" | tail -2)"
  1402	# Red: restore the `.get` on the raw decode in a copy → AttributeError, backfill dies.
  1403	NOB="$WORK/app_nonobj"; rm -rf "$NOB"; mkdir -p "$NOB"; cp -R "$ROOT/utils/py/." "$NOB/"
  1404	python3 - "$NOB/releases_app.py" <<'PYMUT'
  1405	import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
  1406	a='        src = decoded.get("source") if isinstance(decoded, dict) else None\n'
  1407	assert s.count(a)==1, "25 red: decode anchor must be unique"
  1408	s=s.replace(a,'        src = (decoded if decoded is not None else {}).get("source")\n',1)
  1409	io.open(p,"w",encoding="utf-8").write(s)
  1410	PYMUT
  1411	[ $? -eq 0 ] || bad "25 red mutation failed"
  1412	FXN2="$WORK/fx_nonobj_red"; rm -rf "$FXN2"; cp -R "$FXN" "$FXN2"
  1413	XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$NOB/releases_app.py" --root "$FXN2" work backfill >"$WORK/nonobj_red.out" 2>&1; RC25R=$?
  1414	[ "$RC25R" != "0" ] && grep -q 'AttributeError' "$WORK/nonobj_red.out" && ok "25 red: with the raw .get restored, backfill DIES with AttributeError (rc=$RC25R)" || bad "25 red did not reproduce (rc=$RC25R)"
  1415	
  1416	
  1417	echo "26. a writer REFUSAL for one issue cannot take reconcile down before dispatch (impl QA r3)"
  1418	# Inject a refuse() (SystemExit) for one issue's emission; the other lands, dispatch runs, rc 0.
  1419	REF="$WORK/app_refuse"; rm -rf "$REF"; mkdir -p "$REF"; cp -R "$ROOT/utils/py/." "$REF/"
  1420	python3 - "$REF/releases_app.py" <<'PYMUT'
  1421	import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
  1422	a='                     exclude_source=None, terminal=()):\n'
  1423	assert s.count(a)==1, "26: emit signature anchor must be unique"
  1424	s=s.replace(a, a+'    if gh_number == 9906 and event == "review_ready":\n        refuse("injected", "simulated writer refusal for 9906")\n',1)
  1425	io.open(p,"w",encoding="utf-8").write(s)
  1426	PYMUT
  1427	[ $? -eq 0 ] || bad "26 injection failed"
  1428	cat > "$WORK/prs.json" <<'PYJ'
  1429	[{"number": 706, "isDraft": false, "title": "a", "body": "Closes #9906"},
  1430	 {"number": 707, "isDraft": false, "title": "b", "body": "Closes #9907"}]
  1431	PYJ
  1432	FXS="$WORK/fx_refuse"; rm -rf "$FXS"; mkdir -p "$FXS"
  1433	( cd "$FXS" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
  1434	cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXS/"; seed_cursor_tail "$FXS/releases.db"   # GH-695
  1435	python3 "$MOCK" --reset --state "$WORK/mock26.json" >/dev/null 2>&1; python3 "$MOCK" --seed --state "$WORK/mock26.json" >/dev/null 2>&1
  1436	R26="$(MOCKSTATE="$WORK/mock26.json" rr python3 "$REF/releases_app.py" --root "$FXS" work reconcile 2>&1)"; RC26=$?
  1437	[ "$RC26" = "0" ] && ok "26 with one emission REFUSING (SystemExit), reconcile still exits 0" || bad "26 rc=$RC26: $R26"
  1438	[ -n "$(sqlite3 "$FXS/releases.db" "SELECT 1 FROM work_events WHERE gh_number=9907 AND event='review_ready';")" ] && ok "26 ...the other issue's event landed" || bad "26 9907 did not land: $R26"
  1439	case "$R26" in *"GH-9906: FAILED"*) ok "26 ...and the refusal was named" ;; *) bad "26 refusal not reported: $R26" ;; esac
  1440	CUR26="$(sqlite3 "$FXS/releases.db" "SELECT last_event_id FROM connector_cursors WHERE connector='github_board';")"
  1441	[ -n "$CUR26" ] && [ "$CUR26" -gt "$PRISTINE_TAIL" ] && ok "26 ...and dispatch still ran (cursor $PRISTINE_TAIL -> $CUR26)" || bad "26 dispatch did not run (cursor '$CUR26', seeded $PRISTINE_TAIL)"
  1442	# Red: re-raise SystemExit in the copy → the verb dies before dispatch.
  1443	python3 - "$REF/releases_app.py" <<'PYMUT'
  1444	import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
  1445	a='            except (SystemExit, Exception) as exc:    # noqa: BLE001 — one issue must not stop the scan\n'
  1446	assert s.count(a)==1, "26 red: except anchor must be unique"
  1447	s=s.replace(a,'            except SystemExit:\n                raise\n            except Exception as exc:\n',1)
  1448	io.open(p,"w",encoding="utf-8").write(s)
  1449	PYMUT
  1450	[ $? -eq 0 ] || bad "26 red mutation failed"
  1451	python3 -m py_compile "$REF/releases_app.py" || bad "26 red: mutated copy does not compile"
  1452	FXS2="$WORK/fx_refuse_red"; rm -rf "$FXS2"; cp -R "$FXS" "$FXS2"; seed_cursor_tail "$FXS2/releases.db"   # GH-695
  1453	MOCKSTATE="$WORK/mock26.json" rr python3 "$REF/releases_app.py" --root "$FXS2" work reconcile >/dev/null 2>&1; RC26R=$?
  1454	CUR26R="$(sqlite3 "$FXS2/releases.db" "SELECT last_event_id FROM connector_cursors WHERE connector='github_board';")"
  1455	[ "$RC26R" != "0" ] && [ "$CUR26R" = "$PRISTINE_TAIL" ] && ok "26 red: re-raising SystemExit takes the verb down (rc=$RC26R) with NO dispatch — the catch is load-bearing" || bad "26 red did not reproduce (rc=$RC26R, cursors=$CUR26R)"
  1456	# A pre-migration ledger: the scan skips with a reason; the verb does not die.
  1457	FXO="$WORK/fx_old"; rm -rf "$FXO"; mkdir -p "$FXO"
  1458	( cd "$FXO" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
  1459	cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXO/"
  1460	sqlite3 "$FXO/releases.db" "DROP TRIGGER IF EXISTS work_events_no_update; DROP TRIGGER IF EXISTS work_events_no_delete; DROP TABLE work_events;" 2>/dev/null
  1461	[ -z "$(sqlite3 "$FXO/releases.db" "SELECT name FROM sqlite_master WHERE name='work_events';")" ] || bad "fixture guard: work_events still present"
  1462	R26O="$(python3 - "$ROOT" "$FXO" <<'PYPROBE'
  1463	import sys, os, sqlite3
  1464	sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py"))
  1465	import releases_app as R
  1466	c = sqlite3.connect(os.path.join(sys.argv[2], "releases.db"))
  1467	try:
  1468	    out = R._scan_review_ready(sys.argv[2], c)
  1469	    print("returned", out)
  1470	except SystemExit as e:
  1471	    print("SYSTEMEXIT", e.code)
  1472	PYPROBE
  1473	)"
  1474	case "$R26O" in *"returned (0, 0, 0)"*) ok "26 on a ledger without work_events the scan returns (0,0,0) instead of exiting" ;; *) bad "26 pre-migration ledger: $R26O" ;; esac
  1475	
  1476	echo
  1477	echo "GH-549 work-state event stream: $PASS passed, $FAIL failed"
  1478	[ "$FAIL" -eq 0 ] || exit 1
  1479	exit 0
     1	#!/usr/bin/env bash
     2	# gh436-merge-cleanup.sh — gate entry for the /merge-cleanup unit suite (GH-436, GH-534 A.6).
     3	#
     4	# WHY: test/gh436-merge-cleanup.py existed for four days without being in validate.sh TESTS, so
     5	# every guarantee it pinned was unproven at push time. This wrapper is the registered entry; the
     6	# Python file (and the GH-534 Phase A module it collects) is the suite.
     7	set -euo pipefail
     8	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
     9	. "$HERE/lib/fixture-guard.sh"
    10	require_forge_root .git .gitattributes WORKTREE-SAFETY.md   # GH-708: forge-root only — witnessed skip in a vendored .xyz/
    11	exec python3 "$HERE/gh436-merge-cleanup.py"

exec
/bin/zsh -lc "rg -n '\\"'$ROOT|PRISTINE|MOCK=|sleep'"' test/gh549-work-events.sh; nl -ba test/gh549-work-events.sh | sed -n '40,95p'; nl -ba test/gh436-merge-cleanup.py | head -180; rg -n 'ROOT|read_text|read_bytes|copy|SKILL|import|sleep|load' test/gh436-merge-cleanup.py" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-68346-vx81h0en
 succeeded in 0ms:
23:. "$ROOT/test/lib/fixture-guard.sh"
25:APP="$ROOT/utils/py/releases_app.py"
27:. "$ROOT/test/lib/fixture-guard.sh"
44:cp "$ROOT/releases.db" "$ROOT/releases.sql" "$FX/" 2>/dev/null || {
45:  echo "gh549: no ledger to copy from $ROOT" >&2; exit 1; }
101:PLACE="$(GH549_ROOT="$ROOT" python3 "$WORK/place.py" "$FX/releases.db")"
128:COV="$(GH549_ROOT="$ROOT" python3 "$WORK/cov.py")"
143:RAISES="$(GH549_ROOT="$ROOT" python3 "$WORK/raises.py")"
150:PRISTINE="$WORK/pristine"; mkdir -p "$PRISTINE"
151:require_fixture "$PRISTINE" "gh549 pre-rebuild ledger snapshot"
152:cp "$FX/releases.db" "$FX/releases.sql" "$PRISTINE/"
153:# GH-695: $PRISTINE is a copy of the LIVE ledger, whose work_events grows with every reconcile. The
161:PRISTINE_TAIL="$(sqlite3 "$PRISTINE/releases.db" "SELECT COALESCE(MAX(id),0) FROM work_events;")"
162:seed_cursor_tail() {  # <releases.db>  -> cursor for github_board = $PRISTINE_TAIL (insert or reset)
163:  sqlite3 "$1" "INSERT INTO connector_cursors(connector,last_event_id,updated_at) VALUES('github_board',$PRISTINE_TAIL,'2026-09-18T00:00:00Z') ON CONFLICT(connector) DO UPDATE SET last_event_id=$PRISTINE_TAIL;"
195:cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXA/"
225:cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXB/"
285:CFGOUT="$(GH549_ROOT="$ROOT" python3 "$WORK/cfgprobe.py" 2>&1)"
304:BS="$(XYZ_DEVICE_CONFIG_PATH=/dev/null python3 "$ROOT/utils/py/board_sync.py" config 2>&1)"
327:time.sleep(5)
359:    # two 5s sleepers under one 30s window: concurrent launch finishes in ~5s, serial in ~10s
366:    # the same two sleepers under a 2s TOTAL window: both are killed, neither advances,
389:cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXC/"
393:ISO="$(GH549_ROOT="$ROOT" python3 "$WORK/dispatch_probe.py" "$FXC/releases.db" "$WORK" isolation 2>&1)"
400:CONC="$(GH549_ROOT="$ROOT" python3 "$WORK/dispatch_probe.py" "$FXC/releases.db" "$WORK" concurrency 2>&1)"
408:WIN="$(GH549_ROOT="$ROOT" python3 "$WORK/dispatch_probe.py" "$FXC/releases.db" "$WORK" window 2>&1)"
427:cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXD/"
445:cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXE/"
565:cp -R "$ROOT/utils/py/." "$GUARDED/"
589:MC="$ROOT/skills/2-daily/merge-cleanup/scripts/merge_cleanup.py"
598:MCOUT="$(GH549_ROOT="$ROOT" python3 "$WORK/mcprobe.py" 2>&1)"
639:assert {"_gh", "sleep"} <= wait_calls, wait_calls
654:MOCK="$ROOT/utils/py/mock_gh_board.py"
655:[ -f "$ROOT/utils/py/work_connectors/github_board.py" ] \
669:cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXB/"
671:TAIL17="$PRISTINE_TAIL"
710:python3 - "$ROOT" <<'PYMAP'
767:cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXC/"
798:        time.sleep(0.05)
799:time.sleep(1.5)
829:cp -R "$ROOT/utils/py/." "$GUARD2/"
860:python3 - "$ROOT" "$FXC/releases.db" <<'PYMONO'
886:python3 - "$ROOT" "$NOLOCKDIR/releases.db" "$WORK/stub_slow.py" "$RUNLOG" <<'PYFAILCLOSED'
938:cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXD/"
965:DRYC="$WORK/app_nodry"; rm -rf "$DRYC"; mkdir -p "$DRYC"; cp -R "$ROOT/utils/py/." "$DRYC/"
992:MAPC="$WORK/app_map"; rm -rf "$MAPC"; mkdir -p "$MAPC"; cp -R "$ROOT/utils/py/." "$MAPC/"
1012:IDC="$WORK/app_noidem"; rm -rf "$IDC"; mkdir -p "$IDC"; cp -R "$ROOT/utils/py/." "$IDC/"
1043:RACE="$WORK/app_race"; rm -rf "$RACE"; mkdir -p "$RACE"; cp -R "$ROOT/utils/py/." "$RACE/"
1061:        import time as _t; _t.sleep(0.4)
1074:WRAP="$ROOT/test/lib/gh-prlist-wrapper.sh"
1078:cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXR/"
1094:rr() { GH549_PRLIST_JSON="$WORK/prs.json" GH549_PRLIST_CALLS="$CALLS" GH549_MOCK="$MOCK" \
1119:cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXI/"; seed_cursor_tail "$FXI/releases.db"   # GH-695
1149:SRC="$WORK/app_nosrc"; rm -rf "$SRC"; mkdir -p "$SRC"; cp -R "$ROOT/utils/py/." "$SRC/"
1164:EXC="$WORK/app_noexc"; rm -rf "$EXC"; mkdir -p "$EXC"; cp -R "$ROOT/utils/py/." "$EXC/"
1174:cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXR7/"; seed_cursor_tail "$FXR7/releases.db"   # GH-695
1185:SUP="$WORK/app_nosup"; rm -rf "$SUP"; mkdir -p "$SUP"; cp -R "$ROOT/utils/py/." "$SUP/"
1201:EVN="$WORK/app_evname"; rm -rf "$EVN"; mkdir -p "$EVN"; cp -R "$ROOT/utils/py/." "$EVN/"
1216:cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXR4/"; seed_cursor_tail "$FXR4/releases.db"   # GH-695
1233:EMF="$WORK/app_emitfail"; rm -rf "$EMF"; mkdir -p "$EMF"; cp -R "$ROOT/utils/py/." "$EMF/"
1248:cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXR5/"; seed_cursor_tail "$FXR5/releases.db"   # GH-695
1256:[ -n "$CUR22F" ] && [ "$CUR22F" -gt "$PRISTINE_TAIL" ] && ok "22f ...and dispatch still ran (cursor $PRISTINE_TAIL -> $CUR22F)" || bad "22f dispatch did not run (cursor '$CUR22F', seeded $PRISTINE_TAIL)"
1276:python3 - "$ROOT" <<'PYMAP'
1286:MAPR="$WORK/gb_nocompleted"; rm -rf "$MAPR"; mkdir -p "$MAPR"; cp -R "$ROOT/utils/py/." "$MAPR/"
1307:cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXK/"
1315:python3 - "$ROOT" "$FXK/releases.db" <<'PYPROBE'
1332:CAPC="$WORK/app_cap"; rm -rf "$CAPC"; mkdir -p "$CAPC"; cp -R "$ROOT/utils/py/." "$CAPC/"
1358:BYP="$WORK/app_bypass"; rm -rf "$BYP"; mkdir -p "$BYP"; cp -R "$ROOT/utils/py/." "$BYP/"
1388:python3 - "$ROOT" "$FXN/releases.db" <<'PYPROBE'
1403:NOB="$WORK/app_nonobj"; rm -rf "$NOB"; mkdir -p "$NOB"; cp -R "$ROOT/utils/py/." "$NOB/"
1419:REF="$WORK/app_refuse"; rm -rf "$REF"; mkdir -p "$REF"; cp -R "$ROOT/utils/py/." "$REF/"
1434:cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXS/"; seed_cursor_tail "$FXS/releases.db"   # GH-695
1441:[ -n "$CUR26" ] && [ "$CUR26" -gt "$PRISTINE_TAIL" ] && ok "26 ...and dispatch still ran (cursor $PRISTINE_TAIL -> $CUR26)" || bad "26 dispatch did not run (cursor '$CUR26', seeded $PRISTINE_TAIL)"
1455:[ "$RC26R" != "0" ] && [ "$CUR26R" = "$PRISTINE_TAIL" ] && ok "26 red: re-raising SystemExit takes the verb down (rc=$RC26R) with NO dispatch — the catch is load-bearing" || bad "26 red did not reproduce (rc=$RC26R, cursors=$CUR26R)"
1459:cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXO/"
1462:R26O="$(python3 - "$ROOT" "$FXO" <<'PYPROBE'
    40	# ── a real ledger fixture: a git checkout (the writer lock needs a git common-dir, GH-448) ──
    41	FX="$WORK/ledger"; mkdir -p "$FX"
    42	require_fixture "$FX" "gh549 ledger fixture"
    43	( cd "$FX" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
    44	cp "$ROOT/releases.db" "$ROOT/releases.sql" "$FX/" 2>/dev/null || {
    45	  echo "gh549: no ledger to copy from $ROOT" >&2; exit 1; }
    46	app() { python3 "$APP" --root "$FX" "$@"; }
    47	
    48	echo "GH-549 work-state event stream:"
    49	
    50	echo "1. migration 008"
    51	app migrate >/dev/null 2>&1
    52	VER="$(sqlite3 "$FX/releases.db" "SELECT version FROM schema_migrations WHERE version=8;" 2>/dev/null)"
    53	[ "$VER" = "8" ] && ok "schema_migrations carries version 8" || bad "version 8 not stamped (got '$VER')"
    54	OBJ="$(sqlite3 "$FX/releases.db" "SELECT group_concat(name,',') FROM sqlite_master WHERE name IN ('work_events','connector_cursors','work_events_no_update','work_events_no_delete') ORDER BY name;" 2>/dev/null)"
    55	case "$OBJ" in
    56	  *work_events*) ok "work_events, connector_cursors and both triggers exist" ;;
    57	  *) bad "expected objects missing (got '$OBJ')" ;;
    58	esac
    59	for t in work_events_no_update work_events_no_delete; do
    60	  # capture-then-match: a pipe into grep -q loses the producer's exit status (gh139)
    61	  TRG="$(sqlite3 "$FX/releases.db" "SELECT 1 FROM sqlite_master WHERE type='trigger' AND name='$t';")"
    62	  [ "$TRG" = "1" ] && ok "trigger $t present" || bad "trigger $t missing"
    63	done
    64	
    65	echo "2. work_events is append-only (witnessed refusals)"
    66	RID="$(sqlite3 "$FX/releases.db" "SELECT id FROM repos LIMIT 1;")"
    67	sqlite3 "$FX/releases.db" "INSERT INTO work_events(global_id,repo_id,gh_number,txn_id,event,payload,at) VALUES ('wev-01M25ZRSCSHSA1SRZVK8ZPQJBS',$RID,1,'txn-t','probe',NULL,'2026-09-10T00:00:00Z');" 2>/dev/null
    68	U="$(sqlite3 "$FX/releases.db" "UPDATE work_events SET event='x' WHERE txn_id='txn-t';" 2>&1)"
    69	case "$U" in *"append-only"*) ok "UPDATE refused: work_events is append-only" ;;
    70	  *) bad "UPDATE was NOT refused (got '$U')" ;; esac
    71	D="$(sqlite3 "$FX/releases.db" "DELETE FROM work_events WHERE txn_id='txn-t';" 2>&1)"
    72	case "$D" in *"append-only"*) ok "DELETE refused: work_events is append-only" ;;
    73	  *) bad "DELETE was NOT refused (got '$D')" ;; esac
    74	sqlite3 "$FX/releases.db" "DROP TRIGGER work_events_no_delete; DELETE FROM work_events WHERE txn_id='txn-t'; CREATE TRIGGER work_events_no_delete BEFORE DELETE ON work_events BEGIN SELECT RAISE(ABORT,'work_events is append-only'); END;" 2>/dev/null
    75	
    76	echo "5. real verbs emit the right events"
    77	app roadmap add --issue-num 9901 --issue-url "https://example.invalid/9901" \
    78	    --title "gh549 fixture" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
    79	app roadmap rate --issue-num 9901 --rated 10/20/30/40 >/dev/null 2>&1
    80	app roadmap update --issue-num 9901 --status-marker "🚧" >/dev/null 2>&1
    81	EV="$(sqlite3 "$FX/releases.db" "SELECT group_concat(event,',') FROM (SELECT event FROM work_events WHERE gh_number=9901 ORDER BY id);")"
    82	[ -n "$EV" ] || bad "no events emitted at all — the fixture proves nothing"
    83	[ "$EV" = "parked,rated,in_flight" ] \
    84	  && ok "roadmap add/rate/update emitted parked,rated,in_flight" \
    85	  || bad "wrong event sequence (got '$EV')"
    86	app check >/dev/null 2>&1 && ok "check is clean after three emitting writes" || bad "check failed after emission"
    87	
    88	echo "6. dump placement (the load-bearing decision), with rows present"
    89	ROWS="$(sqlite3 "$FX/releases.db" "SELECT count(*) FROM work_events;")"
    90	[ "${ROWS:-0}" -gt 0 ] || bad "no work_events rows - the placement probe would pass vacuously"
    91	cat > "$WORK/place.py" <<'PYPROBE'
    92	import sys, os, sqlite3
    93	sys.path.insert(0, os.path.join(os.environ["GH549_ROOT"], "utils", "py"))
    94	import releases_app as R
    95	conn = sqlite3.connect(sys.argv[1]); conn.row_factory = sqlite3.Row
     1	#!/usr/bin/env python3
     2	"""test/gh436-merge-cleanup.py — Unit tests for /merge-cleanup skill.
     3	
     4	Tests:
     5	1. Deletable path containment & NEVER_DELETE boundary guards.
     6	2. PR dependency parsing and topological sorting.
     7	3. Git checkout inspection & disposition classification.
     8	"""
     9	
    10	import os
    11	import sys
    12	import tempfile
    13	import subprocess
    14	import shutil
    15	import unittest
    16	import unittest.mock as mock
    17	from pathlib import Path
    18	
    19	# Add skill scripts to sys.path
    20	sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "skills" / "2-daily" / "merge-cleanup" / "scripts"))
    21	sys.path.insert(0, str(Path(__file__).resolve().parent))
    22	
    23	from scan_clones import (
    24	    _within,
    25	    scan_directories,
    26	    inspect_primary_landing,
    27	    is_safe_deletable_path,
    28	    inspect_checkout,
    29	    inspect_driver_lock,
    30	    inspect_file_activity,
    31	    inspect_completion_confidence,
    32	    derive_agent_followup,
    33	    resolve_canonical_issue,
    34	    format_issue_marker_body,
    35	    DEFAULT_SAFE_ROOTS,
    36	    DEFAULT_NEVER_DELETE
    37	)
    38	import merge_cleanup
    39	import scan_clones
    40	from merge_cleanup import prune_dangling_skill_symlinks
    41	from toposort_prs import (
    42	    parse_pr_dependencies,
    43	    extract_touched_files,
    44	    toposort_prs
    45	)
    46	
    47	
    48	class TestMergeCleanupSafety(unittest.TestCase):
    49	    def test_within_logic(self):
    50	        parent = Path("/a/b")
    51	        child = Path("/a/b/c")
    52	        self.assertTrue(_within(child, parent))
    53	        self.assertFalse(_within(parent, parent))  # child == parent rejected
    54	        self.assertFalse(_within(Path("/a/b_other"), parent))
    55	        self.assertFalse(_within(Path("/a"), parent))
    56	
    57	    def test_safe_deletable_path_boundaries(self):
    58	        safe_root = Path("/tmp/test_safe_root")
    59	        safe_root.mkdir(parents=True, exist_ok=True)
    60	        never_delete = {Path("/tmp/test_safe_root"), Path.home(), Path("/")}
    61	
    62	        child = safe_root / "repo_clone"
    63	        child.mkdir(parents=True, exist_ok=True)
    64	
    65	        # Child inside safe root
    66	        ok, msg = is_safe_deletable_path(child, safe_roots=[safe_root], never_delete=never_delete)
    67	        self.assertTrue(ok)
    68	
    69	        # Safe root itself is rejected
    70	        ok, msg = is_safe_deletable_path(safe_root, safe_roots=[safe_root], never_delete=never_delete)
    71	        self.assertFalse(ok)
    72	        self.assertIn("NEVER_DELETE", msg)
    73	
    74	        # Protected system root
    75	        ok, msg = is_safe_deletable_path(Path("/"), safe_roots=[safe_root], never_delete=never_delete)
    76	        self.assertFalse(ok)
    77	
    78	        # Path outside safe roots
    79	        outside = Path("/tmp/outside_repo")
    80	        outside.mkdir(parents=True, exist_ok=True)
    81	        ok, msg = is_safe_deletable_path(outside, safe_roots=[safe_root], never_delete=never_delete)
    82	        self.assertFalse(ok)
    83	        self.assertIn("SAFE_ROOTS", msg)
    84	
    85	
    86	class TestTopologicalSort(unittest.TestCase):
    87	    def test_parse_dependencies(self):
    88	        body1 = "This fix depends on #123 and is blocked by https://github.com/HiQS-Labs/XYZ-forge/pull/456."
    89	        deps = parse_pr_dependencies(body1, "feat: implement X")
    90	        self.assertEqual(deps, {123, 456})
    91	
    92	        body2 = "No dependencies here."
    93	        deps2 = parse_pr_dependencies(body2, "fix: bug Y")
    94	        self.assertEqual(deps2, set())
    95	
    96	    def test_toposort_linear_chain(self):
    97	        prs = [
    98	            {"number": 3, "title": "PR 3", "body": "Depends on #2", "createdAt": "2026-09-01T03:00:00Z"},
    99	            {"number": 1, "title": "PR 1", "body": "Initial base", "createdAt": "2026-09-01T01:00:00Z"},
   100	            {"number": 2, "title": "PR 2", "body": "Depends on #1", "createdAt": "2026-09-01T02:00:00Z"},
   101	        ]
   102	        ordered, _, _ = toposort_prs(prs)
   103	        ordered_nums = [p["number"] for p in ordered]
   104	        self.assertEqual(ordered_nums, [1, 2, 3])
   105	
   106	    def test_toposort_file_collision_ordering(self):
   107	        prs = [
   108	            {"number": 20, "title": "PR 20", "body": "", "createdAt": "2026-09-01T02:00:00Z", "files": [{"path": "shared.py"}]},
   109	            {"number": 10, "title": "PR 10", "body": "", "createdAt": "2026-09-01T01:00:00Z", "files": [{"path": "shared.py"}]},
   110	        ]
   111	        ordered, _, warnings = toposort_prs(prs)
   112	        ordered_nums = [p["number"] for p in ordered]
   113	        # PR 10 is older, so it should merge before PR 20
   114	        self.assertEqual(ordered_nums, [10, 20])
   115	        self.assertTrue(any("File collision" in w for w in warnings))
   116	
   117	
   118	class TestCheckoutInspection(unittest.TestCase):
   119	    def setUp(self):
   120	        self.temp_dir = tempfile.mkdtemp()
   121	        self.repo_dir = Path(self.temp_dir) / "test_repo"
   122	        self.repo_dir.mkdir()
   123	        subprocess.run(["git", "init"], cwd=self.repo_dir, capture_output=True, check=True)
   124	        subprocess.run(["git", "config", "user.name", "Test User"], cwd=self.repo_dir, check=True)
   125	        subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=self.repo_dir, check=True)
   126	
   127	        # Initial commit
   128	        (self.repo_dir / "README.md").write_text("Hello")
   129	        subprocess.run(["git", "add", "README.md"], cwd=self.repo_dir, check=True)
   130	        subprocess.run(["git", "commit", "-m", "initial commit"], cwd=self.repo_dir, check=True)
   131	
   132	    def tearDown(self):
   133	        shutil.rmtree(self.temp_dir, ignore_errors=True)
   134	
   135	    def test_clean_repo_inspection(self):
   136	        info = inspect_checkout(self.repo_dir)
   137	        self.assertTrue(info["is_git"])
   138	        self.assertEqual(info["checkout_type"], "standalone_clone")
   139	        self.assertTrue(info["is_clean"])
   140	        self.assertEqual(info["stash_count"], 0)
   141	
   142	    def test_dirty_repo_disposition(self):
   143	        (self.repo_dir / "dirty.txt").write_text("uncommitted")
   144	        info = inspect_checkout(self.repo_dir)
   145	        self.assertFalse(info["is_clean"])
   146	        self.assertEqual(info["disposition"], "PRESERVE_DIRTY")
   147	
   148	    def test_driver_lock_inspection(self):
   149	        lock_file = self.repo_dir / ".git" / "relay-driver.lock"
   150	        lock_file.write_text(f"pid={os.getpid()}\nholder=test\n")
   151	        lock_info = inspect_driver_lock(self.repo_dir)
   152	        self.assertTrue(lock_info["locked"])
   153	        self.assertTrue(lock_info["alive"])
   154	        self.assertEqual(lock_info["pid"], os.getpid())
   155	
   156	
   157	class TestPrimaryCheckoutIsInspectedFirst(unittest.TestCase):
   158	    """Phase 0: the primary on-disk checkout is reviewed before any PR (fixed 2026-09-09).
   159	
   160	    Two defects, both observed on a real run:
   161	      1. `scan_directories` only inspected the primary if a SAFE_ROOT walk happened to reach it
   162	         AND its directory name matched `--prefix`. A primary outside those roots, or under a
   163	         non-matching prefix, was absent from the audit entirely while Phase 5 went on merging
   164	         PRs into it and running reconciliation there.
   165	      2. Nothing asserted the primary could actually RECEIVE the landing. Phase 5 merged every
   166	         PR remotely and only then tried `git merge --ff-only`, so a dirty tree or a feature
   167	         branch was discovered after the merges were already irreversible.
   168	    """
   169	
   170	    def setUp(self):
   171	        self.temp_dir = tempfile.mkdtemp()
   172	        self.origin = Path(self.temp_dir) / "origin.git"
   173	        self.primary = Path(self.temp_dir) / "primary"
   174	        self.elsewhere = Path(self.temp_dir) / "roots"
   175	        self.elsewhere.mkdir()
   176	        subprocess.run(["git", "init", "--bare", "-b", "development", str(self.origin)], capture_output=True, check=True)
   177	        subprocess.run(["git", "clone", str(self.origin), str(self.primary)], capture_output=True, check=True)
   178	        for k, v in (("user.name", "Test User"), ("user.email", "test@example.com")):
   179	            subprocess.run(["git", "config", k, v], cwd=self.primary, check=True)
   180	        (self.primary / "README.md").write_text("hello")
10:import os
11:import sys
12:import tempfile
13:import subprocess
14:import shutil
15:import unittest
16:import unittest.mock as mock
17:from pathlib import Path
23:from scan_clones import (
35:    DEFAULT_SAFE_ROOTS,
38:import merge_cleanup
39:import scan_clones
40:from merge_cleanup import prune_dangling_skill_symlinks
41:from toposort_prs import (
83:        self.assertIn("SAFE_ROOTS", msg)
161:      1. `scan_directories` only inspected the primary if a SAFE_ROOT walk happened to reach it
408:        self.sentinel = fake_home / ".claude" / "skills" / "ghost" / "SKILL.md"
409:        self.sentinel.symlink_to(fake_home / "deleted-source" / "SKILL.md")  # deliberately dangling
550:        with mock.patch.object(merge_cleanup, "_sleep") as sleep:
556:        sleep.assert_called_once_with(merge_cleanup.MERGEABLE_POLL_S)
562:        with mock.patch.object(merge_cleanup, "_sleep") as sleep:
568:        self.assertEqual(sleep.call_count, merge_cleanup.MERGEABLE_POLL_ATTEMPTS)
678:         (~/.claude/skills/front-door/SKILL.md)
701:        nested = self._link(".claude/skills/front-door/SKILL.md")
719:        nested = self._link(".claude/skills/front-door/SKILL.md")
861:# one registered entry point (A.6). `from ... import *` is deliberate: unittest discovers classes
863:from gh534_phase_a_tests import *  # noqa: E402,F401,F403
864:from gh534_phase_b_tests import *  # noqa: E402,F401,F403
865:from gh534_phase_c_tests import *  # noqa: E402,F401,F403

exec
/bin/zsh -lc "rg -n 'ROOT|read_text|read_bytes|copy|SKILL|import |sleep|releases.sql|releases.db' test/gh534_phase_{a,b,c}_tests.py; rg -n '"'^from |''^import |releases.sql|migrations|read_text|__file__'"' utils/py/releases_app.py skills/2-daily/merge-cleanup/scripts/{merge_cleanup,scan_clones,toposort_prs}.py; rg -n 'select_qualification_gate|qualify_landings|subsystem.*small|sequential' utils/py/wave_reconcile.py; rg -n 'O2|O7|O8' PROJECT/2-WORKING/GH-831-THREE-TIER-GATE.md" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-68346-vx81h0en
 succeeded in 0ms:
test/gh534_phase_a_tests.py:12:import ast
test/gh534_phase_a_tests.py:13:import json
test/gh534_phase_a_tests.py:14:import os
test/gh534_phase_a_tests.py:15:import re
test/gh534_phase_a_tests.py:16:import shutil
test/gh534_phase_a_tests.py:17:import stat
test/gh534_phase_a_tests.py:18:import subprocess
test/gh534_phase_a_tests.py:19:import sys
test/gh534_phase_a_tests.py:20:import tempfile
test/gh534_phase_a_tests.py:21:import unittest
test/gh534_phase_a_tests.py:22:import unittest.mock as mock
test/gh534_phase_a_tests.py:23:from pathlib import Path
test/gh534_phase_a_tests.py:28:import scan_clones  # noqa: E402
test/gh534_phase_a_tests.py:29:import merge_cleanup  # noqa: E402
test/gh534_phase_a_tests.py:30:from scan_clones import (  # noqa: E402
test/gh534_phase_a_tests.py:31:    DEFAULT_SAFE_ROOTS, GH_BIN_ENV, LSOF_BIN_ENV, TICK_BIN_ENV,
test/gh534_phase_a_tests.py:103:        # Fixtures live under $TMPDIR, which is not a SAFE_ROOT: widen for the duration.
test/gh534_phase_a_tests.py:104:        p = mock.patch.object(scan_clones, "DEFAULT_SAFE_ROOTS", DEFAULT_SAFE_ROOTS + [self.tmp])
test/gh534_phase_a_tests.py:121:        self.assertIn(Path.home() / "marathon-clones", DEFAULT_SAFE_ROOTS)
test/gh534_phase_a_tests.py:124:        """THE PIN: WORKTREE-SAFETY.md's SAFE_ROOTS example IS DEFAULT_SAFE_ROOTS."""
test/gh534_phase_a_tests.py:125:        doc = (REPO / "WORKTREE-SAFETY.md").read_text()
test/gh534_phase_a_tests.py:126:        block = re.search(r"SAFE_ROOTS = \[(.*?)\]", doc, re.S).group(1)
test/gh534_phase_a_tests.py:129:        self.assertEqual(doc_roots, DEFAULT_SAFE_ROOTS)
test/gh534_phase_a_tests.py:275:        src = (REPO / "skills/2-daily/merge-cleanup/scripts/scan_clones.py").read_text()
test/gh534_phase_a_tests.py:296:        for name in ("harnesses.db", "releases.db.bak", "MARATHON-PLAN-2026-09-09.md"):
test/gh534_phase_a_tests.py:304:    env = dict(os.environ, TICK_REPO_ROOT=str(root))
test/gh534_phase_a_tests.py:420:        src = (REPO / "skills/2-daily/merge-cleanup/scripts/scan_clones.py").read_text()
test/gh534_phase_a_tests.py:443:                                   "import sys,time; f=open(sys.argv[1]); print('open', flush=True); time.sleep(60)",
test/gh534_phase_a_tests.py:545:        p = mock.patch.object(scan_clones, "DEFAULT_SAFE_ROOTS", DEFAULT_SAFE_ROOTS + [self.roots])
test/gh534_phase_c_tests.py:7:import json
test/gh534_phase_c_tests.py:8:import os
test/gh534_phase_c_tests.py:9:import re
test/gh534_phase_c_tests.py:10:import shutil
test/gh534_phase_c_tests.py:11:import sqlite3
test/gh534_phase_c_tests.py:12:import subprocess
test/gh534_phase_c_tests.py:13:import sys
test/gh534_phase_c_tests.py:14:import tempfile
test/gh534_phase_c_tests.py:15:import threading
test/gh534_phase_c_tests.py:16:import time
test/gh534_phase_c_tests.py:17:import unittest
test/gh534_phase_c_tests.py:18:from pathlib import Path
test/gh534_phase_c_tests.py:25:import attempt_record as ar  # noqa: E402
test/gh534_phase_c_tests.py:26:import contextlib
test/gh534_phase_c_tests.py:27:import io
test/gh534_phase_c_tests.py:28:import ledger_merge  # noqa: E402
test/gh534_phase_c_tests.py:29:import merge_cleanup  # noqa: E402
test/gh534_phase_c_tests.py:30:import scan_clones  # noqa: E402
test/gh534_phase_c_tests.py:31:import unittest.mock as mock
test/gh534_phase_c_tests.py:32:from attempt_record import RECORD_ENV, RecordError, RecordLock, reserve  # noqa: E402
test/gh534_phase_c_tests.py:33:from gh534_phase_a_tests import TestA2Provenance, TestA4OpenHandles, TestA4TickClaims, TestA5FailClosed, TestA5FreshInspection  # noqa: E402,F401
test/gh534_phase_c_tests.py:34:from gh534_phase_b_tests import LedgerFixture, TestE6Gate, TestPhase5EndToEnd, _app, _git, commit_all, park  # noqa: E402,F401
test/gh534_phase_c_tests.py:41:import json, os, pathlib, shutil, subprocess, sys, tempfile
test/gh534_phase_c_tests.py:122:        rec = json.loads(self.record.read_text())
test/gh534_phase_c_tests.py:130:        self.assertEqual(json.loads(self.record.read_text())["attempts"][0]["outcome"], "handoff")
test/gh534_phase_c_tests.py:157:        rec = json.loads(self.record.read_text())
test/gh534_phase_c_tests.py:195:        time.sleep(0.5)  # both are now blocked on the lock
test/gh534_phase_c_tests.py:204:        from rtl import driver_lock_path
test/gh534_phase_c_tests.py:252:        shutil.copy(self.gh, backend)
test/gh534_phase_c_tests.py:286:        with sqlite3.connect(self.primary / "releases.db") as conn:
test/gh534_phase_c_tests.py:417:        roots = mock.patch.object(scan_clones, "DEFAULT_SAFE_ROOTS", [self.tmp.resolve()])  # the fixture dir is a safe root here
test/gh534_phase_c_tests.py:478:            for f in ("releases.sql", "releases.db"):
test/gh534_phase_c_tests.py:483:            return {"resolved": True, "handoff": False, "reason": "x", "log": [], "commit": head, "conflict_set": ["releases.sql"]}
test/gh534_phase_c_tests.py:522:# --- Parity guard: SKILL.md's capability table vs the code and the tests ------------------------
test/gh534_phase_c_tests.py:523:SKILL_MD = REPO / "skills" / "2-daily" / "merge-cleanup" / "SKILL.md"
test/gh534_phase_c_tests.py:537:    # not demand can be deleted from SKILL.md with the parity test still green.
test/gh534_phase_c_tests.py:549:    import ast
test/gh534_phase_c_tests.py:563:    """Every way SKILL.md can drift from the code, named. Empty list = parity."""
test/gh534_phase_c_tests.py:564:    import re
test/gh534_phase_c_tests.py:565:    sources = sources or {k: v[0].read_text() for k, v in AST_CALLS.items()}
test/gh534_phase_c_tests.py:604:import toposort_prs as toposort  # noqa: E402
test/gh534_phase_c_tests.py:661:        sleeps = []
test/gh534_phase_c_tests.py:662:        with mock.patch.object(merge_cleanup, "_sleep", side_effect=sleeps.append, create=True):
test/gh534_phase_c_tests.py:670:        self.assertEqual(sleeps, [2, 4], "the retry schedule is 3 calls with 2s then 4s between them")
test/gh534_phase_c_tests.py:674:        attempt succeeds and the PR lands; the sleep sequence pins the retry contract."""
test/gh534_phase_c_tests.py:679:        sleeps = []
test/gh534_phase_c_tests.py:680:        with mock.patch.object(merge_cleanup, "_sleep", side_effect=sleeps.append, create=True):
test/gh534_phase_c_tests.py:685:        self.assertEqual(sleeps, [2, 4])
test/gh534_phase_c_tests.py:694:        sleeps = []
test/gh534_phase_c_tests.py:695:        with mock.patch.object(merge_cleanup, "_sleep", side_effect=sleeps.append, create=True):
test/gh534_phase_c_tests.py:700:        self.assertEqual(sleeps, [2, 4])
test/gh534_phase_c_tests.py:761:                mock.patch.object(merge_cleanup, "_sleep", side_effect=lambda s: None, create=True):
test/gh534_phase_c_tests.py:810:        GH-623 retries a transient failure 3x with [2, 4] sleeps before refusing."""
test/gh534_phase_c_tests.py:823:                mock.patch.object(merge_cleanup, "_sleep", side_effect=lambda s: None, create=True):
test/gh534_phase_c_tests.py:847:                mock.patch.object(merge_cleanup, "_sleep", side_effect=lambda s: None, create=True):
test/gh534_phase_c_tests.py:870:    """R4 regression proof (GH-623 final-QA finding 2): SKILL.md's Drive loop section, its Done
test/gh534_phase_c_tests.py:877:        cls.text = SKILL_MD.read_text()
test/gh534_phase_c_tests.py:901:        self.assertNotEqual(mutated, self.text, "control pattern no longer matches SKILL.md — repoint it")
test/gh534_phase_c_tests.py:924:        cls.skill = SKILL_MD.read_text()
test/gh534_phase_c_tests.py:956:        srcs = {k: v[0].read_text() for k, v in AST_CALLS.items()}
test/gh534_phase_b_tests.py:11:import contextlib
test/gh534_phase_b_tests.py:12:import io
test/gh534_phase_b_tests.py:13:import json
test/gh534_phase_b_tests.py:14:import os
test/gh534_phase_b_tests.py:15:import shutil
test/gh534_phase_b_tests.py:16:import subprocess
test/gh534_phase_b_tests.py:17:import sys
test/gh534_phase_b_tests.py:18:import tempfile
test/gh534_phase_b_tests.py:19:import unittest
test/gh534_phase_b_tests.py:20:import unittest.mock as mock
test/gh534_phase_b_tests.py:21:from pathlib import Path
test/gh534_phase_b_tests.py:26:import ledger_merge  # noqa: E402
test/gh534_phase_b_tests.py:27:import merge_cleanup  # noqa: E402
test/gh534_phase_b_tests.py:28:import scan_clones  # noqa: E402
test/gh534_phase_b_tests.py:29:from ledger_merge import classify, parse_dump, pre_merge_ledger_gate, resolve_ledger_conflict  # noqa: E402
test/gh534_phase_b_tests.py:30:from scan_clones import GH_BIN_ENV  # noqa: E402
test/gh534_phase_b_tests.py:64:import json, os, subprocess, sys, tempfile, shutil
test/gh534_phase_b_tests.py:163:        shutil.copy(APP_SRC, self.seed / "utils" / "py" / "releases_app.py")
test/gh534_phase_b_tests.py:164:        shutil.copy(RESOLVER_SRC, self.seed / "utils" / "releases-merge-resolve.sh")
test/gh534_phase_b_tests.py:165:        shutil.copy(REPO / ".gitattributes", self.seed / ".gitattributes")
test/gh534_phase_b_tests.py:189:        self.st = json.loads(self.state.read_text())
test/gh534_phase_b_tests.py:227:                            "import sqlite3,sys;c=sqlite3.connect(sys.argv[1]);print(sorted(int(r[0]) for r in c.execute('select gh_number from roadmap_items')))",
test/gh534_phase_b_tests.py:228:                            str(c / "releases.db")], capture_output=True, text=True)
test/gh534_phase_b_tests.py:239:        base = (self.seed / "releases.sql").read_text()
test/gh534_phase_b_tests.py:244:        return base, (o / "releases.sql").read_text(), (t / "releases.sql").read_text()
test/gh534_phase_b_tests.py:262:            s = (r / "releases.sql").read_text()
test/gh534_phase_b_tests.py:264:            (r / "releases.sql").write_text(s)
test/gh534_phase_b_tests.py:272:            s = (r / "releases.sql").read_text()
test/gh534_phase_b_tests.py:273:            (r / "releases.sql").write_text("\n".join(l for l in s.splitlines() if not l.startswith("INSERT INTO repos")) + "\n")
test/gh534_phase_b_tests.py:288:        base = (root / "releases.sql").read_text()
test/gh534_phase_b_tests.py:291:        shutil.copytree(root, ours_root)
test/gh534_phase_b_tests.py:292:        shutil.copytree(root, theirs_root)
test/gh534_phase_b_tests.py:295:        ours = (ours_root / "releases.sql").read_text()
test/gh534_phase_b_tests.py:296:        theirs = (theirs_root / "releases.sql").read_text()
test/gh534_phase_b_tests.py:349:        outside_backup = self.tmp / "releases.db.bak"
test/gh534_phase_b_tests.py:353:        self.assertFalse((clone / "releases.db.bak").exists(), "successful B1 left rebuild backup")
test/gh534_phase_b_tests.py:354:        self.assertEqual(outside_backup.read_bytes(), b"outside", "cleanup escaped the landing clone")
test/gh534_phase_b_tests.py:364:                (Path(cwd) / "releases.db.bak").write_bytes(b"recovery evidence")
test/gh534_phase_b_tests.py:371:        self.assertEqual((clone / "releases.db.bak").read_bytes(), b"recovery evidence")
test/gh534_phase_b_tests.py:403:        sleeps = []  # GH-736: record the poll schedule without waiting it out
test/gh534_phase_b_tests.py:404:        with mock.patch.object(merge_cleanup, "_sleep", side_effect=sleeps.append):
test/gh534_phase_b_tests.py:411:        polls = [s for s in sleeps if s == merge_cleanup.MERGEABLE_POLL_S]
test/gh534_phase_b_tests.py:412:        self.assertEqual(len(polls), merge_cleanup.MERGEABLE_POLL_ATTEMPTS, sleeps)
test/gh534_phase_b_tests.py:420:        out, sleeps = io.StringIO(), []
test/gh534_phase_b_tests.py:421:        with contextlib.redirect_stdout(out), mock.patch.object(merge_cleanup, "_sleep", side_effect=sleeps.append):
test/gh534_phase_b_tests.py:425:        polls = [s for s in sleeps if s == merge_cleanup.MERGEABLE_POLL_S]
test/gh534_phase_b_tests.py:426:        self.assertTrue(1 <= len(polls) < merge_cleanup.MERGEABLE_POLL_ATTEMPTS, sleeps)
test/gh534_phase_b_tests.py:430:        # GH-736: `--exclude <N>` (SKILL.md example 6) removes PR N from the queue; before the
test/gh534_phase_b_tests.py:460:             mock.patch.object(merge_cleanup, "_sleep"):
test/gh534_phase_b_tests.py:474:             mock.patch.object(merge_cleanup, "_sleep"):
test/gh534_phase_b_tests.py:504:        with mock.patch.object(merge_cleanup.time, "sleep"):
test/gh534_phase_b_tests.py:550:        sec = subprocess.run([sys.executable, "-c", "import sqlite3,sys;print(sqlite3.connect(sys.argv[1]).execute(\"select section from roadmap_items where gh_number='100'\").fetchone()[0])", str(c / "releases.db")], capture_output=True, text=True).stdout.strip()
test/gh534_phase_b_tests.py:609:            import re as _re
test/gh534_phase_b_tests.py:610:            s = _re.sub(r"^-- generation: \d+$", "-- generation: 1", (root / "releases.sql").read_text(), count=1, flags=_re.M)
test/gh534_phase_b_tests.py:611:            (root / "releases.sql").write_text(s)  # header rewound below both parents
test/gh534_phase_b_tests.py:652:        s = (c / "releases.sql").read_text().replace("-- generation: ", "-- generation: 9", 1)
test/gh534_phase_b_tests.py:653:        (c / "releases.sql").write_text(s)
test/gh534_phase_b_tests.py:660:        (c / "utils" / "py" / "releases_app.py").write_text("import sys; sys.exit(4)\n")
test/gh534_phase_b_tests.py:684:            seen.append((clone / "releases.sql").read_text())
test/gh534_phase_b_tests.py:700:             mock.patch.object(merge_cleanup, "_sleep") as sl, \
test/gh534_phase_b_tests.py:707:            out, refreshes, sleeps = self._run({"mergeable": state}, [])
test/gh534_phase_b_tests.py:708:            self.assertEqual((out["mergeable"], refreshes, sleeps), (state, 0, 0))
test/gh534_phase_b_tests.py:712:        out, refreshes, sleeps = self._run({"error": "boom"}, [])
test/gh534_phase_b_tests.py:713:        self.assertEqual((out.get("error"), refreshes, sleeps), ("boom", 0, 0))
test/gh534_phase_b_tests.py:716:        out, refreshes, sleeps = self._run({"mergeable": "UNKNOWN"}, [{"mergeable": "UNKNOWN"}, {"error": "net"}])
test/gh534_phase_b_tests.py:717:        self.assertEqual((out.get("error"), refreshes, sleeps), ("net", 2, 2))
test/gh534_phase_b_tests.py:721:        out, refreshes, sleeps = self._run({"mergeable": "UNKNOWN"}, reads)
test/gh534_phase_b_tests.py:724:        self.assertEqual(sleeps, merge_cleanup.MERGEABLE_POLL_ATTEMPTS)
skills/2-daily/merge-cleanup/scripts/scan_clones.py:10:import os
skills/2-daily/merge-cleanup/scripts/scan_clones.py:11:import re
skills/2-daily/merge-cleanup/scripts/scan_clones.py:12:import sys
skills/2-daily/merge-cleanup/scripts/scan_clones.py:13:import json
skills/2-daily/merge-cleanup/scripts/scan_clones.py:14:import subprocess
skills/2-daily/merge-cleanup/scripts/scan_clones.py:15:import shutil
skills/2-daily/merge-cleanup/scripts/scan_clones.py:16:import tempfile
skills/2-daily/merge-cleanup/scripts/scan_clones.py:17:import time
skills/2-daily/merge-cleanup/scripts/scan_clones.py:18:from pathlib import Path
skills/2-daily/merge-cleanup/scripts/scan_clones.py:19:from typing import List, Dict, Any, Optional, Tuple
skills/2-daily/merge-cleanup/scripts/scan_clones.py:144:                content = lock.read_text().strip()
skills/2-daily/merge-cleanup/scripts/scan_clones.py:190:    for parent in Path(__file__).resolve().parents:  # skills/<tier>/merge-cleanup/scripts/ (GH-744)
skills/2-daily/merge-cleanup/scripts/scan_clones.py:658:                content = doc.read_text(encoding="utf-8", errors="replace")
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:13:import json
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:14:import re
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:15:import os
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:16:import sys
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:17:import argparse
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:18:import subprocess
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:19:import shutil
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:20:import time
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:21:from pathlib import Path
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:22:from typing import List, Dict, Any, Optional, Tuple
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:24:from scan_clones import (
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:38:from toposort_prs import (
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:44:from scan_clones import GH_BIN_ENV
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:45:import attempt_record
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:46:import ledger_merge
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:47:from ledger_merge import (
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:53:import json
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:54:import tempfile
skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:996:            # pr_merged before this fast-forward dirties releases.sql and can block the landing
skills/2-daily/merge-cleanup/scripts/toposort_prs.py:8:import sys
skills/2-daily/merge-cleanup/scripts/toposort_prs.py:9:import re
skills/2-daily/merge-cleanup/scripts/toposort_prs.py:10:import json
skills/2-daily/merge-cleanup/scripts/toposort_prs.py:11:import os
skills/2-daily/merge-cleanup/scripts/toposort_prs.py:12:import subprocess
skills/2-daily/merge-cleanup/scripts/toposort_prs.py:13:from typing import List, Dict, Any, Set, Tuple, Optional
utils/py/releases_app.py:9:committed logical dump (releases.sql, global-ID-keyed) is authoritative at git merge boundaries
utils/py/releases_app.py:16:The SQLite DB (releases.db) is authoritative for reads and writes at runtime; releases.sql is
utils/py/releases_app.py:29:  releases.sql                   canonical logical dump (committed, git-mergeable)
utils/py/releases_app.py:57:import argparse
utils/py/releases_app.py:58:import datetime as _dt
utils/py/releases_app.py:59:import fcntl
utils/py/releases_app.py:60:import hashlib
utils/py/releases_app.py:61:import json
utils/py/releases_app.py:62:import os
utils/py/releases_app.py:63:import re
utils/py/releases_app.py:64:import shutil
utils/py/releases_app.py:65:import sqlite3
utils/py/releases_app.py:66:import subprocess
utils/py/releases_app.py:67:import sys
utils/py/releases_app.py:68:import time
utils/py/releases_app.py:69:import urllib.parse
utils/py/releases_app.py:70:import uuid
utils/py/releases_app.py:95:DUMP_NAME = "releases.sql"
utils/py/releases_app.py:486:CREATE TABLE schema_migrations (
utils/py/releases_app.py:657:    GH-111: exists so migrations can avoid executescript(), which commits the caller's
utils/py/releases_app.py:704:    predates it: the new schema_migrations row is business state, and a schema change outside a
utils/py/releases_app.py:712:    stamp=False is the REGISTRY entry point: `apply_migrations` owns the ledger row there, and
utils/py/releases_app.py:718:    if stamp and conn.execute("SELECT 1 FROM schema_migrations WHERE version = 2").fetchone() is None:
utils/py/releases_app.py:719:        conn.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (2, ?)",
utils/py/releases_app.py:922:      dump would make releases.sql disagree with the DB the moment any connector ran, and the
utils/py/releases_app.py:970:    if stamp and conn.execute("SELECT 1 FROM schema_migrations WHERE version = 6").fetchone() is None:
utils/py/releases_app.py:971:        conn.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (6, ?)",
utils/py/releases_app.py:1009:# migrations apply in ascending numeric order; gaps are safe only because migrations are
utils/py/releases_app.py:1044:        applied = {r["version"] for r in conn.execute("SELECT version FROM schema_migrations")}
utils/py/releases_app.py:1050:def apply_migrations(conn, stamp_ledger=True):
utils/py/releases_app.py:1051:    """Apply pending registry migrations in ascending order.
utils/py/releases_app.py:1054:    ledger rows itself AFTER load_dump() (which skips the dump's schema_migrations records),
utils/py/releases_app.py:1059:        if stamp_ledger and conn.execute("SELECT 1 FROM schema_migrations WHERE version = ?",
utils/py/releases_app.py:1061:            conn.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (?, ?)",
utils/py/releases_app.py:1107:    _emit(w, "schema_migrations", ["version", "applied_at"],
utils/py/releases_app.py:1108:          _rows(conn, "SELECT version, applied_at FROM schema_migrations ORDER BY version"))
utils/py/releases_app.py:1290:        # releases.sql out of sync with the DB the moment any connector ran and fail
utils/py/releases_app.py:1623:        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
utils/py/releases_app.py:1780:        -> apply pending registry migrations, ascending, parent-before-child
utils/py/releases_app.py:1803:                       conn.execute("SELECT version FROM schema_migrations ORDER BY version")]
utils/py/releases_app.py:1821:            "started_at": now_iso(), "pending_migrations": pending,
utils/py/releases_app.py:1829:            apply_migrations(conn)
utils/py/releases_app.py:1853:                         ("migrations: %s" % ",".join(str(v) for v in pending), now_iso(),
utils/py/releases_app.py:2175:            apply_migrations(conn)
utils/py/releases_app.py:4257:            "SELECT 1 FROM schema_migrations WHERE version = 2").fetchone() is None
utils/py/releases_app.py:4933:        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
utils/py/releases_app.py:4941:        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
utils/py/releases_app.py:4962:    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
utils/py/releases_app.py:5229:        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
utils/py/releases_app.py:5468:        if not _table_exists(conn, "schema_migrations"):
utils/py/releases_app.py:5472:            "SELECT version FROM schema_migrations ORDER BY version")]
utils/py/releases_app.py:5587:        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
utils/py/releases_app.py:5619:    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
utils/py/releases_app.py:5990:    for row in tables.get("schema_migrations", []):
utils/py/releases_app.py:5994:                   "schema_migrations version %s appears more than once. Each migration is applied "
utils/py/releases_app.py:6025:def load_dump(conn, tables, skip_schema_migrations=False):
utils/py/releases_app.py:6029:    skip_schema_migrations=True is the rebuild path (GH-111). The migration LEDGER is owned by
utils/py/releases_app.py:6036:    if not skip_schema_migrations:
utils/py/releases_app.py:6037:        for row in tables.get("schema_migrations", []):
utils/py/releases_app.py:6038:            conn.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (?, ?)",
utils/py/releases_app.py:6265:            #   2. load everything from the dump EXCEPT its schema_migrations records;
utils/py/releases_app.py:6270:            apply_migrations(tconn, stamp_ledger=False)
utils/py/releases_app.py:6276:                load_dump(tconn, parsed, skip_schema_migrations=True)
utils/py/releases_app.py:6290:                            for r in parsed.get("schema_migrations", [])}
utils/py/releases_app.py:6293:                tconn.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (?, ?)",
459:QUALIFICATION_GATE = "validate.sh --sequential"
462:SMALL_GATE = "validate.sh --sequential --subsystem small"
478:    """Require the existing runner's complete, unquarantined sequential evidence.
492:    if (start.get("commit") != tested_sha or start.get("mode") != "sequential"
499:    sequential = [row for row in suites if row.get("lane") == "sequential"]
501:        names = [row.get("name") for row in sequential]
513:    if (len(sequential) != registered or len({row.get("name") for row in sequential}) != registered
589:def select_qualification_gate(clone, metas, env):
617:def qualify_landings(repo_root, metas, journal):
668:            gate, expected, reason = select_qualification_gate(clone, pending, env)
678:            files = list(telemetry.glob(f"validate-sequential-*-{validation.pgid}.jsonl"))
2039:                        help="Run the full sequential suite and retain integration evidence before gated closeout")
2140:                    qualify_landings(repo_root, [metadata[item] for item in landing_items], journal)
61:- After the Codex plan review escalated for them, the operator accepted O1, O2, O3, O4, O7 and O8 as proposed:
63:  - O2: gh549 and gh436 stay in Small;
64:  - O3, O4 and O7: Medium handling, all three;
65:  - O8: promotion always runs Large.
281:| Hosted reconcile after each merge (qualifies the landing) | `validate.sh --sequential --subsystem small`: **one** run | `validate.sh --sequential`: the full registry (O7) | `validate.sh --sequential` |
282:| Promotion (`ci.yml` boundary on `main`) | — | — | `validate.sh --sequential` (unchanged; the classifier is not consulted, O8) |
374:**D6 — Promotion is unchanged (O8).** The boundary job still runs `validate.sh --sequential`, now the
376:deliberately does not, and records that as O8 for the operator. GH-509 becomes two rules:
396:**Confirmed by the operator on 2026-09-25: O1, O2, O3, O4, O7 and O8.** O5 and O6 remain proposals; O5 follows
402:- **O2 — `gh549-work-events.sh` and `gh436-merge-cleanup.sh` stay in Small. Default: yes, by definition (PRS).**
413:- **O7 — The hosted reconcile qualifies Medium merges with the full run, not Small plus the area. Default: yes.**
415:- **O8 — Promotion always runs Large; the classifier is not consulted. Default: yes.** This is a deviation
426:to about 39–43 with O2's alternative. The per-merge wait for docs, ledger and skill merges is where the change
453:The operator confirmed O1–O4, O7 and O8 on 2026-09-25.

codex
Both suites consume tier-1 inputs: gh549 copies the committed ledger, while gh436 checks skill and safety markdown. I’m checking which expensive sections can be reduced without losing that coverage.

exec
/bin/zsh -lc "sed -n '1,160p' test/gh534_phase_a_tests.py; sed -n '135,190p' test/gh534_phase_b_tests.py; nl -ba test/gh534_phase_c_tests.py | sed -n '870,975p'; rg -n 'REPO /|REPO_ROOT|ROOT /|tick|rtl|xyz_tools' test/gh534_phase_{a,b,c}_tests.py skills/2-daily/merge-cleanup/scripts/{attempt_record,ledger_merge,scan_clones}.py; sed -n '589,616p' utils/py/wave_reconcile.py; nl -ba test/gh645-merge-cleanup-xyz-tools.sh | head -85; nl -ba test/gh674-merge-cleanup-hosted-lookup.sh | head -75" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-68346-vx81h0en
 succeeded in 0ms:
#!/usr/bin/env python3
"""test/gh534_phase_a_tests.py — GH-534 Phase A: the scanner tells the truth and fails closed.

Imported by test/gh436-merge-cleanup.py (one registered entry point, A.6). Every fixture is a real
git repo with a real local origin; `tick` is the real bin/tick; `lsof` is the real binary except
where a case needs a stub (absent, signal-killed). `gh` is always a stub — no network.

Sections: A.1 roots · A.2 provenance · A.3 dirt · A.4 session evidence (tick + lsof) · A.5 fresh
inspection + fail-closed queries.
"""

import ast
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
import unittest.mock as mock
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts"))

import scan_clones  # noqa: E402
import merge_cleanup  # noqa: E402
from scan_clones import (  # noqa: E402
    DEFAULT_SAFE_ROOTS, GH_BIN_ENV, LSOF_BIN_ENV, TICK_BIN_ENV,
    classify_local_refs, inspect_checkout, inspect_open_handles, inspect_tick_claims,
    is_safe_deletable_path, scan_directories,
)

TICK = REPO / "bin" / "tick"


def _git(cwd, *args, check=True):
    return subprocess.run(["git", "-C", str(cwd)] + list(args), capture_output=True, text=True, check=check)


def _commit(cwd, name, content, msg=None):
    (Path(cwd) / name).parent.mkdir(parents=True, exist_ok=True)
    (Path(cwd) / name).write_text(content)
    _git(cwd, "add", "-A")
    _git(cwd, "commit", "-q", "-m", msg or f"add {name}")
    return _git(cwd, "rev-parse", "HEAD").stdout.strip()


def make_origin_and_clone(tmp, name="clone"):
    origin = Path(tmp) / "origin.git"
    clone = Path(tmp) / name
    subprocess.run(["git", "init", "-q", "--bare", "-b", "development", str(origin)], check=True)
    subprocess.run(["git", "clone", "-q", str(origin), str(clone)], check=True, capture_output=True)
    for k, v in (("user.name", "t"), ("user.email", "t@e.com")):
        _git(clone, "config", k, v)
    _commit(clone, "README.md", "hello", "initial")
    _git(clone, "push", "-q", "-u", "origin", "development")
    return origin, clone


def write_gh_stub(tmp, origin, merged):
    """A `gh` that answers `repo view` with the fixture origin and `pr list` with `merged`."""
    stub = Path(tmp) / "gh"
    data = Path(tmp) / "gh-merged.json"
    data.write_text(json.dumps(merged))
    stub.write_text(
        "#!/usr/bin/env bash\n"
        f"if [ \"$1\" = repo ]; then printf '{{\"url\":\"%s\"}}\\n' '{origin}'; exit 0; fi\n"
        f"if [ \"$1\" = pr ]; then cat '{data}'; exit 0; fi\n"
        "echo 'stub: unexpected args' >&2; exit 9\n"
    )
    stub.chmod(0o755)
    return stub


def squash_land(clone, branch, number):
    """Land `branch` on development the way this repo does: squash, then push. Returns
    (head_of_branch, squash_commit) and the gh-shaped merged record."""
    head = _git(clone, "rev-parse", branch).stdout.strip()
    _git(clone, "checkout", "-q", "development")
    _git(clone, "merge", "--squash", "-q", branch)
    _git(clone, "commit", "-q", "-m", f"squash #{number}")
    mc = _git(clone, "rev-parse", "HEAD").stdout.strip()
    _git(clone, "push", "-q", "origin", "development")
    _git(clone, "checkout", "-q", branch)
    return head, mc, {"number": number, "state": "MERGED", "headRefOid": head,
                      "mergeCommit": {"oid": mc}, "baseRefName": "development"}


def stub_env(**kv):
    env = {k: v for k, v in kv.items()}
    return mock.patch.dict(os.environ, env)


class _Fixture(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="gh534."))
        self.addCleanup(shutil.rmtree, self.tmp, True)
        scan_clones._merged_pr_cache.clear()
        self.origin, self.clone = make_origin_and_clone(self.tmp)
        # Fixtures live under $TMPDIR, which is not a SAFE_ROOT: widen for the duration.
        p = mock.patch.object(scan_clones, "DEFAULT_SAFE_ROOTS", DEFAULT_SAFE_ROOTS + [self.tmp])
        p.start()
        self.addCleanup(p.stop)
        # Never talk to GitHub: default gh stub knows no merged PRs.
        self.gh = write_gh_stub(self.tmp, self.origin, [])
        e = mock.patch.dict(os.environ, {GH_BIN_ENV: str(self.gh)})
        e.start()
        self.addCleanup(e.stop)

    def inspect(self, path=None, **kw):
        return inspect_checkout(path or self.clone, **kw)


# --- A.1 roots ----------------------------------------------------------------------------

class TestA1Roots(unittest.TestCase):
    def test_marathon_clones_is_a_safe_root(self):
        self.assertIn(Path.home() / "marathon-clones", DEFAULT_SAFE_ROOTS)

    def test_doc_and_code_root_lists_agree(self):
        """THE PIN: WORKTREE-SAFETY.md's SAFE_ROOTS example IS DEFAULT_SAFE_ROOTS."""
        doc = (REPO / "WORKTREE-SAFETY.md").read_text()
        block = re.search(r"SAFE_ROOTS = \[(.*?)\]", doc, re.S).group(1)
        doc_roots = [Path.home().joinpath(*re.findall(r'"([^"]+)"', line))
                     for line in block.splitlines() if "Path.home()" in line]
        self.assertEqual(doc_roots, DEFAULT_SAFE_ROOTS)

    def test_strict_root_prefix_sibling_and_symlink_escape_are_rejected(self):
        tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, tmp, True)
        root = tmp / "XYZ-forge"
        root.mkdir()
        never = {tmp, Path("/")}
        ok, _ = is_safe_deletable_path(root, safe_roots=[root], never_delete=never)
        self.assertFalse(ok, "the root itself must not be deletable")
        sib = tmp / "XYZ-forge-foo" / "clone"
        sib.mkdir(parents=True)
        ok, msg = is_safe_deletable_path(sib, safe_roots=[root], never_delete=never)
        self.assertFalse(ok, f"prefix sibling accepted: {msg}")
        outside = tmp / "outside"
        outside.mkdir()
        link = root / "escapee"
        link.symlink_to(outside)
        ok, msg = is_safe_deletable_path(link, safe_roots=[root], never_delete=never)
        self.assertFalse(ok, f"symlink escaping the root accepted: {msg}")
        inside = root / "clone"
        inside.mkdir()
        self.assertTrue(is_safe_deletable_path(inside, safe_roots=[root], never_delete=never)[0])


# --- A.2 provenance ---------------------------------------------------------------------

class TestA2Provenance(_Fixture):
    def _feature(self, name="feat/x", commits=1):
        _git(self.clone, "checkout", "-q", "-b", name)
        for i in range(commits):
            _commit(self.clone, f"{name.replace('/', '-')}-{i}.txt", f"work {i}\n")
        git(w, "config", "user.email", "gh@stub"); git(w, "config", "user.name", "gh")
        git(w, "checkout", "-q", st["base"])
        r = git(w, "merge", "--squash", "origin/" + pr["headRefName"])
        if r.returncode != 0: print(r.stderr, file=sys.stderr); sys.exit(1)
        git(w, "commit", "-q", "-m", f"squash #{pr['number']}")
        mc = git(w, "rev-parse", "HEAD").stdout.strip()
        head = git(w, "rev-parse", "origin/" + pr["headRefName"]).stdout.strip()
        if git(w, "push", "-q", "origin", st["base"]).returncode != 0: sys.exit(1)
        git(w, "push", "-q", "origin", "--delete", pr["headRefName"])
        pr.update(state="MERGED", mergeCommit=mc, headRefOid=head); save(st)
    finally:
        shutil.rmtree(w, ignore_errors=True)
    sys.exit(0)
print("stub: unknown " + " ".join(a), file=sys.stderr); sys.exit(9)
'''


class LedgerFixture(unittest.TestCase):
    """A bare origin on `development`, a ledger with two parked rows, and a primary clone."""

    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="gh534b."))
        self.addCleanup(shutil.rmtree, self.tmp, True)
        scan_clones._merged_pr_cache.clear()
        self.origin = self.tmp / "origin.git"
        subprocess.run(["git", "init", "-q", "--bare", "-b", "development", str(self.origin)], check=True)
        self.seed = self.clone("seed")
        (self.seed / "utils" / "py").mkdir(parents=True)
        shutil.copy(APP_SRC, self.seed / "utils" / "py" / "releases_app.py")
        shutil.copy(RESOLVER_SRC, self.seed / "utils" / "releases-merge-resolve.sh")
        shutil.copy(REPO / ".gitattributes", self.seed / ".gitattributes")
        (self.seed / "README.md").write_text("fixture\n")
        (self.seed / ".gitignore").write_text(".tick/\n")  # as the real repo: the Phase C record is untracked state
        _app(self.seed, "init", "--slug", "fx")
        park(self.seed, 100, "first")
        park(self.seed, 101, "second", rated="50/50/50/50")
        commit_all(self.seed, "base ledger")
        _git(self.seed, "push", "-q", "-u", "origin", "development")
        self.primary = self.clone("primary")
        self.probe = self.clone("probe")
        self.state = self.tmp / "gh-state.json"
        self.gh = self.tmp / "gh"
        self.gh.write_text(GH_STUB)
        self.gh.chmod(0o755)
        self.st = {"origin": str(self.origin), "base": "development", "probe": str(self.probe), "prs": {}, "calls": []}
        self.save()
        env = mock.patch.dict(os.environ, {GH_BIN_ENV: str(self.gh), "GH_STATE": str(self.state), "RELEASES_GH_BIN": str(self.gh)})
        env.start()
        self.addCleanup(env.stop)

    def save(self):
        self.state.write_text(json.dumps(self.st, indent=1))

    def load(self):
        self.st = json.loads(self.state.read_text())
        return self.st
   870	    """R4 regression proof (GH-623 final-QA finding 2): SKILL.md's Drive loop section, its Done
   871	    rule (with all three explicit-mode exceptions), and the permission-classifier retry-once
   872	    rule are load-bearing contracts, not prose. The controls mutate the text and watch the
   873	    checker go red, so these cannot pass on unrelated wording."""
   874	
   875	    @classmethod
   876	    def setUpClass(cls):
   877	        cls.text = SKILL_MD.read_text()
   878	
   879	    def drive_loop_section(self, text):
   880	        m = re.search(r"## Drive loop[^\n]*\n(.*?)(?=\n## )", text, re.S)
   881	        return m.group(0) if m else ""
   882	
   883	    def assert_contract(self, text):
   884	        section = self.drive_loop_section(text)
   885	        self.assertTrue(section, "the ## Drive loop section is missing")
   886	        for phrase in (
   887	            "--resume --execute",                                  # the continuation command
   888	            "do not report Done unless Phase 5 ran",               # the Done rule
   889	            "`--teardown-only`", "`--scan-only`", "`--prs-only`",  # the three explicit-mode exceptions
   890	            "exit 0 or a stop",                                    # the loop terminates on facts
   891	            "retry the identical command once",                    # classifier-block rule (S2)
   892	            "permission",
   893	        ):
   894	            self.assertIn(phrase, section, f"Drive loop lost a load-bearing contract: {phrase}")
   895	
   896	    def test_drive_loop_contracts_present(self):
   897	        self.assert_contract(self.text)
   898	
   899	    def _section_with(self, replacement, pattern):
   900	        mutated = re.sub(pattern, replacement, self.text, flags=re.S)
   901	        self.assertNotEqual(mutated, self.text, "control pattern no longer matches SKILL.md — repoint it")
   902	        return mutated
   903	
   904	    def test_control_deleting_the_done_rule_is_caught(self):
   905	        mutated = self._section_with("DONE-RULE-REMOVED", r"\*\*Done rule:\*\*.*?(?=\n\n)")
   906	        with self.assertRaises(AssertionError):
   907	            self.assert_contract(mutated)
   908	
   909	    def test_control_deleting_the_classifier_rule_is_caught(self):
   910	        mutated = self._section_with("RETRY-RULE-REMOVED", r"\*\*Permission-classifier blocks:\*\*.*?(?=\n\n)")
   911	        with self.assertRaises(AssertionError):
   912	            self.assert_contract(mutated)
   913	
   914	    def test_control_deleting_the_whole_section_is_caught(self):
   915	        mutated = re.sub(r"## Drive loop.*?(?=\n## Caller decision ladder)", "GONE\n", self.text, flags=re.S)
   916	        self.assertNotEqual(mutated, self.text)
   917	        with self.assertRaises(AssertionError):
   918	            self.assert_contract(mutated)
   919	
   920	
   921	class TestParityGuard(unittest.TestCase):
   922	    @classmethod
   923	    def setUpClass(cls):
   924	        cls.skill = SKILL_MD.read_text()
   925	        cls.help = subprocess.run([sys.executable, str(MC_SRC), "--help"], capture_output=True, text=True).stdout
   926	
   927	    def test_skill_md_matches_code_and_tests(self):
   928	        self.assertEqual(parity_failures(self.skill, self.help, run_tests=True), [])
   929	
   930	    def test_recon_owner_is_pinned_to_caller(self):
   931	        self.assertEqual(REQUIRED_CAPABILITIES["code-conflict-recon"], "caller")
   932	        self.assertEqual(REQUIRED_CAPABILITIES["code-conflict-resolution"], "caller")
   933	
   934	    def _fails(self, skill=None, help_=None, sources=None):
   935	        return parity_failures(skill or self.skill, help_ or self.help, sources)
   936	
   937	    def test_control_deleted_row_is_named(self):
   938	        for cap in REQUIRED_CAPABILITIES:
   939	            mutated = "\n".join(l for l in self.skill.splitlines() if not l.startswith(f"| {cap} |"))
   940	            self.assertIn(f"row missing: {cap}", self._fails(skill=mutated), cap)
   941	
   942	    def test_control_owner_flip_is_named(self):
   943	        mutated = self.skill.replace("| code-conflict-recon | 5 | caller |", "| code-conflict-recon | 5 | script |")
   944	        self.assertTrue(any(f.startswith("owner drift: code-conflict-recon") for f in self._fails(skill=mutated)))
   945	
   946	    def test_control_renamed_test_is_named(self):
   947	        mutated = self.skill.replace("TestE6Gate.test_gate_red_prevents_the_merge", "TestE6Gate.test_gone")
   948	        self.assertIn("test missing: landing-refetch-and-gate names TestE6Gate.test_gone", self._fails(skill=mutated))
   949	
   950	    def test_control_documented_option_absent_from_argparse_is_named(self):
   951	        mutated = self.skill.replace("`--resume`.", "`--resume`, `--bogus-flag`.")
   952	        self.assertNotEqual(mutated, self.skill, "the options line moved — repoint this control")
   953	        self.assertIn("documented option not in argparse: --bogus-flag", self._fails(skill=mutated))
   954	
   955	    def test_control_call_replaced_by_comment_is_named(self):
   956	        srcs = {k: v[0].read_text() for k, v in AST_CALLS.items()}
   957	        d = srcs["D"].replace('res["tick_claims"] = inspect_tick_claims(path)', 'res["tick_claims"] = {"has_claims": False, "verified": True}  # inspect_tick_claims(path)')
   958	        self.assertNotEqual(d, srcs["D"])
   959	        self.assertIn("AST: inspect_checkout() does not call inspect_tick_claims() (D)", self._fails(sources=dict(srcs, D=d)))
   960	        b1 = srcs["B1"].replace("b1 = resolve_ledger_conflict(clone, execute=not dry_run)", "b1 = {'handoff': True, 'reason': 'x', 'conflict_set': [], 'log': []}  # resolve_ledger_conflict")
   961	        self.assertNotEqual(b1, srcs["B1"])
   962	        self.assertIn("AST: land_prs() does not call resolve_ledger_conflict() (B1)", self._fails(sources=dict(srcs, B1=b1)))
   963	        c = srcs["C"].replace("idx, why = attempt_record.reserve(", "idx, why = (0, 'nope')  # attempt_record.reserve(").replace(
   964	            "                                                          clone_path=str(clone), create=fresh)", "                        # clone_path=str(clone), create=fresh)")
   965	        self.assertNotEqual(c, srcs["C"])
   966	        self.assertIn("AST: land_prs() does not call reserve() (C)", self._fails(sources=dict(srcs, C=c)))
   967	
   968	
   969	if __name__ == "__main__":
   970	    unittest.main(verbosity=2)
skills/2-daily/merge-cleanup/scripts/attempt_record.py:4:One record per (origin, PR) at ONE pinned coordinator: `<primary>/.tick/merge-cleanup/<owner>-<repo>/pr-<N>.json`.
skills/2-daily/merge-cleanup/scripts/attempt_record.py:51:    return Path(primary).resolve() / ".tick" / "merge-cleanup" / repo_slug(origin) / f"pr-{pr}.json"
test/gh534_phase_c_tests.py:21:sys.path.insert(0, str(REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts"))
test/gh534_phase_c_tests.py:22:sys.path.insert(0, str(REPO / "utils" / "py"))
test/gh534_phase_c_tests.py:23:sys.path.insert(0, str(REPO / "test"))
test/gh534_phase_c_tests.py:36:CLI = REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts" / "attempt_record.py"
test/gh534_phase_c_tests.py:117:        self.assertEqual(self.record, self.primary.resolve() / ".tick" / "merge-cleanup" / "HiQS-Labs-XYZ-forge" / "pr-538.json")
test/gh534_phase_c_tests.py:159:        self.assertFalse((self.clone1 / ".tick").exists())
test/gh534_phase_c_tests.py:160:        self.assertFalse((self.clone2 / ".tick").exists())
test/gh534_phase_c_tests.py:204:        from rtl import driver_lock_path
test/gh534_phase_c_tests.py:232:        self.assertFalse((self.clone1 / ".tick").exists(), "a worker derived a record root from its CWD")
test/gh534_phase_c_tests.py:334:        self.assertFalse((self.tmp / "w-2" / ".tick" / "merge-cleanup").exists())
test/gh534_phase_c_tests.py:406:            self.assertFalse((d / ".tick" / "merge-cleanup").exists(), f"a record root was minted under {d}")
test/gh534_phase_c_tests.py:523:SKILL_MD = REPO / "skills" / "2-daily" / "merge-cleanup" / "SKILL.md"
test/gh534_phase_c_tests.py:524:MC_SRC = REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts" / "merge_cleanup.py"
test/gh534_phase_c_tests.py:525:SC_SRC = REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts" / "scan_clones.py"
test/gh534_phase_c_tests.py:528:    "session-evidence-driver-lock": "script", "session-evidence-tick-claims": "script",
test/gh534_phase_c_tests.py:542:    "D": (SC_SRC, "inspect_checkout", "inspect_tick_claims"),
test/gh534_phase_c_tests.py:859:        r = subprocess.run([sys.executable, str(REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts" / "toposort_prs.py"),
test/gh534_phase_c_tests.py:957:        d = srcs["D"].replace('res["tick_claims"] = inspect_tick_claims(path)', 'res["tick_claims"] = {"has_claims": False, "verified": True}  # inspect_tick_claims(path)')
test/gh534_phase_c_tests.py:959:        self.assertIn("AST: inspect_checkout() does not call inspect_tick_claims() (D)", self._fails(sources=dict(srcs, D=d)))
skills/2-daily/merge-cleanup/scripts/scan_clones.py:33:# stub `gh` / `lsof` / `tick` without patching module internals (the same shape as
skills/2-daily/merge-cleanup/scripts/scan_clones.py:170:    """The checkout whose `.tick/` governs `repo_path`.
skills/2-daily/merge-cleanup/scripts/scan_clones.py:172:    A linked worktree's `.tick/` is its parent clone's: the event log lives beside the git
skills/2-daily/merge-cleanup/scripts/scan_clones.py:185:def _tick_binary() -> Optional[str]:
skills/2-daily/merge-cleanup/scripts/scan_clones.py:186:    """The harness's own `bin/tick`, then PATH. Never the audited checkout's copy."""
skills/2-daily/merge-cleanup/scripts/scan_clones.py:191:        own = parent / "bin" / "tick"
skills/2-daily/merge-cleanup/scripts/scan_clones.py:194:    return shutil.which("tick")
skills/2-daily/merge-cleanup/scripts/scan_clones.py:197:def inspect_tick_claims(repo_path: Path) -> Dict[str, Any]:
skills/2-daily/merge-cleanup/scripts/scan_clones.py:198:    """GH-534 A.4: active-session evidence from the tick EVENT LOG, never from STATE.md.
skills/2-daily/merge-cleanup/scripts/scan_clones.py:200:    `.tick/STATE.md` is a derived snapshot written by `tick project`; a readable-but-stale or
skills/2-daily/merge-cleanup/scripts/scan_clones.py:202:    "none" spelling anyway). The authoritative fold is exposed read-only by `tick claims --json`,
skills/2-daily/merge-cleanup/scripts/scan_clones.py:203:    run with TICK_REPO_ROOT pinned to the coordination root so the verb can never resolve a
skills/2-daily/merge-cleanup/scripts/scan_clones.py:212:                "details": "cannot resolve the git common dir to locate .tick/"}
skills/2-daily/merge-cleanup/scripts/scan_clones.py:213:    tick_dir = coord / ".tick"
skills/2-daily/merge-cleanup/scripts/scan_clones.py:214:    if not tick_dir.exists():
skills/2-daily/merge-cleanup/scripts/scan_clones.py:215:        # No coordination root at all: nothing can be claimed here. (A `.tick/` that exists
skills/2-daily/merge-cleanup/scripts/scan_clones.py:217:        return {"has_claims": False, "verified": True, "details": "no .tick/ coordination root", "claims": []}
skills/2-daily/merge-cleanup/scripts/scan_clones.py:220:    locks_dir = tick_dir / "locks"
skills/2-daily/merge-cleanup/scripts/scan_clones.py:225:            return {"has_claims": False, "verified": False, "details": f".tick/locks unreadable: {exc}"}
skills/2-daily/merge-cleanup/scripts/scan_clones.py:228:                    "details": f"{len(locks)} entr{'y' if len(locks) == 1 else 'ies'} in .tick/locks: {', '.join(locks)}",
skills/2-daily/merge-cleanup/scripts/scan_clones.py:231:    tick = _tick_binary()
skills/2-daily/merge-cleanup/scripts/scan_clones.py:232:    if not tick:
skills/2-daily/merge-cleanup/scripts/scan_clones.py:233:        return {"has_claims": False, "verified": False, "details": "tick binary not found"}
skills/2-daily/merge-cleanup/scripts/scan_clones.py:235:    env["TICK_REPO_ROOT"] = str(coord)
skills/2-daily/merge-cleanup/scripts/scan_clones.py:237:        proc = subprocess.run([tick, "claims", "--json"], cwd=tempfile.gettempdir(), env=env,
skills/2-daily/merge-cleanup/scripts/scan_clones.py:240:        return {"has_claims": False, "verified": False, "details": f"tick claims did not run: {exc}"}
skills/2-daily/merge-cleanup/scripts/scan_clones.py:243:                "details": f"tick claims exit {proc.returncode}: {proc.stderr.strip() or 'no diagnostic'}"}
skills/2-daily/merge-cleanup/scripts/scan_clones.py:251:        return {"has_claims": False, "verified": False, "details": f"tick claims output malformed: {exc}"}
skills/2-daily/merge-cleanup/scripts/scan_clones.py:705:    tick = inspect_data.get("tick_claims", {})
skills/2-daily/merge-cleanup/scripts/scan_clones.py:706:    if tick.get("has_claims"):
skills/2-daily/merge-cleanup/scripts/scan_clones.py:707:        details = tick.get("details", "")
skills/2-daily/merge-cleanup/scripts/scan_clones.py:782:    GH-534: every safety query FAILS CLOSED. A git/tick/lsof command that exits non-zero or
skills/2-daily/merge-cleanup/scripts/scan_clones.py:805:        "tick_claims": {"has_claims": False, "verified": False},
skills/2-daily/merge-cleanup/scripts/scan_clones.py:934:    # Session evidence (A.4): the tick event fold, then live file handles. Both binding.
skills/2-daily/merge-cleanup/scripts/scan_clones.py:935:    res["tick_claims"] = inspect_tick_claims(path)
skills/2-daily/merge-cleanup/scripts/scan_clones.py:936:    if res["tick_claims"].get("has_claims"):
skills/2-daily/merge-cleanup/scripts/scan_clones.py:938:        res["disposition_reason"] = f"Active task claim in .tick: {res['tick_claims'].get('details')}"
skills/2-daily/merge-cleanup/scripts/scan_clones.py:940:    if not res["tick_claims"].get("verified"):
skills/2-daily/merge-cleanup/scripts/scan_clones.py:942:        res["disposition_reason"] = f"Cannot verify tick claims: {res['tick_claims'].get('details')}"
test/gh534_phase_b_tests.py:24:sys.path.insert(0, str(REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts"))
test/gh534_phase_b_tests.py:32:APP_SRC = REPO / "utils" / "py" / "releases_app.py"
test/gh534_phase_b_tests.py:33:RESOLVER_SRC = REPO / "utils" / "releases-merge-resolve.sh"
test/gh534_phase_b_tests.py:165:        shutil.copy(REPO / ".gitattributes", self.seed / ".gitattributes")
test/gh534_phase_b_tests.py:167:        (self.seed / ".gitignore").write_text(".tick/\n")  # as the real repo: the Phase C record is untracked state
test/gh534_phase_a_tests.py:5:git repo with a real local origin; `tick` is the real bin/tick; `lsof` is the real binary except
test/gh534_phase_a_tests.py:8:Sections: A.1 roots · A.2 provenance · A.3 dirt · A.4 session evidence (tick + lsof) · A.5 fresh
test/gh534_phase_a_tests.py:26:sys.path.insert(0, str(REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts"))
test/gh534_phase_a_tests.py:32:    classify_local_refs, inspect_checkout, inspect_open_handles, inspect_tick_claims,
test/gh534_phase_a_tests.py:36:TICK = REPO / "bin" / "tick"
test/gh534_phase_a_tests.py:125:        doc = (REPO / "WORKTREE-SAFETY.md").read_text()
test/gh534_phase_a_tests.py:275:        src = (REPO / "skills/2-daily/merge-cleanup/scripts/scan_clones.py").read_text()
test/gh534_phase_a_tests.py:303:def tick(root, *args):
test/gh534_phase_a_tests.py:304:    env = dict(os.environ, TICK_REPO_ROOT=str(root))
test/gh534_phase_a_tests.py:312:        self.assertEqual(tick(self.clone, "init").returncode, 0)
test/gh534_phase_a_tests.py:313:        _git(self.clone, "add", "-A")  # .tick/ is untracked otherwise -> dirty would mask the case
test/gh534_phase_a_tests.py:317:        (self.clone / ".gitignore").write_text(".tick/\n")
test/gh534_phase_a_tests.py:319:        _git(self.clone, "commit", "-q", "-m", "ignore tick")
test/gh534_phase_a_tests.py:323:        self.assertEqual(tick(self.clone, "log", "task.created", task, "--agent", agent).returncode, 0)
test/gh534_phase_a_tests.py:324:        r = tick(self.clone, "claim", task, "--agent", agent, "--paths", "README.md")
test/gh534_phase_a_tests.py:340:        state = self.clone / ".tick" / "STATE.md"
test/gh534_phase_a_tests.py:347:        ev = self.clone / ".tick" / "events"
test/gh534_phase_a_tests.py:352:        self.assertIn("tick claims", info["disposition_reason"])
test/gh534_phase_a_tests.py:355:        (self.clone / ".tick" / "locks" / "relay-driver").mkdir(parents=True)
test/gh534_phase_a_tests.py:369:    def test_vii_tick_absent_or_failing_preserves(self):
test/gh534_phase_a_tests.py:370:        with stub_env(**{TICK_BIN_ENV: str(self.tmp / "no-such-tick")}):
test/gh534_phase_a_tests.py:373:        bad = self.tmp / "tick-bad"
test/gh534_phase_a_tests.py:382:        refused — the verb must not trust an absent log. A bare telemetry-only .tick/ takes the
test/gh534_phase_a_tests.py:384:        shutil.rmtree(self.clone / ".tick" / "events")
test/gh534_phase_a_tests.py:385:        (self.clone / ".tick" / "STATE.md").write_text("(stale derived snapshot)\n")
test/gh534_phase_a_tests.py:386:        r = tick(self.clone, "claims", "--json")
test/gh534_phase_a_tests.py:393:    def test_xiv_telemetry_only_tick_is_uninitialized_eligible(self):
test/gh534_phase_a_tests.py:394:        """GH-561: a .tick/ holding ONLY gate-run artifacts (telemetry/, orphan-backups/) with no
test/gh534_phase_a_tests.py:396:        shutil.rmtree(self.clone / ".tick")
test/gh534_phase_a_tests.py:397:        (self.clone / ".tick" / "telemetry").mkdir(parents=True)
test/gh534_phase_a_tests.py:398:        (self.clone / ".tick" / "orphan-backups").mkdir()
test/gh534_phase_a_tests.py:399:        r = tick(self.clone, "claims", "--json")
test/gh534_phase_a_tests.py:405:    def test_tick_claims_writes_nothing(self):
test/gh534_phase_a_tests.py:407:        state = self.clone / ".tick" / "STATE.md"
test/gh534_phase_a_tests.py:408:        rejected = self.clone / ".tick" / "rejected.jsonl"
test/gh534_phase_a_tests.py:412:        r = tick(self.clone, "claims", "--json")
test/gh534_phase_a_tests.py:415:        self.assertFalse(state.exists(), "tick claims wrote STATE.md")
test/gh534_phase_a_tests.py:416:        self.assertFalse(rejected.exists(), "tick claims wrote rejected.jsonl")
test/gh534_phase_a_tests.py:418:    def test_ast_inspect_checkout_calls_inspect_tick_claims(self):
test/gh534_phase_a_tests.py:420:        src = (REPO / "skills/2-daily/merge-cleanup/scripts/scan_clones.py").read_text()
test/gh534_phase_a_tests.py:422:        calls = [n for n in ast.walk(fn) if isinstance(n, ast.Call) and getattr(n.func, "id", "") == "inspect_tick_claims"]
test/gh534_phase_a_tests.py:423:        self.assertTrue(calls, "inspect_checkout never calls inspect_tick_claims")
test/gh534_phase_a_tests.py:603:        (self.task / ".gitignore").write_text(".tick/\n")
test/gh534_phase_a_tests.py:609:            self.assertEqual(tick(self.task, "init").returncode, 0)
test/gh534_phase_a_tests.py:610:            tick(self.task, "log", "task.created", "T-late", "--agent", "agy")
test/gh534_phase_a_tests.py:611:            self.assertEqual(tick(self.task, "claim", "T-late", "--agent", "agy", "--paths", "x").returncode, 0)
test/gh534_phase_a_tests.py:639:        # A `tick claims` failure only matters where a coordination root exists: give it one.
test/gh534_phase_a_tests.py:640:        (self.task / ".gitignore").write_text(".tick/\n")
test/gh534_phase_a_tests.py:644:        self.assertEqual(tick(self.task, "init").returncode, 0)
test/gh534_phase_a_tests.py:645:        self.assertEqual(self._run()[1], [("task-clone", "SAFE_REMOVE_CLONE", True)], "control: eligible with tick")
test/gh534_phase_a_tests.py:646:        with mock.patch.dict(os.environ, {TICK_BIN_ENV: str(self.tmp / "no-tick")}):
test/gh534_phase_a_tests.py:647:            self.assertEqual(self._run()[1], [], "tick claims")
def select_qualification_gate(clone, metas, env):
    """GH-831 D5: classify the pending landings' union diff at the tested commit.

    Tier 1 runs the Small list; anything else, or any doubt, runs the full registry.
    Returns (gate, expected Small list or None, reason).
    """
    paths = []
    try:
        for meta in metas:
            landing = meta["mergeCommit"]["oid"]
            diff = subprocess.run(["git", "diff", "--no-renames", "--name-only", f"{landing}^", landing],
                                  cwd=clone, env=env, capture_output=True, text=True, check=False, timeout=120)
            if diff.returncode:
                return QUALIFICATION_GATE, None, f"no diff for {landing_label(meta)}"
            paths += diff.stdout.splitlines()
        routed = subprocess.run(["bash", "utils/ci-route.sh", "push"], cwd=clone, env=env,
                                input="".join(p + "\n" for p in paths), capture_output=True,
                                text=True, check=False, timeout=120)
        tier = re.findall(r"^tier=(\S*)$", routed.stdout, re.M)
        if routed.returncode or len(tier) != 1:
            return QUALIFICATION_GATE, None, "the classifier could not run"
        if tier[0] != "1":
            return QUALIFICATION_GATE, None, f"tier {tier[0]}"
        return SMALL_GATE, small_suites_at(clone, "HEAD"), "tier 1"
    except (OSError, subprocess.SubprocessError, ValueError, KeyError, TypeError) as exc:
        return QUALIFICATION_GATE, None, f"classification failed: {exc}"


     1	#!/usr/bin/env bash
     2	# gh645-merge-cleanup-xyz-tools.sh — /merge-cleanup must find PRS tools that a consumer repo vendors
     3	# under gitignored `.xyz/utils/py/` (GH-645). A landing clone is a plain `git clone`, so it never
     4	# carries `.xyz/`; the gate went RED with "No such file", and the reconciler was then passed
     5	# `--force-local-reconcile`, which is reserved for explicit operator recovery. Pins resolver order,
     6	# the primary-checkout fallback, and the automatic fallback's flag-free contract.
     7	set -euo pipefail
     8	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
     9	export XYZ_TEST_SCRIPTS="$HERE/../skills/2-daily/merge-cleanup/scripts"
    10	
    11	exec python3 - <<'PY'
    12	import os, stat, sys, tempfile, unittest, subprocess
    13	import unittest.mock as mock
    14	from pathlib import Path
    15	
    16	sys.path.insert(0, os.environ["XYZ_TEST_SCRIPTS"])
    17	import ledger_merge  # noqa: E402
    18	import merge_cleanup  # noqa: E402
    19	from ledger_merge import tool_path  # noqa: E402
    20	
    21	
    22	def _touch(p: Path) -> Path:
    23	    p.parent.mkdir(parents=True, exist_ok=True)
    24	    p.write_text("# stub\n")
    25	    return p
    26	
    27	
    28	class ToolPathResolution(unittest.TestCase):
    29	    def setUp(self):
    30	        self.tmp = tempfile.TemporaryDirectory()
    31	        self.clone = Path(self.tmp.name) / "clone"
    32	        self.primary = Path(self.tmp.name) / "primary"
    33	        self.clone.mkdir(); self.primary.mkdir()
    34	        self._saved = ledger_merge.TOOL_FALLBACK_ROOT
    35	        ledger_merge.TOOL_FALLBACK_ROOT = None
    36	
    37	    def tearDown(self):
    38	        ledger_merge.TOOL_FALLBACK_ROOT = self._saved
    39	        self.tmp.cleanup()
    40	
    41	    def test_canonical_utils_py_wins_over_vendored(self):
    42	        canon = _touch(self.clone / "utils" / "py" / "releases_app.py")
    43	        _touch(self.clone / ".xyz" / "utils" / "py" / "releases_app.py")
    44	        self.assertEqual(tool_path(self.clone, "releases_app.py"), canon)
    45	
    46	    def test_vendored_xyz_in_clone_is_found(self):
    47	        vend = _touch(self.clone / ".xyz" / "utils" / "py" / "releases_app.py")
    48	        self.assertEqual(tool_path(self.clone, "releases_app.py"), vend)
    49	
    50	    def test_gitignored_xyz_falls_back_to_the_primary(self):
    51	        prim = _touch(self.primary / ".xyz" / "utils" / "py" / "releases_app.py")
    52	        ledger_merge.TOOL_FALLBACK_ROOT = self.primary
    53	        self.assertEqual(tool_path(self.clone, "releases_app.py"), prim)
    54	
    55	    def test_vendored_shell_resolver_runs_against_the_landing_clone(self):
    56	        resolver = self.primary / ".xyz" / "utils" / "releases-merge-resolve.sh"
    57	        _touch(resolver)
    58	        resolver.write_text('test "$1" = "--root" && test "$(cd "$2" && pwd -P)" = "$(pwd -P)"\n')
    59	        _touch(self.primary / ".xyz" / "utils" / "py" / "releases_app.py")
    60	        ledger_merge.TOOL_FALLBACK_ROOT = self.primary
    61	        commands = []
    62	
    63	        def run(cmd, cwd):
    64	            commands.append(cmd)
    65	            if cmd[0] == "bash":
    66	                return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    67	            return subprocess.CompletedProcess(cmd, 0, "", "")
    68	
    69	        sem = {"ok": True, "classification": None}
    70	        with mock.patch.object(ledger_merge, "extract_conflict_set", return_value=(True, {"LEADERBOARD.md"}, "")), \
    71	             mock.patch.object(ledger_merge, "ledger_semantic_check", return_value=sem), \
    72	             mock.patch.object(ledger_merge, "run_git", return_value=subprocess.CompletedProcess([], 0, "", "")), \
    73	             mock.patch.object(ledger_merge, "_run", side_effect=run):
    74	            result = ledger_merge.resolve_ledger_conflict(self.clone, execute=True)
    75	        self.assertTrue(result["resolved"], result)
    76	        self.assertIn(["bash", str(resolver), "--root", str(self.clone)], commands)
    77	
    78	    def test_missing_everywhere_reports_the_canonical_path(self):
    79	        ledger_merge.TOOL_FALLBACK_ROOT = self.primary
    80	        self.assertEqual(tool_path(self.clone, "wave_reconcile.py"),
    81	                         self.clone / "utils" / "py" / "wave_reconcile.py")
    82	
    83	    def test_app_command_uses_the_resolver_with_root(self):
    84	        prim = _touch(self.primary / ".xyz" / "utils" / "py" / "releases_app.py")
    85	        ledger_merge.TOOL_FALLBACK_ROOT = self.primary
     1	#!/usr/bin/env bash
     2	# GH-674 — hosted reconciliation lookup sees PR-keyed runs; automatic fallback never forces.
     3	set -euo pipefail
     4	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
     5	export XYZ_TEST_SCRIPTS="$HERE/../skills/2-daily/merge-cleanup/scripts"
     6	
     7	exec python3 - <<'PY'
     8	import json
     9	import os
    10	import subprocess
    11	import sys
    12	import tempfile
    13	import unittest
    14	import unittest.mock as mock
    15	from pathlib import Path
    16	
    17	sys.path.insert(0, os.environ["XYZ_TEST_SCRIPTS"])
    18	import merge_cleanup  # noqa: E402
    19	
    20	
    21	class HostedLookup(unittest.TestCase):
    22	    def test_unfiltered_lookup_adopts_pr_keyed_active_run(self):
    23	        calls = []
    24	        responses = [
    25	            [{"databaseId": 67401, "status": "in_progress", "conclusion": "",
    26	              "headSha": "p" * 40, "event": "push"}],
    27	            [{"databaseId": 67401, "status": "completed", "conclusion": "success",
    28	              "headSha": "p" * 40, "event": "push"}],
    29	        ]
    30	
    31	        def fake_gh(args, cwd, timeout=60):
    32	            calls.append(args)
    33	            # Red control: the pre-fix filtered lookup misses this PR-keyed run.
    34	            payload = [] if "--branch" in args or "--commit" in args else responses.pop(0)
    35	            return subprocess.CompletedProcess(args, 0, json.dumps(payload), "")
    36	
    37	        legacy = fake_gh([
    38	            "run", "list", "--workflow", "wave-reconcile.yml",
    39	            "--branch", "development", "--commit", "m" * 40,
    40	        ], Path("."))
    41	        self.assertEqual(json.loads(legacy.stdout), [], "red control must miss the PR-keyed run")
    42	
    43	        env = {
    44	            merge_cleanup.HOSTED_GRACE_ENV: "60",
    45	            merge_cleanup.HOSTED_WAIT_ENV: "10",
    46	            merge_cleanup.HOSTED_POLL_ENV: "0",
    47	        }
    48	        with tempfile.TemporaryDirectory() as td, \
    49	                mock.patch.object(merge_cleanup, "_gh", side_effect=fake_gh), \
    50	                mock.patch.object(merge_cleanup.time, "sleep", return_value=None), \
    51	                mock.patch.dict(os.environ, env):
    52	            result = merge_cleanup.wait_for_hosted_reconcile(
    53	                "m" * 40, Path(td), "development", pr_head="p" * 40)
    54	
    55	        self.assertEqual(result, "success")
    56	        lookup_calls = calls[1:]
    57	        self.assertEqual(len(lookup_calls), 2)
    58	        self.assertTrue(all("--branch" not in call and "--commit" not in call for call in lookup_calls))
    59	        self.assertTrue(all("headSha" in call[call.index("--json") + 1] for call in lookup_calls))
    60	
    61	    def test_zero_grace_adopts_active_run_without_head_sha(self):
    62	        responses = [
    63	            [{"databaseId": 62901, "status": "in_progress", "conclusion": ""}],
    64	            [{"databaseId": 62901, "status": "completed", "conclusion": "success",
    65	              "headSha": "p" * 40}],
    66	        ]
    67	
    68	        def fake_gh(args, cwd, timeout=60):
    69	            return subprocess.CompletedProcess(args, 0, json.dumps(responses.pop(0)), "")
    70	
    71	        env = {
    72	            merge_cleanup.HOSTED_GRACE_ENV: "0",
    73	            merge_cleanup.HOSTED_WAIT_ENV: "10",
    74	            merge_cleanup.HOSTED_POLL_ENV: "0",
    75	        }

exec
/bin/zsh -lc "nl -ba test/gh534_phase_c_tests.py | sed -n '522,603p'; rg -n 'from |import ' utils/py/{releases_app,board_sync}.py utils/py/work_connectors/*.py; cat bin/tick | head -55; rg -n 'rtl|xyz_tools|utils|REPO /' skills/2-daily/merge-cleanup/scripts/{attempt_record,ledger_merge,scan_clones}.py test/gh534_phase_c_tests.py; tail -65 test/gh645-merge-cleanup-xyz-tools.sh; tail -60 test/gh674-merge-cleanup-hosted-lookup.sh; nl -ba test/gh549-work-events.sh | sed -n '150,178p'" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-68346-vx81h0en
 succeeded in 0ms:
   522	# --- Parity guard: SKILL.md's capability table vs the code and the tests ------------------------
   523	SKILL_MD = REPO / "skills" / "2-daily" / "merge-cleanup" / "SKILL.md"
   524	MC_SRC = REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts" / "merge_cleanup.py"
   525	SC_SRC = REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts" / "scan_clones.py"
   526	# The FIXED required set: deleting a row cannot pass because the others remain.
   527	REQUIRED_CAPABILITIES = {
   528	    "session-evidence-driver-lock": "script", "session-evidence-tick-claims": "script",
   529	    "session-evidence-open-handles": "script", "preservation-dirty-stash-unlanded": "script",
   530	    "preservation-fail-closed": "script", "landing-refetch-and-gate": "script",
   531	    "ledger-resolution-disjoint": "script", "ledger-handoff-and-record": "script",
   532	    "dependents-blocked": "script", "reconciliation-gating": "script",
   533	    "coordinator-pinned-to-primary": "script", "teardown-trash-only": "script",
   534	    "code-conflict-recon": "caller", "code-conflict-resolution": "caller",
   535	    "teardown-fresh-inspection": "script",
   536	    # GH-623 (final-QA finding 1): the new rows are REQUIRED too — a row that the guard does
   537	    # not demand can be deleted from SKILL.md with the parity test still green.
   538	    "soft-edge-nonblocking": "script", "network-retry-defer": "script",
   539	    "resume-skips-parked": "script",
   540	}
   541	AST_CALLS = {  # (module source, enclosing function, callee that must be invoked — a comment is not a call)
   542	    "D": (SC_SRC, "inspect_checkout", "inspect_tick_claims"),
   543	    "B1": (MC_SRC, "land_prs", "resolve_ledger_conflict"),
   544	    "C": (MC_SRC, "land_prs", "reserve"),
   545	}
   546	
   547	
   548	def _calls_in(src: str, func: str):
   549	    import ast
   550	    tree = ast.parse(src)
   551	    for node in ast.walk(tree):
   552	        if isinstance(node, ast.FunctionDef) and node.name == func:
   553	            names = set()
   554	            for n in ast.walk(node):
   555	                if isinstance(n, ast.Call):
   556	                    f = n.func
   557	                    names.add(f.attr if isinstance(f, ast.Attribute) else getattr(f, "id", ""))
   558	            return names
   559	    return None
   560	
   561	
   562	def parity_failures(skill_text: str, cli_help: str, sources=None, run_tests: bool = False):
   563	    """Every way SKILL.md can drift from the code, named. Empty list = parity."""
   564	    import re
   565	    sources = sources or {k: v[0].read_text() for k, v in AST_CALLS.items()}
   566	    fails = []
   567	    m = re.search(r"## Capability table.*?(?=\n## )", skill_text, re.S)
   568	    if not m:
   569	        return ["capability table section missing"]
   570	    rows = {}
   571	    for line in m.group(0).splitlines():
   572	        cells = [c.strip() for c in line.strip().strip("|").split("|")]
   573	        if len(cells) == 4 and cells[0] not in ("Capability", "---"):
   574	            rows[cells[0]] = (cells[2], cells[3])
   575	    for cap, owner in REQUIRED_CAPABILITIES.items():
   576	        if cap not in rows:
   577	            fails.append(f"row missing: {cap}")
   578	            continue
   579	        got_owner, test = rows[cap]
   580	        if got_owner != owner:
   581	            fails.append(f"owner drift: {cap} is {got_owner!r}, required {owner!r}")
   582	        if owner == "script":
   583	            cls, _, meth = test.partition(".")
   584	            klass = globals().get(cls)
   585	            if klass is None or not callable(getattr(klass, meth, None)):
   586	                fails.append(f"test missing: {cap} names {test}")
   587	            elif run_tests:
   588	                r = unittest.TextTestRunner(stream=open(os.devnull, "w")).run(klass(meth))
   589	                if not r.wasSuccessful():
   590	                    fails.append(f"test failing: {cap} → {test}")
   591	    opts = re.search(r"CLI options this document describes[^\n]*?:\s*(.*)", m.group(0))
   592	    for opt in re.findall(r"`(--[a-z-]+)`", opts.group(1) if opts else ""):
   593	        if opt not in cli_help:
   594	            fails.append(f"documented option not in argparse: {opt}")
   595	    for key, (_, func, callee) in AST_CALLS.items():
   596	        calls = _calls_in(sources[key], func)
   597	        if calls is None or callee not in calls:
   598	            fails.append(f"AST: {func}() does not call {callee}() ({key})")
   599	    return fails
   600	
   601	
   602	# --- GH-623: soft edges, network retry + defer, bounded calls, resume ---------------------------
   603	
utils/py/work_connectors/github_board.py:52:import json
utils/py/work_connectors/github_board.py:53:import os
utils/py/work_connectors/github_board.py:54:import sys
utils/py/work_connectors/github_board.py:58:import board_sync
utils/py/work_connectors/github_board.py:128:        raise RuntimeError("saved github_board_selection_policy is invalid: %s" % exc) from exc
utils/py/work_connectors/github_labels.py:7:import json
utils/py/work_connectors/github_labels.py:8:import os
utils/py/work_connectors/github_labels.py:9:import re
utils/py/work_connectors/github_labels.py:10:import subprocess
utils/py/work_connectors/github_labels.py:11:import sys
utils/py/work_connectors/github_labels.py:12:import time
utils/py/work_connectors/github_labels.py:14:from releases_app import (_is_lifecycle_event, _live_roadmap_event, _START_EVENTS,
utils/py/work_connectors/__init__.py:16:   the lock across network time. perform_write calls dispatch_for_txn() from one common
utils/py/work_connectors/__init__.py:23:import errno
utils/py/work_connectors/__init__.py:24:import fcntl
utils/py/work_connectors/__init__.py:25:import json
utils/py/work_connectors/__init__.py:26:import os
utils/py/work_connectors/__init__.py:27:import sqlite3
utils/py/work_connectors/__init__.py:28:import subprocess
utils/py/work_connectors/__init__.py:29:import sys
utils/py/work_connectors/__init__.py:30:import time
utils/py/work_connectors/__init__.py:31:from typing import Any, Dict, List, Optional, Tuple
utils/py/work_connectors/__init__.py:35:    from device_config import resolve_device_block
utils/py/work_connectors/__init__.py:39:    from device_config import resolve_device_block
utils/py/work_connectors/__init__.py:62:# from config: adding a connector is a pull request, not a runtime install (issue non-goal).
utils/py/work_connectors/__init__.py:95:    from device_config import load_device_config_diagnostic
utils/py/work_connectors/__init__.py:144:    from releases_app import (_has_column, _origin_repo_identity, resolve_roadmap_identity,
utils/py/work_connectors/__init__.py:183:    The overlay is read from the ENVIRONMENT and from nowhere else. Device config cannot
utils/py/work_connectors/__init__.py:202:                          "connector(s) %s from the environment" % ", ".join(names))
utils/py/work_connectors/__init__.py:221:    # import fails and every ordinary configured run reports "No module named work_connectors" —
utils/py/work_connectors/__init__.py:300:            results[name] = (None, "advanced_to=%d does not move the cursor forward from %d"
utils/py/work_connectors/__init__.py:446:    to replay. Deleting inside the same critical section makes "replay from zero" mean it.
utils/py/work_connectors/__init__.py:471:                # from the rows we actually handed it — never re-derived from the child.
utils/py/board_sync.py:15:- Empty input fails: a scan that extracts nothing from a populated fixture is a hard
utils/py/board_sync.py:30:import argparse
utils/py/board_sync.py:31:import datetime as dt
utils/py/board_sync.py:32:import errno
utils/py/board_sync.py:33:import hashlib
utils/py/board_sync.py:34:import json
utils/py/board_sync.py:35:import os
utils/py/board_sync.py:36:import re
utils/py/board_sync.py:37:import sqlite3
utils/py/board_sync.py:38:import subprocess
utils/py/board_sync.py:39:import sys
utils/py/board_sync.py:40:import tempfile
utils/py/board_sync.py:41:import time
utils/py/board_sync.py:42:from pathlib import Path
utils/py/board_sync.py:46:    from device_config import get_device_config_path, load_local_device_config, resolve_device_block
utils/py/board_sync.py:49:    from device_config import get_device_config_path, load_local_device_config, resolve_device_block
utils/py/board_sync.py:56:    from harness_paths import repo_root as _consumer_repo_root
utils/py/board_sync.py:536:        raise RuntimeError(f"gh api graphql failed ({gh_bin}): {exc}") from exc
utils/py/board_sync.py:544:        raise RuntimeError(f"gh api graphql returned non-JSON: {exc}") from exc
utils/py/board_sync.py:602:        _warn("cached board IDs were resolved from different settings — re-resolving")
utils/py/board_sync.py:763:        raise IndeterminateMutation("%s response indeterminate: %s" % (operation, exc)) from exc
utils/py/board_sync.py:768:            raise IndeterminateMutation("%s succeeded but result audit failed: %s" % (operation, exc)) from exc
utils/py/board_sync.py:1078:        raise RuntimeError("cannot read JSON %s: %s" % (path, exc)) from exc
utils/py/board_sync.py:1115:    from releases_app import load_work_evidence
utils/py/board_sync.py:1128:        plan["warnings"].append("external observations include stale/unmapped evidence; no board decision was inferred from it")
utils/py/board_sync.py:1169:    from work_connectors import _ConnectorLock
utils/py/board_sync.py:1193:        # Resolve every destination from GitHub, without the state cache, before the first write.
utils/py/board_sync.py:1298:        from work_connectors import _ConnectorLock
utils/py/releases_app.py:23:tracked, generated artifact that conflicted on every concurrent write, one staged output from every
utils/py/releases_app.py:57:import argparse
utils/py/releases_app.py:58:import datetime as _dt
utils/py/releases_app.py:59:import fcntl
utils/py/releases_app.py:60:import hashlib
utils/py/releases_app.py:61:import json
utils/py/releases_app.py:62:import os
utils/py/releases_app.py:63:import re
utils/py/releases_app.py:64:import shutil
utils/py/releases_app.py:65:import sqlite3
utils/py/releases_app.py:66:import subprocess
utils/py/releases_app.py:67:import sys
utils/py/releases_app.py:68:import time
utils/py/releases_app.py:69:import urllib.parse
utils/py/releases_app.py:70:import uuid
utils/py/releases_app.py:97:LEDGER_NAME = "RELEASES.md"          # legacy import source (PRD Phase 0)
utils/py/releases_app.py:128:# The legacy `GH_URL:` import field means a RELEASE pointer; it accepted issue URLs only before
utils/py/releases_app.py:289:> Read-only projection from `releases.db`. Edit the release through the Releases CLI; GitHub Project edits do not synchronize back.
utils/py/releases_app.py:501:    -- checkout paths from the utils/hq/ registry, which is already per-device.
utils/py/releases_app.py:594:  supplied_value TEXT,                 -- what import wrote (default, MIG- ref, normalization)
utils/py/releases_app.py:622:CREATE INDEX idx_gf_import ON grandfather_entries(import_run);
utils/py/releases_app.py:822:    # inferred from today's manifest, not witnessed at the kickoff it claims to describe.
utils/py/releases_app.py:921:      connectors finish. It is therefore excluded from dump_text entirely. Putting it in the
utils/py/releases_app.py:1244:        # NEVER dumped: it is derived at read time from the four axes, and storing a derived value
utils/py/releases_app.py:1288:        # connector_cursors is deliberately absent from this function entirely. It is written
utils/py/releases_app.py:1392:# Returning None means "no row from me". For `work-emit` that is deliberate and load-bearing: its
utils/py/releases_app.py:1396:# The registry is TOTAL. Every op reachable from a perform_write caller is either mapped here or
utils/py/releases_app.py:1405:    "ship":                    "release shipped; issue-level state comes from its manifest items",
utils/py/releases_app.py:1568:    # from the in-memory registry FIRST — a dict lookup — and only touch sqlite_master for the
utils/py/releases_app.py:1617:    cannot even be imported must not change the host verb's exit code — so the import itself
utils/py/releases_app.py:1624:        import work_connectors
utils/py/releases_app.py:1671:                   "an intent journal from an interrupted write exists (%s); run `releases check` "
utils/py/releases_app.py:1797:                   "an intent journal from an interrupted write exists (%s); run `releases check` "
utils/py/releases_app.py:1812:                   "ledger; they are reachable only from `releases init` or `check --rebuild`"
utils/py/releases_app.py:1895:    boundary (DB generation == journal's): the DB is truth; REGENERATE the dump from the
utils/py/releases_app.py:1957:# ── legacy RELEASES.md parsing (import + drift) ─────────────────────────────────────────────────
utils/py/releases_app.py:1962:# from the schema BY DESIGN, aegis proved them harmful), `Manifest:` prose, `RC evidence:`,
utils/py/releases_app.py:2045:               "MIG-XXXXXX placeholders are import-only (migration debt, distinct from the "
utils/py/releases_app.py:2076:    """Best-effort '<org>/<repo>' from a github.com origin remote; None when unresolved."""
utils/py/releases_app.py:2219:                   "this DB already holds releases; the legacy import is ONE-SHOT (PRD Phase 0) "
utils/py/releases_app.py:2321:                    # SOP 1 postdates every legacy block: import — and ONLY import — may create
utils/py/releases_app.py:2375:        print("imported %d block(s) from %s (txn %s): %d doc_lines, %d legacy_lines, "
utils/py/releases_app.py:2723:    guessed by a migration and then indistinguishable from the real thing.
utils/py/releases_app.py:2782:                   "cannot move an item from %r to %r (legality is CLI-enforced)"
utils/py/releases_app.py:2785:    # No live row. Distinguish "never here" from "here, but already terminal" — the second is a
utils/py/releases_app.py:2911:                       "cannot move an item from %r to 'dialed_in' (legality is CLI-enforced)"
utils/py/releases_app.py:3378:# only read from the HEAD of the title. An unanchored search harvested 111 out of "Execution
utils/py/releases_app.py:3383:# The separator set distinguishes a RANGE from prose. `..`/`...` and U+2013 EN DASH are the
utils/py/releases_app.py:3420:    URL, a mail address or a drive-lettered path in it yields a miss indistinguishable from a
utils/py/releases_app.py:3469:    from its bullet line (`- **` or `- [`) to the next bullet, `###`, or `##`."""
utils/py/releases_app.py:3574:    `reconcile-state` reads issue identity from this pair, so a row where they disagree can never
utils/py/releases_app.py:3658:            # scores silently dropped — an unrated row is indistinguishable from "never scored".
utils/py/releases_app.py:3691:    one transaction so the lossless shadow can never disagree with the scores derived from it.
utils/py/releases_app.py:3699:        # A row imported from a multi-issue ROADMAP bullet ("#129/#130/#131 · Wave 1 …") carries NO
utils/py/releases_app.py:4096:                    refuse("roadmap-issue-state", "%s changed from native closed to open during lookup; retry "
utils/py/releases_app.py:4100:                refuse("roadmap-issue-state", "%s changed from native open to closed during lookup; retry "
utils/py/releases_app.py:4152:    # PR #240 review: sync mirrors ROADMAP.md and DELETES rows absent from it — in a releases-mode
utils/py/releases_app.py:4199:                           "parsed 0 entries from %s (%s); refusing to delete roadmap_items%s"
utils/py/releases_app.py:4290:        # The row MIRRORS the entry text: converting an entry from cx/risk/eff to `rated` populates
utils/py/releases_app.py:4467:    refuse("invalid-issue-target", "cannot resolve GitHub issue number from %r" % target)
utils/py/releases_app.py:4931:        from jog_run import jog_run_main
utils/py/releases_app.py:4934:        from jog_run import jog_run_main
utils/py/releases_app.py:4942:        import jog_run
utils/py/releases_app.py:4963:    import jog_run
utils/py/releases_app.py:4979:    """Extract re-anchored break count from a merge-rebuild receipt's target_gid (GH-360).
utils/py/releases_app.py:5013:    # would hide a producer's last row behind enough newer rows from the other producer, and
utils/py/releases_app.py:5044:    event from ANY producer is in `terminal` — a terminal claim (`completed`, `pr_merged`)
utils/py/releases_app.py:5075:    """`work emit` — record one work event from OUTSIDE a domain verb (GH-549).
utils/py/releases_app.py:5084:    insert a second row: `None` from a registered extractor means "my mutate already wrote it",
utils/py/releases_app.py:5136:         and 40 live rows carry a stale 🆕 from the #424 marker bug. NOT `pr_merged`: that name
utils/py/releases_app.py:5225:    can run from any CWD, so the repository must be resolved from the ledger's own identity —
utils/py/releases_app.py:5226:    never from the caller's checkout. First enabled connector's repos[0], else the root's
utils/py/releases_app.py:5230:        import work_connectors
utils/py/releases_app.py:5250:    """Issue numbers a PR closes, from its title and body — the same regex merge_cleanup uses
utils/py/releases_app.py:5316:                # SystemExit included (impl QA r3): a refusal from the writer for ONE issue is a
utils/py/releases_app.py:5588:        import work_connectors
utils/py/releases_app.py:5620:    import work_connectors
utils/py/releases_app.py:5630:    # GH-564: derive "ready for review" from actually-open, non-draft PRs — before dispatch,
utils/py/releases_app.py:5690:                    else "the committed operation is preserved; dump/generated regenerated from "
utils/py/releases_app.py:5856:                         "drifted from the calendar" % (label.strip(), overdue, r["target_date"]))
utils/py/releases_app.py:5871:                print("OK: post-rebuild verification — DB rebuilt from %s, displaced DB at %s"
utils/py/releases_app.py:5964:    A union-style merge of two canonical dumps is ALMOST correct: GID-keyed rows from both sides
utils/py/releases_app.py:6222:    # reconcile` replays from zero, which is idempotent because every connector write is
utils/py/releases_app.py:6235:    merge legitimately forks the receipt chain (both sides branch from one ancestor), so the
utils/py/releases_app.py:6265:            #   2. load everything from the dump EXCEPT its schema_migrations records;
utils/py/releases_app.py:6273:            # merge leaves surface as a bare sqlite3.IntegrityError traceback from inside load_dump.
utils/py/releases_app.py:6346:    print("rebuilt %s from %s (generation %d -> %d); displaced DB backed up at %s"
utils/py/releases_app.py:6510:    sp = sub.add_parser("import", help="ONE-SHOT legacy ledger import (Phase 0)")
utils/py/releases_app.py:6575:                             help="cut an item from a release's manifest (REQUIRES --reason)")
utils/py/releases_app.py:6617:                    help="rebuild the DB from the dump (git-merge resolution ONLY)")
utils/py/releases_app.py:6652:                       help="replay from the beginning, not from the cursor")
utils/py/releases_app.py:6721:                       help="explicit lifecycle marker; never inferred from raw_text")
utils/py/releases_app.py:6761:    sp_jd.add_argument("--reason", required=True, help="reason for dropping from the queue")
utils/py/releases_app.py:6786:    sp_jrg.add_argument("--reviewer", default=None, help="reviewer agent (required; must differ from --builder)")
utils/py/releases_app.py:6793:    sp_jrb.add_argument("--reviewer", default=None, help="reviewer agent (required; must differ from --builder)")
#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const { appendEvent, ensureEventsDir, EVENT_TYPES, readAllEvents, eventsDir } = require('../src/events');
const { project, fold } = require('../src/project');
const { claim } = require('../src/claim');
const { scope, release, circuitBreak, done, reap, heartbeat } = require('../src/scope');
const { next } = require('../src/next');
const { take } = require('../src/take');
const { analyze, renderHuman, renderMd } = require('../src/analyze');
const { gitUserName } = require('../src/identity');
const { parseGeminiStats } = require('../src/cost');

function repoRoot() {
  if (process.env.TICK_REPO_ROOT) return { root: path.resolve(process.env.TICK_REPO_ROOT), source: 'env' };
  try {
    return { root: execFileSync('git', ['rev-parse', '--show-toplevel'], { encoding: 'utf8' }).trim(), source: 'git' };
  } catch {
    return { root: process.cwd(), source: 'cwd' };
  }
}

// Coordination-mutation verbs that operate on a task's lock in .tick/events.
// A bare call from a foreign CWD (no TICK_REPO_ROOT) resolves the wrong root via
// `git rev-parse` and would silently land in — or auto-create — the wrong repo's
// log, no-op'ing against the real harness clone. This is the GH-12 foot-gun that
// stalled a live relay handoff (`claim`/`take` succeed-in-the-wrong-place;
// `release`/`done` throw a bare "task not found" with no hint it's a wrong-CWD
// problem). When the root was INFERRED (not pinned via TICK_REPO_ROOT), surface
// the resolved root and refuse to operate on a repo that was never `tick init`-ed,
// rather than succeeding-as-noop. Best-effort `cost` verb and `cost.*` log events
// are intentionally left out so a turn's auxiliary cost capture never hard-fails
// on this. (GH-411: non-cost `log` types like task.* and marathon.* are guarded).
const MUTATING_GUARD_VERBS = new Set([
  'claim', 'take', 'scope', 'release', 'break', 'done', 'ping', 'reap',
]);

// GH-411: the guard decision is verb + event-type, not verb alone. Every `tick log` type is
// guarded EXCEPT `cost.*` — the only prefix the exemption above actually argues for. The `drift`
// VERB stays exempt (it is not `log`), preserving GH-68's warn-only invariant; that is pinned by
// test/gh411-tick-log-foreign-cwd.sh so a later "guard everything that isn't cost" refactor fails
// loudly rather than silently capturing it.
function shouldGuard(verb, eventType) {
  if (MUTATING_GUARD_VERBS.has(verb)) return true;
  // A bare `tick log` (no type) is left unguarded here and rejected by the `log` case below
  // before anything is written — asserted, not assumed, in the suite's bare-log case.
  if (verb === 'log' && eventType && !eventType.startsWith('cost.')) return true;
  return false;
}

function assertResolvedRoot(verb, root, source, eventType) {
test/gh534_phase_c_tests.py:21:sys.path.insert(0, str(REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts"))
test/gh534_phase_c_tests.py:22:sys.path.insert(0, str(REPO / "utils" / "py"))
test/gh534_phase_c_tests.py:23:sys.path.insert(0, str(REPO / "test"))
test/gh534_phase_c_tests.py:36:CLI = REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts" / "attempt_record.py"
test/gh534_phase_c_tests.py:204:        from rtl import driver_lock_path
test/gh534_phase_c_tests.py:523:SKILL_MD = REPO / "skills" / "2-daily" / "merge-cleanup" / "SKILL.md"
test/gh534_phase_c_tests.py:524:MC_SRC = REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts" / "merge_cleanup.py"
test/gh534_phase_c_tests.py:525:SC_SRC = REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts" / "scan_clones.py"
test/gh534_phase_c_tests.py:859:        r = subprocess.run([sys.executable, str(REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts" / "toposort_prs.py"),
skills/2-daily/merge-cleanup/scripts/ledger_merge.py:8:supported writer path — `utils/py/releases_app.py` verbs — never by editing the dump.
skills/2-daily/merge-cleanup/scripts/ledger_merge.py:10:What the resolver (`utils/releases-merge-resolve.sh`) does NOT decide is which rows survive. B1's
skills/2-daily/merge-cleanup/scripts/ledger_merge.py:262:def tool_path(root: Path, name: str, directory: str = "utils/py") -> Path:
skills/2-daily/merge-cleanup/scripts/ledger_merge.py:264:    then the same two under the primary checkout. Python tools default to `utils/py`. Falls back to
skills/2-daily/merge-cleanup/scripts/ledger_merge.py:486:    r = _run(["bash", str(tool_path(clone, "releases-merge-resolve.sh", directory="utils")), "--root", str(clone)], clone)
        self.assertTrue(result["resolved"], result)
        self.assertIn(["bash", str(resolver), "--root", str(self.clone)], commands)

    def test_missing_everywhere_reports_the_canonical_path(self):
        ledger_merge.TOOL_FALLBACK_ROOT = self.primary
        self.assertEqual(tool_path(self.clone, "wave_reconcile.py"),
                         self.clone / "utils" / "py" / "wave_reconcile.py")

    def test_app_command_uses_the_resolver_with_root(self):
        prim = _touch(self.primary / ".xyz" / "utils" / "py" / "releases_app.py")
        ledger_merge.TOOL_FALLBACK_ROOT = self.primary
        cmd = ledger_merge._app(self.clone)
        self.assertEqual(cmd[1], str(prim))
        self.assertEqual(cmd[2:4], ["--root", str(self.clone)])


class ReconcileFallbackNeverForces(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name)
        self._saved = ledger_merge.TOOL_FALLBACK_ROOT
        ledger_merge.TOOL_FALLBACK_ROOT = None

    def tearDown(self):
        ledger_merge.TOOL_FALLBACK_ROOT = self._saved
        self.tmp.cleanup()

    def _write_reconciler(self, advertises: bool):
        # --help lists the flag or not; unknown arguments are refused like the real argparse tool.
        flag_line = '    print("  --force-local-reconcile")' if advertises else "    pass"
        body = (
            "import sys\n"
            "if '--help' in sys.argv:\n"
            "    print('usage: wave_reconcile.py [--root ROOT] [--pr PR]')\n"
            f"{flag_line}\n"
            "    sys.exit(0)\n"
            "known = {'--root', '--pr'}\n"
            "bad = [a for a in sys.argv[1:] if a.startswith('--') and a not in known"
            + (" | {'--force-local-reconcile'}" if advertises else "") + "]\n"
            "if bad:\n"
            "    print('error: unrecognized arguments: ' + ' '.join(bad), file=sys.stderr); sys.exit(2)\n"
            "open('argv.txt', 'w').write(' '.join(sys.argv[1:]))\n"
        )
        return _touch(self.repo / ".xyz" / "utils" / "py" / "wave_reconcile.py").write_text(body)

    def test_flag_omitted_when_the_tool_does_not_advertise_it(self):
        self._write_reconciler(advertises=False)
        with mock.patch.object(merge_cleanup, "log"), mock.patch.object(merge_cleanup, "log_err") as err:
            self.assertTrue(merge_cleanup.run_local_wave_reconcile(7, self.repo))
            err.assert_not_called()
        argv = (self.repo / "argv.txt").read_text()
        self.assertNotIn("--force-local-reconcile", argv)
        self.assertIn(f"--root {self.repo}", argv)
        self.assertIn("--pr 7", argv)

    def test_flag_omitted_even_when_the_tool_advertises_it(self):
        self._write_reconciler(advertises=True)
        with mock.patch.object(merge_cleanup, "log"), mock.patch.object(merge_cleanup, "log_err"):
            self.assertTrue(merge_cleanup.run_local_wave_reconcile(7, self.repo))
        self.assertNotIn("--force-local-reconcile", (self.repo / "argv.txt").read_text())


if __name__ == "__main__":
    unittest.main(verbosity=1)
PY

    def test_foreign_or_unidentified_success_cannot_attest_this_merge(self):
        for initial_sha, final_sha in (("foreign", "foreign"), (None, "foreign"), (None, None)):
            with self.subTest(initial_sha=initial_sha, final_sha=final_sha):
                responses = [
                    [{"databaseId": 791, "status": "in_progress", "headSha": initial_sha}],
                    [{"databaseId": 791, "status": "completed", "conclusion": "success",
                      "headSha": final_sha}],
                ]
                def fake_gh(args, cwd, timeout=60):
                    return subprocess.CompletedProcess(args, 0, json.dumps(responses.pop(0)), "")
                with mock.patch.object(merge_cleanup, "_gh", side_effect=fake_gh), \
                        mock.patch.object(merge_cleanup.time, "sleep"), \
                        mock.patch.dict(os.environ, {merge_cleanup.HOSTED_GRACE_ENV: "0"}):
                    self.assertEqual(merge_cleanup.wait_for_hosted_reconcile(
                        "m" * 40, Path("."), "development", pr_head="p" * 40), "fallback")

    def test_matching_run_takes_precedence_over_unidentified_adoption(self):
        responses = [
            [{"databaseId": 1, "status": "in_progress"}],
            [{"databaseId": 1, "status": "completed", "conclusion": "failure"},
             {"databaseId": 2, "status": "completed", "conclusion": "success", "headSha": "p" * 40}],
        ]
        def fake_gh(args, cwd, timeout=60):
            return subprocess.CompletedProcess(args, 0, json.dumps(responses.pop(0)), "")
        with mock.patch.object(merge_cleanup, "_gh", side_effect=fake_gh), \
                mock.patch.object(merge_cleanup.time, "sleep"), \
                mock.patch.dict(os.environ, {merge_cleanup.HOSTED_GRACE_ENV: "0"}):
            self.assertEqual(merge_cleanup.wait_for_hosted_reconcile(
                "m" * 40, Path("."), "development", pr_head="p" * 40), "success")

    def test_unidentified_active_run_still_blocks_local_writer_at_timeout(self):
        response = subprocess.CompletedProcess([], 0, json.dumps([
            {"databaseId": 791, "status": "in_progress"}]), "")
        with mock.patch.object(merge_cleanup, "_gh", return_value=response), \
                mock.patch.dict(os.environ, {merge_cleanup.HOSTED_GRACE_ENV: "0",
                                             merge_cleanup.HOSTED_WAIT_ENV: "0"}):
            self.assertEqual(merge_cleanup.wait_for_hosted_reconcile(
                "m" * 40, Path("."), "development", pr_head="p" * 40), "active_timeout")

    def test_automatic_fallback_never_adds_force_flag(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            script = root / "utils" / "py" / "wave_reconcile.py"
            script.parent.mkdir(parents=True)
            script.write_text(
                "import pathlib, sys\n"
                "pathlib.Path('argv.txt').write_text(' '.join(sys.argv[1:]))\n"
            )
            with mock.patch.object(merge_cleanup, "log"), \
                    mock.patch.object(merge_cleanup, "log_err"):
                self.assertTrue(merge_cleanup.run_local_wave_reconcile(674, root))
            argv = (root / "argv.txt").read_text()
            self.assertNotIn("--force-local-reconcile", argv)
            self.assertIn("--pr 674", argv)


if __name__ == "__main__":
    unittest.main(verbosity=1)
PY
   150	PRISTINE="$WORK/pristine"; mkdir -p "$PRISTINE"
   151	require_fixture "$PRISTINE" "gh549 pre-rebuild ledger snapshot"
   152	cp "$FX/releases.db" "$FX/releases.sql" "$PRISTINE/"
   153	# GH-695: $PRISTINE is a copy of the LIVE ledger, whose work_events grows with every reconcile. The
   154	# legs that drive the real github_board connector replay every event past the cursor through the
   155	# mock -- one subprocess each -- inside CONNECTOR_WINDOW_S (5s). With the cursor deleted, the replay
   156	# crossed the window at ~124 rows (green at 101) and leg 17 went red on development with no code
   157	# change; leg 26 followed at ~133. Pin every real-mock fixture's cursor to the pristine ledger's tail
   158	# so a leg replays exactly the events it emits itself: the assertions are "the connector moves a card",
   159	# never "it can drain N months of history in 5s". A red-variant copy re-seeds to the SAME tail so its
   160	# re-replay covers the leg's own events again. Stub-connector legs keep their plain DELETE (fast).
   161	PRISTINE_TAIL="$(sqlite3 "$PRISTINE/releases.db" "SELECT COALESCE(MAX(id),0) FROM work_events;")"
   162	seed_cursor_tail() {  # <releases.db>  -> cursor for github_board = $PRISTINE_TAIL (insert or reset)
   163	  sqlite3 "$1" "INSERT INTO connector_cursors(connector,last_event_id,updated_at) VALUES('github_board',$PRISTINE_TAIL,'2026-09-18T00:00:00Z') ON CONFLICT(connector) DO UPDATE SET last_event_id=$PRISTINE_TAIL;"
   164	}
   165	
   166	echo "8. rebuild round-trips work_events"
   167	BEFORE="$(sqlite3 "$FX/releases.db" "SELECT count(*) FROM work_events;")"
   168	app check --rebuild >/dev/null 2>&1
   169	AFTER="$(sqlite3 "$FX/releases.db" "SELECT count(*) FROM work_events;")"
   170	[ "$BEFORE" -gt 0 ] || bad "fixture had zero events — round-trip proves nothing"
   171	[ "$BEFORE" = "$AFTER" ] && ok "check --rebuild preserved all $AFTER work_events rows" \
   172	                         || bad "rebuild lost rows ($BEFORE -> $AFTER)"
   173	
   174	echo "9. RED CONTROL A — work_events above the include_receipts guard breaks the chain"
   175	MUTA="$WORK/mutA.py"
   176	python3 - "$APP" "$MUTA" <<'PYMUT'
   177	import sys
   178	src = open(sys.argv[1], encoding="utf-8").read()

exec
/bin/zsh -lc "rg -n 'from (rtl|device|work|harness)|import (rtl|device|work)' utils/py/releases_app.py; nl -ba bin/tick | head -30; nl -ba test/gh534_phase_c_tests.py | sed -n '198,213p'; nl -ba test/gh534_phase_b_tests.py | sed -n '23,44p'; rg -n 'require\\(' src/cli.js | head; rg -n 'No new tests' AGENTS.md; nl -ba utils/ci-route.sh | sed -n '290,325p'; rg -n 'read_text|REPO|ROOT|SKILL' test/gh645-merge-cleanup-xyz-tools.sh test/gh674-merge-cleanup-hosted-lookup.sh" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-68346-vx81h0en
 succeeded in 0ms:
1624:        import work_connectors
5230:        import work_connectors
5588:        import work_connectors
5620:    import work_connectors
     1	#!/usr/bin/env node
     2	'use strict';
     3	
     4	const fs = require('fs');
     5	const path = require('path');
     6	const { execFileSync } = require('child_process');
     7	
     8	const { appendEvent, ensureEventsDir, EVENT_TYPES, readAllEvents, eventsDir } = require('../src/events');
     9	const { project, fold } = require('../src/project');
    10	const { claim } = require('../src/claim');
    11	const { scope, release, circuitBreak, done, reap, heartbeat } = require('../src/scope');
    12	const { next } = require('../src/next');
    13	const { take } = require('../src/take');
    14	const { analyze, renderHuman, renderMd } = require('../src/analyze');
    15	const { gitUserName } = require('../src/identity');
    16	const { parseGeminiStats } = require('../src/cost');
    17	
    18	function repoRoot() {
    19	  if (process.env.TICK_REPO_ROOT) return { root: path.resolve(process.env.TICK_REPO_ROOT), source: 'env' };
    20	  try {
    21	    return { root: execFileSync('git', ['rev-parse', '--show-toplevel'], { encoding: 'utf8' }).trim(), source: 'git' };
    22	  } catch {
    23	    return { root: process.cwd(), source: 'cwd' };
    24	  }
    25	}
    26	
    27	// Coordination-mutation verbs that operate on a task's lock in .tick/events.
    28	// A bare call from a foreign CWD (no TICK_REPO_ROOT) resolves the wrong root via
    29	// `git rev-parse` and would silently land in — or auto-create — the wrong repo's
    30	// log, no-op'ing against the real harness clone. This is the GH-12 foot-gun that
   198	        rcs = sorted(p.wait(timeout=20) for p in procs)
   199	        self.assertEqual(rcs, [0, 3], [(p.stdout.read(), p.stderr.read()) for p in procs])
   200	        self.assertEqual(ar.repair_count(ar.load(self.record)), 2)
   201	
   202	    def test_worker_under_a_held_driver_mkdir_lock_still_reserves(self):
   203	        """The record lock is independent of the driver's mkdir lock (a nominal 'same lock' fails)."""
   204	        from rtl import driver_lock_path
   205	        subprocess.run(["git", "init", "-q", str(self.primary)], check=True)
   206	        lock_dir, _ = driver_lock_path(str(self.primary))
   207	        os.mkdir(lock_dir)
   208	        (Path(lock_dir) / "pid").write_text(str(os.getpid()))  # a LIVE driver
   209	        ar.save(self.record, self.fresh)
   210	        r = cli(self.clone1, "reserve", "--rung", "ponytail", "--head", "1" * 40, env=self.env, timeout=10)
   211	        self.assertEqual(r.returncode, 0, r.stderr)
   212	        self.assertTrue(Path(lock_dir).is_dir(), "the driver lock was touched")
   213	        self.assertEqual(RecordLock(self.record).lock_path, self.record.with_name("pr-538.json.lock"))
    23	REPO = Path(__file__).resolve().parent.parent
    24	sys.path.insert(0, str(REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts"))
    25	
    26	import ledger_merge  # noqa: E402
    27	import merge_cleanup  # noqa: E402
    28	import scan_clones  # noqa: E402
    29	from ledger_merge import classify, parse_dump, pre_merge_ledger_gate, resolve_ledger_conflict  # noqa: E402
    30	from scan_clones import GH_BIN_ENV  # noqa: E402
    31	
    32	APP_SRC = REPO / "utils" / "py" / "releases_app.py"
    33	RESOLVER_SRC = REPO / "utils" / "releases-merge-resolve.sh"
    34	
    35	
    36	def _git(cwd, *args, check=True):
    37	    return subprocess.run(["git", "-C", str(cwd)] + list(args), capture_output=True, text=True, check=check)
    38	
    39	
    40	def _app(root, *args, check=True):
    41	    r = subprocess.run([sys.executable, str(Path(root) / "utils/py/releases_app.py"), "--root", str(root)] + list(args),
    42	                       capture_output=True, text=True)
    43	    if check and r.returncode != 0:
    44	        raise AssertionError(f"releases_app {' '.join(args)} failed rc={r.returncode}: {r.stderr}\n{r.stdout}")
rg: src/cli.js: IO error for operation on src/cli.js: No such file or directory (os error 2)
108:Never add a suite to do it; see the *No new tests* rail. This is the precise way this principle fails while looking
136:- **No new tests (GH-831, operator decision 2026-09-25).** This covers three things:
   290	  case ",$changed_tests," in
   291	    *",$candidate,"*) return 0 ;;
   292	  esac
   293	  changed_tests="${changed_tests:+$changed_tests,}$candidate"
   294	}
   295	
   296	add_tier2_test() {  # <suite> — only suites that exist; a subsystem with none runnable on disk
   297	  local candidate="$1"     # escalates to tier 3 at the end, never a zero-test green
   298	  [[ -f "test/$candidate" ]] || return 0
   299	  case ",$tier2_tests," in
   300	    *",$candidate,"*) return 0 ;;
   301	  esac
   302	  tier2_tests="${tier2_tests:+$tier2_tests,}$candidate"
   303	}
   304	
   305	while IFS= read -r path || [[ -n "$path" ]]; do
   306	  [[ -n "$path" ]] || continue
   307	  path_count=$((path_count + 1))
   308	
   309	  # Docs surfaces (GH-35 Phase 1 widened the GH-509 list): evidence, transcripts, notes, and
   310	  # governance levers (*.txt anywhere, decisions/, .pdda-* levers, .xyz-launch-artifact).
   311	  # GH-487: TESTS-RESULTS receipts join the evidence side — a provenance.jsonl follow-up used
   312	  # to re-run the full gate as an unmapped path. GH-831: skill files and the ledger too; the
   313	  # precedence lives in is_docs_surface() above.
   314	  if is_docs_surface "$path"; then
   315	    pdda_needed=true
   316	  else
   317	    docs_only=false
   318	  fi
   319	
   320	  # These surfaces own the coordination kernel, containment boundary, frozen twins,
   321	  # worktree safety, or CI gate itself. They require the full suite before merge.
   322	  # (GH-35 moved utils/pdda/** and skills/*/agent-chorus code off this list and into the
   323	  # subsystem registry, per the issue's Tier-2 mapping; their focused suites run instead.)
   324	  case "$path" in
   325	    validate.sh)
test/gh674-merge-cleanup-hosted-lookup.sh:137:            argv = (root / "argv.txt").read_text()
test/gh645-merge-cleanup-xyz-tools.sh:34:        self._saved = ledger_merge.TOOL_FALLBACK_ROOT
test/gh645-merge-cleanup-xyz-tools.sh:35:        ledger_merge.TOOL_FALLBACK_ROOT = None
test/gh645-merge-cleanup-xyz-tools.sh:38:        ledger_merge.TOOL_FALLBACK_ROOT = self._saved
test/gh645-merge-cleanup-xyz-tools.sh:52:        ledger_merge.TOOL_FALLBACK_ROOT = self.primary
test/gh645-merge-cleanup-xyz-tools.sh:60:        ledger_merge.TOOL_FALLBACK_ROOT = self.primary
test/gh645-merge-cleanup-xyz-tools.sh:79:        ledger_merge.TOOL_FALLBACK_ROOT = self.primary
test/gh645-merge-cleanup-xyz-tools.sh:85:        ledger_merge.TOOL_FALLBACK_ROOT = self.primary
test/gh645-merge-cleanup-xyz-tools.sh:95:        self._saved = ledger_merge.TOOL_FALLBACK_ROOT
test/gh645-merge-cleanup-xyz-tools.sh:96:        ledger_merge.TOOL_FALLBACK_ROOT = None
test/gh645-merge-cleanup-xyz-tools.sh:99:        ledger_merge.TOOL_FALLBACK_ROOT = self._saved
test/gh645-merge-cleanup-xyz-tools.sh:108:            "    print('usage: wave_reconcile.py [--root ROOT] [--pr PR]')\n"
test/gh645-merge-cleanup-xyz-tools.sh:125:        argv = (self.repo / "argv.txt").read_text()
test/gh645-merge-cleanup-xyz-tools.sh:134:        self.assertNotIn("--force-local-reconcile", (self.repo / "argv.txt").read_text())

exec
/bin/zsh -lc "sed -n '324,371p' utils/ci-route.sh; sed -n '4928,4968p' utils/py/releases_app.py; sed -n '1,50p' skills/2-daily/merge-cleanup/scripts/attempt_record.py" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-68346-vx81h0en
 succeeded in 0ms:
  case "$path" in
    validate.sh)
      if ! is_validate_append_only; then
        full_required=true
      fi
      ;;
    .github/workflows/*|utils/ci-route.sh|test/ci-route.sh|test/ci-workflow.sh)
      full_required=true
      ;;
    bin/tick|bin/validate-relay-block|src/*)
      full_required=true
      ;;
    relay-automation/*|skills/*/relay-automation/*|skills/*/relay-xyz/*)
      full_required=true
      ;;
    utils/py/*)
      # Subsystem code with focused suites (releases_app.py, wave_reconcile.py, ATE tools)
      # is not an authoritative twin; unmapped files under utils/py/ are kernel/twin surface.
      [ -n "$(subsystem_of "$path" || true)" ] || full_required=true
      ;;
    test/*worktree*|test/*containment*|test/tick-*|test/relay-*|test/agent-chorus.sh|test/marathon*.sh)
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
    test/*)
      # GH-487: a test path CLAIMED by a subsystem (listed in subsystem_of) is that subsystem's
      # dedicated evidence; it escalates only when the same push touches none of that
      # subsystem's code (co-touch resolved after the loop). A dedicated suite edited alone
      # would otherwise judge itself — the weakened artifact reporting a green nothing in the
      # push disagrees with. Unclaimed test paths keep the full GH-35 escalation.
      _dedicated_sub="$(subsystem_of "$path" || true)"
      if [ -n "$_dedicated_sub" ]; then
        case " $claimed_test_subs " in
          *" $_dedicated_sub "*) ;;
          *) claimed_test_subs="${claimed_test_subs:+$claimed_test_subs }$_dedicated_sub" ;;
        esac
      else
        test_touched=true
      fi
      ;;
def cmd_jog_run(args):
    """Execute the serial jog queue supervisor."""
    try:
        from jog_run import jog_run_main
    except ImportError:
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        from jog_run import jog_run_main
    jog_run_main(args)


def _jog_verb_dispatch(fn_name):
    """GH-280 Phase 3 verb dispatch: shared root/target resolution, then delegate to jog_run."""
    def handler(args):
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import jog_run
        root = resolve_root(getattr(args, "root", None))
        gh_num = resolve_issue_number(args.target)
        sys.exit(getattr(jog_run, fn_name)(root, gh_num, args))
    return handler


def cmd_jog_resume(args):
    _jog_verb_dispatch("jog_resume")(args)


def cmd_jog_retry_gate(args):
    _jog_verb_dispatch("jog_retry_gate")(args)


def cmd_jog_retry_build(args):
    _jog_verb_dispatch("jog_retry_build")(args)


def cmd_jog_land(args):
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import jog_run
    root = resolve_root(getattr(args, "root", None))
    gh_num = resolve_issue_number(args.target)
    sys.exit(jog_run.jog_land(root, gh_num, getattr(args, "pr", None)))


#!/usr/bin/env python3
"""GH-534 Phase C — the durable per-PR attempt record and its lock.

One record per (origin, PR) at ONE pinned coordinator: `<primary>/.tick/merge-cleanup/<owner>-<repo>/pr-<N>.json`.
The script (B1) and the caller's repair rungs both write it, so the two-repair ceiling is enforced across
clones, restarts and heads. Every writer holds `fcntl.flock(LOCK_EX)` on `<record>.lock` for the whole
read → reserve → write sequence. This lock is deliberately NOT the driver's mkdir lock: a worker started
under a running driver must still be able to reserve.

Rules pinned by test/gh534_phase_c_tests.py:
- only repair attempts count; `note` (diagnosis/recon) never consumes budget;
- the ceiling is per PR whatever the head — a failed repair's new head mints nothing;
- a lock timeout STOPS the attempt (it is never counted as "skipped");
- a worker without MERGE_CLEANUP_RECORD, or with an unreadable/malformed record, STOPS — it never
  derives a record root from its own CWD.
"""
from __future__ import annotations

import argparse
import fcntl
import json
import os
import re
import sys
import time
from pathlib import Path
from typing import Any, Dict, Optional, Tuple

RECORD_ENV = "MERGE_CLEANUP_RECORD"
LOCK_TIMEOUT_ENV = "MERGE_CLEANUP_LOCK_TIMEOUT_S"
MAX_REPAIRS = 2
RUNGS = ("B1", "debug-mantra", "recon", "ponytail", "start-task", "unstuck")
REPAIR_RUNGS = ("B1", "ponytail", "start-task")  # rungs that change files; the others are notes


class RecordError(Exception):
    """The record cannot be used: missing variable, unreadable, malformed, or lock timeout."""


def repo_slug(origin: str) -> str:
    """`<owner>-<repo>` from a GitHub URL; the last two path components otherwise."""
    s = origin.strip().rstrip("/")
    s = re.sub(r"\.git$", "", s)
    m = re.search(r"[:/]([^/:]+)/([^/]+)$", s)
    parts = (m.group(1), m.group(2)) if m else (Path(s).parent.name or "local", Path(s).name or "repo")
    return "-".join(re.sub(r"[^A-Za-z0-9_.-]", "_", p) for p in parts)


def record_path(primary: Path, origin: str, pr: int) -> Path:
    # ponytail: the coordinator is the explicit --primary, resolved once by the caller. Never Path.cwd().

codex
**ANSWER:** Keep both in Small for now. Both consume tier-1-routable inputs: gh549 uses the committed ledger; gh436 checks committed skill and safety markdown. Moving either wholesale fails the proposed deciding test. (`test/gh549-work-events.sh:44`; `test/gh534_phase_c_tests.py:877`; `test/gh534_phase_a_tests.py:125`; `utils/ci-route.sh:65`)

**FINDINGS**

- **[Blocker] gh549: keep in Small.** Its ledger is **not synthetic**: it copies real `releases.db` and `releases.sql`, migrates them, exercises writes, checks integrity, and rebuilds while checking event preservation. Both ledger files explicitly route tier 1 despite belonging to the releases subsystem. (`test/gh549-work-events.sh:44`, `:51`, `:76`, `:166`; `utils/ci-route.sh:43`, `:66`)

  Its other tracked inputs are **not tier 1**:
  - `releases_app.py`, `work_connectors/*`: releases subsystem code. (`test/gh549-work-events.sh:25`, `:655`; `utils/py/releases_app.py:1624`; `utils/ci-route.sh:43`)
  - `board_sync.py`, its `device_config`/`harness_paths` dependencies, and `mock_gh_board.py`: unmapped Python code requiring full coverage. (`test/gh549-work-events.sh:304`, `:654`; `utils/py/board_sync.py:46`, `:56`; `utils/ci-route.sh:337`)
  - Merge-cleanup’s `merge_cleanup.py`: core-skill executable, explicitly excluded from docs routing. (`test/gh549-work-events.sh:589`; `utils/ci-route.sh:67`)
  - Fixture guard, PR-list wrapper, and the suite itself: test infrastructure. Mutation variants also copy `utils/py/`. (`test/gh549-work-events.sh:23`, `:565`, `:1074`; `utils/ci-route.sh:353`)

  **Risk if moved:** a ledger-only landing containing events for fixture issue 9901 could break the exact `parked,rated,in_flight` assertion; a ledger schema/trigger regression could break the append-only assertions. These are concrete data dependencies, though the former is fixture fragility rather than necessarily a product defect. The suite already records historical ledger-growth failures without code changes. (`test/gh549-work-events.sh:59`, `:65`, `:81`, `:153`)

- **[Blocker] gh436: keep in Small, preferably make it cheaper.** The shell wrapper loads the Python suite, which collects phases A, B and C. (`test/gh436-merge-cleanup.sh:11`; `test/gh436-merge-cleanup.py:863`)

  **Tier-1 inputs:** `WORKTREE-SAFETY.md` supplies the checked `SAFE_ROOTS` example; `skills/2-daily/merge-cleanup/SKILL.md` supplies capability ownership, named tests, CLI options and Drive-loop contracts. Markdown wins before the core-skill exclusion. (`test/gh534_phase_a_tests.py:125`; `test/gh534_phase_c_tests.py:523`, `:562`, `:877`; `utils/ci-route.sh:65`)

  **Non-tier-1 inputs:** merge-cleanup’s `scan_clones`, `merge_cleanup`, `toposort_prs`, `attempt_record` and `ledger_merge` scripts; `releases_app.py`; `releases-merge-resolve.sh`; `.gitattributes`; `rtl`; and real `bin/tick` with its `src/*` dependencies. These are core-skill code, releases code, unmapped configuration or kernel code. (`test/gh436-merge-cleanup.py:23`; `test/gh534_phase_c_tests.py:25`, `:204`; `test/gh534_phase_b_tests.py:32`, `:163`; `test/gh534_phase_a_tests.py:36`; `bin/tick:8`; `utils/ci-route.sh:43`, `:67`, `:332`)

  **Its ledger is synthetic:** initialization creates a fixture ledger and parks issues 100 and 101; it does not copy the committed ledger. (`test/gh534_phase_b_tests.py:163`–`:170`)

  **Risk if moved:** a markdown-only change deleting the skill’s Done rule or changing capability ownership could qualify without these checks. Existing mutation controls explicitly demonstrate those failures. (`test/gh534_phase_c_tests.py:904`, `:942`)

- **[Should] Optimize existing suites before changing coverage.** gh436’s parity check **reruns named behavioral tests inside another test**, potentially repeating expensive fixture setup. Deduplicate execution while retaining both reference validation and actual behavioral execution; do not simply remove the latter. (`test/gh534_phase_c_tests.py:587`, `:928`) For gh549, investigate the 60 separate real ledger writes in section 24 and repeated whole-Python-tree copies; these are concrete profiling targets, not proven explanations for the supplied timings. Preserve the depth regression and its red control. (`test/gh549-work-events.sh:1312`, `:1332`) Neither optimization requires new suites or gate machinery, which the repository forbids. (`AGENTS.md:136`)

- **[Should] Two better removal candidates:** `gh645-merge-cleanup-xyz-tools.sh` and `gh674-merge-cleanup-hosted-lookup.sh` are currently Small, but exercise core-skill code against generated tools and mocked hosted responses, rather than committed markdown or ledger data. Under the proposed input-based criterion, they belong in Large. (`utils/ci-route.sh:38`; `test/gh645-merge-cleanup-xyz-tools.sh:16`, `:22`, `:101`; `test/gh674-merge-cleanup-hosted-lookup.sh:18`, `:24`, `:123`) This is a bounded finding, not an audit of all 73 suites.

**[Pass] Later detection remains available, but delayed:** removed coverage runs at the next non-tier-1 qualification or promotion, provided the defect persists; it would not retroactively validate the skipped commit. (`utils/py/wave_reconcile.py:589`; `PROJECT/2-WORKING/GH-831-THREE-TIER-GATE.md:281`)

Static review only; no suites executed.

**RECOMMENDATION:** Retain gh549 and gh436 in Small, optimize their existing execution, and consider moving gh645/gh674 instead.
tokens used
67,681
**ANSWER:** Keep both in Small for now. Both consume tier-1-routable inputs: gh549 uses the committed ledger; gh436 checks committed skill and safety markdown. Moving either wholesale fails the proposed deciding test. (`test/gh549-work-events.sh:44`; `test/gh534_phase_c_tests.py:877`; `test/gh534_phase_a_tests.py:125`; `utils/ci-route.sh:65`)

**FINDINGS**

- **[Blocker] gh549: keep in Small.** Its ledger is **not synthetic**: it copies real `releases.db` and `releases.sql`, migrates them, exercises writes, checks integrity, and rebuilds while checking event preservation. Both ledger files explicitly route tier 1 despite belonging to the releases subsystem. (`test/gh549-work-events.sh:44`, `:51`, `:76`, `:166`; `utils/ci-route.sh:43`, `:66`)

  Its other tracked inputs are **not tier 1**:
  - `releases_app.py`, `work_connectors/*`: releases subsystem code. (`test/gh549-work-events.sh:25`, `:655`; `utils/py/releases_app.py:1624`; `utils/ci-route.sh:43`)
  - `board_sync.py`, its `device_config`/`harness_paths` dependencies, and `mock_gh_board.py`: unmapped Python code requiring full coverage. (`test/gh549-work-events.sh:304`, `:654`; `utils/py/board_sync.py:46`, `:56`; `utils/ci-route.sh:337`)
  - Merge-cleanup’s `merge_cleanup.py`: core-skill executable, explicitly excluded from docs routing. (`test/gh549-work-events.sh:589`; `utils/ci-route.sh:67`)
  - Fixture guard, PR-list wrapper, and the suite itself: test infrastructure. Mutation variants also copy `utils/py/`. (`test/gh549-work-events.sh:23`, `:565`, `:1074`; `utils/ci-route.sh:353`)

  **Risk if moved:** a ledger-only landing containing events for fixture issue 9901 could break the exact `parked,rated,in_flight` assertion; a ledger schema/trigger regression could break the append-only assertions. These are concrete data dependencies, though the former is fixture fragility rather than necessarily a product defect. The suite already records historical ledger-growth failures without code changes. (`test/gh549-work-events.sh:59`, `:65`, `:81`, `:153`)

- **[Blocker] gh436: keep in Small, preferably make it cheaper.** The shell wrapper loads the Python suite, which collects phases A, B and C. (`test/gh436-merge-cleanup.sh:11`; `test/gh436-merge-cleanup.py:863`)

  **Tier-1 inputs:** `WORKTREE-SAFETY.md` supplies the checked `SAFE_ROOTS` example; `skills/2-daily/merge-cleanup/SKILL.md` supplies capability ownership, named tests, CLI options and Drive-loop contracts. Markdown wins before the core-skill exclusion. (`test/gh534_phase_a_tests.py:125`; `test/gh534_phase_c_tests.py:523`, `:562`, `:877`; `utils/ci-route.sh:65`)

  **Non-tier-1 inputs:** merge-cleanup’s `scan_clones`, `merge_cleanup`, `toposort_prs`, `attempt_record` and `ledger_merge` scripts; `releases_app.py`; `releases-merge-resolve.sh`; `.gitattributes`; `rtl`; and real `bin/tick` with its `src/*` dependencies. These are core-skill code, releases code, unmapped configuration or kernel code. (`test/gh436-merge-cleanup.py:23`; `test/gh534_phase_c_tests.py:25`, `:204`; `test/gh534_phase_b_tests.py:32`, `:163`; `test/gh534_phase_a_tests.py:36`; `bin/tick:8`; `utils/ci-route.sh:43`, `:67`, `:332`)

  **Its ledger is synthetic:** initialization creates a fixture ledger and parks issues 100 and 101; it does not copy the committed ledger. (`test/gh534_phase_b_tests.py:163`–`:170`)

  **Risk if moved:** a markdown-only change deleting the skill’s Done rule or changing capability ownership could qualify without these checks. Existing mutation controls explicitly demonstrate those failures. (`test/gh534_phase_c_tests.py:904`, `:942`)

- **[Should] Optimize existing suites before changing coverage.** gh436’s parity check **reruns named behavioral tests inside another test**, potentially repeating expensive fixture setup. Deduplicate execution while retaining both reference validation and actual behavioral execution; do not simply remove the latter. (`test/gh534_phase_c_tests.py:587`, `:928`) For gh549, investigate the 60 separate real ledger writes in section 24 and repeated whole-Python-tree copies; these are concrete profiling targets, not proven explanations for the supplied timings. Preserve the depth regression and its red control. (`test/gh549-work-events.sh:1312`, `:1332`) Neither optimization requires new suites or gate machinery, which the repository forbids. (`AGENTS.md:136`)

- **[Should] Two better removal candidates:** `gh645-merge-cleanup-xyz-tools.sh` and `gh674-merge-cleanup-hosted-lookup.sh` are currently Small, but exercise core-skill code against generated tools and mocked hosted responses, rather than committed markdown or ledger data. Under the proposed input-based criterion, they belong in Large. (`utils/ci-route.sh:38`; `test/gh645-merge-cleanup-xyz-tools.sh:16`, `:22`, `:101`; `test/gh674-merge-cleanup-hosted-lookup.sh:18`, `:24`, `:123`) This is a bounded finding, not an audit of all 73 suites.

**[Pass] Later detection remains available, but delayed:** removed coverage runs at the next non-tier-1 qualification or promotion, provided the defect persists; it would not retroactively validate the skipped commit. (`utils/py/wave_reconcile.py:589`; `PROJECT/2-WORKING/GH-831-THREE-TIER-GATE.md:281`)

Static review only; no suites executed.

**RECOMMENDATION:** Retain gh549 and gh436 in Small, optimize their existing execution, and consider moving gh645/gh674 instead.
