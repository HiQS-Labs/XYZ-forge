#!/usr/bin/env bash
# GH-182: self_healer --mode heal safety suite (fail-fast + gates + target restoration)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

# Source shared fixture-guard (GH-1 / GH-10 / GH-564 / GH-567)
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh182-healer-facade.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh182-healer-facade-safety =="

HEALER="$ROOT/utils/py/self_healer.py"
if [ -f "$HEALER" ] && [ -x "$HEALER" ]; then
  pass "utils/py/self_healer.py exists and is executable"
else
  fail "utils/py/self_healer.py missing or not executable"
fi

# Setup common fixtures under $WORK
FIXTURE_SANDBOX="$WORK/disposable_sandbox"
mkdir -p "$FIXTURE_SANDBOX"
require_fixture "$FIXTURE_SANDBOX" "fixture-sandbox"

TARGET_SCRIPT="$FIXTURE_SANDBOX/service.sh"
cat > "$TARGET_SCRIPT" <<'EOF_TARGET'
#!/usr/bin/env bash
if [ "${1:-}" = "--check" ]; then
  echo "service: internal crash" >&2
  exit 5
fi
if [ "${1:-}" = "--regression" ]; then
  echo "service: base feature ok"
  exit 0
fi
echo "service: default ok"
exit 0
EOF_TARGET
chmod +x "$TARGET_SCRIPT"
require_fixture_file "$TARGET_SCRIPT" "target-script"

REPRO_SCRIPT="$FIXTURE_SANDBOX/repro.sh"
cat > "$REPRO_SCRIPT" <<EOF_REPRO
#!/usr/bin/env bash
set -euo pipefail
RC=0
OUT="\$(bash "$TARGET_SCRIPT" --check 2>&1)" || RC=\$?
if [ "\$RC" -eq 0 ]; then
  exit 0
fi
exit 1
EOF_REPRO
chmod +x "$REPRO_SCRIPT"
require_fixture_file "$REPRO_SCRIPT" "repro-script"

REGRESSION_SCRIPT="$FIXTURE_SANDBOX/regression.sh"
cat > "$REGRESSION_SCRIPT" <<EOF_REG
#!/usr/bin/env bash
set -euo pipefail
bash "$TARGET_SCRIPT" --regression
EOF_REG
chmod +x "$REGRESSION_SCRIPT"
require_fixture_file "$REGRESSION_SCRIPT" "regression-script"

# ── 1. Missing --sandbox-root refuses loudly with named requirement (GH-182 Plan §1) ─────────────
rc=0
out="$(python3 "$HEALER" --mode heal --target-file "$TARGET_SCRIPT" --repro "$REPRO_SCRIPT" --regression-cmd "bash $REGRESSION_SCRIPT" 2>&1)" || rc=$?
if [ "$rc" -eq 2 ] && grep -q "\-\-sandbox-root is required" <<<"$out"; then
  pass "missing --sandbox-root refuses with exit 2 and named requirement"
else
  fail "missing --sandbox-root did not refuse as expected (rc=$rc, out=$out)"
fi

# ── 2. Non-existent --sandbox-root refuses loudly (GH-182 Plan §1a) ──────────────────────────────
rc=0
out="$(python3 "$HEALER" --mode heal --sandbox-root "$WORK/nonexistent_dir_123" --target-file "$TARGET_SCRIPT" --repro "$REPRO_SCRIPT" --regression-cmd "bash $REGRESSION_SCRIPT" 2>&1)" || rc=$?
if [ "$rc" -eq 2 ] && grep -q "\-\-sandbox-root does not exist" <<<"$out"; then
  pass "nonexistent --sandbox-root refuses with exit 2"
else
  fail "nonexistent --sandbox-root did not refuse as expected (rc=$rc, out=$out)"
fi

# ── 2b. Regular file as --sandbox-root refuses loudly (GH-182) ──────────────────────────────────
REG_FILE_ROOT="$WORK/regular_file_not_a_dir"
touch "$REG_FILE_ROOT"
require_fixture_file "$REG_FILE_ROOT" "reg-file-root"
rc=0
out="$(python3 "$HEALER" --mode heal --sandbox-root "$REG_FILE_ROOT" --target-file "$REG_FILE_ROOT" --repro "$REPRO_SCRIPT" --regression-cmd "bash $REGRESSION_SCRIPT" 2>&1)" || rc=$?
if [ "$rc" -eq 2 ] && grep -q "\-\-sandbox-root is not a directory" <<<"$out"; then
  pass "regular file --sandbox-root refuses with exit 2 and named requirement"
