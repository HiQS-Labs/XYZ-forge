set -u
L="$PWD/relay-automation/relay-turn-lib.sh"
for v in $(env | sed -n 's/^\(GIT_[A-Za-z_]*\)=.*/\1/p'); do unset "$v"; done
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
T="$(mktemp -d "${TMPDIR:-/tmp}/gh1638-probe.XXXXXX")" || exit 2
R="$T/repo"; mkdir -p "$R/seeded/sub" && cd "$R" || exit 2
git init -q && git config user.name probe && git config user.email probe && git config commit.gpgsign false
echo v1 > seeded/f.txt; echo s1 > seeded/sub/g.txt; git add -A && git commit -qm init || exit 2
echo v2 > seeded/f.txt
export TMPDIR="$T"
rc=1
(
  source "$L" >/dev/null 2>&1 || exit 3
  RTL_ROOT="$R"; RTL_ALLOW=("seeded")
  wt="$(rtl_worktree_begin)" || exit 4
  [ -d "$wt" ] || exit 4
  st=0
  [ -z "$(find "$wt/seeded" -mindepth 1 -maxdepth 2 -name seeded)" ] || { echo "nested copy: $(find "$wt/seeded" -mindepth 1 -maxdepth 2 -name seeded)" >&2; st=1; }
  [ "$(cat "$wt/seeded/f.txt")" = v2 ] || { echo "seed did not carry the current content" >&2; st=1; }
  [ "$(cat "$wt/seeded/sub/g.txt")" = s1 ] || { echo "seed lost a nested file" >&2; st=1; }
  git -C "$R" worktree remove --force "$wt" >/dev/null 2>&1
  exit $st
); rc=$?
cd / && rm -rf "$T"
exit $rc
