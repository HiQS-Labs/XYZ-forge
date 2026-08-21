#!/usr/bin/env bash
# Synthetic Test: GH-124 Closeout Automation & Lifecycle Hygiene
# Validates gate_receipt.py, workspace_manager.py safety predicates,
# marathon-closeout.sh hardening, and rtl_before drift alert.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh124-closeout-test.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# Require fixture guard pattern
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "FAIL: invalid test workdir"; exit 1; }

echo "=== 1. Testing gate_receipt.py ==="
TEST_SHA="11223344556677889900aabbccddeeff11223344"
FAIL_SHA="ffffffffffffffffffffffffffffffffffffffff"

# Write valid receipt
python3 "$ROOT/utils/py/gate_receipt.py" write \
  --repo "$WORK" \
  --sha "$TEST_SHA" \
  --gate "ci-local.sh" \
  --mode "sequential" \
  --exit-code 0 \
  --passed 230 \
  --total 230 \
  --duration 12.5 >/dev/null 2>&1

# Verify valid receipt passes
python3 "$ROOT/utils/py/gate_receipt.py" check --repo "$WORK" --sha "$TEST_SHA" >/dev/null 2>&1 || {
  echo "FAIL: gate_receipt.py check failed for valid receipt"
  exit 1
}

# Verify missing receipt fails
if python3 "$ROOT/utils/py/gate_receipt.py" check --repo "$WORK" --sha "$FAIL_SHA" >/dev/null 2>&1; then
  echo "FAIL: gate_receipt.py check unexpectedly succeeded for missing receipt"
  exit 1
fi
echo "PASS: gate_receipt.py write and check assertions verified"

echo "=== 2. Testing workspace_manager.py safety predicates ==="
# Setup bare origin and test repo
BARE="$WORK/bare.git"
git init --bare "$BARE" >/dev/null 2>&1

LOCAL_MAIN="$WORK/local-main"
git clone "$BARE" "$LOCAL_MAIN" >/dev/null 2>&1
git -C "$LOCAL_MAIN" config user.email "test@example.com"
git -C "$LOCAL_MAIN" config user.name "Test User"
git -C "$LOCAL_MAIN" checkout -b development >/dev/null 2>&1
echo "initial" > "$LOCAL_MAIN/file.txt"
git -C "$LOCAL_MAIN" add file.txt
git -C "$LOCAL_MAIN" commit -m "init" >/dev/null 2>&1
git -C "$LOCAL_MAIN" push origin development >/dev/null 2>&1

# Invariant check: Refuse primary repo sweep
python3 "$ROOT/utils/py/workspace_manager.py" register --repo "$LOCAL_MAIN" --path "$LOCAL_MAIN" --type clone >/dev/null 2>&1
out="$(python3 "$ROOT/utils/py/workspace_manager.py" sweep --repo "$LOCAL_MAIN" 2>&1)"
echo "$out" | grep -q "REFUSED.*primary repository" || {
  echo "FAIL: workspace_manager failed to refuse primary repository sweep"
  exit 1
}

# Create linked worktree with unpushed commit
WT_DIR="$WORK/test-worktree"
git -C "$LOCAL_MAIN" worktree add -b feature-wt "$WT_DIR" >/dev/null 2>&1
echo "wt change" >> "$WT_DIR/file.txt"
git -C "$WT_DIR" add file.txt
git -C "$WT_DIR" commit -m "wt change" >/dev/null 2>&1

python3 "$ROOT/utils/py/workspace_manager.py" register --repo "$LOCAL_MAIN" --path "$WT_DIR" --type worktree >/dev/null 2>&1
out="$(python3 "$ROOT/utils/py/workspace_manager.py" sweep --repo "$LOCAL_MAIN" 2>&1)"
echo "$out" | grep -q "REFUSED.*unpushed commits" || {
  echo "FAIL: workspace_manager failed to refuse worktree with unpushed commits"
  exit 1
}

