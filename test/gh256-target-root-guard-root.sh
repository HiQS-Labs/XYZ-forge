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

echo "-- case 1: --target-root sets every routed shim's guard root, in the AUTHORITATIVE driver"
# The fix must live in utils/py/marathon_drive.py, NOT relay-automation/marathon-drive.sh. That
# Bash file is frozen (GH-308) and unreachable by default — its own header execs Python whenever
# XYZ_PYTHON is unset or 1. A first cut of this fix went into the Bash twin and was dead code;
# codex QA caught it. Asserting against the Bash file would have passed while nothing changed,
# which is precisely the bug class GH-256 is about.
py="$ROOT/utils/py/marathon_drive.py"
block="$(/usr/bin/sed -n '/if args.target_root:/,/env2\[f"{_shim}_TURN_ROOT"\]/p' "$py")"
if [ -n "$block" ]; then
  pass "the guard-root export lives in the Python driver"
else
  fail "GH-256: no target_root guard-root export in utils/py/marathon_drive.py — the fix is not on the default path"
fi

# Every prefix route_agent accepts must have a guard root, or that builder silently reintroduces
# the bug. Derived from the router rather than hardcoded, so adding a route without a guard root
# fails here instead of in a 29-minute marathon.
routes="$(/usr/bin/sed -n 's/.*agent_id.startswith("\([a-z]*\)").*/\1/p' "$py" | sort -u)"
[ -n "$routes" ] || fail "GH-256: could not read route_agent's accepted prefixes"
for r in $routes; do
  up="$(echo "$r" | tr '[:lower:]' '[:upper:]')"
  case "$block" in
    *"\"$up\","*|*"\"$up\")"*) pass "$up has a guard root" ;;
    *) fail "GH-256: route '$r' is accepted by route_agent but has no ${up}_TURN_ROOT — that builder gets a worktree without its own files" ;;
  esac
done

echo "-- case 2: it is scoped to the relay-drive child, not the whole process"
# os.environ would leak the guard root into anything else this process spawns; env2 is the child.
case "$block" in
  *env2*) pass "the export targets env2 (the relay-drive child), not os.environ" ;;
  *) fail "GH-256: the guard root is set process-wide and can leak into unrelated children" ;;
esac

echo "-- case 3: the same-repo default is untouched"
case "$block" in
  *"if args.target_root:"*) pass "gated on --target-root being supplied" ;;
  *) fail "GH-256: unconditional — a same-repo run would have its guard root rewritten" ;;
esac

echo "-- case 4: the frozen Bash twin was NOT taught this (GH-308)"
if /usr/bin/grep -q 'TURN_ROOT="\$TARGET_ROOT"' "$ROOT/relay-automation/marathon-drive.sh"; then
  fail "GH-256: the frozen Bash twin carries a behaviour change — GH-308 forbids it, and it is dead code besides"
else
  pass "the frozen twin carries only a pointer, no behaviour"
fi

echo "gh256-target-root-guard-root: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
