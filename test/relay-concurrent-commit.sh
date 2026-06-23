#!/usr/bin/env bash
# relay-concurrent-commit.sh — GH-13 regression.
#
# A CONCURRENT PEER commit landing in ROOT during a WORKTREE-ISOLATED turn must be PRESERVED by
# rtl_enforce, never reset/orphaned (this is the 2026-06-23 incident: a driven agy turn's
# commit-bypass guard `git reset --hard`'d and orphaned a peer agent's commit). Also asserts the
# IN-ROOT (direct/attended) commit-bypass behavior is UNCHANGED — a HEAD move there still resets + exit 6.
#
# Unit-tests rtl_enforce directly by setting the RTL_* globals rtl_init/rtl_before establish, so it
# needs no model stub. rtl_enforce `exit`s its shell on a violation, so we run it in a subshell.
source "$(dirname "$0")/_setup.sh" relay-concurrent-commit
LIB="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-turn-lib.sh"
# shellcheck source=relay-automation/relay-turn-lib.sh
source "$LIB"

# committed baseline relay file; .tick gitignored (mirrors the real repo; harmless here)
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf '.tick/\n' >"$A/.gitignore"
git -C "$A" add relay.md .gitignore >/dev/null 2>&1
git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1
BASE="$(git -C "$A" rev-parse HEAD)"
LOG="$WORK/enforce.log"; : >"$LOG"

# --- (1) in-ROOT control: agent self-commit during a NON-isolated turn -> reset + exit 6 (unchanged)
rtl_init "$A" "$A/relay.md" ""
rtl_before
RTL_WT_USED=0
printf 'sneaky\n' >"$A/sneaky.md"
git -C "$A" add sneaky.md >/dev/null 2>&1
git -C "$A" commit -q -m "agent self-commit (in-ROOT)" >/dev/null 2>&1
( rtl_enforce "T1" "agent" "$LOG" "test" ) >/dev/null 2>&1; rc=$?
[ "$rc" -eq 6 ] && pass "in-ROOT self-commit -> exit 6 (documented behavior unchanged)" || fail "in-ROOT should exit 6, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$BASE" ] && pass "in-ROOT: HEAD reset to baseline" || fail "in-ROOT HEAD should reset to BASE"
[ ! -f "$A/sneaky.md" ] && pass "in-ROOT: off-lane committed file removed by reset" || fail "sneaky.md should be gone"

# --- (2) GH-13: worktree-isolated turn + a CONCURRENT PEER commit -> preserved, turn commits on top
git -C "$A" reset --hard "$BASE" >/dev/null 2>&1            # clean slate at baseline
rtl_init "$A" "$A/relay.md" ""
rtl_before                                                  # RTL_BEFORE_HEAD = BASE
RTL_WT_USED=1                                               # simulate a worktree-isolated turn
printf 'peer work\n' >"$A/peer.md"                          # a concurrent PEER commit lands in ROOT:
git -C "$A" add peer.md >/dev/null 2>&1
git -C "$A" commit -q -m "PEER concurrent commit" >/dev/null 2>&1
PEER="$(git -C "$A" rev-parse HEAD)"
printf '\n### Round 1 · Reviewer\n**Verdict:** Changes requested\n' >>"$A/relay.md"   # the turn's own allowlist edit
( rtl_enforce "T2" "agent" "$LOG" "test" ) >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "worktree turn + concurrent peer commit -> exit 0 (no false violation)" || fail "expected exit 0, got $rc"
[ -f "$A/peer.md" ] && pass "GH-13: peer file preserved (not orphaned)" || fail "peer.md was orphaned — GH-13 regression"
git -C "$A" merge-base --is-ancestor "$PEER" HEAD 2>/dev/null && pass "GH-13: peer commit still reachable from HEAD" || fail "peer commit was orphaned from HEAD"
git -C "$A" show --stat HEAD | grep -q "relay.md" && pass "turn committed the relay file ON TOP of the peer commit" || fail "turn should commit relay.md on top"

echo "  relay-concurrent-commit: $PASS pass, $FAIL fail"
