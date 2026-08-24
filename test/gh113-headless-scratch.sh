#!/usr/bin/env bash
# test/gh113-headless-scratch.sh — GH-113: a headless builder's root-level scratch no longer fails
# the turn at exit 6; it relocates to the sanctioned scratch lane instead.
#
# The observed incident (marathon/daybreak-wave-2, 2026-08-20): the agy builder dropped fix_lens1.py,
# test_lens6.py and tmp.json into the working-tree root while debugging; rtl_check reverted them as
# OFF-ALLOWLIST and failed the turn (exit 6) even though the lane work itself was fine. GH-91 had
# already sanctioned a scratch ROOM (.relay-scratch/, opt-in by location); GH-113 adds relocation for
# the complementary shape — the builder writes scratch AT THE ROOT, where no affordance existed.
#
# Drives the lib functions directly (same shape as test/gh91-relay-scratch.sh): no agy binary, no
# timing dependence. Controls pin that this is a room, not an amnesty: non-scratch untracked names,
# nested untracked paths, and TRACKED off-lane edits all still violate.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="$HERE/relay-automation/relay-turn-lib.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh113-headless-scratch.XXXXXX")"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "FATAL: mktemp -d failed" >&2; exit 1; }
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*"; FAIL=$((FAIL+1)); }

# A throwaway repo standing in for RTL_ROOT: one committed allowlist lane file plus a second
# TRACKED file (for the tracked-off-lane control GH-113's acceptance pins).
R="$WORK/repo"
mkdir -p "$R"
require_fixture "$R" "fixture repo"
git -C "$R" init -q
git -C "$R" config user.email t@example.com
git -C "$R" config user.name t
printf 'lane v1\n' >"$R/lane.md"
printf 'tracked v1\n' >"$R/tracked.md"
git -C "$R" add -A
git -C "$R" commit -qm init

# shellcheck source=/dev/null
source "$LIB"
RTL_ROOT="$R"
RTL_TOOL="agy"
RTL_LOG=""
RTL_LOG_REL=""
RTL_ARTIFACT=""
RTL_ALLOW=("lane.md")

scratch_dir_of() { find "$R/.tick/scratch" -name "$1" 2>/dev/null | head -1; }

# ── (1) the incident shape: root scratch relocates, turn does NOT fail ───────────────────────────
printf '{"lens":6}\n' >"$R/tmp.json"
printf 'import sys\n' >"$R/fix_lens1.py"
printf 'import sys\n' >"$R/test_lens6.py"
RTL_VIOLATION=0
rtl_check "tmp.json"; rtl_check "fix_lens1.py"; rtl_check "test_lens6.py"
[ "$RTL_VIOLATION" -eq 0 ] && pass "rtl_check: root tmp.json/fix_*/test_* scratch is NOT a violation" \
  || fail "rtl_check: incident-shape scratch flagged as violation"
[ ! -e "$R/tmp.json" ] && [ ! -e "$R/fix_lens1.py" ] && [ ! -e "$R/test_lens6.py" ] \
  && pass "rtl_check: scratch files are gone from the tree root" \
  || fail "rtl_check: scratch file left in tree root"
for f in tmp.json fix_lens1.py test_lens6.py; do
  [ -n "$(scratch_dir_of "$f")" ] && pass "rtl_check: $f relocated under .tick/scratch/ (recoverable)" \
    || fail "rtl_check: $f not found under .tick/scratch/"
done
cmp -s <(printf '{"lens":6}\n') "$(scratch_dir_of tmp.json)" && pass "rtl_check: relocated content is intact" \
  || fail "rtl_check: relocated content corrupted"

# ── (2) the amnesty line: what still violates ────────────────────────────────────────────────────
# (2a) untracked but NOT scratch-shaped by name (the existing off-lane shape from test/agy-turn.sh).
printf 'off-lane\n' >"$R/offlane.md"
RTL_VIOLATION=0; rtl_check "offlane.md"
[ "$RTL_VIOLATION" -eq 1 ] && pass "CONTROL: untracked non-scratch root file (offlane.md) still violates" \
  || fail "CONTROL: offlane.md not flagged — the relocation is an amnesty, not a room"

# (2b) scratch-shaped but NESTED — a lane mistake, not transient scratch.
mkdir -p "$R/src"; printf 'x\n' >"$R/src/tmp.json"
RTL_VIOLATION=0; rtl_check "src/tmp.json"
[ "$RTL_VIOLATION" -eq 1 ] && pass "CONTROL: nested untracked src/tmp.json still violates (root-level only)" \
  || fail "CONTROL: nested scratch-shaped path not flagged"

