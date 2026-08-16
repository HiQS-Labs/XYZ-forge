#!/usr/bin/env bash
# test/gh448-driver-lock-resolver.sh — GH-448: the shared driver-lock resolver.
#
# marathon-drive writes its lock to the git COMMON dir when .git is a FILE (a linked worktree). Every
# read-only consumer used to guess the path with its OWN 2-branch inline logic (dir vs "everything
# else"), which is wrong for the worktree case — so a LIVE marathon reported as IDLE. This test:
#
#   A. Parity — the Bash resolver (relay-automation/driver-lock-lib.sh) and the Python resolver
#      (utils/py/rtl.py's driver_lock_path) agree byte-for-byte on all three branches: .git dir,
#      .git file (real linked worktree), and no .git (vendored).
#   B. Negative control (per #419) — the OLD 2-branch logic each consumer carried pre-fix, replayed
#      verbatim against the SAME linked-worktree fixture, observably misses the lock the driver holds.
#   C. End-to-end, real linked worktree — marathon-ls.sh, utils/hq/marathon-live.sh, and
#      skills/relay-xyz/find-harness.sh --check, run for real against a `git worktree add` fixture
#      with the lock held at the driver's real (common-dir) path, all observe it correctly.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
LIB="$ROOT/relay-automation/driver-lock-lib.sh"
LS="$ROOT/relay-automation/marathon-ls.sh"
LIVE="$ROOT/utils/hq/marathon-live.sh"
FH="$ROOT/skills/relay-xyz/find-harness.sh"

# shellcheck source=relay-automation/driver-lock-lib.sh
. "$LIB"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh448-driver-lock.XXXXXX")"
# GH-177: guard BEFORE the re-capture below and BEFORE the rm -rf trap is armed. A failed mktemp
# leaves $WORK empty, `cd ""` succeeds (it is a no-op), and `pwd -P` would then hand back the
# script's own cwd — the repository root — straight into `rm -rf`. That is the historical repo-wipe
# shape, and test/mktemp-trap-guard.sh caught this exact omission in CI when the re-capture was
# added without it. Both guards abort before the trap exists, so nothing can be removed.
# The `&& exit 1` inside the braces is deliberate and must not be "tidied" to `; exit 1`: the guard
# scans `;`-delimited segments, so a `{ echo ...; exit 1; }` parks the abort in a different segment
# from the `||` and reads as unguarded. Same shape as test/gh292-worktree-vendored-discovery.sh:16.
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "  FAIL: mktemp -d produced no usable dir" >&2 && exit 1; }
# Resolve to the PHYSICAL path before deriving any fixture path from it. The resolver under test
# reads `git rev-parse --path-format=absolute --git-common-dir`, and git ALWAYS reports a physical
# path; on macOS $TMPDIR lives under /var, a symlink to /private/var, so a $TMPDIR-derived expected
# string ("/var/...") never equals git's answer ("/private/var/...") and 3 of 17 assertions fail.
# Linux CI has no such symlink, which is why this passed there (17/0) and failed only on macOS —
# an environment split, not a defect in the resolver: the driver writes the lock through this same
# resolver, so driver and consumers agree on whatever path it returns.
WORK="$(cd "$WORK" && pwd -P)"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "  FAIL: could not resolve \$WORK to a physical path" >&2 && exit 1; }
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { printf '  PASS: %s\n' "$*"; PASS=$((PASS+1)); }
fail() { printf '  FAIL: %s\n' "$*" >&2; FAIL=$((FAIL+1)); }

echo "== test: gh448-driver-lock-resolver =="
echo "  workdir: $WORK"

py_resolve() {  # <repo> -> prints the python resolver's lock path
  python3 -c '
import sys
sys.path.insert(0, sys.argv[2])
from rtl import driver_lock_path
print(driver_lock_path(sys.argv[1])[0], end="")
' "$1" "$ROOT/utils/py"
}

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

# (1) Normal clone: .git is a directory.
DIR_REPO="$WORK/dir-repo"
mkdir -p "$DIR_REPO/.git"

# (2) Vendored: no .git at all.
ABSENT_REPO="$WORK/absent-repo"
mkdir -p "$ABSENT_REPO"

# (3) Real linked worktree: .git is a FILE pointing at the shared gitdir.
MAIN_REPO="$WORK/main-repo"
mkdir -p "$MAIN_REPO"
git init -q "$MAIN_REPO"
git -C "$MAIN_REPO" config user.email t@example.com
git -C "$MAIN_REPO" config user.name "gh448 test"
printf 'seed\n' >"$MAIN_REPO/seed.txt"
git -C "$MAIN_REPO" add seed.txt
git -C "$MAIN_REPO" commit -qm seed
WT="$WORK/wt"
git -C "$MAIN_REPO" worktree add -q "$WT" -b gh448-wt-branch
[ -f "$WT/.git" ] && pass "fixture: linked worktree's .git is a FILE (not a dir)" \
  || fail "fixture setup: expected $WT/.git to be a file"

