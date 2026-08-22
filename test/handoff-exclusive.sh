#!/usr/bin/env bash
# Proves A1 rule: a task handed off to a specific agent cannot be claimed or taken by another.
source "$(dirname "$0")/_setup.sh" handoff-exclusive

tick_a init >/dev/null
TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-007 --agent dispatcher --priority 1 --paths "src/auth/**" >/dev/null

# Alice claims and hands off to bob
TICK_TS=2026-05-04T10:00:01.000Z tick_a claim TASK-007 --agent alice --paths "src/auth/**" >/dev/null
TICK_TS=2026-05-04T10:00:02.000Z tick_a release TASK-007 --agent alice --to bob >/dev/null

# Now Charlie tries to claim it directly
INITIAL_EVENTS=$(ls -1 "$A/.tick/events" | wc -l)
CLAIM_OUT=$(TICK_TS=2026-05-04T10:00:03.000Z tick_b claim TASK-007 --agent charlie --paths "src/auth/**" 2>&1)

if grep -q "lost: TASK-007 is reserved for another agent" <<<"$(echo "$CLAIM_OUT")"; then
  pass "wrong-handoff_to claim is refused"
else
  fail "expected wrong-handoff claim to be refused, got: $CLAIM_OUT"
fi

FINAL_EVENTS=$(ls -1 "$A/.tick/events" | wc -l)
if [ "$INITIAL_EVENTS" -eq "$FINAL_EVENTS" ]; then
  pass "wrong-handoff claim emitted ZERO events"
else
  fail "expected $INITIAL_EVENTS events, got $FINAL_EVENTS"
fi

# Now Charlie tries to TAKE (the only task is reserved for bob → no task) — and ZERO events.
EVENTS_BEFORE_TAKE=$(ls -1 "$A/.tick/events" | wc -l)
TAKE_OUT=$(TICK_TS=2026-05-04T10:00:04.000Z tick_b take --agent charlie 2>&1)
if grep -q "(no available task)" <<<"$(echo "$TAKE_OUT")"; then
  pass "wrong-handoff_to take skips the task (returns no tasks)"
else
  fail "expected take to skip the reserved task and return no tasks, got: $TAKE_OUT"
fi
EVENTS_AFTER_TAKE=$(ls -1 "$A/.tick/events" | wc -l)
if [ "$EVENTS_BEFORE_TAKE" -eq "$EVENTS_AFTER_TAKE" ]; then
  pass "wrong-handoff_to take emitted ZERO events"
else
  fail "expected $EVENTS_BEFORE_TAKE events after skipped take, got $EVENTS_AFTER_TAKE"
fi

# POSITIVE ROUTED CASE — claim: the task reserved for bob (TASK-007) is claimed by bob (handoff_to == caller).
CLAIM_BOB=$(TICK_TS=2026-05-04T10:00:05.000Z tick_b claim TASK-007 --agent bob --paths "src/auth/**" 2>&1)
if grep -q "won: TASK-007" <<<"$(echo "$CLAIM_BOB")"; then
  pass "handoff target (bob) can claim the task routed to it"
else
  fail "expected bob to claim TASK-007 via handoff routing, got: $CLAIM_BOB"
fi

# POSITIVE ROUTED CASE — take: a separate task reserved for bob is taken by bob.
# (TASK-007 is now claimed by bob, so the only open bob-handoff is TASK-008 → unambiguous.)
TICK_TS=2026-05-04T10:00:06.000Z tick_a log task.created TASK-008 --agent dispatcher --priority 1 --paths "src/api/**" >/dev/null
TICK_TS=2026-05-04T10:00:07.000Z tick_a claim TASK-008 --agent alice --paths "src/api/**" >/dev/null
TICK_TS=2026-05-04T10:00:08.000Z tick_a release TASK-008 --agent alice --to bob >/dev/null
TAKE_BOB=$(TICK_TS=2026-05-04T10:00:09.000Z tick_b take --agent bob 2>&1)
if grep -q "won: TASK-008" <<<"$(echo "$TAKE_BOB")"; then
  pass "handoff target (bob) can take the task routed to it"
else
  fail "expected bob to win TASK-008 via handoff routing, got: $TAKE_BOB"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
