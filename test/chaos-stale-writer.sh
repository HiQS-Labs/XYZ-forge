#!/usr/bin/env bash
# Part B Phase 1 / G3 — Stale-writer fencing (the keystone).
#
# Threat (per ROADMAP): "a revived X with the SAME agent id still passes
# ownership checks after takeover." X claims a task, is presumed dead and reaped,
# the task is reclaimed (epoch rises) — then X REVIVES and replays its old
# done/scope/release events. Ownership (claim.agent === agent) does NOT stop a
# same-id zombie; only a monotonic epoch does.
#
# Prove: once the epoch moves on, the displaced epoch CANNOT write/advance — its
# mutations are fenced (rejected) by the projection kernel, not ignored by
# convention. Relay state is unchanged, the current owner can still act, and the
# fence is recorded in a replay-deterministic audit log.
source "$(dirname "$0")/_setup.sh" chaos-stale-writer

# ============================================================================
# SCENARIO 1 — the keystone: SAME agent id, stale epoch.
# alice claims (e1) → reaped → alice RE-claims the same task (e2) → a buffered
# duplicate of her e1 done/scope/release lands AFTER she re-owns at e2. Ownership
# passes (same id); ONLY the epoch fence can stop it.
# ============================================================================
tick_a init >/dev/null
TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-1 --agent dispatcher --priority 10 --paths "src/one/**" >/dev/null