COMMON_LOCK="$MAIN_REPO/.git/relay-driver.lock"

# ===========================================================================
# A. Parity — Bash resolver vs Python resolver, all three branches
# ===========================================================================
echo "-- A. resolver parity (bash vs python) --"

for case_name_repo in "dir:$DIR_REPO" "absent:$ABSENT_REPO" "worktree:$WT"; do
  name="${case_name_repo%%:*}"; repo="${case_name_repo#*:}"
  bash_out="$(driver_lock_path_for_repo "$repo")"
  py_out="$(py_resolve "$repo")"
  [ "$bash_out" = "$py_out" ] \
    && pass "parity ($name): bash and python agree ($bash_out)" \
    || fail "parity ($name): bash='$bash_out' python='$py_out'"
done

[ "$(driver_lock_path_for_repo "$WT")" = "$COMMON_LOCK" ] \
  && pass "worktree case resolves to the git COMMON dir, not <worktree>/.git/…" \
  || fail "worktree case resolved wrong: $(driver_lock_path_for_repo "$WT") (expected $COMMON_LOCK)"

# ===========================================================================
# B. Negative control — the OLD 2-branch logic each site carried, replayed
#    verbatim against the SAME worktree fixture. Per #419: observed, not
#    asserted-in-prose. All three must MISS the lock the driver holds.
# ===========================================================================
echo "-- B. negative control: pre-fix 2-branch logic misses the worktree lock --"

# marathon-ls.sh's original lock_path_for_repo (pre-GH-448):
old_marathon_ls_lock() {
  local repo="$1"
  if [ -d "$repo/.git" ]; then printf '%s/.git/relay-driver.lock' "$repo"
  else printf '%s/.relay-driver.lock' "$repo"; fi
}

# utils/hq/marathon-live.sh's original driver_lock_path (pre-GH-448):
old_marathon_live_lock() {
  local repo="$1"
  [ -e "$repo/.git/relay-driver.lock" ] && { printf '%s' "$repo/.git/relay-driver.lock"; return 0; }
  [ -e "$repo/.xyz/.relay-driver.lock" ] && { printf '%s' "$repo/.xyz/.relay-driver.lock"; return 0; }
  return 1
}

mkdir -p "$COMMON_LOCK"; printf '%s\n' "$$" >"$COMMON_LOCK/pid"

old_ls_path="$(old_marathon_ls_lock "$WT")"
[ "$old_ls_path" != "$COMMON_LOCK" ] && [ ! -e "$old_ls_path" ] \
  && pass "negative control: old marathon-ls.sh logic guesses '$old_ls_path' — misses the held lock" \
  || fail "negative control: old marathon-ls.sh logic unexpectedly found the lock"

if old_live_path="$(old_marathon_live_lock "$WT")"; then
  fail "negative control: old marathon-live.sh logic unexpectedly found the lock ($old_live_path)"
else
  pass "negative control: old marathon-live.sh logic (checks .git/… or .xyz/… under \$WT) misses the held lock"
fi

old_fh_found=0
for _lk in "$WT/.git/relay-driver.lock" "$WT/.relay-driver.lock"; do
  [ -d "$_lk" ] && old_fh_found=1
done
[ "$old_fh_found" -eq 0 ] \
  && pass "negative control: old find-harness.sh 2-candidate loop misses the held lock" \
  || fail "negative control: old find-harness.sh 2-candidate loop unexpectedly found the lock"

rm -rf "$COMMON_LOCK"

# ===========================================================================
# C. End-to-end, real linked worktree — the ACTUAL (fixed) scripts
# ===========================================================================
echo "-- C. end-to-end: fixed scripts observe LIVE from a linked worktree --"

mkdir -p "$COMMON_LOCK"; printf '%s\n' "$$" >"$COMMON_LOCK/pid"

# C1. marathon-ls.sh — registry row pointing at the worktree.
REGISTRY="$WORK/registry.tsv"
printf 'install_dir\tlast_install_utc\ttick_version\tsource_commit\tcoordinated_repo\n' >"$REGISTRY"
printf '%s\t2026-08-08\tv1\tabc\t%s\n' "$WT/.xyz" "$WT" >>"$REGISTRY"

ls_out="$(XYZ_REGISTRY="$REGISTRY" bash "$LS" 2>/dev/null || true)"
ls_state="$(printf '%s' "$ls_out" | awk -F'\t' -v r="$WT" '$1 == r { print $2 }')"
[ "$ls_state" = "LIVE" ] \
  && pass "marathon-ls.sh: linked worktree with held common-dir lock -> LIVE" \
  || fail "marathon-ls.sh: expected LIVE, got '${ls_state:-<no row>}'"

