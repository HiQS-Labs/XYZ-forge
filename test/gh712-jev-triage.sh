#!/usr/bin/env bash
# test/gh712-jev-triage.sh — GH-712: utils/py/jev_triage.py offline replays, mocked endpoint only.
# Pins: FN/FP/agreement math on a fixture; empty input refused (exit 2); red control (a known-fail
# row answered "pass") counts FN = 1; every row carries model + request/response hashes and no stderr.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
FX="$HERE/fixtures/gh712"
TOOL="$ROOT/utils/py/jev_triage.py"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh712.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT
export PYTHONDONTWRITEBYTECODE=1
unset TYPESAFE_API_KEY TYPESAFE_API_URL

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
jq_py() { python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(eval(sys.argv[2]))" "$1" "$2"; }

echo "== test: gh712-jev-triage =="

# 1. benchmark replay, canned responses that match every label -> FN=0 FP=0, floor met
python3 "$TOOL" benchmark --rows "$FX/bench.jsonl" --out "$WORK/bench" --mock-responses "$FX/bench-responses.json" >/dev/null
[ "$(jq_py "$WORK/bench/summary.json" "d['false_negatives']")" = "0" ] && pass "benchmark FN=0 on matching canned answers" || fail "benchmark FN should be 0"
[ "$(jq_py "$WORK/bench/summary.json" "d['false_positives']")" = "0" ] && pass "benchmark FP=0" || fail "benchmark FP should be 0"
[ "$(jq_py "$WORK/bench/summary.json" "d['fn_floor_met']")" = "True" ] && pass "fn_floor_met true" || fail "fn_floor_met should be true"
[ "$(jq_py "$WORK/bench/summary.json" "d['rows']")" = "6" ] && pass "6 rows scored" || fail "row count"
[ "$(jq_py "$WORK/bench/summary.json" "d['tier1_agreement'].get('anomaly',0)")" = "1" ] && pass "tier1 anomaly row (rc=124) listed separately" || fail "tier1 anomaly accounting"
[ "$(jq_py "$WORK/bench/summary.json" "d['models_seen']")" = "{'jev-1.13.0': 6}" ] && pass "model recorded on every response" || fail "models_seen"

# 2. red control: the same fixture with the traceback row answered "pass" -> FN=1, floor NOT met
python3 "$TOOL" benchmark --rows "$FX/bench.jsonl" --out "$WORK/red" --mock-responses "$FX/bench-responses-red.json" >/dev/null
[ "$(jq_py "$WORK/red/summary.json" "d['false_negatives']")" = "1" ] && pass "red control: known-fail answered pass counts FN=1" || fail "red control FN"
[ "$(jq_py "$WORK/red/summary.json" "d['fn_floor_met']")" = "False" ] && pass "red control: fn_floor_met false" || fail "red control floor"

# 3. rows.jsonl: hashes present, no stderr text, no key material
ROWS="$WORK/bench/rows.jsonl"
[ "$(wc -l < "$ROWS" | tr -d ' ')" = "6" ] && pass "rows.jsonl has one line per input" || fail "rows.jsonl line count"
python3 - "$ROWS" <<'PY' && pass "every row has 64-hex request/response hashes + model" || fail "row hash/model contract"
import json,re,sys
for line in open(sys.argv[1]):
    r=json.loads(line)
    assert re.fullmatch(r"[0-9a-f]{64}", r["request_sha256"]) and re.fullmatch(r"[0-9a-f]{64}", r["response_sha256"]), r
    assert r["model"] == "jev-1.13.0", r
PY
! grep -q 'Traceback\|KeyError' "$ROWS" && pass "rows.jsonl carries no stderr text" || fail "stderr leaked into rows.jsonl"

# 4. error-log replay: per-field agreement with the stored Gemma classification
python3 "$TOOL" errorlog --log "$FX/errorlog.jsonl" --out "$WORK/log" --mock-responses "$FX/errorlog-responses.json" >/dev/null
[ "$(jq_py "$WORK/log/summary.json" "d['agreement']['status']['pct']")" = "100.0" ] && pass "errorlog status agreement 100% on matching answers" || fail "errorlog status agreement"
[ "$(jq_py "$WORK/log/summary.json" "d['agreement']['category']['n']")" = "4" ] && pass "errorlog category agreement counted per row" || fail "errorlog category agreement"
[ "$(jq_py "$WORK/log/summary.json" "d['pairs']['severity'].get('high->high')")" = "2" ] && pass "severity Choice label compared exactly (high->high x2)" || fail "severity label agreement"

# 5. empty input refused
: > "$WORK/empty.jsonl"
if python3 "$TOOL" benchmark --rows "$WORK/empty.jsonl" --out "$WORK/e" --mock-responses "$FX/bench-responses.json" >/dev/null 2>&1; then
  fail "empty benchmark should exit non-zero"
else
  rc=$?; [ "$rc" = "2" ] && pass "empty benchmark refused (exit 2)" || fail "empty benchmark exit code $rc (want 2)"
fi

# 6. no key and no mock -> refuses before any network call
if python3 "$TOOL" benchmark --rows "$FX/bench.jsonl" --out "$WORK/nokey" >/dev/null 2>&1; then
  fail "live path without a key should refuse"
else
  pass "live path without a key refuses"
fi

echo "== gh712-jev-triage: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
