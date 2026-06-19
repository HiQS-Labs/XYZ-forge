#!/usr/bin/env bash
# Part B Phase 2 / G1 — Mid-turn kill: DETECTION + structured escalation.
#
# Threat (G1): an agent claims a task then dies (SIGKILL, crash, OOM) before
# it can call `tick done` or `tick release`. The token is held by a corpse. The
# relay would stall forever if the watchdog/analyzer didn't surface it.
#
# This test proves the DETECTION half:
#   1. Agent claims a task (token taken).
#   2. Agent dies — simulated by emitting ZERO subsequent heartbeats.
#   3. Time advances past the parked-claim threshold (~10 min) via TICK_TS.
#   4. `tick analyze --format json` flags the claim as a `parked_suspects` entry.
#   5. The watchdog emits a structured (JSON) escalation record — never silently hangs.
#
# NOTE: Auto-reap RECOVERY (re-offering the orphaned token) is OUT OF SCOPE here.
# It is gated on the unmade R2 "auto-reap authority" decision (--allow-reap stub).
# The assertions below stop at detection + escalation, consistent with the R2
# "auto-reap authority" item under ROADMAP.md "Part B · Phase 2" (still 🔲).
source "$(dirname "$0")/_setup.sh" chaos-midturn-kill

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export TICK_BIN="$TICK"
WD="$ROOT/relay-automation/watchdog.sh"

# ── Setup ──────────────────────────────────────────────────────────────────────
tick_a init >/dev/null

# Create and claim a task. Agent "alice" takes the token.
TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-KILL \
  --agent dispatcher --priority 10 --paths "src/feature/**" >/dev/null
TICK_TS=2026-05-04T10:00:01.000Z tick_a claim TASK-KILL \
  --agent alice --paths "src/feature/**" >/dev/null

# Alice dies here — no `tick done`, no `tick ping`, no heartbeat ever emitted.
# Simulate elapsed time by dropping a synthetic event 31 minutes later (well past
# the 10-min parked-claim threshold used by `tick analyze`).
TICK_TS=2026-05-04T10:31:00.000Z tick_a log task.created TASK-UNRELATED \
  --agent dispatcher --priority 5 --paths "src/other/**" >/dev/null

# ── Assertion 1: analyzer detects the stalled claim ───────────────────────────
# `tick analyze --format json` must include TASK-KILL in parked_suspects[].
tick_a analyze --format json >"$WORK/analyze.json"

PARKED=$(node -e '
  const r = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
  console.log((r.parked_suspects || []).map(s => s.task).sort().join(","));
' "$WORK/analyze.json")

if [ "$PARKED" = "TASK-KILL" ]; then
  pass "analyzer detects orphaned claim as parked suspect (TASK-KILL)"
else
  fail "expected parked_suspects=[TASK-KILL], got [$PARKED]"
fi

# The unrelated task (never claimed) must NOT appear as a suspect.
if echo "$PARKED" | grep -q "TASK-UNRELATED"; then
  fail "unclaimed task wrongly flagged as parked"
else
  pass "unclaimed task not flagged as parked (no false positive)"
fi

# The analyzer must record the stalled agent name and a non-zero gap.
AGENT=$(node -e '
  const r = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
  const s = (r.parked_suspects || []).find(x => x.task === "TASK-KILL");
  console.log(s ? s.agent : "");
' "$WORK/analyze.json")
if [ "$AGENT" = "alice" ]; then
  pass "parked suspect names the stalled agent (alice)"
else
  fail "parked suspect agent wrong (got '$AGENT')"
fi

GAP_OK=$(node -e '
  const r = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
  const s = (r.parked_suspects || []).find(x => x.task === "TASK-KILL");
  // 31 min elapsed; threshold is 10 min (600 000 ms). Gap must exceed threshold.
  process.exit((s && s.max_gap_ms > 600000) ? 0 : 1);
' "$WORK/analyze.json") && GAP_OK=1 || GAP_OK=0

if [ "$GAP_OK" = "1" ]; then
  pass "parked suspect records max_gap_ms > 600000 (gap exceeds threshold)"
else
  fail "parked suspect max_gap_ms not above threshold:\n$(cat "$WORK/analyze.json")"
fi

# ── Assertion 2: watchdog emits a structured escalation — never silently hangs ─
# Feed the analysis JSON to the watchdog via --analysis-file to avoid re-running
# tick and to keep the test deterministic.
ESC_LOG="$WORK/escalation.ndjson"
WATCHDOG_TS='2026-06-18T10:31:00Z' "$WD" \
  --analysis-file "$WORK/analyze.json" \
  --channel file \
  --escalation-log "$ESC_LOG" \
  >"$WORK/wd.stdout" 2>"$WORK/wd.stderr"
WD_EXIT=$?

if [ "$WD_EXIT" -eq 0 ]; then
  pass "watchdog exits 0 on parked suspect (no hang)"
else
  fail "watchdog exited $WD_EXIT (expected 0):\n$(cat "$WORK/wd.stderr")"
fi

# Escalation log must contain exactly one record for TASK-KILL.
ESC_COUNT=$(node -e '
  const fs = require("fs");
  if (!fs.existsSync(process.argv[1])) { process.stdout.write("0"); process.exit(0); }
  const lines = fs.readFileSync(process.argv[1], "utf8").trim().split(/\n/).filter(Boolean);
  process.stdout.write(String(lines.length));
' "$ESC_LOG")

if [ "$ESC_COUNT" = "1" ]; then
  pass "watchdog emits exactly one escalation record"
else
  fail "expected 1 escalation record, got $ESC_COUNT"
fi

# The single escalation record must be valid JSON and must name the right task/agent.
ESC_VALID=$(node -e '
  const fs = require("fs");
  const lines = fs.readFileSync(process.argv[1], "utf8").trim().split(/\n/).filter(Boolean);
  if (lines.length !== 1) { process.stdout.write("bad-count"); process.exit(0); }
  let r;
  try { r = JSON.parse(lines[0]); } catch(e) { process.stdout.write("invalid-json"); process.exit(0); }
  if (r.task !== "TASK-KILL")  { process.stdout.write("wrong-task:" + r.task); process.exit(0); }
  if (r.agent !== "alice")     { process.stdout.write("wrong-agent:" + r.agent); process.exit(0); }
  if (r.max_gap_ms <= 600000)  { process.stdout.write("gap-too-small:" + r.max_gap_ms); process.exit(0); }
  if (r.heartbeats !== 0)      { process.stdout.write("nonzero-heartbeats:" + r.heartbeats); process.exit(0); }
  if (!r.ts)                   { process.stdout.write("missing-ts"); process.exit(0); }
  process.stdout.write("ok");
' "$ESC_LOG")

if [ "$ESC_VALID" = "ok" ]; then
  pass "escalation record is valid JSON with correct task, agent, gap, heartbeats=0, ts"
else
  fail "escalation record invalid ($ESC_VALID):\n$(cat "$ESC_LOG")"
fi

# Watchdog must NOT silently produce an empty stdout (silence = hang risk).
if [ -s "$WORK/wd.stdout" ] || [ -s "$ESC_LOG" ]; then
  pass "watchdog produced output (did not silently hang)"
else
  fail "watchdog produced neither stdout nor escalation log — silent hang risk"
fi

# ── NOTE: Recovery is gated on R2 ─────────────────────────────────────────────
# The auto-reap (re-offer the orphaned token) is NOT tested here.
# It is behind the --allow-reap stub and the unmade R2 "auto-reap authority"
# decision. Detection + escalation above is the complete G1 deliverable.

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
