#!/usr/bin/env bash
# GH-174: Harness & Models Registry SQLite Migration Suite
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

# Source shared fixture-guard (GH-1 / GH-10 / GH-564 / GH-567)
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh174-harness-registry.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh174-harness-registry =="

export PYTHONPATH="$ROOT/utils/py:${PYTHONPATH:-}"

HARNESS_APP="$ROOT/utils/py/harness_app.py"
DEVICE_CONFIG="$ROOT/utils/py/device_config.py"
TURN_LOGGER="$ROOT/utils/py/harness_turn_logger.py"

# 1. Executables exist
if [ -x "$HARNESS_APP" ] && [ -x "$DEVICE_CONFIG" ] && [ -x "$TURN_LOGGER" ]; then
  pass "All GH-174 Python executables exist and are executable"
else
  fail "GH-174 Python executables missing or not executable"
fi

# 2. Database integrity & schema checks
rc=0
out="$(python3 "$HARNESS_APP" check 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "harness check: clean" <<<"$out"; then
  pass "harness_app.py check verifies foreign_keys and SQLite integrity"
else
  fail "harness_app.py check failed (rc=$rc, out=$out)"
fi

# 3. 3-Tier Per-Device Config Resolution
TEST_CFG="$WORK/test_cfg.py"
cat > "$TEST_CFG" <<PYEOF
import json
import os
import sys

from device_config import resolve_device_setting, get_effective_runtime_config

# Tier 3: Global defaults
assert resolve_device_setting("default_model") == "deepseek/deepseek-v4-pro"
assert resolve_device_setting("default_reasoning_effort") == "high"

# Tier 2: Environment variable override
os.environ["XYZ_MODEL"] = "zai-org/GLM-5.3"
os.environ["XYZ_REASONING_EFFORT"] = "max"
assert resolve_device_setting("default_model", "XYZ_MODEL") == "zai-org/GLM-5.3"
assert resolve_device_setting("default_reasoning_effort", "XYZ_REASONING_EFFORT") == "max"

# Effective runtime dict
eff = get_effective_runtime_config()
assert eff["model"] == "zai-org/GLM-5.3"
assert eff["reasoning_effort"] == "max"
print("CFG_RESOLVED_OK")
PYEOF

rc=0
out="$(python3 "$TEST_CFG" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "CFG_RESOLVED_OK" <<<"$out"; then
  pass "device_config.py resolves 3-tier config hierarchy correctly"
else
  fail "device_config.py failed (rc=$rc, out=$out)"
fi

# 4. Turn execution telemetry logging & grading hook
TEST_LOGGER="$WORK/test_logger.py"
cat > "$TEST_LOGGER" <<PYEOF
import json
import os
import sys

from harness_turn_logger import HarnessTurnLogger

with HarnessTurnLogger(
    harness_id="commandcode",
    shim="commandcode-turn.sh",
    task_scope="GH-174 test invocation in sandbox",
    model_id="Qwen/Qwen3.8-Max",
    reasoning_effort="xhigh",
) as logger:
    logger.tokens = 3200
    logger.cost = 0.0064
    logger.exit_code = 0

assert logger.invocation_id is not None

eval_id = logger.record_evaluation(
    evaluated_by="stealth/ox-alpha",
    role="Systems Reviewer",
    grade="A-",
    gate_passed=True,
    narrative="Qwen 3.8-Max executed thorough systems refactoring with extra high reasoning effort.",
    cleanliness=5,
    seam_score=5,
)
assert eval_id is not None
print("LOGGER_EVAL_OK")
PYEOF

rc=0
out="$(python3 "$TEST_LOGGER" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "LOGGER_EVAL_OK" <<<"$out"; then
  pass "HarnessTurnLogger logs telemetry and records evaluation successfully"
else
  fail "HarnessTurnLogger failed (rc=$rc, out=$out)"
fi

# 5. Blog generation synthesis
rc=0
out="$(python3 "$HARNESS_APP" blog gen --theme "Frontier AI Benchmarks in XYZ" --slug "frontier-benchmarks" 2>&1)" || rc=$?
BLOG_FILE="$ROOT/docs/blog-frontier-benchmarks.md"
if [ "$rc" -eq 0 ] && [ -f "$BLOG_FILE" ] && grep -q "Frontier AI Benchmarks in XYZ" "$BLOG_FILE"; then
  pass "harness_app.py blog gen synthesizes publishable Markdown case study"
else
  fail "harness_app.py blog gen failed (rc=$rc, out=$out)"
fi

# 6. Negative control: Invalid grade rejected by SQLite CHECK constraint
TEST_NEG="$WORK/test_neg.py"
cat > "$TEST_NEG" <<PYEOF
import sqlite3
import sys
from harness_app import get_db_path, init_db

conn = init_db(get_db_path())
try:
    with conn:
        conn.execute("""
        INSERT INTO evaluations (
            evaluation_id, invocation_id, evaluated_by, evaluation_role, grade,
            qualifying_gate_passed, work_description_narrative
        ) VALUES ('eval-bad', 'inv-nonexistent', 'tester', 'role', 'INVALID_GRADE', 1, 'text');
        """)
    print("FAILED_NEGATIVE_CONTROL")
    sys.exit(1)
except sqlite3.IntegrityError:
    print("CHECK_CONSTRAINT_REJECTED_OK")
    sys.exit(0)
PYEOF

rc=0
out="$(python3 "$TEST_NEG" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "CHECK_CONSTRAINT_REJECTED_OK" <<<"$out"; then
  pass "Negative control: Invalid evaluation grade correctly rejected by SQLite CHECK constraint"
else
  fail "Negative control failed (rc=$rc, out=$out)"
fi

echo "gh174-harness-registry: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
