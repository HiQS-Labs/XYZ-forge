#!/usr/bin/env bash
# test/gh496-telemetry-isolation.sh — GH-496 Telemetry Relocation & Out-of-Tree Invariants.
#
# Proves:
#   1. get_db_path() defaults to ~/.xyz/projects/<project_key>/telemetry/harnesses.db when unset.
#   2. XYZ_HARNESS_DB environment override is strictly honored.
#   3. get_sql_path() and get_generated_md_path() stay alongside the out-of-tree database.
#   4. check_integrity() strictly fails when explicit XYZ_HARNESS_DB does not exist (no silent fallback).
#   5. CLI --local flag forces resolution and validation of in-repo harnesses.db.
#   6. normalize_remote_url unifies git@, ssh://git@, and https:// remote formats.
#   7. First-turn auto-seed: freshly initialized database auto-seeds canonical harnesses/models.
#   8. Evaluation recording on out-of-tree database succeeds.
#   9. Concurrency test: 10 parallel loggers write simultaneously without integrity failures or lost rows.
#  10. Working tree cleanliness: HarnessTurnLogger writes to host telemetry with zero working tree churn.
#  11. Row persistence: exact row count query on SQLite invocation_logs.
#  12. Red control: invalid/unregistered harness fails foreign key check.
#  13. Negative control: tracked repo files remain 100% byte-unchanged across turns.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh496-telemetry.XXXXXX")"
[ -n "$WORK" ] || exit 1
[ -d "$WORK" ] || exit 1
. "$ROOT/test/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT
WORK="$(cd "$WORK" && pwd -P)"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1" >&2; FAIL=$((FAIL + 1)); }

export PYTHONPATH="$ROOT/utils/py:${PYTHONPATH:-}"
HARNESS_APP="$ROOT/utils/py/harness_app.py"

# Capture baseline checksums of tracked files
BEFORE_DB_CKSUM="$(cksum "$ROOT/harnesses.db")"
BEFORE_SQL_CKSUM="$(cksum "$ROOT/harnesses.sql")"
BEFORE_GEN_MD_CKSUM="$(cksum "$ROOT/HARNESS-MODELS-REGISTRY.generated.md")"

echo "== test: gh496-telemetry-isolation =="

# 1. Default out-of-tree path resolution under ~/.xyz/projects/<key>/telemetry/harnesses.db
FAKE_HOME="$WORK/fake_home"
mkdir -p "$FAKE_HOME"
resolved="$(HOME="$FAKE_HOME" python3 - <<PY
import os, sys
sys.path.insert(0, '$ROOT/utils/py')
os.environ.pop('XYZ_HARNESS_DB', None)
import harness_app
print(harness_app.get_db_path('$ROOT'))
PY
)"
EXPECTED_PREFIX="$FAKE_HOME/.xyz/projects/"
EXPECTED_SUFFIX="/telemetry/harnesses.db"
if [[ "$resolved" == "$EXPECTED_PREFIX"* ]] && [[ "$resolved" == *"$EXPECTED_SUFFIX" ]]; then
  pass "get_db_path() defaults to ~/.xyz/projects/<project_key>/telemetry/harnesses.db when unset"
else
  fail "get_db_path() did not resolve under ~/.xyz/projects/: got '$resolved'"
fi

# 2. XYZ_HARNESS_DB override is strictly honored
overridden="$(XYZ_HARNESS_DB="$WORK/custom/my_harness.db" python3 - <<PY
import sys
sys.path.insert(0, '$ROOT/utils/py')
import harness_app
print(harness_app.get_db_path('$ROOT'))
PY
)"
if [ "$overridden" = "$WORK/custom/my_harness.db" ]; then
  pass "get_db_path() honors XYZ_HARNESS_DB environment override"
else
  fail "XYZ_HARNESS_DB override not honored: got '$overridden'"
fi

# 3. get_sql_path() and get_generated_md_path() stay alongside out-of-tree DB
sql_resolved="$(XYZ_HARNESS_DB="$WORK/custom/my_harness.db" python3 - <<PY
import sys
sys.path.insert(0, '$ROOT/utils/py')
import harness_app
print(harness_app.get_sql_path('$ROOT'))
PY
)"
md_resolved="$(XYZ_HARNESS_DB="$WORK/custom/my_harness.db" python3 - <<PY
import sys
sys.path.insert(0, '$ROOT/utils/py')
import harness_app
print(harness_app.get_generated_md_path('$ROOT'))
PY
)"
if [ "$sql_resolved" = "$WORK/custom/my_harness.sql" ] && [ "$md_resolved" = "$WORK/custom/HARNESS-MODELS-REGISTRY.generated.md" ]; then
  pass "get_sql_path() and get_generated_md_path() stay alongside the out-of-tree database"
else
  fail "paths did not resolve alongside DB: sql='$sql_resolved', md='$md_resolved'"
fi