else
  fail "regular file --sandbox-root did not refuse as expected (rc=$rc, out=$out)"
fi

# ── 3. Mandatory --regression-cmd refusal (GH-182 Plan §2) ───────────────────────────────────────
rc=0
out="$(python3 "$HEALER" --mode heal --sandbox-root "$FIXTURE_SANDBOX" --target-file "$TARGET_SCRIPT" --repro "$REPRO_SCRIPT" 2>&1)" || rc=$?
if [ "$rc" -eq 2 ] && grep -q "\-\-regression-cmd is required" <<<"$out"; then
  pass "missing --regression-cmd refuses with exit 2 and named requirement"
else
  fail "missing --regression-cmd did not refuse as expected (rc=$rc, out=$out)"
fi

# ── 4. Target file outside --sandbox-root refuses loudly (GH-182 Plan §1b) ───────────────────────
OUTSIDE_TARGET="$WORK/outside_target.sh"
cp "$TARGET_SCRIPT" "$OUTSIDE_TARGET"
require_fixture_file "$OUTSIDE_TARGET" "outside-target"

rc=0
out="$(python3 "$HEALER" --mode heal --sandbox-root "$FIXTURE_SANDBOX" --target-file "$OUTSIDE_TARGET" --repro "$REPRO_SCRIPT" --regression-cmd "bash $REGRESSION_SCRIPT" 2>&1)" || rc=$?
if [ "$rc" -eq 2 ] && grep -q "is outside --sandbox-root" <<<"$out"; then
  pass "target outside --sandbox-root refuses with exit 2"
else
  fail "target outside --sandbox-root did not refuse as expected (rc=$rc, out=$out)"
fi

# ── 5. Sandbox == invoking checkout repository refuses loudly (GH-182 Plan §1c) ──────────────────
rc=0
out="$(python3 "$HEALER" --mode heal --sandbox-root "$ROOT" --target-file "$ROOT/validate.sh" --repro "$REPRO_SCRIPT" --regression-cmd "bash $REGRESSION_SCRIPT" 2>&1)" || rc=$?
if [ "$rc" -eq 2 ] && grep -q "cannot be the invoking checkout" <<<"$out"; then
  pass "sandbox == invoking checkout refuses with exit 2 (no in-place patch on host repo)"
else
  fail "sandbox == invoking checkout did not refuse as expected (rc=$rc, out=$out)"
fi

# ── 5b. --diff-out outside --sandbox-root refuses loudly (GH-182) ──────────────────────────────
OUTSIDE_DIFF="$WORK/outside_diff.patch"
rc=0
out="$(python3 "$HEALER" --mode heal --sandbox-root "$FIXTURE_SANDBOX" --target-file "$TARGET_SCRIPT" --repro "$REPRO_SCRIPT" --regression-cmd "bash $REGRESSION_SCRIPT" --diff-out "$OUTSIDE_DIFF" 2>&1)" || rc=$?
if [ "$rc" -eq 2 ] && grep -q "is outside --sandbox-root" <<<"$out"; then
  pass "diff-out outside --sandbox-root refuses with exit 2"
else
  fail "diff-out outside --sandbox-root did not refuse as expected (rc=$rc, out=$out)"
fi

# ── 5c. --issue-rollup-out outside --sandbox-root refuses loudly (GH-182) ──────────────────────
OUTSIDE_ROLLUP="$WORK/outside_rollup.md"
rc=0
out="$(python3 "$HEALER" --mode heal --sandbox-root "$FIXTURE_SANDBOX" --target-file "$TARGET_SCRIPT" --repro "$REPRO_SCRIPT" --regression-cmd "bash $REGRESSION_SCRIPT" --issue-rollup-out "$OUTSIDE_ROLLUP" 2>&1)" || rc=$?
if [ "$rc" -eq 2 ] && grep -q "is outside --sandbox-root" <<<"$out"; then
  pass "issue-rollup-out outside --sandbox-root refuses with exit 2"
else
  fail "issue-rollup-out outside --sandbox-root did not refuse as expected (rc=$rc, out=$out)"
fi

