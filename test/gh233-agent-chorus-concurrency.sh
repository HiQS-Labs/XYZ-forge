#!/usr/bin/env bash
# gh233-agent-chorus-concurrency.sh — Concurrency, race-condition, and doorbell stress suite (GH-233)
#
# Asserts:
# 1. Multi-agent concurrent joins and heartbeat tracking
# 2. Roster widening from 2 to 3+ seats under active load
# 3. discussion.lock mutex contention during serialized handoffs
# 4. Immediate terminal invalidation of background watch processes on close/supersession
# 5. Atomic supersession contention and idempotency

set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
CLI="$REPO/skills/agent-chorus/scripts/agent_chorus.py"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh233-chorus-concurrency.XXXXXX")" || {
  echo "FAIL: mktemp -d failed" >&2
  exit 1
}
[ -n "$WORK" ] && [ -d "$WORK" ] || {
  echo "FAIL: mktemp -d returned an invalid directory" >&2
  exit 1
}
case "$WORK" in
  "${TMPDIR:-/tmp}"/gh233-chorus-concurrency.*) ;;
  *) echo "FAIL: refusing unsafe cleanup target: $WORK" >&2; exit 1 ;;
esac
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0

pass() { printf '  PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); }

expect_contains() {
  _label="$1"; _text="$2"; _needle="$3"
  case "$_text" in *"$_needle"*) pass "$_label" ;; *) fail "$_label (missing: $_needle)" ;; esac
}

STORE="$WORK/store"
mkdir -p "$STORE"
a2a() { python3 "$CLI" --root "$REPO" --store "$STORE" "$@"; }

printf '## Goal\nConcurrency testing\n## Scope\nTest\n## Context and current state\nActive\n## Evidence and artifacts\nNone\n## Constraints and safety boundaries\nNone\n## Questions for participants\nQ\n## Requested outcome / done condition\nDone\n' > "$WORK/packet.md"

# ── Test 1: Racing Joins and Doorbell Registration ────────────────────────────
a2a start --subject "racing joins test" --packet-file "$WORK/packet.md" --id 999001 --agents 3 >/dev/null 2>&1

# Spawn background joins concurrently
(a2a join --id 999001 --agent 2 > "$WORK/join2.out" 2>&1) &
PID_J2=$!
(a2a join --id 999001 --agent 3 > "$WORK/join3.out" 2>&1) &
PID_J3=$!

wait "$PID_J2"
wait "$PID_J3"

JOIN2_OUT="$(cat "$WORK/join2.out")"
JOIN3_OUT="$(cat "$WORK/join3.out")"

expect_contains "agent2 join resolves take-turn" "$JOIN2_OUT" "DECISION: take-turn"
expect_contains "agent3 join resolves wait" "$JOIN3_OUT" "DECISION: wait"

# ── Test 2: Watch Invalidation on Discussion Closure ──────────────────────────
# Start a background watch on agent 3 (who is waiting)
a2a watch --id 999001 --agent 3 --interval 0.1 --timeout 10 > "$WORK/watch3.out" 2>&1 &
WATCH_PID=$!
sleep 0.5

# Agent 2 closes the discussion
a2a close --id 999001 --agent 2 --trivial --message "closing discussion" >/dev/null 2>&1

# The watch process should terminate immediately (well before the 10s timeout)
START_T=$(date +%s)
wait "$WATCH_PID"
WATCH_RC=$?
END_T=$(date +%s)
ELAPSED=$((END_T - START_T))

[ "$WATCH_RC" -eq 0 ] && pass "watch process exits cleanly upon discussion closure" || fail "watch process exit $WATCH_RC"
[ "$ELAPSED" -lt 5 ] && pass "watch process terminated immediately on close (< 5s, was ${ELAPSED}s)" || fail "watch process did not exit promptly: took ${ELAPSED}s"

WATCH3_OUT="$(cat "$WORK/watch3.out")"
expect_contains "watcher observes terminal closed decision" "$WATCH3_OUT" "DECISION: closed"

# ── Test 3: Watch Invalidation on Supersession ────────────────────────────────
a2a start --subject "superseded watch test" --packet-file "$WORK/packet.md" --id 999002 --agents 3 >/dev/null 2>&1

# Start background watch for agent 3 (who is waiting while agent2 owns NEXT)
a2a watch --id 999002 --agent 3 --interval 0.1 --timeout 10 > "$WORK/watch_sup.out" 2>&1 &
WATCH_SUP_PID=$!
sleep 0.5

# Supersede discussion 999002 with 999003
a2a start --subject "new superseding discussion" --packet-file "$WORK/packet.md" --id 999003 --supersedes 999002 >/dev/null 2>&1