# (2c) TRACKED off-lane edit — GH-113 acceptance: exit 6 unchanged.
printf 'tracked v2\n' >"$R/tracked.md"
RTL_VIOLATION=0; rtl_check "tracked.md"
[ "$RTL_VIOLATION" -eq 1 ] && pass "CONTROL: off-lane edit to a TRACKED file still violates (exit-6 path intact)" \
  || fail "CONTROL: tracked off-lane edit not flagged"

# (2d) dot-prefixed paths are never relocation candidates.
printf 'x\n' >"$R/.env.tmp-local"
RTL_VIOLATION=0; rtl_check ".env.tmp-local"
[ "$RTL_VIOLATION" -eq 1 ] && pass "CONTROL: dot-prefixed root file still violates" \
  || fail "CONTROL: dotfile escaped containment"

# ── (3) rtl_enforce end-to-end: scratch + lane edit -> exit 0, no scratch in the commit ──────────
git -C "$R" checkout -q -- . && rm -f "$R/offlane.md" "$R/src/tmp.json" "$R/.env.tmp-local"
RTL_BEFORE=(); RTL_BEFORE_HEAD="$(git -C "$R" rev-parse HEAD)"
rtl_before >/dev/null 2>&1
printf 'lane v2\n' >"$R/lane.md"
printf 'probe\n' >"$R/tmp2.json"
RTL_VIOLATION=0
rtl_enforce "RELAY-TURN-gh113" "agy" "/dev/null" "agy"
rc=$?
[ "$rc" -eq 0 ] && pass "rtl_enforce: lane edit + root scratch -> exit 0 (turn not failed)" \
  || fail "rtl_enforce: expected exit 0, got $rc"
[ ! -e "$R/tmp2.json" ] && [ -n "$(scratch_dir_of tmp2.json)" ] \
  && pass "rtl_enforce: scratch relocated (not reverted-and-lost, not committed)" \
  || fail "rtl_enforce: scratch not relocated"
grep -q "tmp2.json" <<<"$(git -C "$R" show --stat --name-only HEAD)" \
  && fail "rtl_enforce: scratch rode into the commit" \
  || pass "rtl_enforce: commit contains no scratch"
grep -q "lane v2" <<<"$(git -C "$R" show HEAD:lane.md 2>/dev/null)" \
  && pass "rtl_enforce: the legitimate lane edit was committed" \
  || fail "rtl_enforce: lane edit missing from commit"

# ── (4) rtl_worktree_end parity: scratch in an isolated worktree does not set RTL_WT_OFFLANE ─────
# CONTROL first: a non-scratch write in the worktree must still be off-lane.
WT="$(rtl_worktree_begin 2>/dev/null)"
if [ -n "$WT" ] && [ -d "$WT" ]; then
  printf 'off-lane\n' >"$WT/offlane.md"
  rtl_worktree_end "$WT"
  [ "${RTL_WT_OFFLANE:-1}" -eq 1 ] && pass "CONTROL(worktree): non-scratch worktree write still sets RTL_WT_OFFLANE" \
    || fail "CONTROL(worktree): offlane.md in worktree not flagged"
else
  fail "rtl_worktree_begin did not produce a worktree"
fi
WT2="$(rtl_worktree_begin 2>/dev/null)"
if [ -n "$WT2" ] && [ -d "$WT2" ]; then
  n_before="$(find "$R/.tick/scratch" -name tmp_wt.json 2>/dev/null | wc -l | tr -d ' ')"
  printf 'probe\n' >"$WT2/tmp_wt.json"
  rtl_worktree_end "$WT2"
  [ "${RTL_WT_OFFLANE:-1}" -eq 0 ] \
    && pass "rtl_worktree_end: root scratch in the worktree does NOT fail the turn" \
    || fail "rtl_worktree_end: worktree scratch flagged off-lane"
  n_after="$(find "$R/.tick/scratch" -name tmp_wt.json 2>/dev/null | wc -l | tr -d ' ')"
  [ "$n_after" -gt "$n_before" ] \
    && pass "rtl_worktree_end: worktree scratch relocated into ROOT .tick/scratch before teardown" \
    || fail "rtl_worktree_end: worktree scratch not relocated (count $n_before -> $n_after)"
else
  fail "rtl_worktree_begin did not produce a second worktree"
fi

echo
echo "gh113-headless-scratch: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