# C2. utils/hq/marathon-live.sh — claimed task + the same held lock.
mkdir -p "$WT/.tick" "$WT/bin"
cat >"$WT/bin/tick" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$WT/bin/tick"
{
  printf '# Coordination State\n\n## Open\n_(none)_\n\n## Claimed\n'
  printf -- '- MARATHON-GH448-DRIVER-LOCK-TURN by agy\n'
  printf '\n## Done\n_(none)_\n'
} >"$WT/.tick/STATE.md"

XYZ_REG2="$WORK/xyz.tsv"
printf '%s\t2026-08-08T00:00:00Z\tv1\tabc\t%s\n' "$WT/.xyz" "$WT" >"$XYZ_REG2"

LIVE_OUT="$WORK/HQ-MARATHON-LIVE-gh448.md"
HQ_PDDA_REGISTRY_DIR="$WORK/empty-pdda" \
HQ_REBALANCE_DB="$WORK/nonexistent.db" \
HQ_XYZ_REGISTRY="$XYZ_REG2" \
HQ_SEARCH_ROOTS="$WORK" \
HQ_MARATHON_LIVE_TODAY="2026-08-08" \
HQ_MARATHON_LIVE_NOW="2026-08-08T12:00:00Z" \
HQ_MARATHON_LIVE_NOW_EPOCH="1000000000" \
bash "$LIVE" --out "$LIVE_OUT" >/dev/null 2>&1
grep -q '🟢 live' "$LIVE_OUT" 2>/dev/null \
  && pass "marathon-live.sh: claimed task + linked-worktree common-dir lock -> 🟢 live" \
  || fail "marathon-live.sh: expected a 🟢 live row: $(grep -E '^\| ' "$LIVE_OUT" 2>/dev/null || echo '(no report)')"

# C3. find-harness.sh --check — a "harness" fixture whose skill script + lib live in a linked
# worktree, invoked from a separate FOREIGN caller repo so the concurrency-warning gate fires.
HARNESS_MAIN="$WORK/harness-main"
mkdir -p "$HARNESS_MAIN/relay-automation" "$HARNESS_MAIN/skills/relay-xyz"
printf '#!/usr/bin/env bash\n:\n' >"$HARNESS_MAIN/relay-automation/relay-drive.sh"
chmod +x "$HARNESS_MAIN/relay-automation/relay-drive.sh"
cp "$LIB" "$HARNESS_MAIN/relay-automation/driver-lock-lib.sh"
cp "$FH" "$HARNESS_MAIN/skills/relay-xyz/find-harness.sh"
git init -q "$HARNESS_MAIN"
git -C "$HARNESS_MAIN" config user.email t@example.com
git -C "$HARNESS_MAIN" config user.name "gh448 test"
git -C "$HARNESS_MAIN" add -A
git -C "$HARNESS_MAIN" commit -qm seed
HARNESS_WT="$WORK/harness-wt"
git -C "$HARNESS_MAIN" worktree add -q "$HARNESS_WT" -b gh448-harness-wt-branch

HARNESS_COMMON_LOCK="$HARNESS_MAIN/.git/relay-driver.lock"
mkdir -p "$HARNESS_COMMON_LOCK"; printf '%s\n' "$$" >"$HARNESS_COMMON_LOCK/pid"

FOREIGN="$WORK/foreign"
mkdir -p "$FOREIGN"
git init -q "$FOREIGN"

fh_out="$(cd "$FOREIGN" && bash "$HARNESS_WT/skills/relay-xyz/find-harness.sh" --check 2>&1)"
printf '%s' "$fh_out" | grep -q 'a driver lock is currently HELD' \
  && pass "find-harness.sh --check: linked-worktree harness + held common-dir lock -> warns" \
  || fail "find-harness.sh --check: expected a held-lock warning, got: $fh_out"
printf '%s' "$fh_out" | grep -qF "$HARNESS_COMMON_LOCK" \
  && pass "find-harness.sh --check: warning names the REAL (common-dir) lock path" \
  || fail "find-harness.sh --check: warning did not name $HARNESS_COMMON_LOCK: $fh_out"

# ---------------------------------------------------------------------------
echo "-- syntax check --"
for s in "$LIB" "$LS" "$LIVE" "$FH" "$HERE/gh448-driver-lock-resolver.sh"; do
  bash -n "$s" 2>/dev/null && pass "syntax OK: $(basename "$s")" || fail "syntax error in: $s"
done

printf '\ngh448-driver-lock-resolver: %d pass, %d fail\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
