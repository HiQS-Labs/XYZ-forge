set -u
SRC="$PWD"
L="$SRC/relay-automation/relay-turn-lib.sh"
PKG="$SRC/skills/1-hourly/relay-automation/relay-pkg.tar.gz"
for v in $(env | sed -n 's/^\(GIT_[A-Za-z_]*\)=.*/\1/p'); do unset "$v"; done
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
T="$(mktemp -d "${TMPDIR:-/tmp}/gh1638-probe.XXXXXX")" || exit 2
st=0
fail() { echo "$*" >&2; st=1; }
# Packaged copy must match the live library (make-pkg.sh regenerated).
mkdir -p "$T/pkg" && tar xzf "$PKG" -C "$T/pkg" relay-automation/relay-turn-lib.sh 2>/dev/null \
  && cmp -s "$T/pkg/relay-automation/relay-turn-lib.sh" "$L" || fail "relay-pkg.tar.gz does not carry the live relay-turn-lib.sh"
mkrepo() {  # <dir>: repo with seeded/{f.txt,retired.txt,sub/g.txt} and plain.txt committed
  mkdir -p "$1/seeded/sub" && cd "$1" || exit 2
  git init -q && git config user.name probe && git config user.email probe && git config commit.gpgsign false
  echo v1 > seeded/f.txt; echo r1 > seeded/retired.txt; echo s1 > seeded/sub/g.txt; echo p1 > plain.txt
  git add -A && git commit -qm init || exit 2
}
# Arm 1: an existing directory entry and an ordinary file entry.
R="$T/repo"; mkrepo "$R"
echo v2 > seeded/f.txt; rm seeded/retired.txt; echo p2 > plain.txt
out="$(cd "$R" && TMPDIR="$T" bash -c '
  source "$1" >/dev/null 2>&1 || exit 3
  RTL_ROOT="$2"; RTL_ALLOW=("seeded" "plain.txt")
  wt="$(rtl_worktree_begin)" || exit 4
  echo "$wt"' _ "$L" "$R")" || fail "rtl_worktree_begin failed on a readable tree (rc=$?)"
wt="$(printf '%s\n' "$out" | tail -1)"
[ -n "$wt" ] && [ -d "$wt" ] || fail "rtl_worktree_begin returned no usable worktree path"
if [ -n "$wt" ] && [ -d "$wt" ]; then
  [ -z "$(find "$wt/seeded" -mindepth 1 -maxdepth 2 -name seeded)" ] || fail "nested copy under $wt/seeded"
  [ "$(cat "$wt/seeded/f.txt" 2>/dev/null)" = v2 ] || fail "seed did not carry the current content"
  [ "$(cat "$wt/seeded/sub/g.txt" 2>/dev/null)" = s1 ] || fail "seed lost a nested file"
  [ ! -e "$wt/seeded/retired.txt" ] || fail "file deleted on the host survives in the seeded directory"
  [ "$(cat "$wt/plain.txt" 2>/dev/null)" = p2 ] || fail "ordinary file entry not seeded"
  git -C "$R" worktree remove --force "$wt" >/dev/null 2>&1
fi
# Arm 2: a directory copy that fails must not report a successful seed.
R2="$T/repo2"; mkrepo "$R2"
echo v2 > seeded/f.txt; chmod 000 seeded/f.txt
out2="$(cd "$R2" && TMPDIR="$T" bash -c '
  source "$1" >/dev/null 2>&1 || exit 3
  RTL_ROOT="$2"; RTL_ALLOW=("seeded")
  wt="$(rtl_worktree_begin)" || exit 9
  echo "$wt"' _ "$L" "$R2")"; rc2=$?
