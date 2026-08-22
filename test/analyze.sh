#!/usr/bin/env bash
# `tick analyze` test: event-log-only metrics (Run 2 — git log analysis removed
# when the git transport was stripped). Drift/unclaimed detection is deferred.
source "$(dirname "$0")/_setup.sh" analyze

tick_a init >/dev/null
TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-001 --agent dispatcher --priority 10 --paths "src/auth/**"    >/dev/null
TICK_TS=2026-05-04T10:00:01.000Z tick_a log task.created TASK-002 --agent dispatcher --priority  5 --paths "src/billing/**" >/dev/null
TICK_TS=2026-05-04T10:00:02.000Z tick_a log task.created TASK-003 --agent dispatcher --priority  1 --paths "src/poison/**"  >/dev/null

# alice: claims TASK-001 at 10:01, done at 10:15.
# bob:   claims TASK-002 at 10:05 (overlaps alice's window), done at 10:30.
# → concurrent-claim window = 10:05-10:15 (10 min out of ~40 min run window).
TICK_TS=2026-05-04T10:01:00.000Z tick_a claim TASK-001 --agent alice --paths "src/auth/**"    >/dev/null
TICK_TS=2026-05-04T10:05:00.000Z tick_b claim TASK-002 --agent bob   --paths "src/billing/**" >/dev/null
TICK_TS=2026-05-04T10:15:00.000Z tick_a done  TASK-001 --agent alice                          >/dev/null
TICK_TS=2026-05-04T10:30:00.000Z tick_b done  TASK-002 --agent bob                            >/dev/null

# alice: claims and breaks TASK-003 at 10:40-10:41.
TICK_TS=2026-05-04T10:40:00.000Z tick_a claim TASK-003 --agent alice --paths "src/poison/**" >/dev/null
TICK_TS=2026-05-04T10:41:00.000Z tick_a break TASK-003 --agent alice --reason "loop"         >/dev/null

HUMAN=$(tick_a analyze)
echo "$HUMAN" >"$WORK/human.txt"

# Event counts.
grep -q "created:3" <<<"$(echo "$HUMAN")" \
  && pass "event count: 3 created" \
  || fail "expected created:3 in: $(echo "$HUMAN" | head -3)"

grep -q "claimed:3" <<<"$(echo "$HUMAN")" \
  && pass "event count: 3 claimed" \
  || fail "expected claimed:3"

grep -q "done:2" <<<"$(echo "$HUMAN")" \
  && pass "event count: 2 done" \
  || fail "expected done:2"

grep -q "circuit_break:1" <<<"$(echo "$HUMAN")" \
  && pass "event count: 1 circuit_break" \
  || fail "expected circuit_break:1"

# Per-agent stats.
grep -q "claims: 2, done: 1" <<<"$(echo "$HUMAN" | grep -A2 "\[alice\]")" \
  && pass "alice: 2 claims, 1 done" \
  || fail "alice per-agent stats unexpected: $(echo "$HUMAN" | grep -A3 '\[alice\]')"

grep -q "claims: 1, done: 1" <<<"$(echo "$HUMAN" | grep -A2 "\[bob\]")" \
  && pass "bob: 1 claim, 1 done" \
  || fail "bob per-agent stats unexpected: $(echo "$HUMAN" | grep -A3 '\[bob\]')"

# Concurrent-claim time: alice (10:01-10:15) overlaps bob (10:05-10:30).
# Overlap = 10:05-10:15 = 10 min > 0. Expect a percentage like (24%).
if grep -qE "\([1-9][0-9]*%\)" <<<"$(echo "$HUMAN" | grep "concurrent-claim time")"; then
  pass "concurrent-claim time is non-zero (overlapping claim windows detected)"
else
  fail "expected non-zero concurrent-claim time; got: $(echo "$HUMAN" | grep concurrent)"
fi

# GH-4: verdict + collisions on this board. TASK-003 was circuit_broken (not done) and the two lanes
# never path-overlap, so: 0 collisions, and VERDICT FAIL because a claimed lane didn't reach done
# (proves the verdict counts a broken/undone lane as a failure — and is not fooled by the 2 done).
grep -q "collisions (overlapping concurrent claims): 0" <<<"$(echo "$HUMAN")" \
  && pass "verdict: 0 collisions on disjoint lanes" \
  || fail "expected 0 collisions in: $(echo "$HUMAN" | grep -i collision)"
echo "$HUMAN" | grep -qE "VERDICT: FAIL" && echo "$HUMAN" | grep -q "TASK-003" \
  && pass "verdict: FAIL — a claimed lane (TASK-003) did not reach done" \
  || fail "expected VERDICT: FAIL citing TASK-003 in: $(echo "$HUMAN" | grep -i verdict)"

# --write: appends auto-analyzed section to a target file.
TARGET="$WORK/obs.md"
echo "# Observations" >"$TARGET"
tick_a analyze --write "$TARGET" >/dev/null
grep -q "^## Auto-analyzed (tick analyze)" "$TARGET" \
  && pass "tick analyze --write appended the auto-analyzed section" \
  || { cat "$TARGET"; fail "missing auto-analyzed section in target"; }