# ── 5d. run_self_healing_cycle API directly defends against out-of-sandbox paths ─────────────
API_TEST_DRIVER="$WORK/driver_api_containment.py"
cat > "$API_TEST_DRIVER" <<PYEOF
import sys
from self_healer import run_self_healing_cycle

# 1. Non-directory sandbox_root
r1 = run_self_healing_cycle(
    repro_path="$REPRO_SCRIPT",
    target_file="$TARGET_SCRIPT",
    repo_root="$WORK",
    fix_generator=lambda p, e, a: None,
    sandbox_root="$REG_FILE_ROOT",
)
assert r1["status"] == "error" and "not a directory" in r1["message"], f"r1 failed: {r1}"

# 2. Target file outside sandbox_root
r2 = run_self_healing_cycle(
    repro_path="$REPRO_SCRIPT",
    target_file="$OUTSIDE_TARGET",
    repo_root="$FIXTURE_SANDBOX",
    fix_generator=lambda p, e, a: None,
    sandbox_root="$FIXTURE_SANDBOX",
)
assert r2["status"] == "error" and "Target file" in r2["message"], f"r2 failed: {r2}"

# 3. Diff out outside sandbox_root
r3 = run_self_healing_cycle(
    repro_path="$REPRO_SCRIPT",
    target_file="$TARGET_SCRIPT",
    repo_root="$FIXTURE_SANDBOX",
    fix_generator=lambda p, e, a: None,
    sandbox_root="$FIXTURE_SANDBOX",
    diff_out_path="$OUTSIDE_DIFF",
)
assert r3["status"] == "error" and "Diff output path" in r3["message"], f"r3 failed: {r3}"

# 4. Escalation out outside sandbox_root
r4 = run_self_healing_cycle(
    repro_path="$REPRO_SCRIPT",
    target_file="$TARGET_SCRIPT",
    repo_root="$FIXTURE_SANDBOX",
    fix_generator=lambda p, e, a: None,
    sandbox_root="$FIXTURE_SANDBOX",
    escalation_out_path="$OUTSIDE_ROLLUP",
)
assert r4["status"] == "error" and "Escalation output path" in r4["message"], f"r4 failed: {r4}"

print("API_CONTAINMENT_SUCCESS")
PYEOF
require_fixture_file "$API_TEST_DRIVER" "api-test-driver"

rc=0
out="$(PYTHONPATH="$ROOT/utils/py" python3 "$API_TEST_DRIVER" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "API_CONTAINMENT_SUCCESS" <<<"$out"; then
  pass "run_self_healing_cycle API directly defends against out-of-sandbox paths"
else
  fail "run_self_healing_cycle API containment defense failed (rc=$rc, out=$out)"
fi

# ── 6. Fixture sandbox heals fixture defect with mandatory gate & emits winning diff (GH-182 §1, §3) ─
HEAL_SANDBOX="$WORK/heal_sandbox"
mkdir -p "$HEAL_SANDBOX"
require_fixture "$HEAL_SANDBOX" "heal-sandbox"

HEAL_TARGET="$HEAL_SANDBOX/service.sh"
cat > "$HEAL_TARGET" <<'EOF_HT'
#!/usr/bin/env bash
if [ "${1:-}" = "--check" ]; then
  echo "service: broken" >&2
  exit 5
fi
if [ "${1:-}" = "--regression" ]; then
  echo "service: base feature ok"
  exit 0
fi
echo "service: ok"
exit 0
EOF_HT
chmod +x "$HEAL_TARGET"
require_fixture_file "$HEAL_TARGET" "heal-target"

HEAL_REPRO="$HEAL_SANDBOX/repro.sh"
cat > "$HEAL_REPRO" <<EOF_HR
#!/usr/bin/env bash
set -euo pipefail
RC=0
OUT="\$(bash "$HEAL_TARGET" --check 2>&1)" || RC=\$?
if [ "\$RC" -eq 0 ]; then
  exit 0
fi
exit 1
EOF_HR
chmod +x "$HEAL_REPRO"
require_fixture_file "$HEAL_REPRO" "heal-repro"

HEAL_REG="$HEAL_SANDBOX/regression.sh"
cat > "$HEAL_REG" <<EOF_HREG
#!/usr/bin/env bash
set -euo pipefail
bash "$HEAL_TARGET" --regression
EOF_HREG
chmod +x "$HEAL_REG"
require_fixture_file "$HEAL_REG" "heal-reg"

