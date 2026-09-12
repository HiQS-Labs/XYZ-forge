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
expect_route "releases DB changes run the releases subsystem gate (GH-496)" pull_request fast false releases.sql releases.db
expect_route "wave_reconcile changes run the PDDA subsystem gate (GH-496)" pull_request fast true utils/py/wave_reconcile.py
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
expect_tier "releases DB and dump files are tier 2 (GH-496)" pull_request 2 releases.sql releases.db
expect_tier "releases utilities are tier 2 (GH-496)" pull_request 2 utils/releases-merge-resolve.sh utils/leaderboard.sh
expect_tier "wave_reconcile is tier 2 under PDDA (GH-496)" pull_request 2 utils/py/wave_reconcile.py
expect_tier "telemetry is tier 2" pull_request 2 utils/telemetry/health-lib.sh
expect_tier "ATE + fuzzing are tier 2" pull_request 2 utils/ate/install.sh utils/fuzzing/fuzz-loop.sh
expect_tier "swe-diagram is tier 2" pull_request 2 utils/swe-diagram/assets/renderer.js
expect_tier "agent-chorus skill code is tier 2 (GH-35 subsystem 7)" pull_request 2 skills/agent-chorus/scripts/agent_chorus.py
expect_tier "agent-chorus SKILL.md stays docs (explanatory markdown)" pull_request 1 skills/agent-chorus/SKILL.md
expect_tier "kernel changes are tier 3" pull_request 3 src/events.js
expect_tier "authoritative Python twins are tier 3" pull_request 3 utils/py/relay_drive.py
expect_tier "relay-xyz skill surface is tier 3" pull_request 3 skills/relay-xyz/SKILL.md
expect_tier "an UNMAPPED code path is tier 3 even though route=fast" pull_request 3 relay-automation/relay-turn-lib.sh
expect_tier "an ordinary test EDIT is tier 3 (the contract's own evidence)" pull_request 3 test/some-suite.sh
expect_tier "a test-like path outside test/ and outside a subsystem dir is unmapped" pull_request 3 fixtures/mock-test.sh
expect_tier "mixed docs + subsystem is tier 2 with PDDA still on" pull_request 2 README.md utils/hq/hq.sh
expect_tier "mixed subsystem + kernel fails closed to tier 3" pull_request 3 utils/hq/hq.sh src/events.js
expect_tier "scheduled runs stay tier 3" schedule 3

# GH-487 registered-skill contract tests: a modified registered skill with code + dedicated test
# is classified as tier 2 (the fast path), but an unregistered skill or a missing dedicated test
# fails closed into tier 3.
expect_tier "a registered skill + its code + its dedicated tests is tier 2 (GH-487)" pull_request 2 skills/skills-army-hq/scripts/intake.py test/skills-army-hq.sh
expect_tier "a dedicated test edited ALONE stays tier 3 (co-touch requirement, GH-487)" pull_request 3 test/skills-army-hq.sh
expect_tier "shared Python test integration still escalates beside skill code (GH-487)" pull_request 3 skills/skills-army-hq/scripts/intake.py test/test_python_layer.py
expect_tier "a TESTS-RESULTS receipt alone uses the docs gate (GH-487)" pull_request 1 TESTS-RESULTS/2026-09-08+GH-487/evidence.jsonl
expect_tier "a TESTS-RESULTS receipt alone is tier 1 (GH-487)" pull_request 1 TESTS-RESULTS/2026-09-08+GH-487/evidence.jsonl
expect_tier "a receipt beside subsystem code keeps the subsystem gate (GH-487)" pull_request 2 TESTS-RESULTS/2026-09-08+GH-487/evidence.jsonl utils/hq/hq.sh

