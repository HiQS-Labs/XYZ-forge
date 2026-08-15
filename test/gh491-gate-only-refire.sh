#!/usr/bin/env bash
# test/gh491-gate-only-refire.sh — GH-491 gate-only re-fire discoverability test suite.
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh491-gate-only-refire.sh; assertions verify: (1) marathon.sh --help documents when not to use --retry; (2) advisory fires when --retry is passed for a terminal/Approved/done phase; (3) advisory preserves rebuild behavior; (4) negative control: advisory does NOT fire for non-terminal or non-done phases; (5) already-satisfied plain refire path remains intact"}

source "$(dirname "$0")/_setup.sh" gh491-gate-only-refire
DRIVER="$(cd "$(dirname "$0")/.." && pwd)/utils/py/marathon_drive.py"
MARATHON_SH="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/marathon.sh"
export TICK_BIN="$TICK"
tick_a init >/dev/null

printf '.tick/\n' > "$A/.gitignore"
git -C "$A" add .gitignore >/dev/null 2>&1
git -C "$A" commit -q -m init
BRIEF="$WORK/brief.md"; printf '## brief\nbody\n' > "$BRIEF"

STUB_CLAUDE="$WORK/stub-claude"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_CLAUDE"; chmod +x "$STUB_CLAUDE"
STUB_AGY="$WORK/stub-agy"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_AGY"; chmod +x "$STUB_AGY"

RD="$WORK/relay-drive-stub.sh"
cat > "$RD" <<'STUB'
#!/usr/bin/env bash
echo called >> "$RD_CALLS"
exit 0
STUB
chmod +x "$RD"
export RD_CALLS="$WORK/rd-calls"

BASE="MARATHON-P1-TURN"

seed_relay() {  # <status> <recorded-task>
  local status="$1" task="$2"
  mkdir -p "$A/phases/p1"
  printf '# Marathon Phase p1\nSTATUS: %s\nNEXT: agy (Reviewer)\n\n<!-- marathon-drive: task=%s builder=claude reviewer=agy round-cap=5 -->\n\nbody\n' \
    "$status" "$task" > "$A/phases/p1/RELAY.md"
}

mk_token() {  # <task> <done|claimed>
  tick_a log task.created "$1" --agent marathon >/dev/null 2>&1 || true
  tick_a claim "$1" --agent claude --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
  [ "$2" = "done" ] && { tick_a done "$1" --agent claude >/dev/null 2>&1 || true; }
}

run_driver() {  # [extra marathon-drive args...]
  : > "$RD_CALLS"
  MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB_CLAUDE" AGY_BIN="$STUB_AGY" \
  python3 "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
    --reviewer agy --builder claude --pre-advance-cmd "true" "$@" 2>&1
}

reset_state() { rm -rf "$A/phases" "$A/.tick"; tick_a init >/dev/null 2>&1 || true; : > "$RD_CALLS"; }

# --- (1) Acceptance criterion 1: marathon.sh --help text states when --retry is the wrong choice ---
help_out="$(MARATHON_ROOT="$A" bash "$MARATHON_SH" --help 2>&1)"
printf '%s' "$help_out" | grep -q "GH-491: if the phase's relay is already terminal" \
  && pass "marathon.sh --help explains that satisfied phases should re-fire plainly without --retry" \
  || fail "marathon.sh --help missing GH-491 guidance: $help_out"

# --- (2) Acceptance criterion 2: Advisory fires when --retry is passed on a terminal/Approved/done phase ---
reset_state
seed_relay "Approved" "$BASE"
mk_token "$BASE" done
out="$(run_driver --relay-task "${BASE}-2")"
printf '%s' "$out" | grep -q "re-firing WITHOUT --retry would have re-run only the pre-advance gate" \
  && pass "GH-491: advisory fires when --retry is passed on a terminal/Approved/done phase" \
  || fail "GH-491 advisory missing on satisfied phase under --retry: $out"
printf '%s' "$out" | grep -q "GH-491" \
  && pass "advisory explicitly cites GH-491" \
  || fail "advisory does not cite GH-491: $out"

# --- (3) Acceptance criterion 3: Advisory does NOT alter --retry's behavior (rebuilds) ---
printf '%s' "$out" | grep -q "already reached a terminal relay" \
  && fail "advisory erroneously short-circuited -- --retry must still rebuild: $out" \
  || pass "advisory preserves --retry's rebuild behavior"

# --- (4) Acceptance criterion 4: Negative controls ---
# Control 4a: Terminal Approved, but token is NOT done -> NO advisory
reset_state
seed_relay "Approved" "$BASE"
mk_token "$BASE" claimed
out="$(run_driver --relay-task "${BASE}-2")"
printf '%s' "$out" | grep -q "re-firing WITHOUT --retry would have re-run only the pre-advance gate" \
  && fail "control 4a failed: advisory fired when recorded token was not done: $out" \
  || pass "control 4a: no advisory when recorded token is not done"

# Control 4b: Non-terminal relay (Open), token done -> NO advisory
reset_state
seed_relay "Open" "$BASE"
mk_token "$BASE" done
out="$(run_driver --relay-task "${BASE}-2")"
printf '%s' "$out" | grep -q "re-firing WITHOUT --retry would have re-run only the pre-advance gate" \
  && fail "control 4b failed: advisory fired when relay was non-terminal: $out" \
  || pass "control 4b: no advisory when relay status is non-terminal"

# --- (5) Acceptance criterion 5: Plain refire (no --retry) still hits already-satisfied path ---
reset_state
seed_relay "Approved" "$BASE"
mk_token "$BASE" done
out="$(run_driver)"
printf '%s' "$out" | grep -q "already reached a terminal relay" \
  && pass "plain refire without --retry correctly hits the gate-only already-satisfied short-circuit" \
  || fail "plain refire failed to short-circuit: $out"
[ ! -s "$RD_CALLS" ] \
  && pass "plain refire did not dispatch builder or reviewer turns" \
  || fail "plain refire re-dispatched turns: $out"

exit 0
