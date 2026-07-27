#!/usr/bin/env bash
set -euo pipefail
# GH-292 — a vendored .xyz/ lives only in the main checkout, but a linked
# worktree must still select its independent harness and driver lock.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd -P)"
FH="$REPO/skills/relay-xyz/find-harness.sh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh292-worktree.XXXXXX")"
WORK="$(cd "$WORK" && pwd -P)"
MAIN="$WORK/main"
LINKED="$WORK/linked"
pass=0; fail=0

cleanup() {
  git -C "$MAIN" worktree remove --force "$LINKED" >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

ok() {
  if eval "$2"; then
    echo "  PASS: $1"
    pass=$((pass + 1))
  else
    echo "  FAIL: $1" >&2
    fail=$((fail + 1))
  fi
}

seed_vendored_harness() {
  mkdir -p "$MAIN/.xyz/relay-automation" "$MAIN/.xyz/bin"
  printf '#!/usr/bin/env bash\n:\n' > "$MAIN/.xyz/relay-automation/relay-drive.sh"
  printf '#!/usr/bin/env bash\n:\n' > "$MAIN/.xyz/bin/tick"
  chmod +x "$MAIN/.xyz/relay-automation/relay-drive.sh" "$MAIN/.xyz/bin/tick"
}

echo "gh292 worktree vendored discovery:"
[ -x "$FH" ] || { echo "  FAIL: locator not executable at $FH"; exit 1; }

git init -q "$MAIN"
git -C "$MAIN" config user.email gh292@test
git -C "$MAIN" config user.name gh292
touch "$MAIN/.seed"
git -C "$MAIN" add .seed
git -C "$MAIN" commit -qm init
seed_vendored_harness
git -C "$MAIN" worktree add -q -b gh292-linked "$LINKED" HEAD

# The main checkout's result is the control: its local .xyz/ remains first.
main_root="$(cd "$MAIN" && bash "$FH" --root)"
ok "main checkout: local vendored harness remains selected" "[ '$main_root' = '$MAIN/.xyz' ]"

# The linked worktree has no .xyz/, so this exercises the shared .git probe.
[ ! -d "$LINKED/.xyz" ] || { echo "  FAIL: linked fixture unexpectedly has .xyz/"; exit 1; }
linked_root="$(cd "$LINKED" && bash "$FH" --root)"
ok "linked worktree: selects main checkout's vendored harness" "[ '$linked_root' = '$MAIN/.xyz' ]"
linked_env="$(cd "$LINKED" && bash "$FH" --env)"
ok "linked worktree: selects the vendored tick and its lock root" "printf '%s\\n' \"$linked_env\" | grep -Fq 'export TICK=$MAIN/.xyz/bin/tick'"
linked_check="$(cd "$LINKED" && bash "$FH" --check 2>&1)"
ok "linked worktree: does not fall back to the centralized-harness warning" "! printf '%s' \"$linked_check\" | grep -q 'CENTRALIZED harness'"

# An incomplete main-checkout vendor cannot be selected. The fallback remains
# non-fatal, but the readiness output must name the existing vendor truthfully.
rm -f "$MAIN/.xyz/bin/tick"
fallback_root="$(cd "$LINKED" && bash "$FH" --root)"
ok "unusable vendor: centralized fallback remains available" "[ '$fallback_root' = '$REPO' ]"
fallback_check="$(cd "$LINKED" && bash "$FH" --check 2>&1)"
ok "unusable vendor: readiness names the main-checkout .xyz path" "printf '%s' \"$fallback_check\" | grep -Fq 'vendored .xyz found in the main checkout at $MAIN/.xyz'"
ok "unusable vendor: readiness warns about centralized fallback" "printf '%s' \"$fallback_check\" | grep -q 'CENTRALIZED harness'"

echo "  gh292 worktree vendored discovery: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
