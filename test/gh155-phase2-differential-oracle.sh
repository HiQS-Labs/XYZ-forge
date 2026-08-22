#!/usr/bin/env bash
# GH-155 Phase 2: Differential Multi-Harness Cross-Testing Oracle Suite
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

# Source shared fixture-guard (GH-1 / GH-10 / GH-564 / GH-567)
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh155-differential.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh155-phase2-differential-oracle =="

# 1. Oracle file existence
ORACLE="$ROOT/utils/py/differential_oracle.py"
if [ -f "$ORACLE" ] && [ -x "$ORACLE" ]; then
  pass "utils/py/differential_oracle.py exists and is executable"
else
  fail "utils/py/differential_oracle.py missing or not executable"
fi

# 2. Run full differential multi-harness suite
rc=0
out="$(python3 "$ORACLE" --mode suite 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "7/7 differential vectors passed" <<<"$out"; then
  pass "differential_oracle.py --mode suite passes all 7 vectors across all 7 shims"
else
  fail "differential_oracle.py failed (rc=$rc, out=$out)"
fi

# 3. Negative control: Falsifiability on injected divergence
CONTROL_SCRIPT="$WORK/test_divergence.py"
cat > "$CONTROL_SCRIPT" <<'PYEOF'
import sys
from differential_oracle import evaluate_vector_across_runners, RUNNERS

# Inject a mock divergent runner
RUNNERS["mock_divergent"] = {
    "shim": "relay-automation/deepseek-turn.sh",
    "agent_env": "DEEPSEEK_AGENT",
    "name": "mock_divergent"
}

# Run vector with an expectation of rc=2, but assert on expected rc mismatch
res = evaluate_vector_across_runners(
    "Test Divergence",
    [],
    lambda r, m: {},
    repo_root=".",
    expected_exit_code=99 # Intentionally mismatched
)

if not res["passed"] and len(res["divergences"]) > 0:
    print("Divergence successfully detected")
    sys.exit(0)
else:
    print("Failed to detect divergence")
    sys.exit(1)
PYEOF

require_fixture_file "$CONTROL_SCRIPT" "divergence-script"

rc=0
out="$(PYTHONPATH="$ROOT/utils/py" python3 "$CONTROL_SCRIPT" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "Divergence successfully detected" <<<"$out"; then
  pass "differential oracle correctly detects and reports divergence across runners (negative control)"
else
  fail "differential oracle negative control failed (rc=$rc, out=$out)"
fi

echo "  gh155-phase2-differential-oracle: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
