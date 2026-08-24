#!/usr/bin/env bash
# test/gh217-gate-env-plan-outside.sh — GH-217: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING must not cross
# the gate boundary, and test/marathon.sh must stay honest under an ambient value.
#
# The live incident: an outer `marathon.sh` run carried MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 (a
# documented, operator-legitimate override for a plan outside PROJECT/2-WORKING/). marathon-drive's
# pre-advance gate inherited it, and test/marathon.sh's GH-212 default-refusal assertion read the
# PARENT's policy as its own ambient — test 12 expected exit 2 and got exit 0, escalating and
# halting Phase 1 of a live marathon. Standalone the suite passed every time, which is exactly the
# expensive shape gate_env.py exists to prevent (same family as the ALLOW_PATHS incident that cost
# two Litmus rounds).
#
# Three layers, each pinned here:
#   C1 the registry scrubs it (gate_env.gate_env() probe, mirroring gh441's C2 shape)
#   C2 the driver-side literal also drops it (C3d keeps the two from drifting, but say it directly)
#   C3 the issue's literal reproduction — the full marathon suite under the ambient leak — is green
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$HERE"
GE="$ROOT/utils/py/gate_env.py"
DRIVER="$ROOT/utils/py/marathon_drive.py"
GH217_OUT="${GH217_OUT:-${TMPDIR:-/tmp}/gh217-marathon-out.$$.log}"

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*"; FAIL=$((FAIL+1)); }

# ── (1) the registry scrubs it ───────────────────────────────────────────────────────────────────
out="$(MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 python3 -c "
import os, sys
sys.path.insert(0, '$ROOT/utils/py')
import gate_env
print(gate_env.gate_env().get('MARATHON_ALLOW_PLAN_OUTSIDE_WORKING', 'ABSENT'))
")"
[ "$out" = "ABSENT" ] && pass "gate_env(): the ambient override does NOT survive into the gate env" \
  || fail "gate_env(): ambient value survived (got '$out')"

# ── (2) the driver's own literal copy drops it too ──────────────────────────────────────────────
out="$(MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 ALLOW_PATHS=x python3 -c "
import ast, re, sys
src = open('$DRIVER').read()
m = re.search(r'^\s*GATE_SCRUBBED_ENV\s*=\s*(\(.*?\))', src, re.S | re.M)
names = set(ast.literal_eval(m.group(1))) if m else set()
print('in-literal' if 'MARATHON_ALLOW_PLAN_OUTSIDE_WORKING' in names else 'missing')
")"
[ "$out" = "in-literal" ] && pass "marathon_drive GATE_SCRUBBED_ENV literal also scrubs it (C3d keeps both in sync)" \
  || fail "driver literal missing the name — the two copies have drifted"

# ── (3) the issue's literal reproduction: the full suite under the ambient leak ─────────────────
# Pre-fix this was `FAIL: GH-212: expected exit 2 ... got 0`. The defensive unset in test/marathon.sh
# makes the suite's own verdict independent of the ambient value even under a hand-rolled gate that
# skips gate-env.sh (the belt to C1's suspenders).
if MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 bash "$ROOT/test/marathon.sh" >"$GH217_OUT" 2>&1; then
  pass "test/marathon.sh is green under ambient MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 (the live incident shape)"
else
  fail "test/marathon.sh flipped under the ambient leak — the unset prologue regressed:"
  tail -5 "$GH217_OUT" >&2
fi
grep -q "GH-212: plan outside PROJECT/2-WORKING/ is refused by default (exit 2)" "$GH217_OUT" \
  && pass "the GH-212 default-refusal assertion specifically passed (not vacuously skipped)" \
  || fail "the GH-212 default-refusal assertion is missing from the run — did the suite shrink?"

echo
echo "gh217-gate-env-plan-outside: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
