#!/usr/bin/env bash
# Shared setup for tick test scripts. Source this from each test.
#
# Run 2: local transport — both agents share TICK_REPO_ROOT=$A. tick_b is an
# alias for tick_a; git push/pull between clones is not needed for event
# visibility. $B and $REMOTE are retained for tests that still use git
# operations (e.g. git config user.name), but coordination state lives in $A.
#
# Provides:
#   $TICK     — path to bin/tick
#   $WORK     — temp working dir for this test
#   $REMOTE   — bare remote repo path
#   $A        — shared TICK_REPO_ROOT (both tick_a and tick_b read/write here)
#   $B        — second git clone (kept for git ops; NOT used as TICK_REPO_ROOT)
#   tick_a    — run tick with TICK_REPO_ROOT=$A
#   tick_b    — run tick with TICK_REPO_ROOT=$A (same as tick_a)
#   tick_in   — run tick in arbitrary root: tick_in <dir> <args...>
#   pass / fail — assertion helpers; tests exit 1 on first fail
#
# Usage: source _setup.sh <test-name>

set -u
set -o pipefail

# Clean up ambient environment variables that can leak and break tests
unset RELAY_WORKTREE_ISOLATION

TEST_NAME="${1:-unnamed}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TICK="$(cd "$HERE/.." && pwd)/bin/tick"
export TICK

WORK="$(mktemp -d -t "tick-${TEST_NAME}.XXXXXX")"
export WORK
trap 'rm -rf "$WORK"' EXIT

REMOTE="$WORK/remote.git"
A="$WORK/agent-a"
B="$WORK/agent-b"
export REMOTE A B

git init -q --bare "$REMOTE"

# Seed remote with an empty initial commit so clones have something to track.
SEED="$WORK/.seed"
git init -q "$SEED"
git -C "$SEED" config user.email seed@t
git -C "$SEED" config user.name seed
git -C "$SEED" commit -q --allow-empty -m "init"
git -C "$SEED" branch -M main
git -C "$SEED" remote add origin "$REMOTE"
git -C "$SEED" push -q -u origin main
rm -rf "$SEED"

git clone -q "$REMOTE" "$A"
git clone -q "$REMOTE" "$B"
for d in "$A" "$B"; do
  git -C "$d" config user.email "${d##*/}@t"
  git -C "$d" config user.name "${d##*/}"
done

tick_in() {
  local dir="$1"; shift
  TICK_REPO_ROOT="$dir" "$TICK" "$@"
}

tick_a() { tick_in "$A" "$@"; }
tick_b() { tick_in "$A" "$@"; }  # local transport: shares TICK_REPO_ROOT with tick_a

# Bind TICK_REPO_ROOT to the shared coordination root by default, so a test that
# calls `$TICK ...` directly (instead of the tick_a/tick_b wrappers) still
# targets $A rather than hitting an unbound var under `set -u`. The wrappers
# override it per-call via tick_in; this is just the sane default for new tests.
# (Run-4 feedback: TICK_REPO_ROOT was unbound when scaffolding handoff-exclusive.sh.)
export TICK_REPO_ROOT="$A"

PASS=0
FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); exit 1; }

echo "== test: $TEST_NAME =="
echo "  workdir: $WORK"
