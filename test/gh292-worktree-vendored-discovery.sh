#!/usr/bin/env bash
set -euo pipefail
# GH-292 — a vendored .xyz/ lives only in the main checkout, but a linked
# worktree must still select its independent harness and driver lock.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd -P)"
FH="$REPO/skills/relay-xyz/find-harness.sh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh292-worktree.XXXXXX")"
# GH-177: $WORK is `rm -rf`'d by the EXIT trap below, so it must be proven a real,
# non-empty directory BEFORE the re-capture — an empty $WORK would make that trap
# the historical repo-wipe.
# The `&&` before each `exit` is deliberate, not a typo: test/mktemp-trap-guard.sh
# scans `;`-delimited segments, so a `{ echo ...; exit 1; }` would park the abort in
# a different segment from the `||` and read as an unguarded assignment.
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "  FAIL: mktemp -d produced no usable dir" >&2 && exit 1; }
WORK="$(cd "$WORK" && pwd -P)"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "  FAIL: could not resolve \$WORK" >&2 && exit 1; }
MAIN="$WORK/main"
LINKED="$WORK/linked"
pass=0; fail=0

cleanup() {
  git -C "$MAIN" worktree remove --force "$LINKED" >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

# ok/bad take a decided verdict, not a command string to evaluate. Two reasons: the
# GH-64 security gate rejects a new unsanitized-evaluation helper (correctly), and
# that form forced every assertion into a nested-quoted string, which silently
# misfires on any path containing a quote or a space.
ok()  { echo "  PASS: $1"; pass=$((pass + 1)); }
bad() { echo "  FAIL: $1" >&2; fail=$((fail + 1)); }

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
[ "$main_root" = "$MAIN/.xyz" ] \
  && ok "main checkout: local vendored harness remains selected" \
  || bad "main checkout: local vendored harness remains selected (got $main_root)"

# The linked worktree has no .xyz/, so this exercises the shared .git probe.
[ ! -d "$LINKED/.xyz" ] || { echo "  FAIL: linked fixture unexpectedly has .xyz/"; exit 1; }
linked_root="$(cd "$LINKED" && bash "$FH" --root)"
[ "$linked_root" = "$MAIN/.xyz" ] \
  && ok "linked worktree: selects main checkout's vendored harness" \
  || bad "linked worktree: selects main checkout's vendored harness (got $linked_root)"

linked_env="$(cd "$LINKED" && bash "$FH" --env)"
printf '%s\n' "$linked_env" | grep -Fq "export TICK=$MAIN/.xyz/bin/tick" \
  && ok "linked worktree: selects the vendored tick and its lock root" \
  || bad "linked worktree: selects the vendored tick and its lock root"

linked_check="$(cd "$LINKED" && bash "$FH" --check 2>&1)"
printf '%s' "$linked_check" | grep -q 'CENTRALIZED harness' \
  && bad "linked worktree: does not fall back to the centralized-harness warning" \
  || ok "linked worktree: does not fall back to the centralized-harness warning"

# An incomplete main-checkout vendor cannot be selected. The fallback remains
# non-fatal, but the readiness output must name the existing vendor truthfully.
rm -f "$MAIN/.xyz/bin/tick"
fallback_root="$(cd "$LINKED" && bash "$FH" --root)"
[ "$fallback_root" = "$REPO" ] \
  && ok "unusable vendor: centralized fallback remains available" \
  || bad "unusable vendor: centralized fallback remains available (got $fallback_root)"

fallback_check="$(cd "$LINKED" && bash "$FH" --check 2>&1)"
printf '%s' "$fallback_check" | grep -Fq "vendored .xyz found in the main checkout at $MAIN/.xyz" \
  && ok "unusable vendor: readiness names the main-checkout .xyz path" \
  || bad "unusable vendor: readiness names the main-checkout .xyz path"

printf '%s' "$fallback_check" | grep -q 'CENTRALIZED harness' \
  && ok "unusable vendor: readiness warns about centralized fallback" \
  || bad "unusable vendor: readiness warns about centralized fallback"

echo "  gh292 worktree vendored discovery: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