# A DELETED dedicated suite fails closed into the full gate: move the real wrapper away so the
# CWD-relative existence check sees the deletion — the rename fixture's mechanism, GH-487 form.
SKILLS_SUITE="$ROOT/test/skills-army-hq.sh"
if [ -f "$SKILLS_SUITE" ]; then
  mv "$SKILLS_SUITE" "$WORK/skills-army-hq.sh.stash"
  out="$(route push test/skills-army-hq.sh || true)"
  mv "$WORK/skills-army-hq.sh.stash" "$SKILLS_SUITE"
  grep -Fqx 'route=full' <<<"$out" \
    && pass "a deleted dedicated suite fails closed into the full gate (GH-487)" \
    || fail "deleted dedicated suite did not fail closed: $out"
else
  fail "test/skills-army-hq.sh missing — the GH-487 deletion control cannot run"
fi

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
[[ "$(wc -w <<<"$out")" -eq 13 ]] \
  && pass "subsystems hq lists its 13 suites" \
  || fail "subsystems hq listed $(wc -w <<<"$out") suites: $out"
out="$(bash "$ROUTER" subsystems releases)"
[[ "$(wc -w <<<"$out")" -eq 21 ]] \
  && pass "subsystems releases lists its 21 suites (GH-496; +gh549-work-events; -roadmap-dashboard)" \
  || fail "subsystems releases listed $(wc -w <<<"$out") suites: $out"
out="$(bash "$ROUTER" subsystems pdda)"
[[ "$(wc -w <<<"$out")" -eq 12 ]] \
  && pass "subsystems pdda lists its 12 suites (GH-496)" \
  || fail "subsystems pdda listed $(wc -w <<<"$out") suites: $out"
out="$(bash "$ROUTER" subsystems skills-army-hq)"
[[ "$(wc -w <<<"$out")" -eq 1 ]] \
  && pass "subsystems skills-army-hq lists its dedicated suite (GH-487)" \
  || fail "subsystems skills-army-hq listed $(wc -w <<<"$out") suites: $out"

# ── GH-496: validate.sh append-only test registration routing ─────────────────────────────────
# When validate.sh only appends new test suites to its TESTS array, it should route to fast/Tier-2
# and add the new test(s) to changed_tests.
# If validate.sh is modified in any other way (deletions, non-test logic, syntax error, top-level
# script additions, invalid base, multi-commit dirty base), it MUST fail closed to route=full (tier 3).

VALIDATE_REPO="$WORK/validate-fixture"
git init -q "$VALIDATE_REPO"
git -C "$VALIDATE_REPO" config user.email t@t
git -C "$VALIDATE_REPO" config user.name t
mkdir -p "$VALIDATE_REPO/test" "$VALIDATE_REPO/utils/hq"
printf '#!/usr/bin/env bash\nTESTS=(\n  "existing-test.sh"\n)\n' >"$VALIDATE_REPO/validate.sh"
chmod +x "$VALIDATE_REPO/validate.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"$VALIDATE_REPO/test/existing-test.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"$VALIDATE_REPO/test/hq.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"$VALIDATE_REPO/utils/hq/hq.sh"
git -C "$VALIDATE_REPO" add -A >/dev/null 2>&1
git -C "$VALIDATE_REPO" commit -q -m seed
VALIDATE_BASE="$(git -C "$VALIDATE_REPO" rev-parse HEAD)"

# Case 1: Append-only test registration in validate.sh + new test suite
printf '#!/usr/bin/env bash\nTESTS=(\n  "existing-test.sh"\n  "new-test.sh" # GH-496 (new test)\n)\n' >"$VALIDATE_REPO/validate.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"$VALIDATE_REPO/test/new-test.sh"
git -C "$VALIDATE_REPO" add -A >/dev/null 2>&1
git -C "$VALIDATE_REPO" commit -q -m "append new test"

