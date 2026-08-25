#!/usr/bin/env bash
set -uo pipefail
#
# gh201-bounded-autonomy-governor.sh — Bounded Autonomy, Governor Control & Calibration (GH-201 / Tasks 7 & 8)
#
# Proves:
#   1. self_healer.py --mode suite passes all internal assertions (including governor, sensor, calibration)
#   2. control.json abort halts self-healing cycle gracefully
#   3. Advisory blast radius sensor rejects candidate patch exceeding max-diff-lines
#   4. control.json abort halts active explorer campaign immediately
#   5. Structured JSON output contains valid calibration telemetry payload

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
HEALER="$REPO/utils/py/self_healer.py"
EXPLORER="$REPO/utils/py/active_explorer.py"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh201-bounded-autonomy-governor =="

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh201-governor.XXXXXX")"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "mktemp failed" >&2; exit 1; }
cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

SANDBOX="$WORK/disposable-sandbox"
mkdir -p "$SANDBOX"
require_fixture "$SANDBOX" "disposable sandbox"

# 1. Internal self_healer suite
rc=0
out="$(python3 "$HEALER" --mode suite 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "SUITE_RESULT=PASS" <<< "$out"; then
  pass "self_healer.py --mode suite passes all 9 assertions"
else
  fail "self_healer.py --mode suite failed (rc=$rc, out=$out)"
fi

# Fixture setup for CLI tests
TARGET="$SANDBOX/calc.sh"
cat > "$TARGET" << 'SCRIPT'
#!/usr/bin/env bash
if [ "$1" = "--calc" ]; then
  echo "calc: error 42" >&2
  exit 2
fi
echo "calc: ok"
exit 0
SCRIPT
chmod +x "$TARGET"
require_fixture_file "$TARGET" "target script"

REPRO="$SANDBOX/repro.sh"
cat > "$REPRO" << SCRIPT
#!/usr/bin/env bash
set -euo pipefail
RC=0
OUT="\$(bash $(printf '%q' "$TARGET") --calc 2>&1)" || RC=\$?
if [ "\$RC" -eq 0 ]; then
  exit 0
fi
exit 1
SCRIPT
chmod +x "$REPRO"
require_fixture_file "$REPRO" "repro script"

PATCH="$SANDBOX/fix.sh"
cat > "$PATCH" << 'SCRIPT'
#!/usr/bin/env bash
# Header comment 1
# Header comment 2
# Header comment 3
# Header comment 4
# Header comment 5
# Header comment 6
# Header comment 7
# Header comment 8
# Header comment 9
# Header comment 10
if [ "$1" = "--calc" ]; then
  echo "calc: result: 42"
  exit 0
fi
echo "calc: ok"
exit 0
SCRIPT
require_fixture_file "$PATCH" "patch script"

# 2. Control.json abort halts self_healer CLI
GOV_FILE="$SANDBOX/control.json"
cat > "$GOV_FILE" << 'JSONEOF'
{"action": "abort", "reason": "Emergency halt by operator"}
JSONEOF
require_fixture_file "$GOV_FILE" "governor file"

rc_gov=0
out_gov="$(python3 "$HEALER" --mode heal \
  --sandbox-root "$SANDBOX" \
  --repro "$REPRO" \
  --target-file "$TARGET" \
  --regression-cmd "bash $TARGET --help" \
  --patch-file "$PATCH" \
  --governor "$GOV_FILE" \
  --json \
  2>&1)" || rc_gov=$?

if [ "$rc_gov" -ne 0 ] && grep -q '"status": "aborted_by_governor"' <<< "$out_gov"; then
  pass "control.json abort halts self_healer CLI and records aborted_by_governor status"
else
  fail "self_healer governor abort failed (rc=$rc_gov, out=$out_gov)"
fi

# 3. Advisory blast radius sensor rejects bloated patch
rc_sensor=0
out_sensor="$(python3 "$HEALER" --mode heal \
  --sandbox-root "$SANDBOX" \
  --repro "$REPRO" \
  --target-file "$TARGET" \
  --regression-cmd "bash $TARGET --help" \
  --patch-file "$PATCH" \
  --max-diff-lines 5 \
  --json \
  2>&1)" || rc_sensor=$?

if [ "$rc_sensor" -ne 0 ] && grep -q "advisory_sensor_rejected" <<< "$out_sensor"; then
  pass "Advisory blast radius sensor rejects candidate patch exceeding --max-diff-lines"
else
  fail "Advisory sensor rejection failed (rc=$rc_sensor, out=$out_sensor)"
fi

# 4. Control.json abort halts active_explorer CLI
out_exp_gov="$(PYTHONPATH="$REPO/utils/py" python3 "$EXPLORER" --mode explore \
  --target-cmd "bash $TARGET --help" \
  --governor "$GOV_FILE" \
  --json \
  2>&1)" || true

if grep -q '"total_probes": 0' <<< "$out_exp_gov"; then
  pass "control.json abort halts active_explorer campaign immediately (0 probes executed)"
else
  fail "active_explorer governor abort failed (out=$out_exp_gov)"
fi

# 5. Calibration telemetry payload is returned in JSON output
OUT_HEAL="$(python3 "$HEALER" --mode heal \
  --sandbox-root "$SANDBOX" \
  --repro "$REPRO" \
  --target-file "$TARGET" \
  --regression-cmd "bash $TARGET --help" \
  --patch-file "$PATCH" \
  --json \
  2>&1 || true)"

if grep -q '"calibration"' <<< "$OUT_HEAL" && grep -q '"total_duration_ms"' <<< "$OUT_HEAL"; then
  pass "Self-healer emits structured calibration telemetry payload"
else
  fail "Calibration payload missing from JSON output: $OUT_HEAL"
fi

echo "== result: $PASS passed; $FAIL failed =="
[ "$FAIL" -eq 0 ] || exit 1
