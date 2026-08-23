#!/usr/bin/env bash
# GH-509: deterministic route selection for docs, fast PR, and full integration gates.
source "$(dirname "$0")/_setup.sh" ci-route
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROUTER="$ROOT/utils/ci-route.sh"

route() {
  local event="$1"
  shift
  printf '%s\n' "$@" | bash "$ROUTER" "$event"
}

expect_route() {
  local label="$1" event="$2" expected_route="$3" expected_pdda="$4"
  shift 4
  local out
  out="$(route "$event" "$@")"
  if grep -Fqx "route=$expected_route" <<<"$out" \
    && grep -Fqx "pdda_needed=$expected_pdda" <<<"$out"; then
    pass "$label"
  else
    fail "$label: $out"
  fi
}

expect_route "markdown-only PR uses the docs gate" pull_request docs true README.md PROJECT/1-INBOX/NOTE.md
expect_route "ordinary code-only PR uses the fast gate without PDDA" pull_request fast false utils/hq/hq.sh
expect_route "mixed docs and ordinary code runs both fast tests and PDDA" pull_request fast true README.md utils/hq/hq.sh
expect_route "Tick/event changes require the full pre-merge gate" pull_request full true src/events.js
expect_route "relay containment changes require the full pre-merge gate" pull_request full true relay-automation/relay-turn-lib.sh
expect_route "Python-authoritative twin changes require the full pre-merge gate" pull_request full true utils/py/relay_drive.py
expect_route "worktree safety test changes require the full pre-merge gate" pull_request full true test/worktree-isolation.sh
expect_route "CI workflow changes require the full pre-merge gate" pull_request full true .github/workflows/ci.yml
# GH-35 moved PDDA tooling off the blanket-full list and into the Tier-2 subsystem registry
# (issue #35, subsystem 6): the focused PDDA suites run instead of the whole pool. PDDA itself
# still gates (pdda_needed=true). utils/pdda/** staying tier 3 was the pre-GH-35 posture.
expect_route "PDDA implementation changes run the PDDA subsystem gate (GH-35)" pull_request fast true utils/pdda/pdda.sh
shell_suffix=sh
deleted_test="test/removed-regression.${shell_suffix}"
expect_route "a deleted regression test fails closed into the full gate" pull_request full true "$deleted_test"
# GH-509 Phase 3 relabelled this: a push is no longer unconditionally full. With NO paths it still
# is, because zero paths is the fail-closed case — which is what this line actually exercises.
expect_route "a push with no usable range fails closed into the full gate" push full true
expect_route "scheduled runs remain the full fallback boundary" schedule full true

out="$(route pull_request utils/hq/hq.sh)"
grep -Fqx 'changed_tests=hq.sh' <<<"$out" \
  && pass "fast routes include a directly matching changed-area test" \
  || fail "fast route omitted its changed-area test: $out"

out="$(printf '' | bash "$ROUTER" pull_request)"
grep -Fqx 'route=full' <<<"$out" \
  && pass "an empty PR diff fails closed into the full gate" \
  || fail "empty PR diff did not fail closed: $out"

set +e
unknown_out="$(bash "$ROUTER" unsupported </dev/null 2>&1)"
unknown_rc=$?
set -e
[[ "$unknown_rc" -eq 2 && "$unknown_out" == *"unsupported event"* ]] \
  && pass "unknown events fail loudly" \
  || fail "unknown event result: rc=$unknown_rc out=$unknown_out"

# ── GH-509 Phase 3: pushes are classified, not blanket-full ──────────────────────────────────────
# 72% of the billed minutes were pushes to `development`, every one on the full route. They now
# classify from their pushed range exactly as a PR classifies from its diff.
expect_route "docs-only push uses the docs gate (was blanket full)" push docs true README.md
expect_route "text documentation uses the docs gate" push docs true docs/guide.txt
expect_route "AgentChorus skill instructions use the docs gate" push docs true skills/agent-chorus/SKILL.md
# GH-28 follow-up: consult.sh always writes .txt sidecars (NO-CITATION.txt, PROVENANCE.txt,
# DEGRADED-SINGLE-MODEL.txt) alongside each relay-system/ transcript. Before this, a lone sidecar
# fell through to the catch-all `docs_only=false` branch, forcing a transcript-only push onto the
# full 6-minute local gate instead of the ~2-minute docs gate — observed directly on 2026-08-18.
expect_route "a relay-system .txt sidecar alone uses the docs gate" push docs true "relay-system/2026-08-18/run/NO-CITATION.txt"
expect_route "a relay-system transcript plus its .txt sidecar both use the docs gate" push docs true "relay-system/2026-08-18/run/consult.codex.md" "relay-system/2026-08-18/run/PROVENANCE.txt"
expect_route "ordinary code-only push uses the fast gate" push fast false utils/hq/hq.sh
expect_route "a push touching the kernel still fails closed to full" push full true src/events.js
expect_route "a push touching relay containment still fails closed to full" push full true relay-automation/relay-turn-lib.sh

