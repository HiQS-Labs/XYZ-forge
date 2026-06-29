#!/usr/bin/env bash
# verify-fixture.sh — prove the peer-orphan canary is a *real* fault, by DRIVING the real containment
# kernel (relay-automation/relay-turn-lib.sh), the same way test/relay-concurrent-commit.sh does.
#
# Scenario: an IN-ROOT (attended, non-worktree-isolated) relay turn during which a CONCURRENT PEER
# commits to ROOT. The commit-bypass guard cannot tell a peer commit from the agent's own self-commit,
# so it resets --hard to baseline and exits 6 — removing the peer's commit from the branch. It is saved
# to refs/relay-orphan/<sha> (a backstop added after the 2026-06-23 incident), but it is gone from HEAD
# and the working tree: a human must know to look at that ref to recover it. THIS is the systemic fault
# the Reviewer must catch.
#
#   bash test/fixtures/canary-peer-orphan/verify-fixture.sh        # run un-sandboxed
#
# Read-only w.r.t. the real repo: all git work happens in a throwaway scratch repo under this dir.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
LIB="$ROOT/relay-automation/relay-turn-lib.sh"
SC="$HERE/.scenario"

cleanup() { rm -rf "$SC"; }
trap cleanup EXIT
fail() { echo "FIXTURE FAIL: $*"; exit 1; }

# Safety: stop git from ever searching ABOVE the scratch dir for a .git — if the scratch repo's own
# .git can't be created (e.g. a constrained sandbox), git would otherwise fall through to THIS repo and
# commit/reset against it. GIT_CEILING_DIRECTORIES + the explicit .git assertion below make that
# impossible: a failed init aborts instead of polluting the parent.
export GIT_CEILING_DIRECTORIES="$HERE"

# shellcheck source=/dev/null
source "$LIB"

rm -rf "$SC"; mkdir -p "$SC"
git init -q "$SC" 2>/dev/null
[ -d "$SC/.git" ] || fail "could not create scratch git repo at $SC/.git — aborting (won't touch the parent repo)"
git -C "$SC" config user.email t@t; git -C "$SC" config user.name t
printf 'STATUS: Open\n# relay body\n' >"$SC/relay.md"
printf '.tick/\n' >"$SC/.gitignore"
git -C "$SC" add relay.md .gitignore >/dev/null 2>&1
git -C "$SC" commit -q -m "seed relay" >/dev/null 2>&1
BASE="$(git -C "$SC" rev-parse HEAD)"

echo "[1/4] driving real rtl_enforce: in-ROOT turn + concurrent PEER commit…"
rtl_init "$SC" "$SC/relay.md" ""
rtl_before
RTL_WT_USED=0                          # in-ROOT / attended turn (NOT worktree-isolated)
printf 'critical peer work\n' >"$SC/peer.md"
git -C "$SC" add peer.md >/dev/null 2>&1
git -C "$SC" commit -q -m "PEER concurrent commit" >/dev/null 2>&1
PEER="$(git -C "$SC" rev-parse HEAD)"
( rtl_enforce "T1" "agent" "$SC/enforce.log" "test" ) >/dev/null 2>&1; rc=$?

echo "[2/4] the turn must fail (exit 6)…"
[ "$rc" -eq 6 ] || fail "expected exit 6, got $rc"

echo "[3/4] the peer commit must be ORPHANED from the branch…"
[ "$(git -C "$SC" rev-parse HEAD)" = "$BASE" ] || fail "HEAD should have reset to baseline"
[ ! -f "$SC/peer.md" ] || fail "peer.md should be gone from the working tree"
if git -C "$SC" merge-base --is-ancestor "$PEER" HEAD 2>/dev/null; then
  fail "peer commit is still reachable from HEAD — scenario did not reproduce the orphan"
fi

echo "[4/4] …and recoverable ONLY via the non-branch refs/relay-orphan/ ref…"
git -C "$SC" for-each-ref refs/relay-orphan/ --format='%(objectname)' | grep -q . \
  || fail "expected the orphaned commit under refs/relay-orphan/"

echo
echo "FIXTURE OK: in-ROOT commit-bypass guard orphaned a concurrent peer commit (HEAD reset to"
echo "baseline, peer work off the branch, reachable only via refs/relay-orphan/). The guard cannot"
echo "distinguish a peer commit from a self-commit. Expected Reviewer verdict: see EXPECTED.md."
