#!/usr/bin/env bash
set -uo pipefail
#
# gh182-healer-facade-safety.sh — GH-182 self_healer CLI safety (fail-fast + gates + restoration)
#
# Proves:
#   1. Missing --sandbox-root refuses with named requirement (exit code 2)
#   2. --sandbox-root equal to invoking checkout refuses immediately (exit code 2)
#   3. Missing --regression-cmd refuses with mandatory gate requirement (exit code 2)
#   4. Fixture sandbox heals fixture defect when given valid patch and regression gate
#   5. Interrupted / failed attempt restores target file cleanly (fail-safe invariant)
#   6. Target file outside sandbox-root is rejected (GH-567 realpath containment)

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
HEALER="$REPO/utils/py/self_healer.py"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh182-healer-facade-safety =="

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh182-healer.XXXXXX")"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "mktemp failed" >&2; exit 1; }
cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

SANDBOX="$WORK/disposable-sandbox"
mkdir -p "$SANDBOX"
require_fixture "$SANDBOX" "disposable sandbox"

# Create a defective calculator script inside sandbox
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

# Create a reproducer script inside sandbox
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

# Create a valid fixed patch
PATCH="$SANDBOX/fix.sh"
cat > "$PATCH" << 'SCRIPT'
#!/usr/bin/env bash
if [ "$1" = "--calc" ]; then
  echo "calc: result: 42"
  exit 0
fi
echo "calc: ok"
exit 0
SCRIPT
require_fixture_file "$PATCH" "patch script"

# 1. Missing --sandbox-root refuses with exit code 2 and named requirement
RC_1=0
OUT_1="$(python3 "$HEALER" --mode heal --repro "$REPRO" --target-file "$TARGET" --regression-cmd "bash $TARGET --help" 2>&1)" || RC_1=$?
if [ "$RC_1" -eq 2 ] && grep -q "sandbox-root is required for heal mode" <<< "$OUT_1"; then
  pass "Missing --sandbox-root refuses with exit code 2"
else
  fail "Missing --sandbox-root did not refuse as expected (rc=$RC_1, out=$OUT_1)"
fi

# 2. --sandbox-root equal to invoking checkout refuses with exit code 2
RC_2=0
OUT_2="$(python3 "$HEALER" --mode heal --sandbox-root "$REPO" --repro "$REPRO" --target-file "$TARGET" --regression-cmd "bash $TARGET --help" 2>&1)" || RC_2=$?
if [ "$RC_2" -eq 2 ] && grep -q "cannot be the invoking repository checkout" <<< "$OUT_2"; then
  pass "--sandbox-root matching invoking checkout refuses immediately with exit code 2"
else
  fail "--sandbox-root matching checkout did not refuse as expected (rc=$RC_2, out=$OUT_2)"
fi

# 3. Missing --regression-cmd refuses with exit code 2
RC_3=0
OUT_3="$(python3 "$HEALER" --mode heal --sandbox-root "$SANDBOX" --repro "$REPRO" --target-file "$TARGET" 2>&1)" || RC_3=$?
if [ "$RC_3" -eq 2 ] && grep -q "regression-cmd is required for heal mode" <<< "$OUT_3"; then
  pass "Missing --regression-cmd refuses with exit code 2"
else
  fail "Missing --regression-cmd did not refuse as expected (rc=$RC_3, out=$OUT_3)"
fi

# 4. Target file outside sandbox root refuses (GH-567 containment)
RC_4=0
OUT_4="$(python3 "$HEALER" --mode heal --sandbox-root "$SANDBOX" --repro "$REPRO" --target-file "$REPO/validate.sh" --regression-cmd "bash $TARGET --help" 2>&1)" || RC_4=$?
if [ "$RC_4" -eq 2 ] && grep -q "not contained within --sandbox-root" <<< "$OUT_4"; then
  pass "Target file outside sandbox-root is rejected with exit code 2 (GH-567 containment)"
else
  fail "Target outside sandbox was not rejected (rc=$RC_4, out=$OUT_4)"
fi

# 5. Successful heal in fixture sandbox with valid patch and regression gate
DIFF_OUT="$SANDBOX/winning.diff"
OUT_5="$(python3 "$HEALER" --mode heal \
  --sandbox-root "$SANDBOX" \
  --repro "$REPRO" \
  --target-file "$TARGET" \
  --regression-cmd "bash $TARGET --help" \
  --patch-file "$PATCH" \
  --diff-output "$DIFF_OUT" \
  2>&1 || true)"
if [ -f "$DIFF_OUT" ] && grep -q "Self-Healing Result: healed" <<< "$OUT_5"; then
  pass "Fixture sandbox heals defect and writes winning diff"
else
  fail "Fixture heal failed: $OUT_5"
fi

# 6. Target restoration on failed attempt (fail-safe invariant)
cat > "$TARGET" << 'SCRIPT'
#!/usr/bin/env bash
if [ "$1" = "--calc" ]; then
  exit 99
fi
exit 0
SCRIPT
TARGET_POISON_MD5="$(md5 -q "$TARGET" 2>/dev/null || md5sum "$TARGET" | awk '{print $1}')"

BAD_PATCH="$SANDBOX/bad_patch.sh"
cat > "$BAD_PATCH" << 'SCRIPT'
#!/usr/bin/env bash
if [ "$1" = "--calc" ]; then
  exit 88
fi
exit 0
SCRIPT

ESCALATION_MD="$SANDBOX/escalation.md"
OUT_6="$(python3 "$HEALER" --mode heal \
  --sandbox-root "$SANDBOX" \
  --repro "$REPRO" \
  --target-file "$TARGET" \
  --regression-cmd "bash $TARGET --help" \
  --patch-file "$BAD_PATCH" \
  --escalation-report "$ESCALATION_MD" \
  --max-attempts 2 \
  2>&1 || true)"
TARGET_AFTER_MD5="$(md5 -q "$TARGET" 2>/dev/null || md5sum "$TARGET" | awk '{print $1}')"

if [ "$TARGET_POISON_MD5" = "$TARGET_AFTER_MD5" ] && [ -f "$ESCALATION_MD" ] && grep -q "Self-Healer Escalation Report" "$ESCALATION_MD"; then
  pass "Target file restored to original content after failed attempts"
else
  fail "Target restoration failed: original=$TARGET_POISON_MD5, after=$TARGET_AFTER_MD5"
fi

echo "== result: $PASS passed; $FAIL failed =="
[ "$FAIL" -eq 0 ] || exit 1
