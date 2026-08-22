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
if [ "$rc" -eq 0 ] && grep -q "SUITE_RESULT=PASS" <<<"$out"; then
  pass "differential_oracle.py --mode suite passes all 7 vectors across all 7 shims"
else
  fail "differential_oracle.py --mode suite failed (rc=$rc, out=$out)"
fi

# 3. Test single vector execution mode (--mode vector --vector help)
rc=0
out="$(python3 "$ORACLE" --mode vector --vector help 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "Passed: True" <<<"$out"; then
  pass "differential_oracle.py --mode vector --vector help successfully evaluates single vector"
else
  fail "differential_oracle.py --mode vector failed (rc=$rc, out=$out)"
fi

# 4. Test structured JSON output mode (--mode suite --json)
rc=0
out="$(python3 "$ORACLE" --mode suite --json 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q '"passed": true' <<<"$out" && grep -q '"total_count": 7' <<<"$out"; then
  pass "differential_oracle.py --mode suite --json returns valid structured JSON payload"
else
  fail "differential_oracle.py --mode suite --json failed (rc=$rc, out=$out)"
fi

# 5. Negative control: Falsifiability on true cross-runner exit code divergence
MOCK_SHIM="$WORK/mock_divergent.sh"
cat > "$MOCK_SHIM" <<'SH_EOF'
#!/usr/bin/env bash
exit 42
SH_EOF
chmod +x "$MOCK_SHIM"
require_fixture_file "$MOCK_SHIM" "mock-shim"

CONTROL_SCRIPT="$WORK/test_divergence.py"
cat > "$CONTROL_SCRIPT" <<PYEOF
import sys
from differential_oracle import evaluate_vector_across_runners, RUNNERS

# Inject a mock divergent runner pointing to a shim that exits 42
RUNNERS["mock_divergent"] = {
    "shim": "$MOCK_SHIM",
    "agent_env": "MOCK_AGENT",
    "name": "mock_divergent"
}

# Run help vector where other runners exit 0 but mock exits 42
res = evaluate_vector_across_runners(
    "Test Exit Code Divergence",
    ["--help"],
    lambda r, m: {},
    repo_root="$ROOT",
    expected_exit_code=0
)

# Must detect divergence across runners
if not res["passed"] and any("Exit code divergence across runners" in d for d in res["divergences"]):
    print("DIVERGENCE_CAUGHT")
    sys.exit(0)
else:
    print(f"Failed to detect divergence: {res}")
    sys.exit(1)
PYEOF

require_fixture_file "$CONTROL_SCRIPT" "divergence-script"

rc=0
out="$(PYTHONPATH="$ROOT/utils/py" python3 "$CONTROL_SCRIPT" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "DIVERGENCE_CAUGHT" <<<"$out"; then
  pass "differential oracle detects genuine cross-runner exit code divergence (negative control)"
else
  fail "differential oracle negative control failed (rc=$rc, out=$out)"
fi

echo "  gh155-phase2-differential-oracle: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
