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

# regression (live dogfood 2026-06-15): open+handoff-to-other with EMPTY --claude-agents
# must NOT crash on set -u (bash 3.2 empty-array expansion in is_claude_agent).
handoff_to RT-xmodel-noflag zorro
xm2="$(decide --relay-file "$A/relay.md" --artifact "$A/art.md" --relay-task RT-xmodel-noflag --analysis-file "$NONE")"
[ "$xm2" = "nudge-cross-model" ] && pass "empty --claude-agents does not crash (set -u regression)" || fail "empty claude-agents crashed/misdecided: '$xm2'"

# self-expiry: --deadline in the past -> stop (even on my turn); future -> normal
handoff_to RT-expire alice
[ "$(decide --relay-file "$A/relay.md" --artifact "$A/art.md" --relay-task RT-expire --analysis-file "$NONE" --deadline 1)" = "stop" ] \
  && pass "--deadline in the past -> stop (self-expire)" || fail "past deadline should stop"
[ "$(decide --relay-file "$A/relay.md" --artifact "$A/art.md" --relay-task RT-expire --analysis-file "$NONE" --deadline 9999999999)" = "run-runner" ] \
  && pass "--deadline in the future -> normal decision (no premature stop)" || fail "future deadline should not stop"

# --- (i-file) --turn-source file: whose-turn from the relay NEXT: field, tick token OPTIONAL ---
# (the dueling-claudes field finding: a peer that never joins tick still advances the relay)
printf 'STATUS: Open\n**NEXT:** alice — go do the thing\n# body\n' >"$A/relay-next-mine.md"
printf 'STATUS: Open\nNEXT: bob\n# body\n'                          >"$A/relay-next-other.md"
printf 'STATUS: Open\nNEXT: codex\n# body\n'                        >"$A/relay-next-codex.md"
printf 'STATUS: Approved\n**NEXT:** alice\n# body\n'                >"$A/relay-next-approved.md"
git -C "$A" add relay-next-mine.md relay-next-other.md relay-next-codex.md relay-next-approved.md >/dev/null 2>&1
git -C "$A" commit -q -m "file-source fixtures" >/dev/null 2>&1
# file source as agent alice; NO tick token is ever created for these (proves token-optional).
decide_file(){ POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent alice --turn-source file "$@" --dry-run 2>/dev/null | sed -n 's/^DECISION: \([a-z-]*\).*/\1/p'; }

[ "$(decide_file --relay-file "$A/relay-next-mine.md" --artifact "$A/art.md")" = "run-runner" ] \
  && pass "file source: bold **NEXT:**==me + clean -> run-runner (no tick token)" || fail "expected run-runner (file/mine)"

[ "$(decide_file --relay-file "$A/relay-next-other.md" --artifact "$A/art.md" --claude-agents alice,bob)" = "idle" ] \
  && pass "file source: NEXT==other Claude -> idle (not my turn)" || fail "expected idle (file/other)"

[ "$(decide_file --relay-file "$A/relay-next-codex.md" --artifact "$A/art.md" --claude-agents alice)" = "nudge-cross-model" ] \
  && pass "file source: NEXT==non-Claude -> nudge-cross-model" || fail "expected nudge (file/codex)"

[ "$(decide_file --relay-file "$A/relay-next-mine.md" --artifact "$A/art-dirty.md")" = "idle" ] \
  && pass "file source: NEXT==me + dirty scope -> idle" || fail "expected idle (file/dirty)"

[ "$(decide_file --relay-file "$A/relay-next-approved.md" --artifact "$A/art.md")" = "stop" ] \
  && pass "file source: STATUS Approved (terminal) still -> stop" || fail "expected stop (file/approved)"

# commit-signal gate: NEXT==me but run-runner only once a matching peer commit lands
[ "$(decide_file --relay-file "$A/relay-next-mine.md" --artifact "$A/art.md" --peer-commit-repo "$A" --peer-commit-match 'file-source fixtures')" = "run-runner" ] \
  && pass "file source: peer-commit present -> run-runner" || fail "expected run-runner (commit present)"
[ "$(decide_file --relay-file "$A/relay-next-mine.md" --artifact "$A/art.md" --peer-commit-repo "$A" --peer-commit-match 'ZZZ-no-such-subject')" = "idle" ] \
  && pass "file source: peer-commit missing -> idle (waiting for peer commit)" || fail "expected idle (commit waiting)"

# --- (i-delay) --emit-delay: DECISION -> suggested next-poll delay (GH-33 Phase 1) ---
# Additive: the DELAY line is a pure function of the already-computed decision state.
delay_file(){ POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent alice --turn-source file "$@" --emit-delay --dry-run 2>/dev/null | sed -n 's/^DELAY: \([0-9]*\).*/\1/p'; }

