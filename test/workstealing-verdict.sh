#!/usr/bin/env bash
# GH-4: work-stealing (via the existing `tick take` candidate filter) + a lane-count-independent
# `tick analyze` verdict. The scenario a clean 2-lane split can't satisfy under the OLD ">=2 done/agent"
# bar: beta finishes its lane fast and STEALS a third task from a free lane (turning idle tail-time into
# real parallel work), producing an imbalanced 2-vs-1 done count that the OLD bar failed — but the NEW
# verdict PASSES on concurrency + zero-parked + all-lanes-done + zero-collisions.
source "$(dirname "$0")/_setup.sh" workstealing-verdict

tick_a init >/dev/null
# 3 tasks in 3 disjoint lanes so a free agent can steal the third collision-free.
TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created A1 --agent dispatcher --priority 10 --paths "a/**" >/dev/null
TICK_TS=2026-05-04T10:00:00.100Z tick_a log task.created B1 --agent dispatcher --priority  8 --paths "b/**" >/dev/null
TICK_TS=2026-05-04T10:00:00.200Z tick_a log task.created C1 --agent dispatcher --priority  5 --paths "c/**" >/dev/null

# alice + beta start together (concurrency); take picks highest-priority collision-free open task.
TICK_TS=2026-05-04T10:01:00.000Z tick_a take --agent alice >"$WORK/a1.out"
grep -q "won: A1" "$WORK/a1.out" && pass "alice take -> A1 (highest priority)" || fail "alice take: $(cat "$WORK/a1.out")"
TICK_TS=2026-05-04T10:01:00.000Z tick_a take --agent beta >"$WORK/b1.out"
grep -q "won: B1" "$WORK/b1.out" && pass "beta take -> B1 (A1 already claimed by alice)" || fail "beta take: $(cat "$WORK/b1.out")"

# beta finishes its lane fast, then STEALS C1 from the free lane (the work-stealing move).
TICK_TS=2026-05-04T10:03:00.000Z tick_a done B1 --agent beta >/dev/null
TICK_TS=2026-05-04T10:03:01.000Z tick_a take --agent beta >"$WORK/steal.out"
grep -q "won: C1" "$WORK/steal.out" \
  && pass "WORK-STEALING: free agent beta takes C1 from another lane (collision-free)" \
  || fail "beta failed to steal C1: $(cat "$WORK/steal.out")"

# beta must NOT be able to steal a task overlapping a live claim — prove the steal stays collision-safe.
# (alice still holds a/**; there is no open task now, so a further take yields nothing.)
TICK_TS=2026-05-04T10:03:02.000Z tick_a take --agent beta >"$WORK/nomore.out"
grep -q "no available task" "$WORK/nomore.out" && pass "no collision-unsafe steal (board drained for beta)" || fail "unexpected: $(cat "$WORK/nomore.out")"

TICK_TS=2026-05-04T10:05:00.000Z tick_a done A1 --agent alice >/dev/null
TICK_TS=2026-05-04T10:06:00.000Z tick_a done C1 --agent beta  >/dev/null

tick_a analyze --format json >"$WORK/an.json"

# The crux: imbalanced per-agent done (beta 2, alice 1) — the OLD ">=2 done/agent" bar FAILS alice —
# yet the verdict PASSES.
node -e '
  const r = JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
  const v = r.verdict, c = v.checks;
  const fail = (m) => { console.error("ASSERT: "+m); process.exit(1); };
  if (v.verdict !== "pass") fail("verdict expected pass, got "+v.verdict+" reasons="+JSON.stringify(v.reasons));
  if (!c.all_lanes_done) fail("all_lanes_done should be true (A1,B1,C1 all done)");
  if (!c.no_collisions) fail("no_collisions should be true, got "+c.collisions);
  if (!c.parked_ok) fail("parked_ok should be true");
  if (!c.concurrency_ok) fail("concurrency should meet target, got "+c.concurrency_pct+"%");
  const by = Object.fromEntries(r.agents.map(a => [a.agent, a.dones]));
  if (by.beta !== 2) fail("beta should have 2 done (stole C1), got "+by.beta);
  if (by.alice !== 1) fail("alice should have 1 done, got "+by.alice);
  // the whole point: an imbalanced 2-vs-1 split still PASSES (not gated on per-agent done count).
' "$WORK/an.json" \
  && pass "VERDICT: PASS on an imbalanced 2-vs-1 done split (concurrency + all-done + 0 collisions; NOT per-agent done)" \
  || fail "verdict/agent-count assertions failed (see ASSERT above)"

# The balance report surfaces the idle tail (imbalance signal, fix 3).
grep -qE "lane balance:" <<<"$(tick_a analyze)" && pass "analyze surfaces a lane-balance line (idle-tail imbalance signal)" || fail "no lane balance line in human output"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
