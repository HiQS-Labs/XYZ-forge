#!/usr/bin/env bash
# test/relay-file-seeding-visibility.sh — GH-178 B2: mechanically prove (not just assert on warning
# text) that rtl_worktree_begin()'s seeding step makes an UNCOMMITTED relay file's current content
# visible inside the isolated worktree it hands to a turn-taker. This closes the gap left by
# test/relay-untracked-file-warn.sh, whose "warns" cases use a no-op --agent-cmd stub that never
# calls into relay-turn-lib.sh at all — it only proves the WARNING fires, never whether the warning's
# underlying claim ("will find nothing") is actually true.
#
# Also proves the one case seeding does NOT cover: a relay file living in a DIFFERENT repo than the
# effective RTL_ROOT (the archive-routed shape) is NOT seeded — it should be absent from the worktree.
source "$(dirname "$0")/_setup.sh" relay-file-seeding-visibility

LIB="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-turn-lib.sh"
# shellcheck source=relay-automation/relay-turn-lib.sh
source "$LIB"

# --- Case 1: relay file in the SAME repo as RTL_ROOT, never committed → seeding makes it visible. ---
RELAY_A="$A/relay-system/2026-07-08/seed-test.md"
mkdir -p "$(dirname "$RELAY_A")"
printf 'STATUS: In progress\nUNCOMMITTED CONTENT %s\n' "$$" >"$RELAY_A"
# (deliberately never git add/commit — this is the exact B2 scenario)

rtl_init "$A" "$RELAY_A" ""
wt1="$(rtl_worktree_begin)"; rc1=$?
if [ "$rc1" -eq 0 ] && [ -n "$wt1" ] && [ -f "$wt1/relay-system/2026-07-08/seed-test.md" ]; then
  pass "same-repo uncommitted relay file: worktree created with the file present"
  if grep -q "UNCOMMITTED CONTENT $$" "$wt1/relay-system/2026-07-08/seed-test.md" 2>/dev/null; then
    pass "same-repo uncommitted relay file: worktree has the CURRENT (uncommitted) content"
  else
    fail "same-repo uncommitted relay file: worktree content is stale (expected current, uncommitted text)"
  fi
else
  fail "same-repo uncommitted relay file: rtl_worktree_begin failed or file absent (rc=$rc1, wt=$wt1)"
fi
[ -n "$wt1" ] && { git -C "$A" worktree remove --force "$wt1" >/dev/null 2>&1 || rm -rf "$wt1"; git -C "$A" worktree prune >/dev/null 2>&1; }

# --- Case 2: relay file in a DIFFERENT repo ($B) than RTL_ROOT ($A) → seeding does NOT cover it. ---
# This is the archive-routed shape: rtl_init normalizes an out-of-RTL_ROOT path to an absolute
# string, so the seed step's `[[ -e "$RTL_ROOT/$a" ]]` relative check can't find it under $A.
RELAY_B="$B/relay-system/2026-07-08/archive-test.md"
mkdir -p "$(dirname "$RELAY_B")"
printf 'STATUS: In progress\nUNCOMMITTED CONTENT IN B %s\n' "$$" >"$RELAY_B"

rtl_init "$A" "$RELAY_B" ""
wt2="$(rtl_worktree_begin)"; rc2=$?
if [ "$rc2" -eq 0 ] && [ -n "$wt2" ]; then
  if grep -q . <<<"$([ -f "$wt2$B/relay-system/2026-07-08/archive-test.md" ] || find "$wt2" -name archive-test.md 2>/dev/null)"; then
    fail "cross-repo relay file unexpectedly seeded into the worktree — B2's cross-repo warning is now wrong"
  else
    pass "cross-repo relay file NOT seeded — confirms the archive-routed case genuinely needs the strong warning"
  fi
else
  fail "cross-repo case: rtl_worktree_begin failed unexpectedly (rc=$rc2)"
fi
[ -n "$wt2" ] && { git -C "$A" worktree remove --force "$wt2" >/dev/null 2>&1 || rm -rf "$wt2"; git -C "$A" worktree prune >/dev/null 2>&1; }

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