[ "$(delay_file --relay-file "$A/relay-next-mine.md" --artifact "$A/art.md")" = "0" ] \
  && pass "emit-delay: run-runner -> 0 (act now)" || fail "expected delay 0 (run-runner)"

[ "$(delay_file --relay-file "$A/relay-next-other.md" --artifact "$A/art.md" --claude-agents alice,bob)" = "300" ] \
  && pass "emit-delay: idle (not my turn) -> 300 backoff" || fail "expected delay 300 (idle backoff)"

[ "$(delay_file --relay-file "$A/relay-next-mine.md" --artifact "$A/art-dirty.md")" = "30" ] \
  && pass "emit-delay: idle (dirty scope) -> 30 retry-soon" || fail "expected delay 30 (dirty)"

[ "$(delay_file --relay-file "$A/relay-next-codex.md" --artifact "$A/art.md" --claude-agents alice)" = "120" ] \
  && pass "emit-delay: nudge-cross-model -> 120" || fail "expected delay 120 (nudge)"

[ "$(delay_file --relay-file "$A/relay-next-mine.md" --artifact "$A/art.md" --peer-commit-repo "$A" --peer-commit-match 'ZZZ-no-such-subject')" = "90" ] \
  && pass "emit-delay: waiting-for-peer-commit -> 90" || fail "expected delay 90 (wait-commit)"

# env override of a delay knob is honored (default idle=300 is asserted above)
[ "$(POLL_DELAY_IDLE=600 POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent alice --turn-source file --relay-file "$A/relay-next-other.md" --artifact "$A/art.md" --claude-agents alice,bob --emit-delay --dry-run 2>/dev/null | sed -n 's/^DELAY: \([0-9]*\).*/\1/p')" = "600" ] \
  && pass "emit-delay: POLL_DELAY_IDLE override honored (600)" || fail "expected 600 (env override)"

# deadline clamp: a 300s idle backoff is clamped so the next wake lands at the deadline
_dl=$(( $(date +%s) + 8 ))
_dc="$(delay_file --relay-file "$A/relay-next-other.md" --artifact "$A/art.md" --claude-agents alice,bob --deadline "$_dl")"
[ "$_dc" -ge 1 ] && [ "$_dc" -le 8 ] && pass "emit-delay: delay clamped to time-remaining before deadline ($_dc<=8)" || fail "expected clamp to <=8, got $_dc"

POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent alice --relay-file "$A/relay-approved.md" --artifact "$A/art.md" --relay-task RT-none --analysis-file "$NONE" --dry-run >/dev/null 2>&1
[ "$?" -eq 10 ] && pass "stop exits 10" || fail "stop should exit 10"

# --- (ii) fake live integration: dispatch under the guard ----------------
SENT="$WORK/ran.txt"; : >"$SENT"
handoff_to RT-live-ok alice
POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent alice --relay-file "$A/relay.md" --artifact "$A/art.md" --relay-task RT-live-ok --analysis-file "$NONE" \
  --runner-cmd "echo ran >>'$SENT'" >/dev/null 2>&1
[ "$(grep -c ran "$SENT")" -eq 1 ] && pass "live: runner dispatched once under my-turn+clean" || fail "runner should dispatch once"

# spaced bare --runner-cmd path is invoked directly, not word-split (GH-12 poll.sh:210 regression).
# The default RUNNER_CMD is "$ROOT_DIR/relay-automation/runner.sh"; a clone under ".../GH Repos/..."
# puts a space in that path and the old `eval "$RUNNER_CMD"` split it (exec'd "/Users/.../GH").
# poll.sh now runs a bare executable path directly; a command-string still falls back to eval.
SPACED_DIR="$WORK/dir with space"; mkdir -p "$SPACED_DIR"
SRUNNER="$SPACED_DIR/runner.sh"; SSENT="$WORK/spaced-runner-ran"; rm -f "$SSENT"
cat >"$SRUNNER" <<RS
#!/usr/bin/env bash
printf 'ran\n' > "$SSENT"
RS
chmod +x "$SRUNNER"
handoff_to RT-live-spaced alice
POLL_GIT_ROOT="$A" bash "$POLL" --mode relay --agent alice --relay-file "$A/relay.md" --artifact "$A/art.md" --relay-task RT-live-spaced --analysis-file "$NONE" \
  --runner-cmd "$SRUNNER" >/dev/null 2>&1
[ -f "$SSENT" ] && pass "live: spaced bare --runner-cmd path invoked directly (not split by eval)" || fail "spaced runner-cmd was word-split instead of run"

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