val_paths="$(git -C "$VALIDATE_REPO" diff --no-renames --name-only "$VALIDATE_BASE" HEAD)"
out="$(printf '%s\n' "$val_paths" | (cd "$VALIDATE_REPO" && CI_BASE="$VALIDATE_BASE" bash "$ROUTER" push))"
if grep -Fqx 'route=fast' <<<"$out" && grep -Fq 'changed_tests=new-test.sh' <<<"$out"; then
  pass "append-only test addition in validate.sh routes to fast and extracts changed test"
else
  fail "append-only test addition in validate.sh did not route to fast: $out"
fi

# Case 2: Append-only test registration beside a subsystem update + its dedicated test routes to tier 2
CASE2_BASE="$(git -C "$VALIDATE_REPO" rev-parse HEAD)"
mkdir -p "$VALIDATE_REPO/skills/skills-army-hq/scripts"
printf '#!/usr/bin/env python3\n' >"$VALIDATE_REPO/skills/skills-army-hq/scripts/intake.py"
printf '#!/usr/bin/env bash\nexit 0\n' >"$VALIDATE_REPO/test/skills-army-hq.sh"
printf '#!/usr/bin/env bash\nTESTS=(\n  "existing-test.sh"\n  "new-test.sh" # GH-496 (new test)\n  "skills-army-hq.sh"\n)\n' >"$VALIDATE_REPO/validate.sh"
git -C "$VALIDATE_REPO" add -A >/dev/null 2>&1
git -C "$VALIDATE_REPO" commit -q -m "append skills suite beside skill code and test"
val_paths_sub="$(git -C "$VALIDATE_REPO" diff --no-renames --name-only "$CASE2_BASE" HEAD)"
out_sub="$(printf '%s\n' "$val_paths_sub" | (cd "$VALIDATE_REPO" && CI_BASE="$CASE2_BASE" bash "$ROUTER" push))"
if grep -Fqx 'route=fast' <<<"$out_sub" && grep -Fqx 'tier=2' <<<"$out_sub" && grep -Fq 'skills-army-hq.sh' <<<"$out_sub"; then
  pass "append-only test addition in validate.sh beside subsystem code + dedicated test preserves tier 2"
else
  fail "append-only test addition in validate.sh beside subsystem code failed tier 2: $out_sub"
fi

# Case 3: Non-append addition in validate.sh (e.g. adding variable / runner logic) fails closed to full
printf '#!/usr/bin/env bash\nMAX_JOBS=4\nTESTS=(\n  "existing-test.sh"\n  "new-test.sh"\n)\n' >"$VALIDATE_REPO/validate.sh"
git -C "$VALIDATE_REPO" add -A >/dev/null 2>&1
git -C "$VALIDATE_REPO" commit -q -m "edit runner variable"
val_paths_var="$(git -C "$VALIDATE_REPO" diff --no-renames --name-only "$VALIDATE_BASE" HEAD)"
out_var="$(printf '%s\n' "$val_paths_var" | (cd "$VALIDATE_REPO" && CI_BASE="$VALIDATE_BASE" bash "$ROUTER" push))"
if grep -Fqx 'route=full' <<<"$out_var" && grep -Fqx 'tier=3' <<<"$out_var"; then
  pass "non-append code addition in validate.sh fails closed to route=full tier=3"
else
  fail "non-append code addition in validate.sh did not fail closed: $out_var"
fi

# Case 4: Deletion in validate.sh fails closed to full
printf '#!/usr/bin/env bash\nTESTS=(\n  "new-test.sh"\n)\n' >"$VALIDATE_REPO/validate.sh"
git -C "$VALIDATE_REPO" add -A >/dev/null 2>&1
git -C "$VALIDATE_REPO" commit -q -m "delete existing test"
val_paths_del="$(git -C "$VALIDATE_REPO" diff --no-renames --name-only "$VALIDATE_BASE" HEAD)"
out_del="$(printf '%s\n' "$val_paths_del" | (cd "$VALIDATE_REPO" && CI_BASE="$VALIDATE_BASE" bash "$ROUTER" push))"
if grep -Fqx 'route=full' <<<"$out_del" && grep -Fqx 'tier=3' <<<"$out_del"; then
  pass "deletion in validate.sh fails closed to route=full tier=3"
