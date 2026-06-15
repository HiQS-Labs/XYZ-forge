#!/usr/bin/env bash
# Phase 4(a): poll.sh decision engine + guarded dispatch, relay mode driven by a
# real tick RELAY-TURN token (not a baton file). (i) dry-run decision sequence,
# (ii) fake live integration. NOTE: per-agent claim cap is 2, so my-turn cases use
# open+handoff-to-me (the poller never claims) to stay cap-safe; distinct claimers
# elsewhere.
source "$(dirname "$0")/_setup.sh" poll-driver

POLL="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/poll.sh"
export TICK_BIN="$TICK"
tick_a init >/dev/null

printf 'STATUS: Open\n# body\n'     >"$A/relay.md"
printf 'STATUS: Approved\n# body\n' >"$A/relay-approved.md"
printf 'art\n'        >"$A/art.md"
printf 'dirty-base\n' >"$A/art-dirty.md"
git -C "$A" add relay.md relay-approved.md art.md art-dirty.md >/dev/null 2>&1
git -C "$A" commit -q -m "poll-driver fixtures" >/dev/null 2>&1
printf 'now-dirty\n' >>"$A/art-dirty.md"   # uncommitted edit in scope → dirty

NONE="$WORK/none.json"; PARKED="$WORK/parked.json"
printf '{"parked_suspects":[]}' >"$NONE"
printf '{"parked_suspects":[{"task":"T-9","agent":"x","max_gap_ms":900000,"heartbeats":0}]}' >"$PARKED"

# open + handoff_to <agent> (no active claim held → cap-safe); each call uses a fresh seed.
handoff_to(){ tick_a log task.created "$1" --agent dispatcher >/dev/null; tick_a claim "$1" --agent "seed-$1" --paths "z/**" >/dev/null; tick_a release "$1" --agent "seed-$1" --to "$2" >/dev/null; }
# claimed by <agent>
claim_by(){ tick_a log task.created "$1" --agent dispatcher >/dev/null; tick_a claim "$1" --agent "$2" --paths "z/**" >/dev/null; }

# decide <args...> : poll relay dry-run as agent alice, echo the DECISION token
decide(){ POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent alice "$@" --dry-run 2>/dev/null | sed -n 's/^DECISION: \([a-z-]*\).*/\1/p'; }

# --- (i) dry-run decision sequence ---------------------------------------
handoff_to RT-mine alice
[ "$(decide --relay-file "$A/relay.md" --artifact "$A/art.md" --relay-task RT-mine --analysis-file "$NONE")" = "run-runner" ] \
  && pass "open+handoff-to-me (wake-on-handoff) -> run-runner" || fail "expected run-runner"

claim_by RT-resume alice
[ "$(decide --relay-file "$A/relay.md" --artifact "$A/art.md" --relay-task RT-resume --analysis-file "$NONE")" = "run-runner" ] \
  && pass "claimed-by-me (resume) -> run-runner" || fail "expected run-runner (resume)"
tick_a done RT-resume --agent alice >/dev/null   # free alice's slot

claim_by RT-other bob
[ "$(decide --relay-file "$A/relay.md" --artifact "$A/art.md" --relay-task RT-other --analysis-file "$NONE")" = "idle" ] \
  && pass "claimed-by-other -> idle" || fail "expected idle"

handoff_to RT-dirty alice
[ "$(decide --relay-file "$A/relay.md" --artifact "$A/art-dirty.md" --relay-task RT-dirty --analysis-file "$NONE")" = "idle" ] \
  && pass "my-turn + dirty scope -> idle" || fail "expected idle (dirty)"

claim_by RT-parked bobp
[ "$(decide --relay-file "$A/relay.md" --artifact "$A/art.md" --relay-task RT-parked --analysis-file "$PARKED" --watchdog-authority)" = "run-watchdog" ] \
  && pass "parked + authority (not my turn) -> run-watchdog" || fail "expected run-watchdog"
[ "$(decide --relay-file "$A/relay.md" --artifact "$A/art.md" --relay-task RT-parked --analysis-file "$PARKED")" = "idle" ] \
  && pass "parked + NO authority -> idle" || fail "expected idle (no authority)"

[ "$(decide --relay-file "$A/relay-approved.md" --artifact "$A/art.md" --relay-task RT-none --analysis-file "$NONE")" = "stop" ] \
  && pass "relay STATUS Approved -> stop" || fail "expected stop"

handoff_to RT-xmodel codex
xm="$(decide --relay-file "$A/relay.md" --artifact "$A/art.md" --relay-task RT-xmodel --analysis-file "$NONE" --claude-agents alice)"
[ "$xm" = "nudge-cross-model" ] && pass "RELAY-TURN handed to non-Claude -> nudge-cross-model" || fail "expected nudge, got: $xm"

POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent alice --relay-file "$A/relay-approved.md" --artifact "$A/art.md" --relay-task RT-none --analysis-file "$NONE" --dry-run >/dev/null 2>&1
[ "$?" -eq 10 ] && pass "stop exits 10" || fail "stop should exit 10"

# --- (ii) fake live integration: dispatch under the guard ----------------
SENT="$WORK/ran.txt"; : >"$SENT"
handoff_to RT-live-ok alice
POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent alice --relay-file "$A/relay.md" --artifact "$A/art.md" --relay-task RT-live-ok --analysis-file "$NONE" \
  --runner-cmd "echo ran >>'$SENT'" >/dev/null 2>&1
[ "$(grep -c ran "$SENT")" -eq 1 ] && pass "live: runner dispatched once under my-turn+clean" || fail "runner should dispatch once"

: >"$SENT"
handoff_to RT-live-dirty alice
POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent alice --relay-file "$A/relay.md" --artifact "$A/art-dirty.md" --relay-task RT-live-dirty --analysis-file "$NONE" \
  --runner-cmd "echo ran >>'$SENT'" >/dev/null 2>&1
[ ! -s "$SENT" ] && pass "live: dirty scope blocks runner dispatch" || fail "dirty must not dispatch"

WLOG="$WORK/wd.txt"; : >"$WLOG"
claim_by RT-live-parked bobw
POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent alice --relay-file "$A/relay.md" --artifact "$A/art.md" --relay-task RT-live-parked --analysis-file "$PARKED" --watchdog-authority \
  --watchdog-cmd "echo esc >>'$WLOG'" >/dev/null 2>&1
[ "$(grep -c esc "$WLOG")" -eq 1 ] && pass "live: parked+authority escalates once" || fail "watchdog should escalate once"

: >"$WLOG"
POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent alice --relay-file "$A/relay.md" --artifact "$A/art.md" --relay-task RT-live-parked --analysis-file "$PARKED" \
  --watchdog-cmd "echo esc >>'$WLOG'" >/dev/null 2>&1
[ ! -s "$WLOG" ] && pass "live: parked w/o authority does NOT escalate (no double-escalate)" || fail "no-authority must not escalate"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
