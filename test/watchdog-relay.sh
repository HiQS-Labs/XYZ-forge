#!/usr/bin/env bash
# Phase 4(a) payoff: the watchdog SEES a stalled RELAY-TURN. Because the relay turn
# is now a tick task, a claim with no heartbeat past the threshold is a parked
# suspect → watchdog escalates it. (Under the old baton model this was invisible.)
source "$(dirname "$0")/_setup.sh" watchdog-relay
export TICK_BIN="$TICK"
WD="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/watchdog.sh"
tick_a init >/dev/null

# Stalled RELAY-TURN: claimed ~1h before the latest event, never pinged.
TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created RELAY-TURN --agent dispatcher >/dev/null
TICK_TS=2026-05-04T10:00:01.000Z tick_a claim RELAY-TURN --agent ra --paths "z/**" >/dev/null
# Healthy RELAY-TURN-2: claimed close to the run-end (small gap → not parked).
TICK_TS=2026-05-04T10:58:00.000Z tick_a log task.created RELAY-TURN-2 --agent dispatcher >/dev/null
TICK_TS=2026-05-04T10:58:30.000Z tick_a claim RELAY-TURN-2 --agent rb --paths "y/**" >/dev/null
# Recent event advances the analyzer's run-end well past the 10-min parked threshold.
TICK_TS=2026-05-04T11:00:00.000Z tick_a log task.created OTHER --agent dispatcher >/dev/null

out="$(TICK_REPO_ROOT="$A" bash "$WD" 2>&1)"

echo "$out" | grep -q 'RELAY-TURN"' && pass "watchdog escalates the stalled RELAY-TURN" || fail "stalled RELAY-TURN not escalated: $out"
echo "$out" | grep -q '"agent":"ra"' && pass "escalation names the stalled actor" || fail "escalation missing actor: $out"
echo "$out" | grep -q 'RELAY-TURN-2"' && fail "healthy RELAY-TURN-2 should NOT escalate" || pass "healthy RELAY-TURN-2 not escalated (no false positive)"

# with --allow-reap, the watchdog REALLY reaps the stalled one (R2 — re-offers the orphaned token),
# scoped to the stalled claim and never touching the HEALTHY live claim (RELAY-TURN-2 held by rb).
out2="$(TICK_REPO_ROOT="$A" bash "$WD" --allow-reap 2>&1)"
echo "$out2" | grep -q 'reaped 1 claim(s) from ra' && pass "--allow-reap reaps the stalled RELAY-TURN (real re-offer, not a stub)" || fail "real reap did not fire: $out2"
tick_a info RELAY-TURN | grep -qE 'claimer:[[:space:]]+ra' && fail "RELAY-TURN still held by ra after reap" || pass "RELAY-TURN released after reap (orphaned token re-offered)"
tick_a info RELAY-TURN-2 | grep -qE 'claimer:[[:space:]]+rb' && pass "healthy RELAY-TURN-2 (rb) NOT reaped — live claim untouched (never reap a live claim)" || fail "healthy RELAY-TURN-2 wrongly disturbed: $(tick_a info RELAY-TURN-2)"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