else
  fail "deletion in validate.sh did not fail closed: $out_del"
fi

# Case 5: Syntax error in validate.sh fails closed to full
printf '#!/usr/bin/env bash\nTESTS=(\n  "new-test.sh"\n' >"$VALIDATE_REPO/validate.sh"
git -C "$VALIDATE_REPO" add -A >/dev/null 2>&1
git -C "$VALIDATE_REPO" commit -q -m "syntax error"
val_paths_syn="$(git -C "$VALIDATE_REPO" diff --no-renames --name-only "$VALIDATE_BASE" HEAD)"
out_syn="$(printf '%s\n' "$val_paths_syn" | (cd "$VALIDATE_REPO" && CI_BASE="$VALIDATE_BASE" bash "$ROUTER" push))"
if grep -Fqx 'route=full' <<<"$out_syn" && grep -Fqx 'tier=3' <<<"$out_syn"; then
  pass "syntax error in validate.sh fails closed to route=full tier=3"
else
  fail "syntax error in validate.sh did not fail closed: $out_syn"
fi

# Case 6: Top-level line addition outside TESTS array (e.g. command injection attempt) fails closed to full
printf '#!/usr/bin/env bash\nTESTS=(\n  "existing-test.sh"\n  "new-test.sh"\n)\n"payload.sh"\n' >"$VALIDATE_REPO/validate.sh"
git -C "$VALIDATE_REPO" add -A >/dev/null 2>&1
git -C "$VALIDATE_REPO" commit -q -m "top level payload addition"
val_paths_payload="$(git -C "$VALIDATE_REPO" diff --no-renames --name-only "$VALIDATE_BASE" HEAD)"
out_payload="$(printf '%s\n' "$val_paths_payload" | (cd "$VALIDATE_REPO" && CI_BASE="$VALIDATE_BASE" bash "$ROUTER" push))"
if grep -Fqx 'route=full' <<<"$out_payload" && grep -Fqx 'tier=3' <<<"$out_payload"; then
  pass "top-level addition outside TESTS array fails closed to route=full tier=3"
else
  fail "top-level addition outside TESTS array did not fail closed: $out_payload"
fi

# Case 7: Multi-commit push where earlier commit modified runner logic and last commit was append-only
MULTI_REPO="$WORK/multi-commit-fixture"
git init -q "$MULTI_REPO"
git -C "$MULTI_REPO" config user.email t@t
git -C "$MULTI_REPO" config user.name t
mkdir -p "$MULTI_REPO/test"
printf '#!/usr/bin/env bash\nTESTS=(\n  "existing-test.sh"\n)\n' >"$MULTI_REPO/validate.sh"
chmod +x "$MULTI_REPO/validate.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"$MULTI_REPO/test/existing-test.sh"
git -C "$MULTI_REPO" add -A >/dev/null 2>&1
git -C "$MULTI_REPO" commit -q -m seed
MULTI_BASE="$(git -C "$MULTI_REPO" rev-parse HEAD)"

# Commit 1: runner logic change (forbidden)
printf '#!/usr/bin/env bash\nRUNNER_MODE=custom\nTESTS=(\n  "existing-test.sh"\n)\n' >"$MULTI_REPO/validate.sh"
git -C "$MULTI_REPO" add -A >/dev/null 2>&1
git -C "$MULTI_REPO" commit -q -m "commit 1: runner mode edit"

# Commit 2: append new test (append-only relative to commit 1, but dirty relative to MULTI_BASE)
printf '#!/usr/bin/env bash\nRUNNER_MODE=custom\nTESTS=(\n  "existing-test.sh"\n  "new-test.sh"\n)\n' >"$MULTI_REPO/validate.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"$MULTI_REPO/test/new-test.sh"
git -C "$MULTI_REPO" add -A >/dev/null 2>&1
git -C "$MULTI_REPO" commit -q -m "commit 2: append new test"

