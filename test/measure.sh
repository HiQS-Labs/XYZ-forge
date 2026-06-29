#!/usr/bin/env bash
# measure.sh test — the Part C self-improvement-loop metric-capture primitive (#50).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
M="$HERE/../relay-automation/measure.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: measure =="

out="$(bash "$M" -c 'echo 42')"; rc=$?
{ [ "$rc" = 0 ] && [ "$out" = 42 ]; } && pass "extracts a clean integer" || fail "rc=$rc out=$out"

out="$(bash "$M" -c 'echo building...; echo crunching; echo 17')"
[ "$out" = 17 ] && pass "parses the LAST non-empty line (ignores log lines)" || fail "got '$out'"

out="$(bash "$M" -c 'echo 3.14')"; [ "$out" = 3.14 ] && pass "decimal metric ok" || fail "decimal got '$out'"
out="$(bash "$M" -c 'printf "%s\n" -5')"; [ "$out" = -5 ] && pass "negative metric ok" || fail "negative got '$out'"

bash "$M" -c 'echo not_a_number' >/dev/null 2>&1; rc=$?
[ "$rc" = 4 ] && pass "rejects a non-numeric last line (exit 4)" || fail "expected 4 got $rc"

bash "$M" -c 'echo 1 2' >/dev/null 2>&1; rc=$?
[ "$rc" = 4 ] && pass "rejects a multi-token last line (exit 4)" || fail "expected 4 got $rc"

bash "$M" -c 'echo 5; exit 1' >/dev/null 2>&1; rc=$?
[ "$rc" = 3 ] && pass "measure-cmd non-zero exit -> exit 3" || fail "expected 3 got $rc"

out="$(bash "$M" --check-deterministic -c 'echo 7')"; rc=$?
{ [ "$rc" = 0 ] && [ "$out" = 7 ]; } && pass "--check-deterministic passes on a stable metric" || fail "rc=$rc out=$out"

# a metric that changes every run (counter file) must be rejected as noise
T="${TMPDIR:-/tmp}/measure-noise.$$"; echo 0 >"$T"
NOISY='n=$(cat '"$T"'); n=$((n+1)); echo "$n" >'"$T"'; echo "$n"'
bash "$M" --check-deterministic -c "$NOISY" >/dev/null 2>&1; rc=$?
[ "$rc" = 5 ] && pass "--check-deterministic rejects a noisy metric (exit 5)" || fail "expected 5 got $rc"
rm -f "$T"

ERR="${TMPDIR:-/tmp}/measure-err.$$"
out="$(bash "$M" -c 'echo "12 floor"' 2>"$ERR")"
{ [ "$out" = 12 ] && /usr/bin/grep -q '^floor$' "$ERR"; } && pass "floor marker: emits number + floor note on stderr" || fail "floor got '$out'"
rm -f "$ERR"

out="$(bash "$M" -- printf '%s\n' 99)"; [ "$out" = 99 ] && pass "argv (--) mode" || fail "argv got '$out'"

bash "$M" >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && pass "no command -> usage (exit 2)" || fail "expected 2 got $rc"

echo "  measure: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