# Second --write replaces, doesn't append twice.
tick_a analyze --write "$TARGET" >/dev/null
HITS=$(grep -c "^## Auto-analyzed (tick analyze)" "$TARGET")
[ "$HITS" = "1" ] \
  && pass "second --write replaces, doesn't duplicate" \
  || fail "expected 1 section, got $HITS"

# GH-93 regression: concurrency % must be computed over the work-bounded window (first
# task.claimed -> last task.done), NOT the whole .tick/events/ log span. A fresh board so leftover
# events from the scenario above can't interfere: the whole-log span is WIDE (a task.created
# almost 6 months before the run, and a trailing task.commented almost 6 months after it), but the
# actual claimed->done window is NARROW (65s) and highly concurrent (alice/bob overlap for 55s of
# it, ~85%). Before the fix, `analyze` fed the whole-log span into computeParallelism and this
# printed ~0% (55s / ~1 year) despite the run itself being genuinely concurrent — exactly the bug
# GH-93 reports (a real ~51%+ concurrent run misreporting as 0%).
GH93="$WORK/gh93"
tick_in "$GH93" init >/dev/null

# Widens the whole-log span far to the left — long before any claim/done activity.
TICK_TS=2026-01-01T00:00:00.000Z tick_in "$GH93" log task.created TASK-100 --agent dispatcher --priority 10 --paths "src/wide-a/**" >/dev/null
TICK_TS=2026-01-01T00:00:01.000Z tick_in "$GH93" log task.created TASK-101 --agent dispatcher --priority  5 --paths "src/wide-b/**" >/dev/null

# The actual run: alice and bob overlap for 55s of a 65s claimed->done window.
TICK_TS=2026-07-01T10:00:00.000Z tick_in "$GH93" claim TASK-100 --agent alice --paths "src/wide-a/**" >/dev/null
TICK_TS=2026-07-01T10:00:05.000Z tick_in "$GH93" claim TASK-101 --agent bob   --paths "src/wide-b/**" >/dev/null
TICK_TS=2026-07-01T10:01:00.000Z tick_in "$GH93" done  TASK-100 --agent alice                         >/dev/null
TICK_TS=2026-07-01T10:01:05.000Z tick_in "$GH93" done  TASK-101 --agent bob                            >/dev/null

# Widens the whole-log span far to the right — long after the run finished.
TICK_TS=2026-12-31T00:00:00.000Z tick_in "$GH93" log task.commented TASK-101 --agent bob --note "stale trailing event" >/dev/null

GH93_HUMAN=$(tick_in "$GH93" analyze)
echo "$GH93_HUMAN" >"$WORK/gh93-human.txt"

grep -q "window (whole log): 2026-01-01T00:00:00.000Z → 2026-12-31T00:00:00.000Z" <<<"$(echo "$GH93_HUMAN")" \
  && pass "GH-93: whole-log window still reported (wide, ~1 year, informational)" \
  || fail "expected whole-log window to remain visible: $(echo "$GH93_HUMAN" | grep 'whole log')"

grep -q "window (work-bounded, first claimed → last done): 2026-07-01T10:00:00.000Z → 2026-07-01T10:01:05.000Z" <<<"$(echo "$GH93_HUMAN")" \
  && pass "GH-93: work-bounded window is the narrow claimed->done span, not the whole log" \
  || fail "expected narrow work-bounded window: $(echo "$GH93_HUMAN" | grep 'work-bounded')"

# The printed percentage must reflect the narrow 65s window (~85%), not the ~1-year whole-log span
# (which would round to 0%) — this is the exact regression GH-93 reports.
grep -qE "\(8[0-9]%\)" <<<"$(echo "$GH93_HUMAN" | grep "concurrent-claim time")" \
  && pass "GH-93: concurrent-claim percentage reflects the narrow work-bounded window (~85%), not the wide whole-log span" \
  || fail "expected ~85% concurrent-claim time (work-bounded), got: $(echo "$GH93_HUMAN" | grep concurrent)"

# A genuinely concurrent, fully-done, collision-free run must PASS — not FAIL due to a span bug.
grep -qE "VERDICT: PASS" <<<"$(echo "$GH93_HUMAN")" \
  && pass "GH-93: genuinely concurrent run now PASSES (was misreporting FAIL/0% before the fix)" \
  || fail "expected VERDICT: PASS, got: $(echo "$GH93_HUMAN" | grep -i verdict)"

# JSON output carries both fields too (the report object, not just the text renderer).
GH93_JSON=$(tick_in "$GH93" analyze --format json)
grep -q '"work_bound_start": "2026-07-01T10:00:00.000Z"' <<<"$(echo "$GH93_JSON")" \
  && pass "GH-93: JSON report includes work_bound_start" \
  || fail "expected work_bound_start in JSON: $(echo "$GH93_JSON" | grep -A1 window)"
grep -q '"work_bound_end": "2026-07-01T10:01:05.000Z"' <<<"$(echo "$GH93_JSON")" \
  && pass "GH-93: JSON report includes work_bound_end" \
  || fail "expected work_bound_end in JSON: $(echo "$GH93_JSON" | grep -A1 window)"
grep -q '"earliest_event": "2026-01-01T00:00:00.000Z"' <<<"$(echo "$GH93_JSON")" \
  && pass "GH-93: JSON report still includes the whole-log earliest_event (unchanged, informational)" \
  || fail "expected earliest_event preserved in JSON: $(echo "$GH93_JSON" | grep -A1 window)"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
