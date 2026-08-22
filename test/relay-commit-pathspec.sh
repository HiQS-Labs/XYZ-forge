#!/usr/bin/env bash
# relay-commit-pathspec.sh — GH-198 Bug 1 regression.
#
# rtl_enforce's "file-scoped" commit (relay-turn-lib.sh) must NOT sweep pre-existing staged content
# that isn't on the turn's own allowlist into the relay's commit. A bare `git commit` (no pathspec)
# commits the WHOLE staged index; a turn that starts with unrelated staged content already in the
# index (e.g. an operator's own in-progress `git add`, or a rename staged by an earlier unrelated
# edit) used to have that content silently ride along into the relay's auto-commit, under a message
# that only names the relay file (live incident, 2026-07-10/11, reproduced twice driving relay-drive
# --target-root against a repo with pre-existing staged WIP).
#
# Unit-tests rtl_enforce directly (same pattern as relay-concurrent-commit.sh) — no model stub needed.
source "$(dirname "$0")/_setup.sh" relay-commit-pathspec
LIB="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-turn-lib.sh"
# shellcheck source=relay-automation/relay-turn-lib.sh
source "$LIB"

printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf '.tick/\n' >"$A/.gitignore"
git -C "$A" add relay.md .gitignore >/dev/null 2>&1
git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1
BASE="$(git -C "$A" rev-parse HEAD)"
LOG="$WORK/enforce.log"; : >"$LOG"

# --- (1) pre-existing staged, off-allowlist content must NOT ride along into the relay commit ---
rtl_init "$A" "$A/relay.md" ""
# Stage the unrelated WIP BEFORE rtl_before captures the "before" snapshot, so rtl_was_dirty_before
# correctly recognizes it as pre-existing ambient WIP (never enforced/reverted) — mirroring the real
# incident: the operator's own in-progress staged edit was already in the index when the turn began.
printf 'unrelated pre-existing WIP\n' >"$A/unrelated.md"
git -C "$A" add unrelated.md >/dev/null 2>&1
rtl_before
printf '\n### Round 1 · Builder\ndid the thing\n' >>"$A/relay.md"   # the turn's own allowlisted edit
( rtl_enforce "T1" "agent" "$LOG" "test" ) >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "turn with pre-existing staged WIP still exits 0" || fail "expected exit 0, got $rc"
grep -q "relay.md" <<<"$(git -C "$A" show --stat HEAD)" && pass "relay.md is in the new commit" || fail "relay.md missing from the new commit"
grep -q "unrelated.md" <<<"$(git -C "$A" show --stat HEAD)" \
  && fail "GH-198 regression: unrelated.md was swept into the relay commit" \
  || pass "GH-198: unrelated.md NOT swept into the relay commit"
grep -qx "unrelated.md" <<<"$(git -C "$A" diff --cached --name-only)" \
  && pass "unrelated.md remains staged (untouched) after the turn — still the operator's to commit" \
  || fail "unrelated.md should still be staged, not committed or lost"
[ -f "$A/unrelated.md" ] && pass "unrelated.md still present on disk" || fail "unrelated.md should not have disappeared"
git -C "$A" merge-base --is-ancestor "$BASE" HEAD 2>/dev/null && pass "relay commit landed on top of baseline" || fail "unexpected HEAD lineage"

# --- (2) control: a NEW allowlisted artifact still commits correctly alongside the relay file ---
git -C "$A" reset --hard "$BASE" >/dev/null 2>&1
git -C "$A" clean -fd >/dev/null 2>&1
rtl_init "$A" "$A/relay.md" "art.txt"
rtl_before
printf 'built output\n' >"$A/art.txt"
printf '\n### Round 1 · Builder\nbuilt art.txt\n' >>"$A/relay.md"
( rtl_enforce "T2" "agent" "$LOG" "test" ) >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "control: allowlisted artifact turn still exits 0" || fail "control expected exit 0, got $rc"
grep -q "relay.md" <<<"$(git -C "$A" show --stat HEAD)" && pass "control: relay.md committed" || fail "control: relay.md missing"
grep -q "art.txt" <<<"$(git -C "$A" show --stat HEAD)" && pass "control: allowlisted art.txt committed" || fail "control: art.txt missing from commit"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
