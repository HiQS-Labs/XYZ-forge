#!/usr/bin/env bash
# Watchdog liveness contract: escalate real parked suspects, stay quiet on
# healthy input, and gate the REAL reap (R2) behind --allow-reap. (This test drives a STATIC
# analysis fixture with no real tick claim, so it asserts the reap PATH is invoked + the no-op
# degrades cleanly; the real release/re-offer is proven against live tick state in chaos-midturn-kill.sh.)
source "$(dirname "$0")/_setup.sh" watchdog-liveness

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WATCHDOG="$ROOT/relay-automation/watchdog.sh"

# Init a (empty) tick repo at the exported TICK_REPO_ROOT so the watchdog's reap has a valid repo to
# no-op against — these static fixtures hold no real claim, so the scoped reap is always a clean no-op.
tick_a init >/dev/null

cat >"$WORK/parked.json" <<'EOF'
{"parked_suspects":[{"task":"TASK-PARKED","agent":"alice","max_gap_ms":600001,"heartbeats":0}]}
EOF

cat >"$WORK/healthy.json" <<'EOF'
{"parked_suspects":[]}
EOF

if bash -n "$WATCHDOG"; then
  pass "watchdog.sh parses"
else
  fail "watchdog.sh failed bash -n"
fi

PARKED_LOG="$WORK/parked.ndjson"
if WATCHDOG_TS='2026-06-14T12:00:00Z' "$WATCHDOG" \
  --analysis-file "$WORK/parked.json" \
  --channel file \
  --escalation-log "$PARKED_LOG" \
  >"$WORK/parked.stdout" 2>"$WORK/parked.stderr"; then
  :
else
  fail "watchdog failed on parked fixture"
fi

if node -e 'const fs=require("fs"); const lines=fs.readFileSync(process.argv[1],"utf8").trim().split(/\n/).filter(Boolean); if (lines.length !== 1) process.exit(1); const r=JSON.parse(lines[0]); if (r.task !== "TASK-PARKED") process.exit(2); if (r.agent !== "alice") process.exit(3); if (r.max_gap_ms !== 600001) process.exit(4); if (r.heartbeats !== 0) process.exit(5); if (!String(r.evidence).includes("max_gap_ms=600001")) process.exit(6); if (r.ts !== "2026-06-14T12:00:00Z") process.exit(7);' "$PARKED_LOG"; then
  pass "parked suspect writes one escalation record with task and gap"
else
  fail "parked escalation record missing expected fields"
fi

HEALTHY_LOG="$WORK/healthy.ndjson"
if WATCHDOG_TS='2026-06-14T12:00:00Z' "$WATCHDOG" \
  --analysis-file "$WORK/healthy.json" \
  --channel file \
  --escalation-log "$HEALTHY_LOG" \
  >"$WORK/healthy.stdout" 2>"$WORK/healthy.stderr"; then
  pass "healthy run exits 0"
else
  fail "healthy run should exit 0"
fi

if [[ "$(cat "$WORK/healthy.stdout")" == 'watchdog: no parked tasks detected' ]] && [[ ! -s "$HEALTHY_LOG" ]]; then
  pass "healthy run emits no escalation record"
else
  fail "healthy run should only report no parked tasks"
fi

REAP_LOG="$WORK/reap.ndjson"
if WATCHDOG_TS='2026-06-14T12:00:00Z' "$WATCHDOG" \
  --analysis-file "$WORK/parked.json" \
  --channel file \
  --escalation-log "$REAP_LOG" \
  --allow-reap \
  >"$WORK/reap.stdout" 2>"$WORK/reap.stderr"; then
  :
else
  fail "watchdog failed on parked fixture with --allow-reap"
fi

if grep -q 'watchdog: reap TASK-PARKED (held by alice)' "$WORK/reap.stderr"; then
  pass "--allow-reap invokes the real scoped reap for the suspect (not the stub)"
else
  fail "expected real reap invocation for parked suspect, got: $(cat "$WORK/reap.stderr")"
fi

# The reap is a no-op here (no real TASK-PARKED claim in this test's tick state) and MUST still exit 0.
if grep -q 'no active claims held by alice' "$WORK/reap.stderr"; then
  pass "idempotent no-op reap (no live claim) degrades cleanly, exit 0"
else
  fail "expected a clean no-op reap against the static fixture, got: $(cat "$WORK/reap.stderr")"
fi

if WATCHDOG_TS='2026-06-14T12:00:00Z' "$WATCHDOG" \
  --analysis-file "$WORK/healthy.json" \
  --channel file \
  --escalation-log "$WORK/healthy-reap.ndjson" \
  --allow-reap \
  >"$WORK/healthy-reap.stdout" 2>"$WORK/healthy-reap.stderr"; then
  :
else
  fail "healthy run with --allow-reap should exit 0"
fi

if grep -q 'watchdog: reap ' "$WORK/healthy-reap.stderr"; then
  fail "healthy run should not invoke any reap"
else
  pass "healthy run does not invoke reap (no parked suspect, nothing reaped)"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0