#!/usr/bin/env bash
# test/relay-token-collision.sh — GH-18 #1b: a spent (done) turn-token id is self-documenting.
# Two surfaces must hint the fix instead of leaving the operator to discover --relay-task:
#   1. `tick claim` on a terminal token → "use a fresh per-relay id" hint.
#   2. relay-drive on a done token under a non-terminal thread → "spent from a prior relay" hint
#      (and the message names the actual --relay-task, not a hardcoded RELAY-TURN).
source "$(dirname "$0")/_setup.sh" relay-token-collision

export TICK_BIN="$TICK"
DRIVE="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-drive.sh"

tick_a init >/dev/null

# Drive a token to `done` (a prior relay that finished).
tick_a log task.created RELAY-TURN --agent claude-a --paths foo.txt >/dev/null 2>&1
tick_a claim   RELAY-TURN --agent claude-a --paths foo.txt >/dev/null 2>&1
tick_a release RELAY-TURN --agent claude-a --to codex     >/dev/null 2>&1
tick_a claim   RELAY-TURN --agent codex --paths foo.txt    >/dev/null 2>&1
tick_a done    RELAY-TURN --agent codex                    >/dev/null 2>&1

# --- Surface 1: tick claim on the spent id ---
out="$(tick_a claim RELAY-TURN --agent claude-a --paths foo.txt 2>&1)"
grep -q "not claimable" <<<"$(printf '%s' "$out")" \
  && pass "tick: spent token still reports not claimable" || fail "expected 'not claimable' (got: $out)"
grep -q -- "--relay-task" <<<"$(printf '%s' "$out")" \
  && pass "tick: not-claimable error hints --relay-task" || fail "missing --relay-task hint (got: $out)"

# --- Surface 2: relay-drive sees the done token under a non-terminal thread ---
printf 'STATUS: In progress\n# body\n' >"$A/relay.md"
out2="$(bash "$DRIVE" --dry-run --relay-file "$A/relay.md" --relay-task RELAY-TURN 2>&1)"; rc2=$?
[ "$rc2" -eq 4 ] && pass "relay-drive escalates (exit 4) on a spent token" || fail "expected exit 4 (got $rc2: $out2)"
grep -q "spent from a prior relay" <<<"$(printf '%s' "$out2")" \
  && pass "relay-drive hints the spent-token fix" || fail "missing spent-token hint (got: $out2)"
# Message must name the real task, not a hardcoded RELAY-TURN, when a custom id is used.
printf 'STATUS: In progress\n# body\n' >"$A/relay2.md"
tick_a log task.created RELAY-custom --agent claude-a --paths foo.txt >/dev/null 2>&1
tick_a claim   RELAY-custom --agent claude-a --paths foo.txt >/dev/null 2>&1
tick_a release RELAY-custom --agent claude-a --to codex     >/dev/null 2>&1
tick_a claim   RELAY-custom --agent codex --paths foo.txt    >/dev/null 2>&1
tick_a done    RELAY-custom --agent codex                    >/dev/null 2>&1
out3="$(bash "$DRIVE" --dry-run --relay-file "$A/relay2.md" --relay-task RELAY-custom 2>&1)"
grep -q "RELAY-custom has no actor" <<<"$(printf '%s' "$out3")" \
  && pass "relay-drive names the actual --relay-task in its message" || fail "message hardcodes wrong task (got: $out3)"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