# The trigger that must NOT be routed. A manual dispatch is someone asking for the whole gate;
# answering with a routed subset answers a different question than the one asked.
out="$(printf '%s\n' README.md | bash "$ROUTER" workflow_dispatch)"
grep -Fqx 'route=full' <<<"$out" \
  && pass "workflow_dispatch stays unconditionally full even for a docs-only path list" \
  || fail "workflow_dispatch was routed away from full: $out"

# ── GH-509: a RENAMED regression test must select full ───────────────────────────────────────────
# This drives a real `git mv` through the exact command the workflow runs, because the defect lives
# in the FLAG, not in the classifier. With git's default rename detection, `--name-only` prints only
# the DESTINATION path — which still exists — so a renamed test reads as an ordinary changed file and
# ci-route.sh's fail-closed branch for a vanished test is never reached. That branch's comment says
# "deleted/renamed"; before this flag it only ever saw deletions.
#
# Asserting on ci-route.sh alone could not catch it: the classifier behaves correctly for whatever
# paths it is handed. The bug is in WHICH paths it is handed.
RENAME_REPO="$WORK/rename-fixture"
git init -q "$RENAME_REPO"
git -C "$RENAME_REPO" config user.email t@t
git -C "$RENAME_REPO" config user.name t
mkdir -p "$RENAME_REPO/test"
printf '#!/usr/bin/env bash\nexit 0\n' >"$RENAME_REPO/test/old-regression.sh"
git -C "$RENAME_REPO" add -A >/dev/null 2>&1
git -C "$RENAME_REPO" commit -q -m seed
RENAME_BASE="$(git -C "$RENAME_REPO" rev-parse HEAD)"
git -C "$RENAME_REPO" mv test/old-regression.sh test/new-regression.sh
git -C "$RENAME_REPO" commit -q -m rename

# The defect, demonstrated rather than described: default rename detection hides the source path.
if [ "$(git -C "$RENAME_REPO" diff --name-only "$RENAME_BASE" HEAD | wc -l | tr -d ' ')" -eq 1 ]; then
  pass "control: plain --name-only reports ONE path for a rename (the source is invisible)"
else
  fail "control failed: git no longer hides the rename source, so this guard's premise is stale"
fi

rename_paths="$(git -C "$RENAME_REPO" diff --no-renames --name-only "$RENAME_BASE" HEAD)"
# CWD must be the FIXTURE: ci-route.sh resolves `[[ -f "$path" ]]` relative to the working
# directory, which is the whole mechanism under test — a vanished source path is what trips the
# fail-closed branch. Run it from the harness root and every fixture path looks vanished, which
# would make this assertion pass for the wrong reason and the edit case below fail outright.
out="$(cd "$RENAME_REPO" && printf '%s\n' "$rename_paths" | bash "$ROUTER" push)"
grep -Fqx 'route=full' <<<"$out" \
  && pass "a renamed regression test selects full (--no-renames surfaces the removal)" \
  || fail "GH-509: a renamed test did not select full — test removal can escape the full gate: $out"

# And the reverse, so this is not simply "renames always full for some other reason": the same
# fixture with the file merely EDITED must not be forced to full.
printf '#!/usr/bin/env bash\nexit 1\n' >"$RENAME_REPO/test/new-regression.sh"
git -C "$RENAME_REPO" add -A >/dev/null 2>&1
git -C "$RENAME_REPO" commit -q -m edit
edit_paths="$(git -C "$RENAME_REPO" diff --no-renames --name-only HEAD~1 HEAD)"
out="$(cd "$RENAME_REPO" && printf '%s\n' "$edit_paths" | bash "$ROUTER" push)"
grep -Fqx 'route=full' <<<"$out" \
  && fail "an ordinary test EDIT was forced to full — the rename rule is over-broad" \
  || pass "an ordinary test edit is not forced to full (the rename rule is not a blanket)"

