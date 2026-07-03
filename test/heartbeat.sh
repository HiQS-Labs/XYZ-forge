#!/usr/bin/env bash
# Run 3: `tick ping` emits a task.heartbeat liveness event (ownership-guarded),
# and `tick analyze` flags a claim window with no heartbeat for longer than the
# parked-claim threshold (10 min) as a parked-claim suspect — the work-activity
# signal that does NOT depend on git author identity.
source "$(dirname "$0")/_setup.sh" heartbeat

tick_a init >/dev/null
TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-1 --agent dispatcher --priority 10 --paths "src/http/**" >/dev/null
TICK_TS=2026-05-04T10:00:00.100Z tick_a log task.created TASK-2 --agent dispatcher --priority 10 --paths "src/store/**" >/dev/null

# alice claims both (cross-half, within the cap of 2).
TICK_TS=2026-05-04T10:00:01.000Z tick_a claim TASK-1 --agent alice --paths "src/http/**" >/dev/null
TICK_TS=2026-05-04T10:00:02.000Z tick_a claim TASK-2 --agent alice --paths "src/store/**" >/dev/null

# Ownership guard: a non-claimer cannot heartbeat the task.
if TICK_TS=2026-05-04T10:00:03.000Z tick_a ping TASK-1 --agent bob >"$WORK/bobping.out" 2>&1; then
  fail "bob (non-owner) was allowed to ping TASK-1: $(cat "$WORK/bobping.out")"
else
  pass "ping is ownership-guarded (non-owner rejected)"
fi

# alice heartbeats TASK-1 mid-window; emits a task.heartbeat event file.
TICK_TS=2026-05-04T10:05:01.000Z tick_a ping TASK-1 --agent alice >/dev/null
BEATS=$(ls "$A/.tick/events/" | grep -c "alice-heartbeat-TASK-1" || true)
if [ "$BEATS" = "1" ]; then
  pass "tick ping emitted a task.heartbeat event"
else
  fail "expected 1 alice-heartbeat-TASK-1 event, got $BEATS"
fi

# Close both windows. TASK-1: claimed 10:00:01, beat 10:05:01, done 10:08:01
# (max gap 5m < 10m → healthy). TASK-2: claimed 10:00:02, NO beats, done
# 10:20:02 (20m gap > 10m → parked suspect).
TICK_TS=2026-05-04T10:08:01.000Z tick_a done TASK-1 --agent alice >/dev/null
TICK_TS=2026-05-04T10:20:02.000Z tick_a done TASK-2 --agent alice >/dev/null

tick_a analyze --format json >"$WORK/analyze.json"
PARKED=$(node -e 'const r=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")); console.log(r.parked_suspects.map(s=>s.task).sort().join(","))' "$WORK/analyze.json")

if [ "$PARKED" = "TASK-2" ]; then
  pass "analyze flags only the heartbeat-less claim as parked (TASK-2)"
else
  fail "expected parked_suspects=[TASK-2], got [$PARKED]"
fi

# The heartbeat-covered window must NOT be flagged.
if echo "$PARKED" | grep -q "TASK-1"; then
  fail "TASK-1 wrongly flagged parked despite an in-window heartbeat"
else
  pass "heartbeat-covered claim window is not flagged parked"
fi

# --- GH-3: liveness = ANY task.* event, not just task.heartbeat ---
# TASK-3: alice claims 10:30:00, emits a task.scope_changed (NOT a heartbeat) at 10:39:00,
# done 10:48:00. Both gaps are 9m < 10m, so a truthful liveness signal must NOT flag it —
# but a heartbeat-ONLY signal would see an 18m gap and wrongly flag it (the false positive #3).
TICK_TS=2026-05-04T10:29:59.000Z tick_a log task.created TASK-3 --agent dispatcher --priority 10 --paths "src/x/**" >/dev/null
TICK_TS=2026-05-04T10:30:00.000Z tick_a claim TASK-3 --agent alice --paths "src/x/**" >/dev/null
TICK_TS=2026-05-04T10:39:00.000Z tick_a log task.scope_changed TASK-3 --agent alice --paths "src/x/**,src/y/**" >/dev/null
TICK_TS=2026-05-04T10:48:00.000Z tick_a done TASK-3 --agent alice >/dev/null
tick_a analyze --format json >"$WORK/analyze3.json"
if node -e 'const r=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")); process.exit((r.parked_suspects||[]).some(s=>s.task==="TASK-3")?1:0)' "$WORK/analyze3.json"; then
  pass "GH-3: a non-heartbeat task.* event (scope_changed) counts as liveness — TASK-3 not flagged"
else
  fail "GH-3: TASK-3 wrongly flagged parked despite an in-window scope_changed (liveness must not be heartbeat-only)"
fi

# --- GH-3: TICK_PARKED_THRESHOLD_MS operator override ---
# TASK-4: alice claims 11:00:00, no activity, done 11:15:00 -> a real 15m idle gap.
TICK_TS=2026-05-04T10:59:59.000Z tick_a log task.created TASK-4 --agent dispatcher --priority 10 --paths "src/z/**" >/dev/null
TICK_TS=2026-05-04T11:00:00.000Z tick_a claim TASK-4 --agent alice --paths "src/z/**" >/dev/null
TICK_TS=2026-05-04T11:15:00.000Z tick_a done TASK-4 --agent alice >/dev/null
# default 10m threshold: the 15m gap IS flagged.
tick_a analyze --format json >"$WORK/analyze4a.json"
if node -e 'const r=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")); process.exit((r.parked_suspects||[]).some(s=>s.task==="TASK-4")?0:1)' "$WORK/analyze4a.json"; then
  pass "GH-3: 15m-gap TASK-4 flagged at the default 10m threshold"
else
  fail "GH-3: TASK-4 (15m gap) not flagged at the default threshold"
fi
# raised to 30m: the same 15m gap is NOT flagged.
TICK_PARKED_THRESHOLD_MS=1800000 tick_a analyze --format json >"$WORK/analyze4b.json"
if node -e 'const r=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")); process.exit((r.parked_suspects||[]).some(s=>s.task==="TASK-4")?1:0)' "$WORK/analyze4b.json"; then
  pass "GH-3: TICK_PARKED_THRESHOLD_MS=30m suppresses the 15m-gap flag (operator-tunable)"
else
  fail "GH-3: TICK_PARKED_THRESHOLD_MS override did not raise the threshold"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
