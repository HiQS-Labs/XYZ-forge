#!/usr/bin/env bash
# loop-stop.sh test — the Part C loop's guaranteed-halt stop-condition evaluator (#50).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
S="$HERE/../relay-automation/loop-stop.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: loop-stop =="

# helper: run; capture stdout + rc
run(){ OUT="$(bash "$S" "$@" 2>/dev/null)"; RC=$?; }

run --iteration 0 --max-iterations 5
{ [ "$RC" = 0 ] && [ "$OUT" = CONTINUE ]; } && pass "continues when nothing triggers" || fail "rc=$RC out=$OUT"

run --iteration 5 --max-iterations 5
{ [ "$RC" = 10 ] && case "$OUT" in STOP\ iteration-cap*) true;; *) false;; esac; } && pass "iteration cap -> STOP iteration-cap (exit 10)" || fail "rc=$RC out=$OUT"

run --iteration 1 --max-iterations 5 --metric 60 --target 55 --goal max
{ [ "$RC" = 10 ] && case "$OUT" in STOP\ target-reached*) true;; *) false;; esac; } && pass "target reached (max: 60>=55)" || fail "rc=$RC out=$OUT"

run --iteration 1 --max-iterations 5 --metric 50 --target 55 --goal min
{ [ "$RC" = 10 ] && case "$OUT" in STOP\ target-reached*) true;; *) false;; esac; } && pass "target reached (min: 50<=55)" || fail "rc=$RC out=$OUT"

run --iteration 1 --max-iterations 5 --metric 50 --target 55 --goal max
{ [ "$RC" = 0 ] && [ "$OUT" = CONTINUE ]; } && pass "target NOT reached (max: 50<55) -> continue" || fail "rc=$RC out=$OUT"

run --iteration 1 --max-iterations 5 --spent 100 --max-total-budget 100
{ [ "$RC" = 10 ] && case "$OUT" in STOP\ budget-exhausted*) true;; *) false;; esac; } && pass "budget exhausted (100>=100)" || fail "rc=$RC out=$OUT"

run --iteration 1 --max-iterations 5 --spent 50 --max-total-budget 100
{ [ "$RC" = 0 ] && [ "$OUT" = CONTINUE ]; } && pass "budget not exhausted -> continue" || fail "rc=$RC out=$OUT"

run --iteration 1 --max-iterations 5 --no-improve 3 --plateau 3
{ [ "$RC" = 10 ] && case "$OUT" in STOP\ plateau*) true;; *) false;; esac; } && pass "plateau (3>=3) -> STOP plateau" || fail "rc=$RC out=$OUT"

# precedence: cap AND target both true -> target wins (checked first)
run --iteration 5 --max-iterations 5 --metric 60 --target 55 --goal max
case "$OUT" in STOP\ target-reached*) pass "precedence: target reported over cap";; *) fail "expected target precedence, got $OUT";; esac

# guaranteed halt: no budget/plateau/target, just the cap
run --iteration 9 --max-iterations 9
{ [ "$RC" = 10 ] && case "$OUT" in STOP\ iteration-cap*) true;; *) false;; esac; } && pass "guaranteed halt via the cap alone" || fail "rc=$RC out=$OUT"

# float metric/target
run --iteration 1 --max-iterations 5 --metric 3.14 --target 3.0 --goal max
case "$OUT" in STOP\ target-reached*) pass "float comparison (3.14>=3.0)";; *) fail "float got $OUT";; esac

# --max-iterations is required (the halt guarantee)
bash "$S" --iteration 0 >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && pass "missing --max-iterations -> usage (exit 2)" || fail "expected 2 got $rc"
bash "$S" --iteration 0 --max-iterations 0 >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && pass "non-positive --max-iterations -> usage (exit 2)" || fail "expected 2 got $rc"

echo "  loop-stop: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