[ "$rc2" -eq 9 ] || fail "failed directory copy reported a successful seed (rc=$rc2)"
chmod 644 "$R2/seeded/f.txt" 2>/dev/null
w2="$(printf '%s\n' "$out2" | tail -1)"; [ -n "$w2" ] && [ -d "$w2" ] && git -C "$R2" worktree remove --force "$w2" >/dev/null 2>&1
git -C "$R2" worktree prune >/dev/null 2>&1
# Arm 3: when the checkout copy of the directory cannot be cleared, the begin must fail with no path,
# even though the source is readable (rm is shadowed to refuse only paths ending in /seeded).
R3="$T/repo3"; mkrepo "$R3"
echo v2 > seeded/f.txt
out3="$(cd "$R3" && TMPDIR="$T" bash -c '
  source "$1" >/dev/null 2>&1 || exit 3
  rm() { case "${@: -1}" in */seeded) echo "probe: refusing rm $*" >&2; return 1 ;; esac; command rm "$@"; }
  RTL_ROOT="$2"; RTL_ALLOW=("seeded")
  wt="$(rtl_worktree_begin)" || exit 9
  echo "$wt"' _ "$L" "$R3")"; rc3=$?
[ "$rc3" -eq 9 ] && [ -z "$out3" ] || fail "uncleared checkout copy still reported a seed (rc=$rc3, path=${out3:-none})"
w3="$(printf '%s\n' "$out3" | tail -1)"; [ -n "$w3" ] && [ -d "$w3" ] && git -C "$R3" worktree remove --force "$w3" >/dev/null 2>&1
git -C "$R3" worktree prune >/dev/null 2>&1
# Arm 4: the checkout's parent of the entry is a tracked symlink escaping the worktree while the host
# has a real directory there. The begin must fail with no path and create nothing outside.
O="$T/outside"; mkdir -p "$O"
R4="$T/repo4"; mkdir -p "$R4" && cd "$R4" || exit 2
git init -q && git config user.name probe && git config user.email probe && git config commit.gpgsign false
ln -s "$O" parent && echo x > keep.txt && git add -A && git commit -qm init || exit 2
rm parent && mkdir -p parent/new/seeded && echo h > parent/new/seeded/f.txt
out4="$(cd "$R4" && TMPDIR="$T" bash -c '
  source "$1" >/dev/null 2>&1 || exit 3
  RTL_ROOT="$2"; RTL_ALLOW=("parent/new/seeded")
  wt="$(rtl_worktree_begin)" || exit 9
  echo "$wt"' _ "$L" "$R4" 2>/dev/null)"; rc4=$?
[ "$rc4" -eq 9 ] && [ -z "$out4" ] || fail "escaping checkout parent still reported a seed (rc=$rc4)"
[ ! -e "$O/new" ] || fail "seeding created a directory outside the worktree ($O/new)"
w4="$(printf '%s\n' "$out4" | tail -1)"; [ -n "$w4" ] && [ -d "$w4" ] && git -C "$R4" worktree remove --force "$w4" >/dev/null 2>&1
git -C "$R4" worktree prune >/dev/null 2>&1
# Arm 5: a failed seed whose Git teardown is refused must say so and must not raw-delete the worktree.
R5="$T/repo5"; mkrepo "$R5"
echo v2 > seeded/f.txt; chmod 000 seeded/f.txt
mkdir -p "$T/wt5" && err5="$(cd "$R5" && TMPDIR="$T/wt5" bash -c '
  source "$1" >/dev/null 2>&1 || exit 3
  git() { if [ "${3:-}" = worktree ] && [ "${4:-}" = remove ]; then return 1; fi; command git "$@"; }
  RTL_ROOT="$2"; RTL_ALLOW=("seeded")
  wt="$(rtl_worktree_begin)" || exit 9
  echo "$wt"' _ "$L" "$R5" 2>&1 >/dev/null)"; rc5=$?
chmod 644 "$R5/seeded/f.txt" 2>/dev/null
[ "$rc5" -eq 9 ] || fail "seed failure with refused teardown reported success (rc=$rc5)"
printf '%s' "$err5" | grep -qi 'worktree remove' || fail "refused Git teardown was not reported"
ls -d "$T"/wt5/rtl-wt.* >/dev/null 2>&1 || fail "worktree was raw-deleted after Git refused to remove it"
for w5 in "$T"/wt5/rtl-wt.*; do [ -d "$w5" ] && git -C "$R5" worktree remove --force "$w5" >/dev/null 2>&1; done
git -C "$R5" worktree prune >/dev/null 2>&1
cd / && rm -rf "$T"
exit $st
