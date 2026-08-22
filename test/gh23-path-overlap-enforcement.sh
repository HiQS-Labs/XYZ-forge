#!/usr/bin/env bash
# GH-23: Enforce path-overlap rejection on direct tick claim and tick scope.
source "$(dirname "$0")/_setup.sh" gh23-path-overlap-enforcement

tick_a init >/dev/null

# 1. Setup tasks
TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-101 --agent dispatcher --paths "src/auth/**" >/dev/null
TICK_TS=2026-05-04T10:00:01.000Z tick_a log task.created TASK-102 --agent dispatcher --paths "src/auth/login.js" >/dev/null
TICK_TS=2026-05-04T10:00:02.000Z tick_a log task.created TASK-103 --agent dispatcher --paths "src/billing/**" >/dev/null

# Alice claims TASK-101 with src/auth/**
tick_a claim TASK-101 --agent alice --paths "src/auth/**" >/dev/null
if [ $? -eq 0 ]; then
  pass "alice successfully claimed TASK-101"
else
  fail "alice failed to claim TASK-101"
fi

# 2. Bob attempts direct claim on TASK-102 (src/auth/login.js) -> MUST FAIL due to overlap with Alice
BOB_OUT=$(tick_b claim TASK-102 --agent bob --paths "src/auth/login.js" 2>&1)
BOB_STATUS=$?
if grep -q "paths overlap active claim (TASK-101) held by alice" <<<"$([ $BOB_STATUS -ne 0 ] && echo "$BOB_OUT")"; then
  pass "direct claim on overlapping task TASK-102 rejected (exit $BOB_STATUS): $BOB_OUT"
else
  fail "direct claim on overlapping task was not rejected! status=$BOB_STATUS out=$BOB_OUT"
fi

# 2b. Non-mutation assertion: TASK-102 must remain status: open with 0 claim events
TASK_102_STATUS=$(tick_b info TASK-102 2>/dev/null | awk -F': *' '$1=="status"{print $2}')
if [ "$TASK_102_STATUS" = "open" ]; then
  pass "rejected claim was non-mutating: TASK-102 remains open"
else
  fail "rejected claim mutated state! status=$TASK_102_STATUS"
fi

# 3. Bob uses --force -> MUST SUCCEED
BOB_FORCE_OUT=$(tick_b claim TASK-102 --agent bob --paths "src/auth/login.js" --force 2>&1)
BOB_FORCE_STATUS=$?
if grep -q "won: TASK-102 claimed by bob" <<<"$([ $BOB_FORCE_STATUS -eq 0 ] && echo "$BOB_FORCE_OUT")"; then
  pass "direct claim with --force succeeded: $BOB_FORCE_OUT"
else
  fail "direct claim with --force failed! status=$BOB_FORCE_STATUS out=$BOB_FORCE_OUT"
fi

# 3b. Provenance check: force: true must be recorded in the event log
if grep -rnq '"force":true' "$A/.tick/events/"*claimed*TASK-102*; then
  pass "force provenance recorded in event log for forced claim"
else
  fail "force provenance missing from event log for TASK-102"
fi

# Bob releases TASK-102
tick_b release TASK-102 --agent bob >/dev/null

# 4. Bob claims TASK-103 (src/billing/**) -> non-overlapping, MUST SUCCEED
tick_b claim TASK-103 --agent bob --paths "src/billing/**" >/dev/null
if [ $? -eq 0 ]; then
  pass "bob claimed non-overlapping TASK-103"
else
  fail "bob failed to claim TASK-103"
fi

# 5. Bob attempts tick scope on TASK-103 to include "src/auth/oauth.js" -> MUST FAIL due to overlap with Alice
SCOPE_OUT=$(tick_b scope TASK-103 --agent bob --paths "src/billing/**,src/auth/oauth.js" 2>&1)
SCOPE_STATUS=$?
if grep -q "paths overlap active claim (TASK-101) held by alice" <<<"$([ $SCOPE_STATUS -ne 0 ] && echo "$SCOPE_OUT")"; then
  pass "scope expansion into overlapping paths rejected (exit $SCOPE_STATUS): $SCOPE_OUT"
else
  fail "scope expansion into overlapping paths was not rejected! status=$SCOPE_STATUS out=$SCOPE_OUT"
