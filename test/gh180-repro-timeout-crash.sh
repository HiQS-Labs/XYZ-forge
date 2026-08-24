#!/usr/bin/env bash
# GH-180: repro_builder must ingest timeout telemetry records (exit_code: null) without crashing.
# Pre-fix behavior: TypeError at repro_builder.py:68 (see test/baselines/GH-180-negative-control.md,
# soak evidence #177 §3.1). Contract: null exit coalesces to the 124 timeout signature; a repro is
# emitted only when the timeout shape actually reproduces.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh180-repro-timeout.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh180-repro-timeout-crash =="

# Fixture command that deterministically "times out": exits 124 with a signature on stderr.
MOCK124="$WORK/mock124.sh"
cat > "$MOCK124" <<'SH'
#!/usr/bin/env bash
echo "simulated timeout sentinel" >&2
exit 124
SH
chmod +x "$MOCK124"
require_fixture_file "$MOCK124" "mock-124"

NULL_RECORD="$WORK/null-record.json"
cat > "$NULL_RECORD" <<JSON
{"cmd": ["bash", "$MOCK124"], "exit_code": null, "stderr": "simulated timeout sentinel", "err_substring": "simulated timeout sentinel"}
JSON
require_fixture_file "$NULL_RECORD" "null-record"

# 1. Parser coalesces null exit to the 124 timeout signature without crashing
cat > "$WORK/check_parse.py" <<PY
import sys, json
sys.path.insert(0, "$ROOT/utils/py")
from repro_builder import parse_failure_telemetry
rec = parse_failure_telemetry(json.load(open("$NULL_RECORD")))
assert rec["exit_code"] == 124, f"expected 124, got {rec['exit_code']}"
assert rec["expected_exit_code"] == 124
print("PARSE_OK")
PY
require_fixture_file "$WORK/check_parse.py" "check-parse"
rc=0; out="$(python3 "$WORK/check_parse.py" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "PARSE_OK" <<<"$out"; then
  pass "parse_failure_telemetry coalesces exit_code null -> 124 (no TypeError)"
else
  fail "null-exit record crashed the parser (rc=$rc, out=$out)"
fi

# 2. Build mode emits a runnable reproducer for a genuinely-timeouting record
REPRO="$WORK/repro.sh"
rc=0; out="$(python3 "$ROOT/utils/py/repro_builder.py" --mode build --telemetry "$NULL_RECORD" --output "$REPRO" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && [ -x "$REPRO" ]; then
  pass "--mode build succeeds on null-exit telemetry (timeout signature)"
else
  fail "--mode build failed on null-exit record (rc=$rc, out=$out)"
fi
require_fixture_file "$REPRO" "repro"

# 3. Emitted reproducer PASSes against the timing-out fixture
rc=0; out="$(bash "$REPRO" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "PASS: Failure reproduced" <<<"$out"; then
  pass "emitted timeout reproducer reproduces rc=124 + signature"
else
  fail "timeout reproducer did not reproduce (rc=$rc, out=$out)"
fi

# 4. Negative control: a record whose command exits 0 must NOT fabricate a timeout reproducer
MOCK0="$WORK/mock0.sh"
printf '#!/usr/bin/env bash\necho ok\nexit 0\n' > "$MOCK0"; chmod +x "$MOCK0"
require_fixture_file "$MOCK0" "mock-0"
CLEAN_RECORD="$WORK/clean-record.json"
cat > "$CLEAN_RECORD" <<JSON
{"cmd": ["bash", "$MOCK0"], "exit_code": null}
JSON
require_fixture_file "$CLEAN_RECORD" "clean-record"
rc=0; out="$(python3 "$ROOT/utils/py/repro_builder.py" --mode build --telemetry "$CLEAN_RECORD" --output "$WORK/should-not-exist.sh" 2>&1)" || rc=$?
if [ "$rc" -eq 2 ] && grep -qi "failed to reproduce" <<<"$out"; then
  pass "build refuses to fabricate a timeout reproducer for a non-timeouting command"
else
  fail "negative control failed (rc=$rc, out=$out)"
fi

echo "  gh180-repro-timeout-crash: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
