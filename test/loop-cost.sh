#!/usr/bin/env bash
# loop-cost.sh test — Part C loop honest spend capture (#50).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
L="$HERE/../relay-automation/loop-cost.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: loop-cost =="
# run -> OUT (stdout scalar), HON (stderr honesty line), RC
# HON = last stderr line = the honesty flag (exact|floor); any advisory note precedes it.
run(){ ERRF="${TMPDIR:-/tmp}/lc-err.$$"; OUT="$(bash "$L" "$@" 2>"$ERRF")"; RC=$?; HON="$(tail -1 "$ERRF")"; rm -f "$ERRF"; }

# seconds is exact for every agent (the default currency)
run --agent codex --wall-clock-sec 42
{ [ "$RC" = 0 ] && [ "$OUT" = 42 ] && [ "$HON" = exact ]; } && pass "seconds (codex): 42 exact" || fail "rc=$RC out=$OUT hon=$HON"
run --agent agy --currency seconds --wall-clock-sec 30
{ [ "$OUT" = 30 ] && [ "$HON" = exact ]; } && pass "seconds (agy): exact too — wall-clock is universal" || fail "out=$OUT hon=$HON"

# tokens exact for codex/claude/gemini
run --agent codex --currency tokens --tokens 1500
{ [ "$OUT" = 1500 ] && [ "$HON" = exact ]; } && pass "tokens (codex): 1500 exact" || fail "out=$OUT hon=$HON"
run --agent claude --currency tokens --tokens 900
{ [ "$OUT" = 900 ] && [ "$HON" = exact ]; } && pass "tokens (claude): 900 exact" || fail "out=$OUT hon=$HON"

# tokens for agy -> floor 0 (cost-blind), honestly flagged
run --agent agy --currency tokens --tokens 9999
{ [ "$OUT" = 0 ] && [ "$HON" = floor ]; } && pass "tokens (agy): floor 0 (cost-blind, uncounted)" || fail "out=$OUT hon=$HON"

# usage: tokens currency without --tokens (non-agy)
bash "$L" --agent codex --currency tokens >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && pass "tokens without --tokens -> usage (exit 2)" || fail "expected 2 got $rc"
# usage: seconds without --wall-clock-sec
bash "$L" --agent codex --currency seconds >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && pass "seconds without --wall-clock-sec -> usage (exit 2)" || fail "expected 2 got $rc"
# usage: no agent
bash "$L" --wall-clock-sec 5 >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && pass "no --agent -> usage (exit 2)" || fail "expected 2 got $rc"

echo "  loop-cost: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