multi_paths="$(git -C "$MULTI_REPO" diff --no-renames --name-only "$MULTI_BASE" HEAD)"
out_multi="$(printf '%s\n' "$multi_paths" | (cd "$MULTI_REPO" && CI_BASE="$MULTI_BASE" bash "$ROUTER" push))"
if grep -Fqx 'route=full' <<<"$out_multi" && grep -Fqx 'tier=3' <<<"$out_multi"; then
  pass "multi-commit push with earlier runner edit fails closed to route=full tier=3 across full range"
else
  fail "multi-commit push with earlier runner edit did not fail closed: $out_multi"
fi

# Case 8: Invalid / non-existent explicit base fails closed
out_bad_base="$(printf '%s\n' "validate.sh" | (cd "$VALIDATE_REPO" && CI_BASE="nonexistent_base_sha" bash "$ROUTER" push))"
if grep -Fqx 'route=full' <<<"$out_bad_base" && grep -Fqx 'tier=3' <<<"$out_bad_base"; then
  pass "invalid explicit CI_BASE fails closed to route=full tier=3"
else
  fail "invalid explicit CI_BASE did not fail closed: $out_bad_base"
fi

# Case 9: All-zeros explicit base fails closed
out_zero_base="$(printf '%s\n' "validate.sh" | (cd "$VALIDATE_REPO" && CI_BASE="0000000000000000000000000000000000000000" bash "$ROUTER" push))"
if grep -Fqx 'route=full' <<<"$out_zero_base" && grep -Fqx 'tier=3' <<<"$out_zero_base"; then
  pass "all-zeros explicit CI_BASE fails closed to route=full tier=3"
else
  fail "all-zeros explicit CI_BASE did not fail closed: $out_zero_base"
fi

# Case 10: Missing/nonexistent validate.sh on disk fails closed
MISSING_REPO="$WORK/missing-fixture"
git init -q "$MISSING_REPO"
git -C "$MISSING_REPO" config user.email t@t
git -C "$MISSING_REPO" config user.name t
mkdir -p "$MISSING_REPO/test"
printf '#!/usr/bin/env bash\nexit 0\n' >"$MISSING_REPO/test/dummy.sh"
git -C "$MISSING_REPO" add -A >/dev/null 2>&1
git -C "$MISSING_REPO" commit -q -m seed
out_missing="$(printf '%s\n' "validate.sh" | (cd "$MISSING_REPO" && bash "$ROUTER" push))"
if grep -Fqx 'route=full' <<<"$out_missing" && grep -Fqx 'tier=3' <<<"$out_missing"; then
  pass "missing validate.sh on disk fails closed to route=full tier=3"
else
  fail "missing validate.sh on disk did not fail closed: $out_missing"
fi

# Case 11: Non-git directory diff failure fails closed
NON_GIT_DIR="$WORK/non-git-fixture"
mkdir -p "$NON_GIT_DIR"
printf '#!/usr/bin/env bash\nTESTS=(\n  "new.sh"\n)\n' >"$NON_GIT_DIR/validate.sh"
out_non_git="$(printf '%s\n' "validate.sh" | (cd "$NON_GIT_DIR" && bash "$ROUTER" push))"
if grep -Fqx 'route=full' <<<"$out_non_git" && grep -Fqx 'tier=3' <<<"$out_non_git"; then
  pass "non-git directory diff failure fails closed to route=full tier=3"
else
  fail "non-git directory diff failure did not fail closed: $out_non_git"
fi