# ── GH-35: the TIER answers are pinned separately from the route ────────────────────────────────
# route is the CI job shape; tier is the local gate selection. They DELIBERATELY disagree on
# two pinned cases: an unmapped code path routes fast (CI runs its containment list) but stays
# tier 3 locally (the push hook runs the full gate), and an ordinary test edit routes fast but
# is tier 3 — the routing contract's own evidence never weakens its own gate.
expect_tier() {
  local label="$1" event="$2" expected_tier="$3"
  shift 3
  local out
  out="$(route "$event" "$@")"
  if grep -Fqx "tier=$expected_tier" <<<"$out"; then
    pass "$label"
  else
    fail "$label: $out"
  fi
}

expect_tier "docs-only changes are tier 1" pull_request 1 README.md PROJECT/x.md decisions/d.md docs/guide.txt .pdda-mode
expect_tier "text and markdown anywhere are docs (GH-35 widened)" pull_request 1 relay-system/2026-08-18/run/NOTE.txt
expect_tier "HQ utility changes are tier 2" pull_request 2 utils/hq/hq.sh skills/hq/find-hq.sh
expect_tier "releases subsystem (incl. the one non-twin utils/py file) is tier 2" pull_request 2 utils/py/releases_app.py utils/release-lanes.sh
expect_tier "telemetry is tier 2" pull_request 2 utils/telemetry/health-lib.sh
expect_tier "ATE + fuzzing are tier 2" pull_request 2 utils/ate/install.sh utils/fuzzing/fuzz-loop.sh
expect_tier "swe-diagram is tier 2" pull_request 2 utils/swe-diagram/assets/renderer.js
expect_tier "agent-chorus skill code is tier 2 (GH-35 subsystem 7)" pull_request 2 skills/agent-chorus/scripts/agent_chorus.py
expect_tier "agent-chorus SKILL.md stays docs (explanatory markdown)" pull_request 1 skills/agent-chorus/SKILL.md
expect_tier "kernel changes are tier 3" pull_request 3 src/events.js relay-automation/relay-drive.sh
expect_tier "authoritative Python twins are tier 3" pull_request 3 utils/py/relay_drive.py
expect_tier "relay-xyz skill surface is tier 3" pull_request 3 skills/relay-xyz/SKILL.md
expect_tier "an UNMAPPED code path is tier 3 even though route=fast" pull_request 3 tool.js
expect_tier "an ordinary test EDIT is tier 3 (the contract's own evidence)" pull_request 3 test/hq.sh
expect_tier "a test-like path outside test/ and outside a subsystem dir is unmapped" pull_request 3 utils/hq_test.sh
expect_tier "mixed docs + subsystem is tier 2 with PDDA still on" pull_request 2 README.md utils/hq/hq.sh
expect_tier "mixed subsystem + kernel fails closed to tier 3" pull_request 3 utils/hq/hq.sh src/events.js
expect_tier "scheduled runs stay tier 3" schedule 3

# The subsystem registry listing that validate.sh --subsystem consumes: every entry must name
# suites that exist here, or --tier 2 would silently run nothing (the drift half of the guard;
# the TESTS-registration half lives in test/gh35-test-tiers.sh).
out="$(bash "$ROUTER" subsystems 2>&1)"
if grep -Fq $'hq\thq.sh hq-park.sh' <<<"$out"; then
  pass "subsystems listing names hq and its suites"
else
  fail "subsystems listing shape: $out"
fi
set +e
out="$(bash "$ROUTER" subsystems does-not-exist 2>&1)"; rc=$?
set -e
[[ "$rc" -eq 2 && "$out" == *"unknown subsystem"* ]] \
  && pass "an unknown subsystem fails loudly (exit 2)" \
  || fail "unknown subsystem result: rc=$rc out=$out"
out="$(bash "$ROUTER" subsystems hq)"
[[ "$(wc -w <<<"$out")" -eq 12 ]] \
  && pass "subsystems hq lists its 12 suites" \
  || fail "subsystems hq listed $(wc -w <<<"$out") suites: $out"

echo "  ci-route: $PASS pass, $FAIL fail"
exit "$FAIL"