fi

# 5b. Non-mutation assertion: TASK-103 paths must NOT have changed
TASK_103_PATHS=$(tick_b info TASK-103 2>/dev/null | awk -F': *' '$1=="paths"{print $2}')
if echo "$TASK_103_PATHS" | grep -q "src/billing/\*\*" && ! echo "$TASK_103_PATHS" | grep -q "src/auth"; then
  pass "rejected scope expansion was non-mutating: TASK-103 paths unchanged ($TASK_103_PATHS)"
else
  fail "rejected scope expansion mutated paths! paths=$TASK_103_PATHS"
fi

# 6. Bob uses tick scope --force -> MUST SUCCEED
SCOPE_FORCE_OUT=$(tick_b scope TASK-103 --agent bob --paths "src/billing/**,src/auth/oauth.js" --force 2>&1)
SCOPE_FORCE_STATUS=$?
if grep -q "scoped: TASK-103" <<<"$([ $SCOPE_FORCE_STATUS -eq 0 ] && echo "$SCOPE_FORCE_OUT")"; then
  pass "scope expansion with --force succeeded: $SCOPE_FORCE_OUT"
else
  fail "scope expansion with --force failed! status=$SCOPE_FORCE_STATUS out=$SCOPE_FORCE_OUT"
fi

# 6b. Provenance check: force: true must be recorded in scope_changed event
if grep -rnq '"force":true' "$A/.tick/events/"*scope_changed*TASK-103*; then
  pass "force provenance recorded in event log for forced scope change"
else
  fail "force provenance missing from event log for TASK-103 scope"
fi

# 7. Alice completes TASK-101
tick_a done TASK-101 --agent alice --note "auth done" >/dev/null

# 8. Release unblocking: Charlie claims TASK-104 (src/auth/register.js).
# Alice is done, and Bob's forced scope is src/auth/oauth.js (distinct file). Charlie MUST SUCCEED without --force.
TICK_TS=2026-05-04T10:00:10.000Z tick_a log task.created TASK-104 --agent dispatcher --paths "src/auth/register.js" >/dev/null
CHARLIE_AUTH_OUT=$(tick_b claim TASK-104 --agent charlie --paths "src/auth/register.js" 2>&1)
CHARLIE_AUTH_STATUS=$?
if grep -q "won: TASK-104 claimed by charlie" <<<"$([ $CHARLIE_AUTH_STATUS -eq 0 ] && echo "$CHARLIE_AUTH_OUT")"; then
  pass "release unblocking verified: charlie claimed TASK-104 after alice completed TASK-101"
else
  fail "release unblocking failed! status=$CHARLIE_AUTH_STATUS out=$CHARLIE_AUTH_OUT"
fi

# 9. Third-party rejection after force: Dave attempts to claim TASK-106 on src/auth/oauth.js (held by Bob's forced scope) -> MUST BE REJECTED
TICK_TS=2026-05-04T10:00:12.000Z tick_a log task.created TASK-106 --agent dispatcher --paths "src/auth/oauth.js" >/dev/null
DAVE_OUT=$(tick_b claim TASK-106 --agent dave --paths "src/auth/oauth.js" 2>&1)
DAVE_STATUS=$?
if grep -q "paths overlap active claim (TASK-103) held by bob" <<<"$([ $DAVE_STATUS -ne 0 ] && echo "$DAVE_OUT")"; then
  pass "third-party claim rejected against Bob's forced active scope: $DAVE_OUT"
else
  fail "third-party claim was not rejected against forced scope! status=$DAVE_STATUS out=$DAVE_OUT"
fi

# 10. Idempotent re-claim: Charlie re-claims own held task (TASK-104) -> MUST SUCCEED (won)
CHARLIE_RECLAIM=$(tick_b claim TASK-104 --agent charlie --paths "src/auth/register.js" 2>&1)
if grep -q "won: TASK-104 claimed by charlie" <<<"$([ $? -eq 0 ] && echo "$CHARLIE_RECLAIM")"; then
  pass "idempotent re-claim by current holder succeeded without self-overlap rejection"
else
  fail "idempotent re-claim failed! out=$CHARLIE_RECLAIM"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