GENERATOR_SCRIPT="$HEAL_SANDBOX/generator.sh"
cat > "$GENERATOR_SCRIPT" <<'EOF_GEN'
#!/usr/bin/env bash
cat <<'EOF_FIX'
#!/usr/bin/env bash
if [ "${1:-}" = "--check" ]; then
  echo "service: fixed cleanly"
  exit 0
fi
if [ "${1:-}" = "--regression" ]; then
  echo "service: base feature ok"
  exit 0
fi
echo "service: ok"
exit 0
EOF_FIX
EOF_GEN
chmod +x "$GENERATOR_SCRIPT"
require_fixture_file "$GENERATOR_SCRIPT" "generator-script"

DIFF_FILE="$HEAL_SANDBOX/winning_diff.patch"
rc=0
out="$(python3 "$HEALER" --mode heal \
  --sandbox-root "$HEAL_SANDBOX" \
  --target-file "$HEAL_TARGET" \
  --repro "$HEAL_REPRO" \
  --regression-cmd "bash $HEAL_REG" \
  --generator-cmd "bash $GENERATOR_SCRIPT" \
  --diff-out "$DIFF_FILE" 2>&1)" || rc=$?

if [ "$rc" -eq 0 ] && [ -f "$DIFF_FILE" ] && grep -q "fixed cleanly" "$HEAL_TARGET" && grep -q "fixed cleanly" "$DIFF_FILE"; then
  pass "heal mode successfully repairs fixture defect in sandbox and writes winning diff file"
else
  fail "heal mode failed to repair fixture defect (rc=$rc, out=$out)"
fi

# ── 7. Escalation emits issue-rollup artifact (GH-182 Plan §3) ──────────────────────────────────
ESCALATE_SANDBOX="$WORK/escalate_sandbox"
mkdir -p "$ESCALATE_SANDBOX"
require_fixture "$ESCALATE_SANDBOX" "escalate-sandbox"

ESC_TARGET="$ESCALATE_SANDBOX/unsolvable.sh"
cat > "$ESC_TARGET" <<'EOF_ESC'
#!/usr/bin/env bash
exit 9
EOF_ESC
chmod +x "$ESC_TARGET"
require_fixture_file "$ESC_TARGET" "esc-target"

ESC_REPRO="$ESCALATE_SANDBOX/repro.sh"
cat > "$ESC_REPRO" <<EOF_ER
#!/usr/bin/env bash
set -euo pipefail
RC=0
OUT="\$(bash "$ESC_TARGET" 2>&1)" || RC=\$?
if [ "\$RC" -eq 0 ]; then
  exit 0
fi
exit 1
EOF_ER
chmod +x "$ESC_REPRO"
require_fixture_file "$ESC_REPRO" "esc-repro"

ESC_REG="$ESCALATE_SANDBOX/reg.sh"
cat > "$ESC_REG" <<'EOF_EREG'
#!/usr/bin/env bash
exit 0
EOF_EREG
chmod +x "$ESC_REG"
require_fixture_file "$ESC_REG" "esc-reg"

ROLLUP_FILE="$ESCALATE_SANDBOX/issue_body.md"
rc=0
out="$(python3 "$HEALER" --mode heal \
  --sandbox-root "$ESCALATE_SANDBOX" \
  --target-file "$ESC_TARGET" \
  --repro "$ESC_REPRO" \
  --regression-cmd "bash $ESC_REG" \
  --issue-rollup-out "$ROLLUP_FILE" 2>&1)" || rc=$?

if [ "$rc" -eq 1 ] && [ -f "$ROLLUP_FILE" ] && grep -q "Automated Self-Healing Escalation Report" "$ROLLUP_FILE" && grep -q "\- \[ \] \*\*Defect unresolved" "$ROLLUP_FILE"; then
  pass "unsolvable defect escalates with exit 1 and writes issue-rollup markdown artifact"
else
  fail "escalation failed to produce issue-rollup artifact (rc=$rc, out=$out)"
fi

# ── 8. Crash mid-attempt restores target file on ANY exit (GH-182 Plan §2, §4d) ─────────────────
CRASH_SANDBOX="$WORK/crash_sandbox"
mkdir -p "$CRASH_SANDBOX"
require_fixture "$CRASH_SANDBOX" "crash-sandbox"

