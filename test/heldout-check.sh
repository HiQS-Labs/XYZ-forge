#!/usr/bin/env bash
# heldout-check.sh test — Part C loop held-out anti-gaming validation (#50).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
H="$HERE/../relay-automation/heldout-check.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: heldout-check =="
run(){ OUT="$(bash "$H" "$@" 2>&1)"; RC=$?; }

# visible up + held-out up -> OK (genuine improvement)
run --visible-before 50 --visible-after 55 --held-before 30 --held-after 33 --goal max
[ "$RC" = 0 ] && pass "visible up + held-out up -> OK" || fail "rc=$RC out=$OUT"

# visible up + held-out DOWN -> GAMING (the signature)
run --visible-before 50 --visible-after 55 --held-before 30 --held-after 25 --goal max
{ [ "$RC" = 9 ] && case "$OUT" in *GAMING*) true;; *) false;; esac; } && pass "visible up + held-out down -> GAMING (exit 9)" || fail "rc=$RC out=$OUT"

# visible up + held-out flat -> OK (no regression)
run --visible-before 50 --visible-after 55 --held-before 30 --held-after 30 --goal max
[ "$RC" = 0 ] && pass "visible up + held-out flat -> OK" || fail "rc=$RC out=$OUT"

# visible flat + held-out down -> OK (no visible gain, so not gaming)
run --visible-before 50 --visible-after 50 --held-before 30 --held-after 25 --goal max
[ "$RC" = 0 ] && pass "visible flat + held-out down -> OK (no gain to game)" || fail "rc=$RC out=$OUT"

# visible down -> OK (would be rejected by champion anyway)
run --visible-before 50 --visible-after 40 --held-before 30 --held-after 20 --goal max
[ "$RC" = 0 ] && pass "visible down -> OK (not a gaming case)" || fail "rc=$RC out=$OUT"

# minimize visible (lower better): 100->80 improved, held-out (max) 50->60 up -> OK
run --visible-before 100 --visible-after 80 --held-before 50 --held-after 60 --goal min --held-goal max
[ "$RC" = 0 ] && pass "min visible improved + held-out(max) up -> OK" || fail "rc=$RC out=$OUT"
# minimize visible improved + held-out(max) DOWN -> GAMING
run --visible-before 100 --visible-after 80 --held-before 50 --held-after 40 --goal min --held-goal max
[ "$RC" = 9 ] && pass "min visible improved + held-out(max) down -> GAMING" || fail "rc=$RC out=$OUT"

# held-goal defaults to --goal; held-goal min: visible(max) up, held(min) 20->30 regressed -> GAMING
run --visible-before 1 --visible-after 2 --held-before 20 --held-after 30 --goal max --held-goal min
[ "$RC" = 9 ] && pass "held-goal min: visible up + held(min) up(=regress) -> GAMING" || fail "rc=$RC out=$OUT"

# floats
run --visible-before 0.5 --visible-after 0.7 --held-before 0.9 --held-after 0.8 --goal max
[ "$RC" = 9 ] && pass "float gaming detected" || fail "rc=$RC out=$OUT"

# usage: missing a value
bash "$H" --visible-before 1 --visible-after 2 --held-before 3 >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && pass "missing a value -> usage (exit 2)" || fail "expected 2 got $rc"

echo "  heldout-check: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
