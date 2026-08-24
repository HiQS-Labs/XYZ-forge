#!/usr/bin/env bash
set -uo pipefail

# gh50-sandboxed-git-guard.sh — GH-50: a guarded tracking switch must refuse
# before it can rewrite the index or working tree when .git/config is read-only.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
GUARD="$ROOT/utils/git-sandbox-guard.sh"

pass=0
fail=0
ok() {
  label="$1"
  shift
  if "$@"; then
    echo "  PASS: $label"
    pass=$((pass + 1))
  else
    echo "  FAIL: $label" >&2
    fail=$((fail + 1))
  fi
}

echo "== test: gh50-sandboxed-git-guard =="

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh50-sandbox-guard.XXXXXX")"
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
cleanup() {
  [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"
}
trap cleanup EXIT

R="$WORK/repo"
mkdir -p "$R"
require_fixture "$R" "GH-50 repository"

git -C "$R" init -q
git -C "$R" config user.email test@example.invalid
git -C "$R" config user.name "GH-50 test"
printf 'main\n' > "$R/payload.txt"
git -C "$R" add payload.txt
git -C "$R" commit -qm main
git -C "$R" branch -M main
git -C "$R" switch -qc topic
printf 'topic\n' > "$R/payload.txt"
git -C "$R" commit -qam topic
git -C "$R" switch -q main

CONFIG="$R/.git/config"
require_fixture_file "$CONFIG" "GH-50 config"
cp "$R/payload.txt" "$WORK/payload.before"
cp "$CONFIG" "$WORK/config.before"
chmod a-w "$CONFIG"

OUT="$WORK/refusal.out"
"$GUARD" --repo "$R" --operation "git switch --track" -- \
  git -C "$R" switch --track -c tracked topic >"$OUT" 2>&1
rc=$?

ok "guard refuses the read-only config with exit 2" test "$rc" -eq 2
ok "refusal is named and says the operation was not attempted" \
  grep -q "git-sandbox-guard: REFUSING.*not attempted (GH-50)" "$OUT"
ok "refusal names the config write problem" grep -q "config.*not writable" "$OUT"
ok "working-tree payload is byte-identical after refusal" cmp -s "$WORK/payload.before" "$R/payload.txt"
ok "HEAD remains on main after refusal" test "$(git -C "$R" symbolic-ref --short HEAD)" = main
if git -C "$R" show-ref --verify --quiet refs/heads/tracked; then
  echo "  FAIL: refused command created the tracked branch" >&2
  fail=$((fail + 1))
else
  echo "  PASS: refused command did not create the tracked branch"
  pass=$((pass + 1))
fi
ok "config bytes are unchanged after refusal" cmp -s "$WORK/config.before" "$CONFIG"
ok "config-lock probe leaves no lock behind" test ! -e "$CONFIG.lock"

# Control: once config writes are possible, the wrapper must run the exact command rather
# than acting as a blanket branch-operation ban.
chmod u+w "$CONFIG"
"$GUARD" --repo "$R" --operation "git switch --track" -- \
  git -C "$R" switch --track -c tracked topic >"$WORK/control.out" 2>&1
control_rc=$?
ok "writable-config control executes the guarded command" test "$control_rc" -eq 0
ok "writable-config control reaches the topic content" grep -q '^topic$' "$R/payload.txt"
ok "writable-config control switches to the new branch" \
  test "$(git -C "$R" symbolic-ref --short HEAD)" = tracked

echo "  gh50-sandboxed-git-guard: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