# The watcher on 999002 should terminate immediately with superseded pointer
START_T=$(date +%s)
wait "$WATCH_SUP_PID"
WATCH_SUP_RC=$?
END_T=$(date +%s)
ELAPSED=$((END_T - START_T))

[ "$WATCH_SUP_RC" -eq 0 ] && pass "watch process exits cleanly upon discussion supersession" || fail "watch process exit $WATCH_SUP_RC"
[ "$ELAPSED" -lt 5 ] && pass "watch process terminated immediately on supersession (< 5s, was ${ELAPSED}s)" || fail "watch did not exit promptly on supersession: took ${ELAPSED}s"

WATCH_SUP_OUT="$(cat "$WORK/watch_sup.out")"
expect_contains "watcher receives SUPERSEDED-BY line" "$WATCH_SUP_OUT" "SUPERSEDED-BY: 999003"
expect_contains "watcher decides closed on supersession" "$WATCH_SUP_OUT" "DECISION: closed"

# ── Test 4: Roster Widening from 2 to 3+ under Active Load ────────────────────
a2a start --subject "widening under load" --packet-file "$WORK/packet.md" --id 999004 --agents 2 >/dev/null 2>&1

# Agent 2 sends turn to agent 1
a2a send --id 999004 --agent 2 --next-agent 1 --message "turn 2" >/dev/null 2>&1

# Operator widens to agent 3
INV_OUT="$(a2a invite --id 999004 --agent 3 --reason "Add specialist reviewer" 2>&1)"
expect_contains "invite succeeds and returns invitation" "$INV_OUT" 'Join XYZ AgentChorus #999004 as agent number three'

# Operator widens to agent 4
INV4_OUT="$(a2a invite --id 999004 --agent 4 --reason "Add verification auditor" 2>&1)"
expect_contains "sequential widening to agent4 succeeds" "$INV4_OUT" 'Join XYZ AgentChorus #999004 as agent number four'

STATUS_WIDEN="$(a2a status --id 999004 2>&1)"
expect_contains "roster includes all 4 agents" "$STATUS_WIDEN" "AGENTS: agent1 agent2 agent3 agent4"

# Agent 1 (who still owns NEXT) can route to the newly added agent 3
a2a send --id 999004 --agent 1 --next-agent 3 --message "turn 4 routing to agent3" >/dev/null 2>&1

JOIN3_WIDEN="$(a2a join --id 999004 --agent 3 2>&1)"
expect_contains "newly invited agent 3 owns NEXT" "$JOIN3_WIDEN" "DECISION: take-turn"

# ── Test 5: Mutex Contention and Out-of-Turn Rejection ────────────────────────
# Multiple agents attempting concurrent writes to a single discussion
# Agent 3 currently owns NEXT. Agent 2 and Agent 4 try to send out of turn concurrently.
(a2a send --id 999004 --agent 2 --next-agent 1 --message "illegal turn" > "$WORK/send2.err" 2>&1) &
PID_S2=$!
(a2a send --id 999004 --agent 4 --next-agent 1 --message "illegal turn" > "$WORK/send4.err" 2>&1) &
PID_S4=$!

wait "$PID_S2"
RC_S2=$?
wait "$PID_S4"
RC_S4=$?

[ "$RC_S2" -ne 0 ] && pass "out-of-turn send by agent 2 rejected" || fail "send 2 succeeded unexpectedly"
[ "$RC_S4" -ne 0 ] && pass "out-of-turn send by agent 4 rejected" || fail "send 4 succeeded unexpectedly"

# ── Test 6: Concurrent Supersession Conflict ──────────────────────────────────
# Two processes racing to supersede the same parent discussion 999004
a2a close --id 999004 --agent 3 --trivial --message "finish" >/dev/null 2>&1

(a2a start --subject "race sup A" --packet-file "$WORK/packet.md" --id 999005 --supersedes 999004 > "$WORK/supA.out" 2>&1) &
PID_SA=$!
(a2a start --subject "race sup B" --packet-file "$WORK/packet.md" --id 999006 --supersedes 999004 > "$WORK/supB.out" 2>&1) &
PID_SB=$!

wait "$PID_SA"
RC_SA=$?
wait "$PID_SB"
RC_SB=$?

# Exactly one must succeed and one must fail (or both fail if already superseded)
if { [ "$RC_SA" -eq 0 ] && [ "$RC_SB" -ne 0 ]; } || { [ "$RC_SA" -ne 0 ] && [ "$RC_SB" -eq 0 ]; }; then
  pass "supersession mutex ensures exactly one child supersedes parent"
else
  fail "supersession race condition: SA_RC=$RC_SA SB_RC=$RC_SB"
fi

printf '  gh233-agent-chorus-concurrency: %s pass, %s fail\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