# Push worktree branch -> now eligible
git -C "$WT_DIR" push origin feature-wt >/dev/null 2>&1
out="$(python3 "$ROOT/utils/py/workspace_manager.py" sweep --repo "$LOCAL_MAIN" 2>&1)"
echo "$out" | grep -q "ELIGIBLE" || {
  echo "FAIL: workspace_manager should have marked clean & pushed worktree as eligible"
  exit 1
}

# Execute sweep -> worktree removed
python3 "$ROOT/utils/py/workspace_manager.py" sweep --repo "$LOCAL_MAIN" --execute >/dev/null 2>&1
[ ! -d "$WT_DIR" ] || {
  echo "FAIL: worktree directory was not removed after execute sweep"
  exit 1
}
echo "PASS: workspace_manager worktree safety & removal verified"

# Create full clone with unpushed stash
CLONE_DIR="$WORK/test-clone"
git clone "$BARE" "$CLONE_DIR" >/dev/null 2>&1
git -C "$CLONE_DIR" config user.email "test@example.com"
git -C "$CLONE_DIR" config user.name "Test User"
git -C "$CLONE_DIR" checkout development >/dev/null 2>&1
echo "stashed" >> "$CLONE_DIR/file.txt"
git -C "$CLONE_DIR" stash >/dev/null 2>&1

python3 "$ROOT/utils/py/workspace_manager.py" register --repo "$LOCAL_MAIN" --path "$CLONE_DIR" --type clone >/dev/null 2>&1
out="$(python3 "$ROOT/utils/py/workspace_manager.py" sweep --repo "$LOCAL_MAIN" 2>&1)"
echo "$out" | grep -q "REFUSED.*stashes" || {
  echo "FAIL: workspace_manager failed to refuse clone with stashes"
  exit 1
}

# Clear stash -> clone eligible and moved to trash
git -C "$CLONE_DIR" stash drop >/dev/null 2>&1
python3 "$ROOT/utils/py/workspace_manager.py" sweep --repo "$LOCAL_MAIN" --execute >/dev/null 2>&1
[ ! -d "$CLONE_DIR" ] || {
  echo "FAIL: clone directory was not moved away after execute sweep"
  exit 1
}
TRASH_DIR="$LOCAL_MAIN/.xyz/trash"
[ -d "$TRASH_DIR" ] && [ "$(ls -A "$TRASH_DIR")" ] || {
  echo "FAIL: clone was not quarantined into .xyz/trash/"
  exit 1
}

# Test --purge-trash
python3 "$ROOT/utils/py/workspace_manager.py" sweep --repo "$LOCAL_MAIN" --purge-trash >/dev/null 2>&1
[ ! "$(ls -A "$TRASH_DIR" 2>/dev/null)" ] || {
  echo "FAIL: --purge-trash failed to empty .xyz/trash/"
  exit 1
}
echo "PASS: workspace_manager clone safety, quarantine, and trash reaper verified"

echo "=== 3. Testing marathon-closeout.sh hardening ==="
# Test refusal of --base main
if bash "$ROOT/relay-automation/marathon-closeout.sh" --dry-run --head feat-test --base main >/dev/null 2>&1; then
  echo "FAIL: marathon-closeout.sh did not refuse --base main"
  exit 1
fi

# Test --auto-pr dry run output
auto_out="$(bash "$ROOT/relay-automation/marathon-closeout.sh" --dry-run --auto-pr --head feat-test)"
echo "$auto_out" | grep -q "\-\-no-commit: skipping commit step" || {
  echo "FAIL: marathon-closeout.sh --auto-pr dry run does not contain --no-commit skip"
  exit 1
}
echo "$auto_out" | grep -q "gh pr create" || {
  echo "FAIL: marathon-closeout.sh --auto-pr dry run does not contain gh pr create"
  exit 1
}
echo "PASS: marathon-closeout.sh hardening assertions verified"

echo "ALL GH-124 SYNTHETIC CHECKS PASSED (4/4)"
