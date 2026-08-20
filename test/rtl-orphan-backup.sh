#!/usr/bin/env bash
# test/rtl-orphan-backup.sh — GH-141: concurrent peer-edit race, recoverability mitigation.
#
# The race: rtl_before() snapshots the dirty set ONCE at turn start. A second, independent session
# hand-editing a file in the same clone DURING the turn window produces a porcelain entry with no
# match in RTL_BEFORE — byte-identical to the agent's own off-lane self-escape. rtl_check() then
# reverts it in the real RTL_ROOT, destroying the peer's work.
#
# What this suite asserts is deliberately NOT "the peer edit survives". No code-only signal can tell
# the two cases apart, and preserving newly-dirty non-allowlisted paths would disable rtl_enforce's
# GH-22 self-escape backstop. The ratified mitigation (GH-141 recommended next step 1) is
# recoverability: the revert decision is unchanged, but the pre-revert content is copied aside first.
#
# These cases drive rtl_check() directly rather than racing a real turn, so the "mid-turn" edit is
# injected deterministically (rtl_before runs on a CLEAN tree, the edit lands after) with no timing
# dependence and no agy/codex binary required.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="$HERE/relay-automation/relay-turn-lib.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/rtl-orphan-backup.XXXXXX")"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$WORK"   # GH-10: pin the sandbox root
[[ -n "$WORK" && -d "$WORK" && "$WORK" != "/" ]] || { echo "FATAL: mktemp -d failed"; exit 1; }
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*"; FAIL=$((FAIL+1)); }

# A throwaway repo standing in for RTL_ROOT.
R="$WORK/repo"
mkdir -p "$R"
git -C "$R" init -q
git -C "$R" config user.email t@example.com
git -C "$R" config user.name t
mkdir -p "$R/PROJECT"
printf 'committed\n' >"$R/PROJECT/peer.md"
printf 'lane artifact\n' >"$R/lane.md"
git -C "$R" add -A
git -C "$R" commit -qm init

# shellcheck source=/dev/null
source "$LIB"

RTL_ROOT="$R"
RTL_TOOL="test"
RTL_LOG=""
RTL_LOG_REL=""
RTL_ALLOW=("lane.md")
RTL_VIOLATION=0
unset RTL_ORPHAN_BACKUP

# --- the race: snapshot a CLEAN tree, THEN inject the peer edit -------------------------------
rtl_before

printf 'peer session work — must be recoverable\n' >"$R/PROJECT/peer.md"   # tracked, modified
printf 'peer untracked note\n' >"$R/PROJECT/peer-new.md"                   # untracked, created
printf 'agent lane work\n' >"$R/lane.md"                                   # allowlisted

rtl_check "PROJECT/peer.md"
rtl_check "PROJECT/peer-new.md"
rtl_check "lane.md"

# 1. The revert decision is UNCHANGED — this is the containment backstop, still intact.
if [[ "$(cat "$R/PROJECT/peer.md")" == "committed" ]]; then
  pass "S1: tracked off-lane peer edit is still reverted (GH-22 backstop unchanged)"
else
  fail "S1: tracked off-lane path was NOT reverted — containment regression"
fi
if [[ ! -e "$R/PROJECT/peer-new.md" ]]; then
  pass "S2: untracked off-lane peer file is still removed (GH-22 backstop unchanged)"
else
  fail "S2: untracked off-lane path was NOT removed — containment regression"
fi

# 2. ...but the destroyed content is now recoverable.
if [[ -n "${RTL_ORPHAN_BACKUP:-}" && -d "$RTL_ORPHAN_BACKUP" ]]; then
  pass "S3: an orphan-backup dir was created"
else
  fail "S3: no orphan-backup dir — a wrongly-caught peer edit is unrecoverable"
fi
if [[ "$(cat "$RTL_ORPHAN_BACKUP/PROJECT/peer.md" 2>/dev/null)" == "peer session work — must be recoverable" ]]; then
  pass "S4: reverted tracked peer edit recoverable with exact pre-revert content"
else
  fail "S4: tracked peer edit content not recoverable from the backup"
fi
if [[ "$(cat "$RTL_ORPHAN_BACKUP/PROJECT/peer-new.md" 2>/dev/null)" == "peer untracked note" ]]; then
  pass "S5: removed untracked peer file recoverable with exact pre-revert content"
else
  fail "S5: untracked peer file content not recoverable from the backup"
fi

# 3. An allowlisted path is neither reverted nor backed up (no spurious copies).
if [[ "$(cat "$R/lane.md")" == "agent lane work" ]]; then
  pass "S6: allowlisted path untouched"
else
  fail "S6: allowlisted path was reverted"
fi
if [[ ! -e "$RTL_ORPHAN_BACKUP/lane.md" ]]; then
  pass "S7: allowlisted path not copied into the backup"
else
  fail "S7: allowlisted path spuriously backed up"
fi

# 4. Regression: PRE-existing ambient WIP is still exempted (test/agy-turn.sh case (8) equivalent).
#    Dirty the tree FIRST, then snapshot — the documented, still-supported case.
RTL_VIOLATION=0
unset RTL_ORPHAN_BACKUP
printf 'ambient WIP\n' >"$R/PROJECT/peer.md"
rtl_before
if rtl_was_dirty_before "$(git -C "$R" status --porcelain -z | tr -d '\0' | head -c 200)" \
   || [[ "${#RTL_BEFORE[@]}" -gt 0 ]]; then
  pass "S8: pre-turn ambient WIP is recorded in RTL_BEFORE (case-8 protection intact)"
else
  fail "S8: pre-turn ambient WIP not snapshotted — case-8 protection regressed"
fi

echo
echo "  rtl-orphan-backup: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
