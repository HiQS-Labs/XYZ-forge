#!/usr/bin/env bash
# champion.sh test — Part C loop champion/challenger state (#50).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
C="$HERE/../relay-automation/champion.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: champion =="
D="${TMPDIR:-/tmp}/champion-test.$$"; rm -rf "$D"
trap 'rm -rf "$D"' EXIT

# init (maximize): baseline 50
bash "$C" init "$D" --metric 50 --goal max >/dev/null
[ "$(bash "$C" state "$D" --field metric)" = 50 ] && pass "init sets the baseline champion" || fail "baseline wrong"

# accept on improvement (oracle pass + metric up)
bash "$C" judge "$D" --oracle-pass 1 --metric 55 --spent 10 >/dev/null; rc=$?
{ [ "$rc" = 0 ] && [ "$(bash "$C" state "$D" --field metric)" = 55 ]; } && pass "improvement -> ACCEPT (exit 0), champion=55" || fail "rc=$rc metric=$(bash "$C" state "$D" --field metric)"
[ "$(bash "$C" state "$D" --field no-improve)" = 0 ] && pass "accept resets no-improve streak" || fail "no-improve not reset"

# reject on no improvement (oracle pass, metric down) -> champion KEPT
bash "$C" judge "$D" --oracle-pass 1 --metric 52 --spent 10 >/dev/null; rc=$?
{ [ "$rc" = 11 ] && [ "$(bash "$C" state "$D" --field metric)" = 55 ]; } && pass "no-improvement -> REJECT (exit 11), champion still 55 (no-regress)" || fail "rc=$rc metric=$(bash "$C" state "$D" --field metric)"
[ "$(bash "$C" state "$D" --field no-improve)" = 1 ] && pass "reject increments no-improve streak" || fail "no-improve not incremented"

# reject on oracle failure (even if metric looks better) -> champion KEPT
bash "$C" judge "$D" --oracle-pass 0 --metric 99 --spent 10 >/dev/null; rc=$?
{ [ "$rc" = 11 ] && [ "$(bash "$C" state "$D" --field metric)" = 55 ]; } && pass "oracle fail -> REJECT even with a 'better' metric (champion still 55)" || fail "rc=$rc metric=$(bash "$C" state "$D" --field metric)"

# cumulative spend accumulated across the 3 judges (10+10+10)
[ "$(bash "$C" state "$D" --field spent)" = 30 ] && pass "cumulative spend accumulates (30)" || fail "spent=$(bash "$C" state "$D" --field spent)"
[ "$(bash "$C" state "$D" --field iteration)" = 3 ] && pass "iteration count = 3" || fail "iter wrong"

# provenance log: baseline + 3 judgements = 4 lines
[ "$(/usr/bin/grep -c . "$D/provenance.jsonl")" = 4 ] && pass "provenance.jsonl has baseline + 3 records" || fail "provenance line count wrong"

# minimize goal: lower is better
Dm="${TMPDIR:-/tmp}/champion-min.$$"; rm -rf "$Dm"
bash "$C" init "$Dm" --metric 100 --goal min >/dev/null
bash "$C" judge "$Dm" --oracle-pass 1 --metric 80 >/dev/null; rc=$?
{ [ "$rc" = 0 ] && [ "$(bash "$C" state "$Dm" --field metric)" = 80 ]; } && pass "min goal: 80<100 -> ACCEPT" || fail "min accept rc=$rc"
bash "$C" judge "$Dm" --oracle-pass 1 --metric 90 >/dev/null; rc=$?
{ [ "$rc" = 11 ] && [ "$(bash "$C" state "$Dm" --field metric)" = 80 ]; } && pass "min goal: 90>80 -> REJECT, champion 80 kept" || fail "min reject rc=$rc"
rm -rf "$Dm"

# usage guards
bash "$C" init "${TMPDIR:-/tmp}/champion-bad.$$" --metric notanumber >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && pass "non-numeric baseline -> usage (exit 2)" || fail "expected 2 got $rc"
bash "$C" judge "$D" --oracle-pass 7 --metric 1 >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && pass "bad --oracle-pass -> usage (exit 2)" || fail "expected 2 got $rc"

echo "  champion: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
