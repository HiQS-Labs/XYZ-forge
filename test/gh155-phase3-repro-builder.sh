#!/usr/bin/env bash
# GH-155 Phase 3: Hermetic Reproducer & Delta Minimization Suite
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

# Source shared fixture-guard (GH-1 / GH-10 / GH-564 / GH-567)
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh155-repro-builder.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh155-phase3-repro-builder =="

# 1. Builder file existence & permissions
BUILDER="$ROOT/utils/py/repro_builder.py"
if [ -f "$BUILDER" ] && [ -x "$BUILDER" ]; then
  pass "utils/py/repro_builder.py exists and is executable"
else
  fail "utils/py/repro_builder.py missing or not executable"
fi

# 2. Run internal self-test suite
rc=0
out="$(python3 "$BUILDER" --mode suite 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "SUITE_RESULT=PASS" <<<"$out"; then
  pass "repro_builder.py --mode suite passes all internal assertions"
else
  fail "repro_builder.py --mode suite failed (rc=$rc, out=$out)"
fi

# 3. Test structured JSON output mode
rc=0
out="$(python3 "$BUILDER" --mode suite --json 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q '"passed": true' <<<"$out" && grep -q '"total_count": 6' <<<"$out"; then
  pass "repro_builder.py --mode suite --json returns valid structured JSON payload"
else
  fail "repro_builder.py --mode suite --json failed (rc=$rc, out=$out)"
fi

# 4. Ingest raw telemetry file and synthesize hermetic repro.sh
TELEMETRY_FILE="$WORK/failing_telemetry.json"
cat > "$TELEMETRY_FILE" <<'JSONEOF'
{
  "cmd": ["bash", "relay-automation/deepseek-turn.sh"],
  "argv": ["--extra-opt-1", "--extra-opt-2"],
  "env": {
    "RELAY_AGENT": "tester",
    "DEEPSEEK_AGENT": "tester",
    "NOISE_VAR_1": "abc",
    "NOISE_VAR_2": "xyz"
  },
  "expected_exit_code": 2,
  "err_substring": "RELAY_FILE required",
  "runner": "deepseek"
}
JSONEOF
require_fixture_file "$TELEMETRY_FILE" "telemetry-input"

REPRO_OUT="$WORK/repro.sh"
rc=0
out="$(python3 "$BUILDER" --mode build --telemetry "$TELEMETRY_FILE" --output "$REPRO_OUT" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && [ -f "$REPRO_OUT" ] && [ -x "$REPRO_OUT" ]; then
  pass "repro_builder.py successfully synthesizes executable repro.sh from telemetry"
else
  fail "repro_builder.py failed to synthesize repro.sh (rc=$rc, out=$out)"
fi
require_fixture_file "$REPRO_OUT" "repro-script"

# 5. Execute generated repro.sh in sandbox to verify reproduced failure
rc=0
out="$(bash "$REPRO_OUT" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "PASS: Failure reproduced successfully with expected signature" <<<"$out"; then
  pass "synthesized repro.sh executes and reproduces failure in isolated sandbox"
else
  fail "synthesized repro.sh failed (rc=$rc, out=$out)"
fi

# 6. Falsifiability negative control: Non-reproducing candidate detection
CONTROL_SCRIPT="$WORK/test_repro_control.py"
cat > "$CONTROL_SCRIPT" <<PYEOF
import sys
from repro_builder import test_reproduction

# Verify that a command expecting exit code 2 but actually exiting 0 is detected as non-reproducing
res = test_reproduction(
    ["bash", "$ROOT/relay-automation/agy-turn.sh", "--help"],
    {},
    "$ROOT",
    target_rc=2 # Intentionally mismatched (help exits 0)
)

if res is False:
    print("NON_REPRO_CAUGHT")
    sys.exit(0)
else:
    print("Failed to detect non-reproducing candidate")
    sys.exit(1)
PYEOF
require_fixture_file "$CONTROL_SCRIPT" "control-script"

rc=0
out="$(PYTHONPATH="$ROOT/utils/py" python3 "$CONTROL_SCRIPT" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "NON_REPRO_CAUGHT" <<<"$out"; then
  pass "repro_builder correctly rejects non-reproducing test candidate (negative control)"
else
  fail "negative control failed (rc=$rc, out=$out)"
fi

echo "  gh155-phase3-repro-builder: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
