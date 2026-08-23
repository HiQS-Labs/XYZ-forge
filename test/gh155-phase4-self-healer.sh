#!/usr/bin/env bash
# GH-155 Phase 4: Gated Autonomous Self-Healing Builder Loop Suite
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

# Source shared fixture-guard (GH-1 / GH-10 / GH-564 / GH-567)
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh155-self-healer.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh155-phase4-self-healer =="

# 1. Builder file existence & permissions
HEALER="$ROOT/utils/py/self_healer.py"
if [ -f "$HEALER" ] && [ -x "$HEALER" ]; then
  pass "utils/py/self_healer.py exists and is executable"
else
  fail "utils/py/self_healer.py missing or not executable"
fi

# 2. Run internal self-test suite
rc=0
out="$(python3 "$HEALER" --mode suite 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "SUITE_RESULT=PASS" <<<"$out"; then
  pass "self_healer.py --mode suite passes all internal assertions"
else
  fail "self_healer.py --mode suite failed (rc=$rc, out=$out)"
fi

# 3. Test structured JSON output mode
rc=0
out="$(python3 "$HEALER" --mode suite --json 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q '"passed": true' <<<"$out" && grep -q '"total_count": 4' <<<"$out"; then
  pass "self_healer.py --mode suite --json returns valid structured JSON payload"
else
  fail "self_healer.py --mode suite --json failed (rc=$rc, out=$out)"
fi

# 4. End-to-end integration test: Synthesize defective fixture, repro.sh, and execute self-healing cycle
DEFECT_SCRIPT="$WORK/faulty_tool.sh"
cat > "$DEFECT_SCRIPT" <<'EOF_TOOL'
#!/usr/bin/env bash
if [ "${1:-}" = "--check" ]; then
  echo "faulty_tool: unhandled internal exception" >&2
  exit 5
fi
echo "faulty_tool: ok"
exit 0
EOF_TOOL
chmod +x "$DEFECT_SCRIPT"
require_fixture_file "$DEFECT_SCRIPT" "defect-script"

REPRO_SCRIPT="$WORK/repro.sh"
cat > "$REPRO_SCRIPT" <<EOF_REPRO
#!/usr/bin/env bash
set -euo pipefail
RC=0
OUT="\$(bash "$DEFECT_SCRIPT" --check 2>&1)" || RC=\$?
if [ "\$RC" -eq 0 ]; then
  echo "PASS: fixed"
  exit 0
fi
echo "FAIL: still broken (rc=\$RC)"
exit 1
EOF_REPRO
chmod +x "$REPRO_SCRIPT"
require_fixture_file "$REPRO_SCRIPT" "repro-script"

DRIVER_SCRIPT="$WORK/run_e2e_healer.py"
cat > "$DRIVER_SCRIPT" <<PYEOF
import sys
from self_healer import run_self_healing_cycle

def sample_fix_generator(path, error_trace, attempt):
    if attempt == 1:
        return """#!/usr/bin/env bash
if [ "\${1:-}" = "--check" ]; then
  echo "faulty_tool: status verified cleanly"
  exit 0
fi
echo "faulty_tool: ok"
exit 0
"""
    return None

res = run_self_healing_cycle(
    repro_path="$REPRO_SCRIPT",
    target_file="$DEFECT_SCRIPT",
    repo_root="$WORK",
    fix_generator=sample_fix_generator,
    max_attempts=2,
    sandbox_root="$WORK",
)

if res["status"] == "healed" and res["attempts"] == 1 and "winning_diff" in res:
    print("E2E_HEAL_SUCCESS")
    sys.exit(0)
else:
    print(f"E2E_HEAL_FAILED: {res}")
    sys.exit(1)
PYEOF
require_fixture_file "$DRIVER_SCRIPT" "driver-script"

rc=0
out="$(PYTHONPATH="$ROOT/utils/py" python3 "$DRIVER_SCRIPT" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "E2E_HEAL_SUCCESS" <<<"$out"; then
  pass "self-healing cycle end-to-end integration successfully heals defect and emits winning diff"
else
  fail "self-healing cycle end-to-end failed (rc=$rc, out=$out)"
fi

# 5. Falsifiability negative control: Unsolvable defect halts and escalates
# Reset DEFECT_SCRIPT to defective state
cat > "$DEFECT_SCRIPT" <<'EOF_TOOL_RESET'
#!/usr/bin/env bash
if [ "${1:-}" = "--check" ]; then
  echo "faulty_tool: unhandled internal exception" >&2
  exit 5
fi
echo "faulty_tool: ok"
exit 0
EOF_TOOL_RESET
chmod +x "$DEFECT_SCRIPT"

NEG_SCRIPT="$WORK/run_neg_control.py"
cat > "$NEG_SCRIPT" <<PYEOF
import sys
from self_healer import run_self_healing_cycle

def broken_generator(path, error_trace, attempt):
    return "# completely useless patch\nexit 99\n"

res = run_self_healing_cycle(
    repro_path="$REPRO_SCRIPT",
    target_file="$DEFECT_SCRIPT",
    repo_root="$WORK",
    fix_generator=broken_generator,
    max_attempts=2,
    sandbox_root="$WORK",
)

if res["status"] == "escalated" and res["attempts"] == 2:
    print("NEG_CONTROL_SUCCESS")
    sys.exit(0)
else:
    print(f"NEG_CONTROL_FAILED: {res}")
    sys.exit(1)
PYEOF
require_fixture_file "$NEG_SCRIPT" "neg-script"

rc=0
out="$(PYTHONPATH="$ROOT/utils/py" python3 "$NEG_SCRIPT" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "NEG_CONTROL_SUCCESS" <<<"$out"; then
  pass "negative control correctly halts and escalates unsolvable defects after max_attempts"
else
  fail "negative control failed (rc=$rc, out=$out)"
fi

echo "  gh155-phase4-self-healer: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