CRASH_TARGET="$CRASH_SANDBOX/crash_target.sh"
ORIGINAL_CONTENT="ORIGINAL_CONTENT_PRE_CRASH_SENTINEL_GH182"
echo "$ORIGINAL_CONTENT" > "$CRASH_TARGET"
require_fixture_file "$CRASH_TARGET" "crash-target"

CRASH_REPRO="$CRASH_SANDBOX/repro.sh"
cat > "$CRASH_REPRO" <<'EOF_CR'
#!/usr/bin/env bash
exit 1
EOF_CR
chmod +x "$CRASH_REPRO"
require_fixture_file "$CRASH_REPRO" "crash-repro"

CRASH_DRIVER="$CRASH_SANDBOX/driver_crash_test.py"
cat > "$CRASH_DRIVER" <<PYEOF
import sys
from self_healer import run_self_healing_cycle

def crashing_generator(path, error_trace, attempt):
    # Overwrite target file before raising unhandled exception / crash
    with open(path, "w") as f:
        f.write("CORRUPTED_MID_ATTEMPT_CONTENT")
    raise RuntimeError("Simulated crash mid-attempt (kill/exception simulation)")

try:
    run_self_healing_cycle(
        repro_path="$CRASH_REPRO",
        target_file="$CRASH_TARGET",
        repo_root="$CRASH_SANDBOX",
        fix_generator=crashing_generator,
        max_attempts=1,
        sandbox_root="$CRASH_SANDBOX",
    )
except Exception:
    pass
PYEOF
require_fixture_file "$CRASH_DRIVER" "crash-driver"

rc=0
out="$(PYTHONPATH="$ROOT/utils/py" python3 "$CRASH_DRIVER" 2>&1)" || rc=$?
CONTENT_AFTER_CRASH="$(cat "$CRASH_TARGET")"

if [ "$CONTENT_AFTER_CRASH" = "$ORIGINAL_CONTENT" ]; then
  pass "target file restored to original content after mid-attempt crash / exception"
else
  fail "target file was left corrupted after mid-attempt crash: '$CONTENT_AFTER_CRASH'"
fi

# ── 9. Gate failure restores target file before next attempt & exit (GH-182 Plan §2) ────────────
GATE_FAIL_SANDBOX="$WORK/gate_fail_sandbox"
mkdir -p "$GATE_FAIL_SANDBOX"
require_fixture "$GATE_FAIL_SANDBOX" "gate-fail-sandbox"

GF_TARGET="$GATE_FAIL_SANDBOX/gf_target.sh"
ORIGINAL_GF="ORIGINAL_GF_UNTOUCHED_SENTINEL"
echo "$ORIGINAL_GF" > "$GF_TARGET"
require_fixture_file "$GF_TARGET" "gf-target"

GF_REPRO="$GATE_FAIL_SANDBOX/repro.sh"
cat > "$GF_REPRO" <<'EOF_GFR'
#!/usr/bin/env bash
exit 1
EOF_GFR
chmod +x "$GF_REPRO"
require_fixture_file "$GF_REPRO" "gf-repro"

GF_DRIVER="$GATE_FAIL_SANDBOX/driver_gf_test.py"
cat > "$GF_DRIVER" <<PYEOF
import sys
from self_healer import run_self_healing_cycle

def failed_patch_generator(path, error_trace, attempt):
    return "ATTEMPT_PATCH_CONTENT"

res = run_self_healing_cycle(
    repro_path="$GF_REPRO",
    target_file="$GF_TARGET",
    repo_root="$GATE_FAIL_SANDBOX",
    fix_generator=failed_patch_generator,
    max_attempts=2,
    sandbox_root="$GATE_FAIL_SANDBOX",
)
PYEOF
require_fixture_file "$GF_DRIVER" "gf-driver"

rc=0
out="$(PYTHONPATH="$ROOT/utils/py" python3 "$GF_DRIVER" 2>&1)" || rc=$?
CONTENT_AFTER_GF="$(cat "$GF_TARGET")"

if [ "$CONTENT_AFTER_GF" = "$ORIGINAL_GF" ]; then
  pass "target file restored to original content after gate failures and cycle termination"
else
  fail "target file was left corrupted after gate failure: '$CONTENT_AFTER_GF'"
fi

echo "  gh182-healer-facade-safety: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