# Case 12: In-array comment deletion / modification while adding suite fails closed
COMMENT_REPO="$WORK/comment-fixture"
git init -q "$COMMENT_REPO"
git -C "$COMMENT_REPO" config user.email t@t
git -C "$COMMENT_REPO" config user.name t
mkdir -p "$COMMENT_REPO/test"
printf '#!/usr/bin/env bash\nTESTS=(\n  # Section 1\n  "existing-test.sh"\n)\n' >"$COMMENT_REPO/validate.sh"
chmod +x "$COMMENT_REPO/validate.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"$COMMENT_REPO/test/existing-test.sh"
git -C "$COMMENT_REPO" add -A >/dev/null 2>&1
git -C "$COMMENT_REPO" commit -q -m seed
COMMENT_BASE="$(git -C "$COMMENT_REPO" rev-parse HEAD)"

# Delete '# Section 1' comment and add new test
printf '#!/usr/bin/env bash\nTESTS=(\n  "existing-test.sh"\n  "new-test.sh"\n)\n' >"$COMMENT_REPO/validate.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"$COMMENT_REPO/test/new-test.sh"
git -C "$COMMENT_REPO" add -A >/dev/null 2>&1
git -C "$COMMENT_REPO" commit -q -m "delete comment and add test"

comm_paths="$(git -C "$COMMENT_REPO" diff --no-renames --name-only "$COMMENT_BASE" HEAD)"
out_comm="$(printf '%s\n' "$comm_paths" | (cd "$COMMENT_REPO" && CI_BASE="$COMMENT_BASE" bash "$ROUTER" push))"
if grep -Fqx 'route=full' <<<"$out_comm" && grep -Fqx 'tier=3' <<<"$out_comm"; then
  pass "in-array comment deletion while adding suite fails closed to route=full tier=3"
else
  fail "in-array comment deletion did not fail closed: $out_comm"
fi

# Case 13: Forced git diff failure (rc > 1) with working git show fails closed
FORCED_DIFF_REPO="$WORK/forced-diff-fixture"
git init -q "$FORCED_DIFF_REPO"
git -C "$FORCED_DIFF_REPO" config user.email t@t
git -C "$FORCED_DIFF_REPO" config user.name t
mkdir -p "$FORCED_DIFF_REPO/test" "$WORK/fake-git-bin"
printf '#!/usr/bin/env bash\nTESTS=(\n  "existing-test.sh"\n)\n' >"$FORCED_DIFF_REPO/validate.sh"
chmod +x "$FORCED_DIFF_REPO/validate.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"$FORCED_DIFF_REPO/test/existing-test.sh"
git -C "$FORCED_DIFF_REPO" add -A >/dev/null 2>&1
git -C "$FORCED_DIFF_REPO" commit -q -m seed

# Append-only working tree change (valid diff content if diff were executed)
printf '#!/usr/bin/env bash\nTESTS=(\n  "existing-test.sh"\n  "new-test.sh"\n)\n' >"$FORCED_DIFF_REPO/validate.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"$FORCED_DIFF_REPO/test/new-test.sh"

# Mock git wrapper that rejects 'diff' with exit 128 while delegating all other calls to real git
REAL_GIT="$(command -v git)"
cat << EOF > "$WORK/fake-git-bin/git"
#!/usr/bin/env bash
for arg in "\$@"; do
  if [ "\$arg" = "diff" ]; then
    exit 128
  fi
done
exec "$REAL_GIT" "\$@"
EOF
chmod +x "$WORK/fake-git-bin/git"

out_forced="$(printf '%s\n' "validate.sh" | (cd "$FORCED_DIFF_REPO" && PATH="$WORK/fake-git-bin:$PATH" bash "$ROUTER" push))"
if grep -Fqx 'route=full' <<<"$out_forced" && grep -Fqx 'tier=3' <<<"$out_forced"; then
  pass "forced git diff failure (rc > 1) with working git show fails closed to route=full tier=3"
else
  fail "forced git diff failure did not fail closed: $out_forced"
fi

echo "  ci-route: $PASS pass, $FAIL fail"
exit "$FAIL"
