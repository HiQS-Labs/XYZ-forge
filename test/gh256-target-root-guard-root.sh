#!/usr/bin/env bash
# GH-256 — under --target-root, the turn shim must GUARD the same repo the worktree is cut FROM.
#
# relay-drive.sh:254 exports RELAY_TARGET_ROOT and relay-turn-lib.sh:251 reads
# RTL_ROOT="${RELAY_TARGET_ROOT:-$1}", so the WORKTREE is cut from the target correctly. But each
# shim resolves its own containment root from <AGENT>_TURN_ROOT (utils/py/agy-turn.py:321,
# utils/py/codex-turn.py:26), and marathon-drive never set it. relay-turn-lib.sh:283 already stated
# the gap — "marathon-drive/relay-drive don't export CODEX_TURN_ROOT/AGY_TURN_ROOT — they never do" —
# and named the symptom: the per-artifact seed check resolves against the wrong root, finds nothing,
# and hands the agent a worktree with its own artifact missing.
#
# Measured cost before the fix: four consecutive builder turns produced no tracked changes and no
# builder block, the reviewer read the correct (unchanged) files and filed real findings so the
# transcript looked healthy, and the phase escalated cap-stalled after 29 minutes with zero lines
# written. The builder was telling the truth; nothing gave it a way to say so.
#
# This asserts the INVARIANT (guard root == target root), not the symptom (no-op turns). A test on
# the symptom would pass the moment the builder happened to write something for another reason.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PASS=0; FAIL=0
pass() { echo "  ok  $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL  $1"; FAIL=$((FAIL+1)); }

echo "-- case 1: --target-root exports every shim's guard root to the target"
# Read the source directly rather than booting a full marathon: the export is a static contract,
# and a live run would need two repos, two CLIs and a network round trip to assert one assignment.
block="$(/usr/bin/sed -n '/^if \[\[ -n "\$TARGET_ROOT" \]\]; then$/,/^fi$/p' "$ROOT/relay-automation/marathon-drive.sh")"
for v in AGY_TURN_ROOT CODEX_TURN_ROOT COMMANDCODE_TURN_ROOT; do
  case "$block" in
    *"$v=\"\$TARGET_ROOT\""*) pass "$v is exported to the target root" ;;
    *) fail "GH-256: $v is not exported under --target-root — the shim would guard the harness while the worktree is the target" ;;
  esac
done

echo "-- case 2: the same-repo default is untouched (no --target-root)"
if [ -n "$block" ]; then
  pass "the export is gated on TARGET_ROOT being set"
else
  fail "GH-256: the export is unconditional — a same-repo run would have its guard root rewritten"
fi

echo "-- case 3: an unseeded artifact is reported on stderr, not only under XYZ_DEBUG"
# The silence is what made this cost 29 minutes. rtl_trace is debug-gated; a normal run must say it.
if /usr/bin/grep -q 'artifact not seeded into worktree' "$ROOT/relay-automation/relay-turn-lib.sh"; then
  pass "rtl_worktree_begin warns when an allowlisted artifact is not seeded"
else
  fail "GH-256: an artifact missing from the worktree is still silent on a normal run"
fi
if /usr/bin/grep -q 'artifact not seeded into worktree.*>&2' "$ROOT/relay-automation/relay-turn-lib.sh"; then
  pass "the warning goes to stderr where a normal run shows it"
else
  fail "GH-256: the warning is not on stderr"
fi

echo "gh256-target-root-guard-root: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
