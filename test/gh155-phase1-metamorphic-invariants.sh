#!/usr/bin/env bash
# GH-155 Phase 1: Metamorphic Invariant Assertions & Sandbox Hardening Suite
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

# Source shared fixture-guard (GH-1 / GH-10 / GH-564 / GH-567)
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh155-metamorphic.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh155-phase1-metamorphic-invariants =="

# 1. Oracle file existence
ORACLE="$ROOT/utils/py/metamorphic_oracle.py"
if [ -f "$ORACLE" ] && [ -x "$ORACLE" ]; then
  pass "utils/py/metamorphic_oracle.py exists and is executable"
else
  fail "utils/py/metamorphic_oracle.py missing or not executable"
fi

# 2. Run full built-in oracle suite
rc=0
out="$(python3 "$ORACLE" --mode suite 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "29/29 assertions passed" <<<"$out"; then
  pass "metamorphic_oracle.py --mode suite passes 29/29 assertions"
else
  fail "metamorphic_oracle.py --mode suite failed (rc=$rc, out=$out)"
fi

# 3. CLI Zero-Mutation Positive Control
rc=0
out="$(python3 "$ORACLE" --mode zero-mutation --cmd "echo safe" --cwd "$ROOT" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "Zero-mutation verdict: PASS" <<<"$out"; then
  pass "Zero-mutation CLI mode passes on non-mutating command"
else
  fail "Zero-mutation CLI mode failed on non-mutating command (rc=$rc)"
fi

# 4. CLI Zero-Mutation Negative Control (Falsifiability)
TMP_REPO="$WORK/test-zero-mutation"
mkdir -p "$TMP_REPO"
require_fixture "$TMP_REPO" "zero-mutation-repo"

git -C "$TMP_REPO" init -q
git -C "$TMP_REPO" config user.email test@test.local
git -C "$TMP_REPO" config user.name "Test"
touch "$TMP_REPO/tracked.txt"
git -C "$TMP_REPO" add tracked.txt
git -C "$TMP_REPO" commit -m "init" -q

rc=0
out="$(python3 "$ORACLE" --mode zero-mutation --cmd "touch stray.tmp" --cwd "$TMP_REPO" 2>&1)" || rc=$?
if [ "$rc" -eq 1 ] && grep -q "Zero-mutation verdict: FAIL" <<<"$out"; then
  pass "Zero-mutation CLI mode correctly catches and flags stray file mutation (negative control)"
else
  fail "Zero-mutation negative control did not flag mutation (rc=$rc, out=$out)"
fi

# 5. CLI Idempotence Positive & Negative Controls
rc=0
out="$(python3 "$ORACLE" --mode idempotence --cmd "echo stable-token" --repetitions 3 --cwd "$ROOT" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "Idempotence verdict: PASS" <<<"$out"; then
  pass "Idempotence CLI mode passes on deterministic output"
else
  fail "Idempotence CLI mode failed on deterministic output (rc=$rc)"
fi

rc=0
out="$(python3 "$ORACLE" --mode idempotence --cmd "python3 -c 'import random; print(random.random())'" --repetitions 3 --cwd "$ROOT" 2>&1)" || rc=$?
if [ "$rc" -eq 1 ] && grep -q "Idempotence verdict: FAIL" <<<"$out"; then
  pass "Idempotence CLI mode correctly flags non-deterministic output drift (negative control)"
else
  fail "Idempotence negative control did not flag non-determinism (rc=$rc, out=$out)"
fi

# 6. CLI Containment Positive & Negative Controls
TMP_SBOX="$WORK/test-containment"
mkdir -p "$TMP_SBOX/child"
require_fixture "$TMP_SBOX" "containment-sandbox"

rc=0
out="$(python3 "$ORACLE" --mode containment --path "$TMP_SBOX/child" --sandbox "$TMP_SBOX" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "Containment verdict: PASS" <<<"$out"; then
  pass "Containment CLI mode passes on valid descendant path"
else
  fail "Containment CLI mode failed on valid child path (rc=$rc, out=$out)"
fi

rc=0
out="$(python3 "$ORACLE" --mode containment --path "$TMP_SBOX/../../etc" --sandbox "$TMP_SBOX" 2>&1)" || rc=$?
if [ "$rc" -eq 1 ] && grep -q "Containment verdict: FAIL" <<<"$out"; then
  pass "Containment CLI mode correctly catches and refuses path traversal escape (negative control)"
else
  fail "Containment negative control did not catch traversal (rc=$rc, out=$out)"
fi

echo "  gh155-phase1-metamorphic-invariants: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
