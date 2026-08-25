#!/usr/bin/env bash
# GH-155 Phase 5: 4-Family Active Explorer Agent Suite
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

# Source shared fixture-guard (GH-1 / GH-10 / GH-564 / GH-567)
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh155-active-explorer.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh155-phase5-active-explorer =="

# 1. Explorer file existence & permissions
EXPLORER="$ROOT/utils/py/active_explorer.py"
if [ -f "$EXPLORER" ] && [ -x "$EXPLORER" ]; then
  pass "utils/py/active_explorer.py exists and is executable"
else
  fail "utils/py/active_explorer.py missing or not executable"
fi

# 2. Run internal self-test suite
rc=0
out="$(python3 "$EXPLORER" --mode suite 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "SUITE_RESULT=PASS" <<<"$out"; then
  pass "active_explorer.py --mode suite passes all internal assertions"
else
  fail "active_explorer.py --mode suite failed (rc=$rc, out=$out)"
fi

# 3. Test structured JSON output mode
rc=0
out="$(python3 "$EXPLORER" --mode suite --json 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q '"passed": true' <<<"$out" && grep -q '"total_count": 6' <<<"$out"; then
  pass "active_explorer.py --mode suite --json returns valid structured JSON payload"
else
  fail "active_explorer.py --mode suite --json failed (rc=$rc, out=$out)"
fi

# 4. End-to-End Pipeline Integration: Active Explorer -> Phase 3 ddmin -> Phase 4 Self-Healer
INTEGRATION_SCRIPT="$WORK/test_pipeline_e2e.py"
cat > "$INTEGRATION_SCRIPT" <<PYEOF
import json
import os
import sys

from active_explorer import generate_argv_mutations, run_exploration_campaign
from repro_builder import minimize_argv
from self_healer import run_self_healing_cycle

sandbox_dir = "$WORK"
target_file = os.path.join(sandbox_dir, "calc_cli.py")

initial_code = """#!/usr/bin/env bash
# Buggy script: crashes on --fuzz-trigger
for arg in "\$@"; do
    if [ "\$arg" = "--fuzz-trigger" ]; then
        echo "calc_cli: unhandled crash error" >&2
        exit 1
    fi
done
echo "calc_cli: ok"
exit 0
"""
with open(target_file, "w") as f:
    f.write(initial_code)
os.chmod(target_file, 0o755)

# Step 1: Active Explorer discovers the crash anomaly
campaign = run_exploration_campaign(
    target_cmd=["bash", target_file, "--fuzz-trigger"],
    base_env={},
    repo_root=sandbox_dir,
    family="argv",
    max_rounds=5,
)

# Step 2: Phase 3 Hierarchical ddmin minimizes input vector
min_cmd = minimize_argv(
    ["bash", target_file, "--extra-opt-1", "--fuzz-trigger", "--extra-opt-2"],
    {},
    sandbox_dir,
    target_rc=1,
    target_err_substring="unhandled crash error",
    keep_first_n=2,
)

# Step 3: Synthesize Acceptance Gate Script (asserts fix: target must exit 0)
gate_script_path = os.path.join(sandbox_dir, "gate_repro.sh")
with open(gate_script_path, "w") as f:
    f.write(f"""#!/usr/bin/env bash
set -euo pipefail
RC=0
OUT="\$(bash {target_file} --fuzz-trigger 2>&1)" || RC=\$?
if [ "\$RC" -eq 0 ]; then
  echo "PASS: fixed"
  exit 0
fi
echo "FAIL: not fixed (rc=\$RC)"
exit 1
""")
os.chmod(gate_script_path, 0o755)

# Step 4: Phase 4 Autonomous Gated Self-Healing Loop
def fix_generator(path, error_trace, attempt):
    return """#!/usr/bin/env bash
for arg in "\$@"; do
    if [ "\$arg" = "--fuzz-trigger" ]; then
        echo "calc_cli: handled fuzz trigger cleanly"
        exit 0
    fi
done
echo "calc_cli: ok"
exit 0
"""

heal_result = run_self_healing_cycle(
    repro_path=gate_script_path,
    target_file=target_file,
    repo_root=os.environ.get("ROOT", sandbox_dir),
    fix_generator=fix_generator,
    regression_cmd=["bash", target_file, "--help"],
    max_attempts=2,
    sandbox_root=sandbox_dir,
)

if heal_result["status"] == "healed" and "winning_diff" in heal_result:
    print("3RD_GEN_PIPELINE_COMPLETE")
    sys.exit(0)
else:
    print(f"FAILED_STEP_4: {heal_result}")
    sys.exit(1)
PYEOF
require_fixture_file "$INTEGRATION_SCRIPT" "integration-script"

rc=0
out="$(ROOT="$ROOT" PYTHONPATH="$ROOT/utils/py" python3 "$INTEGRATION_SCRIPT" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "3RD_GEN_PIPELINE_COMPLETE" <<<"$out"; then
  pass "3rd Gen ATE Pipeline E2E (Explorer -> Reproducer ddmin -> Self-Healer) verified"
else
  fail "3rd Gen ATE Pipeline E2E failed (rc=$rc, out=$out)"
fi

# 5. CLI explore mode with --repro-out synthesis
REPRO_OUT_DIR="$WORK/cli_repros"
mkdir -p "$REPRO_OUT_DIR"
require_fixture "$REPRO_OUT_DIR" "cli repro output dir"

TARGET_PY="$WORK/cli_target.py"
cat > "$TARGET_PY" << 'PYEOF'
#!/usr/bin/env python3
import sys
if "--unknown-fuzz-flag-xyz" in sys.argv:
    raise RuntimeError("unhandled_fuzz_crash")
print("ok")
PYEOF
chmod +x "$TARGET_PY"
require_fixture_file "$TARGET_PY" "cli target script"

rc=0
out="$(PYTHONPATH="$ROOT/utils/py" python3 "$EXPLORER" --mode explore --family argv --rounds 25 --target-cmd "python3 $TARGET_PY" --repro-out "$REPRO_OUT_DIR" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && [ -f "$REPRO_OUT_DIR/repro_anomaly_1.sh" ]; then
  # Verify that the generated reproducer script runs and passes (faithfully reproduces)
  rc_rep=0
  out_rep="$(bash "$REPRO_OUT_DIR/repro_anomaly_1.sh" 2>&1)" || rc_rep=$?
  if [ "$rc_rep" -eq 0 ] && grep -q "PASS: Failure reproduced" <<<"$out_rep"; then
    pass "active_explorer.py --repro-out synthesizes verified runnable repro.sh"
  else
    fail "Synthesized repro.sh execution failed (rc=$rc_rep, out=$out_rep)"
  fi
else
  fail "active_explorer.py --mode explore with --repro-out failed (rc=$rc, out=$out)"
fi

echo "  gh155-phase5-active-explorer: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
