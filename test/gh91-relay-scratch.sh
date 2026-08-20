#!/usr/bin/env bash
# test/gh91-relay-scratch.sh — GH-91: a sanctioned scratch dir for builder verification output.
#
# The 0.7.2 daybreak wave-1 re-fire: the builder ran its probes (collect.sh → JSON), saved the
# output next to the thing being probed to feed triage.py — exactly what the brief's pass
# condition required — and containment reverted all four JSON files at exit 6. The turn's
# deliverable was complete and green. Every other category of incidental write already had an
# exemption (.tick, .relay-artifacts, the transcript log, GH-107 tool caches); builder scratch
# had nothing, and "$TMPDIR" was convention carried only in prose the builder demonstrably did
# not weight.
#
# The fix (issue option 1): `.relay-scratch/` — exempted in rtl_check and rtl_worktree_end
# exactly as the other intrinsic categories, pre-created by rtl_worktree_begin, named in
# rtl_turn_prompt so the affordance is visible at the point of use. Never copied back; on the
# non-worktree path it is discarded (it lives in RTL_ROOT there and must not linger or ride
# into a commit). This suite drives the lib functions directly — no agy/codex binary, no
# timing dependence.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="$HERE/relay-automation/relay-turn-lib.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh91-relay-scratch.XXXXXX")"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "FATAL: mktemp -d failed" >&2; exit 1; }
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*"; FAIL=$((FAIL+1)); }

# A throwaway repo standing in for RTL_ROOT with one committed allowlist lane file.
R="$WORK/repo"
mkdir -p "$R"
require_fixture "$R" "fixture repo"
git -C "$R" init -q
git -C "$R" config user.email t@example.com
git -C "$R" config user.name t
printf 'lane v1\n' >"$R/lane.md"
git -C "$R" add -A
git -C "$R" commit -qm init

# shellcheck source=/dev/null
source "$LIB"
RTL_ROOT="$R"
RTL_TOOL="test"
RTL_LOG=""
RTL_LOG_REL=""
RTL_ARTIFACT=""

# ── (1) rtl_check: scratch under ROOT is exempted AND discarded, and the turn does not fail ─────
RTL_ALLOW=("lane.md")
printf 'lane v2\n' >"$R/lane.md"                          # the legitimate lane edit
mkdir -p "$R/.relay-scratch"
printf '{"lens":2}\n' >"$R/.relay-scratch/out2.json"      # the probe output that killed the real turn
printf '{"lens":3}\n' >"$R/.relay-scratch/out3.json"
RTL_VIOLATION=0
rtl_check ".relay-scratch/out2.json"
[ "$RTL_VIOLATION" -eq 0 ] && pass "rtl_check: a scratch write is NOT a violation" \
  || fail "rtl_check: scratch write flagged as violation"
[ ! -d "$R/.relay-scratch" ] && pass "rtl_check: the scratch dir is DISCARDED from ROOT (not committed, not lingering)" \
  || fail "rtl_check: scratch dir still present in ROOT after the check"
cmp -s <(printf 'lane v2\n') "$R/lane.md" && pass "rtl_check: the legitimate lane edit is untouched" \
  || fail "rtl_check: lane edit damaged by scratch handling"

# The collapsed-dir form (git shows ".relay-scratch/" when the dir is wholly untracked) — same branch.
mkdir -p "$R/.relay-scratch"; printf 'x\n' >"$R/.relay-scratch/probe.json"
RTL_VIOLATION=0
rtl_check ".relay-scratch/"
[ "$RTL_VIOLATION" -eq 0 ] && [ ! -d "$R/.relay-scratch" ] \
  && pass "rtl_check: the collapsed '.relay-scratch/' status form is exempted and discarded too" \
  || fail "rtl_check: collapsed-dir form not handled"

# ── (2) containment still BITES: scratch is a room, not an amnesty ───────────────────────────────
printf 'stray\n' >"$R/stray.txt"
RTL_VIOLATION=0
rtl_check "stray.txt"
[ "$RTL_VIOLATION" -eq 1 ] && pass "CONTROL: a stray file OUTSIDE .relay-scratch still violates (exit-6 path intact)" \
  || fail "CONTROL: stray write not flagged — the exemption is an amnesty, not a room"
[ ! -f "$R/stray.txt" ] && pass "CONTROL: the stray file is reverted as before" \
  || fail "CONTROL: stray file survived"
# A lookalike prefix must NOT ride the exemption.
mkdir -p "$R/.relay-scratch2"; printf 'x\n' >"$R/.relay-scratch2/out.json"
RTL_VIOLATION=0
rtl_check ".relay-scratch2/out.json"
[ "$RTL_VIOLATION" -eq 1 ] && pass "CONTROL: '.relay-scratch2' (lookalike prefix) is NOT exempt" \
  || fail "CONTROL: lookalike prefix .relay-scratch2 slipped the exemption"

# ── (3) worktree isolation: begin pre-creates the dir, end exempts it and never copies it back ──
git -C "$R" checkout -q -- lane.md 2>/dev/null || true
RTL_ALLOW=("lane.md")
wt="$(rtl_worktree_begin)"
[ -d "$wt/.relay-scratch" ] && pass "rtl_worktree_begin: the scratch dir EXISTS in the worktree (affordance, not prose)" \
  || fail "rtl_worktree_begin: scratch dir not pre-created"
# the builder's turn: edit the lane file AND leave probe output in the sanctioned place
printf 'lane v2\n' >"$wt/lane.md"
printf '{"lens":2}\n' >"$wt/.relay-scratch/out2.json"
rtl_worktree_end "$wt"
[ "$RTL_WT_OFFLANE" -eq 0 ] && pass "rtl_worktree_end: probe output in .relay-scratch is NOT off-lane" \
  || fail "rtl_worktree_end: scratch marked off-lane (the GH-91 fire reproduced)"
cmp -s <(printf 'lane v2\n') "$R/lane.md" && pass "rtl_worktree_end: the lane edit still copies back" \
  || fail "rtl_worktree_end: lane edit did not copy back"
[ ! -e "$R/.relay-scratch" ] && pass "rtl_worktree_end: scratch is NEVER copied back to ROOT" \
  || fail "rtl_worktree_end: scratch leaked into ROOT"

# ── (4) worktree containment still bites beside the new room ────────────────────────────────────
wt2="$(rtl_worktree_begin)"
printf 'lane v3\n' >"$wt2/lane.md"
printf 'stray\n' >"$wt2/stray.txt"
rtl_worktree_end "$wt2"
[ "$RTL_WT_OFFLANE" -eq 1 ] && pass "CONTROL: a stray write in the worktree still goes off-lane" \
  || fail "CONTROL: worktree stray not flagged"
cmp -s <(printf 'lane v2\n') "$R/lane.md" && pass "CONTROL: off-lane turns copy NOTHING back (lane edit withheld)" \
  || fail "CONTROL: off-lane turn still copied the lane edit back"

# ── (5) the prompt names the affordance at the point of use ─────────────────────────────────────
RTL_ROOT="$R"
out="$(rtl_turn_prompt builder "$R/lane.md" TASK lane.md)"
printf '%s' "$out" | grep -q '.relay-scratch' \
  && pass "rtl_turn_prompt: the prompt TELLS the builder where scratch goes" \
  || fail "rtl_turn_prompt: scratch affordance not named"
printf '%s' "$out" | grep -q 'never copied back' \
  && pass "rtl_turn_prompt: and says what happens to it (never copied back)" \
  || fail "rtl_turn_prompt: scratch disposition not stated"

echo "  gh91-relay-scratch: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
