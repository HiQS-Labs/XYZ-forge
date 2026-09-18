#!/usr/bin/env bash
# test/gh681-reviewer-probe-rules.sh — GH-681 regression.
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh681-reviewer-probe-rules.sh; pre-fix revision: relay-turn-lib.sh before GH-681, whose reviewer note read 'do NOT edit, create, or run any artifact or source file' and whose shared verification clause told the same reviewer to 'verify ONLY with the specific test for the file(s) you changed'; pre-fix result: cases 1-2 FAILED (no probe allowance, contradictory verification clause); post-fix result: all cases pass, reviewer prompt carries one role-consistent verification instruction and the done-handoff sentence gh505 attests"}
#
# The gh673 final QA relay (relay-system/2026-09-17/gh673-final-qa.md) ran three rounds with a Reviewer
# forbidden to execute anything. In Round 1 it generalized one late-error observation into "or a later
# invalid identity"; the Producer implemented it; the same seat [Pass]ed it in Round 2. One historical
# NULL-URL ledger row then blanked every issue. The defect was a row count nobody was allowed to run.
#
# GH-681 makes two prose changes and this suite pins them:
#   A  the Reviewer note in rtl_turn_prompt allows narrow, non-mutating probes (scratch-only output),
#      keeps test suites out of the worktree, and the shared "verify ONLY with the specific test" clause
#      becomes Producer-only — so each role has exactly one verification instruction;
#   B  new-relay.sh's Reviewer bullet (and its mirrors in skills/relay, skills/relay-xyz, and the marathon
#      brief) require a generalization to carry Observed input / Affected scope / Falsifier.
#
# Cases 1-6 pin wording (this is prose; a suite can only pin its text, not its effect — stated plainly).
# Case 7 is behavioural: a reviewer worktree that writes under .relay-scratch/ is NOT off-lane, and one
# that writes .pytest_cache/ IS — the containment backstop the probe allowance relies on. Deleting the
# .relay-scratch exemption in rtl_worktree_end passes cases 1-6 and fails case 7.

source "$(dirname "$0")/_setup.sh" gh681-reviewer-probe-rules
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$ROOT/relay-automation/relay-turn-lib.sh"
# shellcheck source=relay-automation/relay-turn-lib.sh
source "$LIB"

git -C "$A" rev-parse --verify -q HEAD >/dev/null 2>&1 \
  || git -C "$A" checkout -q -B main origin/main >/dev/null 2>&1 \
  || git -C "$A" commit -q --allow-empty -m "gh681 base" >/dev/null 2>&1 || true

has() { grep -qF -- "$2" <<<"$1"; }

# --- Cases 1-3: the rendered prompts, one verification instruction per role ----------------------
REL="relay-system/2026-09-17/gh681.md"
RELAY="$A/$REL"
mkdir -p "$(dirname "$RELAY")"

printf 'STATUS: Open\nNEXT: Reviewer\n\nbody\n' >"$RELAY"
rtl_init "$A" "$RELAY" ""
rev="$(rtl_turn_prompt codex "$RELAY" RELAY-TURN "" other)"

for needle in \
  "You are the REVIEWER this turn" \
  "MAY run narrow, non-mutating probes" \
  ".relay-scratch/" \
  'export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"' \
  "quote the command, exit status and decisive output" \
  "Do NOT run validate.sh, test/*.sh, pytest, or executable fixtures" \
  "[Unverified — needs clone run]" \
  "hand the token off with done and set STATUS: Approved"; do
  has "$rev" "$needle" \
    && pass "case 1: reviewer prompt carries: $needle" \
    || fail "case 1: reviewer prompt lacks: $needle"
done

for absent in \
  "or run any artifact" \
  "verify ONLY with the specific test"; do
  has "$rev" "$absent" \
    && fail "case 2: reviewer prompt still says: $absent" \
    || pass "case 2: reviewer prompt no longer says: $absent"
done

printf 'STATUS: Open\nNEXT: Producer\n\nbody\n' >"$RELAY"
rtl_init "$A" "$RELAY" ""
prod="$(rtl_turn_prompt codex "$RELAY" RELAY-TURN "" other)"
has "$prod" "verify ONLY with the specific test for the file(s) you changed" \
  && pass "case 3: producer prompt keeps its own verification clause" \
  || fail "case 3: producer prompt lost its verification clause"