# 4. Explicit XYZ_HARNESS_DB to non-existent file strictly fails check (Blocker 1)
rc_missing=0
out_missing="$(XYZ_HARNESS_DB="$WORK/nonexistent_dir/missing.db" python3 "$HARNESS_APP" check 2>&1)" || rc_missing=$?
if [ "$rc_missing" -ne 0 ] && grep -qi "database missing" <<<"$out_missing"; then
  pass "check_integrity() strictly fails when explicit XYZ_HARNESS_DB does not exist (no silent fallback)"
else
  fail "check_integrity() did not fail on missing explicit DB: rc=$rc_missing, out=$out_missing"
fi

# 5. CLI --local flag forces resolution and validation of in-repo harnesses.db (Should 3)
local_out="$(python3 "$HARNESS_APP" --local check 2>&1)"
local_rc=$?
if [ "$local_rc" -eq 0 ] && grep -qi "harnesses.db" <<<"$local_out" && grep -qi "clean" <<<"$local_out"; then
  pass "Real CLI flag --local check succeeds and validates in-repo harnesses.db"
else
  fail "CLI --local check failed: rc=$local_rc, out=$local_out"
fi

# 6. normalize_remote_url unifies git@, ssh://git@, and https:// URLs (Should 5)
norm_test="$(python3 - <<PY
import sys
sys.path.insert(0, '$ROOT/utils/py')
from harness_app import normalize_remote_url
ssh_url = "git@github.com:HiQS-Labs/XYZ-forge.git"
https_url = "https://github.com/HiQS-Labs/XYZ-forge"
ssh_prefixed = "ssh://git@github.com:HiQS-Labs/XYZ-forge.git"
assert normalize_remote_url(ssh_url) == "https://github.com/HiQS-Labs/XYZ-forge", f"Failed ssh: {normalize_remote_url(ssh_url)}"
assert normalize_remote_url(https_url) == "https://github.com/HiQS-Labs/XYZ-forge", f"Failed https: {normalize_remote_url(https_url)}"
assert normalize_remote_url(ssh_prefixed) == "https://github.com/HiQS-Labs/XYZ-forge", f"Failed ssh prefixed: {normalize_remote_url(ssh_prefixed)}"
print("MATCH")
PY
)"
if [ "$norm_test" = "MATCH" ]; then
  pass "normalize_remote_url unifies git@, ssh://git@, and https:// URLs to identical canonical identity"
else
  fail "normalize_remote_url failed: got '$norm_test'"
fi

# 7. First-turn auto-seed: logging to a new empty DB succeeds without foreign key failure
SCRATCH_DB="$WORK/auto_seed_test/harnesses.db"
XYZ_HARNESS_DB="$SCRATCH_DB" python3 "$HARNESS_APP" log \
  --device-id "test-device" \
  --harness-id "codex" \
  --model-id "deepseek/deepseek-v4-pro" \
  --gateway "openrouter" \
  --reasoning-effort "high" \
  --shim "codex-turn.py" \
  --task-scope "GH-496 auto-seed validation" \
  --seconds 1.2 \
  --exit-code 0 > "$WORK/log.out" 2> "$WORK/log.err" || true

inv_id="$(cat "$WORK/log.out" 2>/dev/null || true)"
if [ -n "$inv_id" ] && [[ "$inv_id" == inv-* ]]; then
  pass "First-turn auto-seed: newly initialized database auto-populates harnesses and models on log"
else
  fail "First-turn auto-seed failed: log did not produce an invocation ID (err: $(cat "$WORK/log.err" 2>/dev/null))"
fi

# 8. Evaluation recording on auto-seeded database
eval_id="$(XYZ_HARNESS_DB="$SCRATCH_DB" python3 "$HARNESS_APP" eval \
  --invocation-id "$inv_id" \
  --evaluated-by "tester" \
  --role "Reviewer" \
  --grade "A" \
  --gate-passed 1 \
  --narrative "Verified auto-seed evaluation recording" 2>"$WORK/eval.err" || true)"

if [ -n "$eval_id" ] && [[ "$eval_id" == eval-* ]]; then
  pass "Evaluation records cleanly into out-of-tree database without touching git working tree"
else
  fail "Evaluation recording failed: err: $(cat "$WORK/eval.err" 2>/dev/null)"
fi

# 9. Concurrency test: 10 parallel loggers write simultaneously (Blocker 2)
CONCUR_DB="$WORK/concur_test/harnesses.db"
mkdir -p "$WORK/concur_test"
pids=()
for i in $(seq 1 10); do
  XYZ_HARNESS_DB="$CONCUR_DB" python3 "$HARNESS_APP" log \
    --device-id "device-$i" \
    --harness-id "codex" \
    --model-id "deepseek/deepseek-v4-pro" \
    --gateway "openrouter" \
    --reasoning-effort "high" \
    --shim "codex-turn.py" \
    --task-scope "GH-496 concurrency test worker $i" \
    --seconds 0.5 \
    --exit-code 0 >/dev/null 2>&1 &
  pids+=($!)