TICK_TS=2026-05-04T10:00:01.000Z tick_a claim TASK-1 --agent alice --paths "src/one/**" >/dev/null
if grep -q '"epoch":1' "$A"/.tick/events/*alice-claimed-TASK-1.jsonl; then
  pass "first claim carries epoch 1"
else
  fail "first claim missing epoch 1"
fi

# Reaped (presumed crashed), then alice revives and legitimately RE-claims → e2.
TICK_TS=2026-05-04T10:00:05.000Z tick_a reap alice --by coordinator >/dev/null
TICK_TS=2026-05-04T10:00:06.000Z tick_a claim TASK-1 --agent alice --paths "src/one/**" >"$WORK/re.out"
RECLAIM_EPOCH=$(grep -ho '"epoch":[0-9]*' "$A"/.tick/events/*alice-claimed-TASK-1.jsonl | sort -u | tail -1)
if [ "$RECLAIM_EPOCH" = '"epoch":2' ]; then
  pass "same-agent reclaim after reap raises the epoch to 2"
else
  fail "reclaim did not raise epoch (got $RECLAIM_EPOCH)"
fi

tick_a project >/dev/null
cp "$A/.tick/STATE.md" "$WORK/state-before.md"

# The zombie's epoch-1 events replay AFTER the e2 reclaim (direct log injection =
# the duplicate / synced / buffered-corpse write the CLI guard cannot stop).
TICK_TS=2026-05-04T10:00:09.000Z tick_a log task.done          TASK-1 --agent alice --epoch 1 >/dev/null
TICK_TS=2026-05-04T10:00:10.000Z tick_a log task.scope_changed TASK-1 --agent alice --epoch 1 --paths "src/evil/**" >/dev/null
TICK_TS=2026-05-04T10:00:11.000Z tick_a log task.released      TASK-1 --agent alice --epoch 1 >/dev/null
tick_a project >/dev/null

# The stale done must NOT advance the task; the stale release must NOT retire the
# live e2 claim; the stale scope must NOT corrupt the lane.
if grep -qE "^- TASK-1 by alice" "$A/.tick/STATE.md"; then
  pass "same-id stale done+release fenced — TASK-1 still claimed (alice, e2), not done/open"
else
  fail "stale same-id events leaked through:\n$(cat "$A/.tick/STATE.md")"
fi
if grep -q "evil" "$A/.tick/STATE.md"; then
  fail "stale scope_changed corrupted the lane (src/evil/** leaked)"
else
  pass "stale scope_changed fenced — lane uncorrupted (src/one/** intact)"
fi
if diff -q "$WORK/state-before.md" "$A/.tick/STATE.md" >/dev/null; then
  pass "relay state byte-identical before/after the stale replay"
else
  diff "$WORK/state-before.md" "$A/.tick/STATE.md" || true
  fail "stale replay mutated projected state"
fi

# Audit log: the keystone reason is stale-epoch (agent id MATCHES the owner).
DONE_REASON=$(grep '"type":"task.done"' "$A/.tick/rejected.jsonl" | grep -o '"reason":"[^"]*"')
if [ "$DONE_REASON" = '"reason":"stale-epoch"' ]; then
  pass "stale done logged as stale-epoch (proves epoch — not identity — is the fence)"
else
  fail "stale done reason wrong (got $DONE_REASON):\n$(cat "$A/.tick/rejected.jsonl")"
fi
if grep -q '"type":"task.scope_changed".*"reason":"stale-epoch"' "$A/.tick/rejected.jsonl"; then
  pass "stale scope logged as stale-epoch"
else
  fail "stale scope not fenced in audit log:\n$(cat "$A/.tick/rejected.jsonl")"
fi
# The legitimate reap release (pre-reclaim) must NOT be flagged as a fence.
if grep -q '"ts":"2026-05-04T10:00:05' "$A/.tick/rejected.jsonl"; then
  fail "legitimate reap release wrongly logged as fenced"
else
  pass "legitimate reap release not flagged (only post-takeover writes are fences)"
fi

# `tick fences` surfaces the same log; verdict is replay-deterministic.
tick_a fences >"$WORK/fences.out"
if grep -q '"fenced_agent":"alice"' "$WORK/fences.out"; then
  pass "tick fences reports the displaced writer"
else
  fail "tick fences output unexpected:\n$(cat "$WORK/fences.out")"
fi
cp "$A/.tick/rejected.jsonl" "$WORK/rej-1.jsonl"
tick_a project >/dev/null
if diff -q "$WORK/rej-1.jsonl" "$A/.tick/rejected.jsonl" >/dev/null; then
  pass "rejected.jsonl byte-identical across re-projections (deterministic)"
else
  fail "fence verdict not deterministic across replays"
fi

# The current owner (alice, e2) is unaffected and can still complete the task.
TICK_TS=2026-05-04T10:00:20.000Z tick_a done TASK-1 --agent alice --note "real work" >/dev/null
tick_a project >/dev/null
if grep -qE "^- TASK-1$" "$A/.tick/STATE.md"; then
  pass "current owner (alice, e2) can still complete the task"
else
  fail "current owner could not complete after fence:\n$(cat "$A/.tick/STATE.md")"
fi

# ============================================================================
# SCENARIO 2 — cross-agent takeover: a DIFFERENT agent now owns, the displaced
# writer's events are fenced as non-owner-agent.
# ============================================================================
TICK_TS=2026-05-04T11:00:00.000Z tick_a log task.created TASK-2 --agent dispatcher --priority 10 --paths "src/two/**" >/dev/null
TICK_TS=2026-05-04T11:00:01.000Z tick_a claim TASK-2 --agent carol --paths "src/two/**" >/dev/null
TICK_TS=2026-05-04T11:00:05.000Z tick_a reap carol --by coordinator >/dev/null
TICK_TS=2026-05-04T11:00:06.000Z tick_a claim TASK-2 --agent dave --paths "src/two/**" >/dev/null
TICK_TS=2026-05-04T11:00:09.000Z tick_a log task.done TASK-2 --agent carol --epoch 1 >/dev/null
tick_a project >/dev/null
if grep -qE "^- TASK-2 by dave" "$A/.tick/STATE.md"; then
  pass "cross-agent takeover: carol's stale done fenced — dave still owns TASK-2"
else
  fail "cross-agent stale done leaked:\n$(cat "$A/.tick/STATE.md")"
fi
if grep -q '"task":"TASK-2".*"fenced_agent":"carol".*"owner_agent":"dave".*"reason":"non-owner-agent"' "$A/.tick/rejected.jsonl"; then
  pass "cross-agent stale done logged as non-owner-agent"
else
  fail "cross-agent fence not in audit log:\n$(grep TASK-2 "$A/.tick/rejected.jsonl")"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