for absent in "You are the REVIEWER this turn" "MAY run narrow, non-mutating probes"; do
  has "$prod" "$absent" \
    && fail "case 3: producer prompt carries reviewer-only text: $absent" \
    || pass "case 3: producer prompt does not carry: $absent"
done

# --- Case 4: the scaffold carries the generalization rule ---------------------------------------
scaffold="$(bash "$ROOT/relay-automation/new-relay.sh" --title "gh681 probe" --reviewer codex --producer claude-a --print 2>/dev/null || true)"
[ -n "$scaffold" ] || scaffold="$(sed -n '/TAKE YOUR TURN/,/^## Log/p' "$ROOT/relay-automation/new-relay.sh")"
for needle in "Observed input:" "Affected scope:" "Falsifier:" "Declined — unproven generalization" "must cite an observed failure"; do
  has "$scaffold" "$needle" \
    && pass "case 4: scaffold carries: $needle" \
    || fail "case 4: scaffold lacks: $needle"
done

# --- Case 5: the residue backstop is unchanged --------------------------------------------------
if rtl_scratch_relocate ".pytest_cache" "$A" "$WORK" 2>/dev/null; then
  fail "case 5: rtl_scratch_relocate now relocates a dot-directory (.pytest_cache) — residue would be hidden"
else
  pass "case 5: rtl_scratch_relocate still refuses .pytest_cache (a probe that leaves it fails the turn)"
fi

# --- Case 6: drift guard — every place the rule is codified still carries it ---------------------
for f in skills/relay-xyz/SKILL.md skills/relay/SKILL.md utils/py/marathon_drive.py; do
  grep -qF "Declined — unproven generalization" "$ROOT/$f" \
    && pass "case 6: $f carries the generalization rule" \
    || fail "case 6: $f lost the generalization rule (GH-681 codified it in two-plus places)"
done
grep -qF "MAY run narrow, non-mutating probes" "$ROOT/skills/relay-xyz/SKILL.md" \
  && pass "case 6: skills/relay-xyz/SKILL.md carries the probe allowance" \
  || fail "case 6: skills/relay-xyz/SKILL.md lost the probe allowance"

# --- Case 7 (behavioural): scratch output is sanctioned, .pytest_cache residue is off-lane ----------
printf 'STATUS: Open\nNEXT: Reviewer\n\nbody\n' >"$RELAY"
git -C "$A" add -A >/dev/null 2>&1; git -C "$A" commit -q -m "gh681 seed relay" >/dev/null 2>&1 || true
rtl_init "$A" "$RELAY" ""
wt="$(rtl_worktree_begin)"; rc=$?
if [ "$rc" -eq 0 ] && [ -n "$wt" ] && [ -d "$wt/.relay-scratch" ]; then
  pass "case 7: reviewer worktree begins with .relay-scratch/ pre-created"
  mkdir -p "$wt/.relay-scratch/tmp"
  printf 'probe: 202 rows, 1 invalid\n' >"$wt/.relay-scratch/probe.txt"
  printf 'tmp\n' >"$wt/.relay-scratch/tmp/x"
  RTL_WT_OFFLANE=0
  rtl_worktree_end "$wt" >/dev/null 2>&1 || true
  [ "${RTL_WT_OFFLANE:-1}" -eq 0 ] \
    && pass "case 7: a probe that writes only under .relay-scratch/ is not off-lane" \
    || fail "case 7: scratch-only probe output was judged off-lane (the .relay-scratch exemption is gone)"
else
  fail "case 7: rtl_worktree_begin failed (rc=$rc, wt=$wt)"
fi
git -C "$A" worktree prune >/dev/null 2>&1 || true

wt="$(rtl_worktree_begin)"; rc=$?
if [ "$rc" -eq 0 ] && [ -n "$wt" ]; then
  mkdir -p "$wt/.pytest_cache"
  printf 'x\n' >"$wt/.pytest_cache/x"
  RTL_WT_OFFLANE=0
  rtl_worktree_end "$wt" >/dev/null 2>&1 || true
  [ "${RTL_WT_OFFLANE:-0}" -eq 1 ] \
    && pass "case 7: a probe that leaves .pytest_cache/ in the worktree is off-lane (residue still fails the turn)" \
    || fail "case 7: .pytest_cache/ residue was tolerated — the backstop the probe allowance relies on is gone"
else
  fail "case 7: second rtl_worktree_begin failed (rc=$rc, wt=$wt)"
fi
git -C "$A" worktree prune >/dev/null 2>&1 || true

echo "gh681-reviewer-probe-rules: all cases passed"
