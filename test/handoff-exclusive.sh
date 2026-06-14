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

if echo "$CLAIM_OUT" | grep -q "lost: TASK-007 is reserved for another agent"; then
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

# Now Charlie tries to take a task (there are no other tasks, so it should report no tasks)
TAKE_OUT=$(TICK_TS=2026-05-04T10:00:04.000Z tick_b take --agent charlie 2>&1)
if echo "$TAKE_OUT" | grep -q "(no available task)"; then
  pass "wrong-handoff_to take skips the task (returns no tasks)"
else
  fail "expected take to skip the reserved task and return no tasks, got: $TAKE_OUT"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