done

concur_err=0
for pid in "${pids[@]}"; do
  wait "$pid" || concur_err=$((concur_err + 1))
done

if [ "$concur_err" -eq 0 ]; then
  c_count="$(sqlite3 "$CONCUR_DB" "SELECT COUNT(*) FROM invocation_logs WHERE harness_id='codex';")"
  c_integ="$(XYZ_HARNESS_DB="$CONCUR_DB" python3 "$HARNESS_APP" check 2>&1)"
  if [ "$c_count" -eq 10 ] && grep -qi "clean" <<<"$c_integ"; then
    pass "Concurrency test: 10 parallel loggers wrote 10 rows with zero integrity failures"
  else
    fail "Concurrency test mismatch: count=$c_count, check=$c_integ"
  fi
else
  fail "Concurrency test: $concur_err worker processes exited with error"
fi

# 10. Working tree cleanliness: running HarnessTurnLogger leaves git status 100% clean
TURN_WORK="$WORK/turn_simulation"
mkdir -p "$TURN_WORK/fake_user_home"
HOME="$TURN_WORK/fake_user_home" XYZ_HARNESS_LOGGING=1 python3 - <<PY
import os, sys
sys.path.insert(0, '$ROOT/utils/py')
os.environ.pop('XYZ_HARNESS_DB', None)
from harness_turn_logger import HarnessTurnLogger

with HarnessTurnLogger(
    harness_id="agy",
    shim="agy-turn.py",
    task_scope="GH-496 working tree cleanliness check",
    model_id="deepseek/deepseek-v4-pro",
    reasoning_effort="high",
) as logger:
    logger.tokens = 500
    logger.cost = 0.001
    logger.exit_code = 0
PY

# Verify that the turn wrote to fake HOME
SIM_DB_MATCH=( "$TURN_WORK/fake_user_home/.xyz/projects"/*"/telemetry/harnesses.db" )
if [ -e "${SIM_DB_MATCH[0]}" ]; then
  pass "Turn logging successfully routed to host runtime location (~/.xyz/.../telemetry/harnesses.db)"
else
  fail "Turn logging did not create database in expected out-of-tree telemetry directory"
fi

# 11. Row persistence: exact row count query on SQLite invocation_logs (Should 3)
row_count="$(sqlite3 "${SIM_DB_MATCH[0]}" "SELECT COUNT(*) FROM invocation_logs WHERE harness_id='agy';")"
if [ "$row_count" -ge 1 ]; then
  pass "Row persistence: exact query on invocation_logs verifies row committed (count=$row_count)"
else
  fail "Row persistence query returned 0 rows in invocation_logs"
fi

# Verify working tree has ZERO new uncommitted modifications to harnesses.*
diff_status="$(git -C "$ROOT" status --porcelain harnesses.db harnesses.sql HARNESS-MODELS-REGISTRY.generated.md || true)"
if [ -z "$diff_status" ]; then
  pass "Working tree cleanliness: git status --porcelain shows zero tracked harness telemetry churn"
else
  fail "Working tree dirty after turn: $diff_status"
fi

# 12. Red Control: Invalid/unregistered harness fails foreign key check
rc=0
out="$(XYZ_HARNESS_DB="$SCRATCH_DB" python3 "$HARNESS_APP" log \
  --device-id "test-device" \
  --harness-id "nonexistent_harness_xyz_999" \
  --model-id "deepseek/deepseek-v4-pro" \
  --shim "test.py" \
  --task-scope "Red control foreign key" 2>&1)" || rc=$?

if [ "$rc" -ne 0 ] && grep -qi "foreign key" <<<"$out"; then
  pass "Red control: unregistered harness_id is strictly rejected by foreign key constraint"
else
  fail "Red control failed: expected foreign key rejection, got rc=$rc, out=$out"
fi

# 13. Negative control: Tracked repo files remain 100% byte-unchanged
AFTER_DB_CKSUM="$(cksum "$ROOT/harnesses.db")"
AFTER_SQL_CKSUM="$(cksum "$ROOT/harnesses.sql")"
AFTER_GEN_MD_CKSUM="$(cksum "$ROOT/HARNESS-MODELS-REGISTRY.generated.md")"

if [ "$BEFORE_DB_CKSUM" = "$AFTER_DB_CKSUM" ] && \
   [ "$BEFORE_SQL_CKSUM" = "$AFTER_SQL_CKSUM" ] && \
   [ "$BEFORE_GEN_MD_CKSUM" = "$AFTER_GEN_MD_CKSUM" ]; then
  pass "Negative control: tracked root files remain 100% byte-identical"
else
  fail "Negative control failed: tracked root files were modified during tests"
fi

echo "gh496-telemetry-isolation: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
