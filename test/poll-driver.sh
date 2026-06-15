#!/usr/bin/env bash
# Phase 4 (4a): poll.sh decision engine + guarded dispatch.
# (i) dry-run decision sequence (relay mode), (ii) fake live integration (dispatch under guard).
source "$(dirname "$0")/_setup.sh" poll-driver

POLL="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/poll.sh"
RELAY="$A/relay.md"
ART="$A/artifact.md"
ANALYSIS_NONE="$WORK/none.json"
ANALYSIS_PARKED="$WORK/parked.json"
printf '{"parked_suspects":[]}' >"$ANALYSIS_NONE"
printf '{"parked_suspects":[{"task":"T-9","agent":"x","max_gap_ms":900000,"heartbeats":0}]}' >"$ANALYSIS_PARKED"

# Write the relay file with a given NEXT/STATUS, and commit it clean (in $A).
set_relay() { # <next> <status>
  printf 'NEXT: %s\nSTATUS: %s\n# body\n' "$1" "$2" >"$RELAY"
  git -C "$A" add relay.md artifact.md >/dev/null 2>&1 || true
  git -C "$A" commit -q -m "relay state $1/$2" >/dev/null 2>&1 || true
}
printf 'artifact\n' >"$ART"

# Decision helper: run poll.sh --dry-run in relay mode, echo the DECISION token.
decide() { POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent claude-a --my-role Producer \
  --relay-file "$RELAY" --artifact "$ART" --dry-run "$@" 2>/dev/null \
  | sed -n 's/^DECISION: \([a-z-]*\).*/\1/p'; }

# --- (i) dry-run decision sequence ---------------------------------------

set_relay Producer Open
[ "$(decide --analysis-file "$ANALYSIS_NONE")" = "run-runner" ] \
  && pass "my-turn + clean -> run-runner" || fail "my-turn+clean expected run-runner"

set_relay Reviewer Open
[ "$(decide --analysis-file "$ANALYSIS_NONE")" = "idle" ] \
  && pass "not-my-turn -> idle" || fail "not-my-turn expected idle"

set_relay Producer Open
printf 'NEXT: Producer\nSTATUS: Open\n# dirty edit\n' >"$RELAY"   # modify tracked file in scope (uncommitted)
[ "$(decide --analysis-file "$ANALYSIS_NONE")" = "idle" ] \
  && pass "my-turn + dirty scope -> idle" || fail "dirty scope expected idle"

set_relay Reviewer Open
[ "$(decide --analysis-file "$ANALYSIS_PARKED" --watchdog-authority)" = "run-watchdog" ] \
  && pass "parked + authority -> run-watchdog" || fail "parked+authority expected run-watchdog"

set_relay Reviewer Open
[ "$(decide --analysis-file "$ANALYSIS_PARKED")" = "idle" ] \
  && pass "parked + NO authority -> idle" || fail "parked-no-authority expected idle"

set_relay Reviewer Approved
[ "$(decide --analysis-file "$ANALYSIS_NONE")" = "stop" ] \
  && pass "relay Approved -> stop" || fail "approved expected stop"

# cross-model: NEXT is a non-Claude agent's role
set_relay Reviewer Open
xm="$(POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent claude-a --my-role Producer \
  --relay-file "$RELAY" --artifact "$ART" --analysis-file "$ANALYSIS_NONE" \
  --roles "Producer=claude-a,Reviewer=codex" --claude-agents "claude-a" --dry-run 2>/dev/null \
  | sed -n 's/^DECISION: \([a-z-]*\).*/\1/p')"
[ "$xm" = "nudge-cross-model" ] && pass "cross-model turn -> nudge-cross-model" || fail "cross-model expected nudge, got: $xm"

# stop exit code is 10
set_relay Reviewer Closed
POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent claude-a --my-role Producer \
  --relay-file "$RELAY" --artifact "$ART" --analysis-file "$ANALYSIS_NONE" --dry-run >/dev/null 2>&1
[ "$?" -eq 10 ] && pass "stop exits 10" || fail "stop should exit 10"

# --- (ii) fake live integration: dispatch actually runs, under the guard ---

SENTINEL="$WORK/ran.txt"; : >"$SENTINEL"
set_relay Producer Open
POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent claude-a --my-role Producer \
  --relay-file "$RELAY" --artifact "$ART" --analysis-file "$ANALYSIS_NONE" \
  --runner-cmd "echo ran-runner >>'$SENTINEL'" >/dev/null 2>&1
[ "$(grep -c ran-runner "$SENTINEL")" -eq 1 ] \
  && pass "live: runner dispatched exactly once under my-turn+clean" || fail "runner should dispatch once"

# dirty scope must NOT dispatch the runner (guard holds in live mode too)
: >"$SENTINEL"
printf 'NEXT: Producer\nSTATUS: Open\n# dirty\n' >"$RELAY"   # uncommitted edit
POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent claude-a --my-role Producer \
  --relay-file "$RELAY" --artifact "$ART" --analysis-file "$ANALYSIS_NONE" \
  --runner-cmd "echo ran-runner >>'$SENTINEL'" >/dev/null 2>&1
[ ! -s "$SENTINEL" ] \
  && pass "live: dirty scope blocks runner dispatch" || fail "dirty scope must not dispatch runner"

# parked + authority dispatches the watchdog exactly once; no authority -> none
WLOG="$WORK/wd.txt"; : >"$WLOG"
set_relay Reviewer Open
POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent claude-a --my-role Producer \
  --relay-file "$RELAY" --artifact "$ART" --analysis-file "$ANALYSIS_PARKED" --watchdog-authority \
  --watchdog-cmd "echo escalated >>'$WLOG'" >/dev/null 2>&1
[ "$(grep -c escalated "$WLOG")" -eq 1 ] \
  && pass "live: parked+authority escalates exactly once" || fail "watchdog should escalate once"

: >"$WLOG"
POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent claude-a --my-role Producer \
  --relay-file "$RELAY" --artifact "$ART" --analysis-file "$ANALYSIS_PARKED" \
  --watchdog-cmd "echo escalated >>'$WLOG'" >/dev/null 2>&1
[ ! -s "$WLOG" ] \
  && pass "live: parked without authority does NOT escalate (no double-escalate)" || fail "no-authority must not escalate"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
