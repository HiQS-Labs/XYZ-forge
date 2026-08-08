#!/usr/bin/env bash
# test/gh385-retry-token-satisfied.sh — GH-385 regression.
#
# An Approved phase rebuilt from scratch because its completion was recorded on a --retry SUFFIXED
# token while satisfied_lane_terminal() read only the BASE token:
#
#   1. p1 runs, the builder fails, the phase escalates — MARATHON-P1-TURN is left claimed.
#   2. Operator re-runs with --retry. GH-116 allocates MARATHON-P1-TURN-2, the phase succeeds,
#      -TURN-2 reaches done and RELAY.md records STATUS: Approved.
#   3. A later run without --retry computes the BASE name again, reads the dead attempt's state,
#      and rebuilds a phase that is demonstrably Approved.
#
# Observed on a real 10-phase run: phase 1 rebuilt while phases 2-4 correctly reported satisfied, and
# the only difference was that phase 1 had once been retried. Cost is a full builder + reviewer cycle
# — real money on --builder claude — and the rebuild re-introduced a defect that had been reverted,
# so a phase believed complete silently regressed the tree. Nothing in the log said why.
#
# The driver now reads which task the relay was actually rendered for, from its own marathon-drive
# directive, instead of assuming the base name.
source "$(dirname "$0")/_setup.sh" gh385-retry-token-satisfied
DRIVER="$(cd "$(dirname "$0")/.." && pwd)/utils/py/marathon_drive.py"
export TICK_BIN="$TICK"
tick_a init >/dev/null

printf '.tick/\n' > "$A/.gitignore"
git -C "$A" add .gitignore >/dev/null 2>&1
git -C "$A" commit -q -m init
BRIEF="$WORK/brief.md"; printf '## brief\nbody\n' > "$BRIEF"

STUB_CLAUDE="$WORK/stub-claude"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_CLAUDE"; chmod +x "$STUB_CLAUDE"
STUB_AGY="$WORK/stub-agy"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_AGY"; chmod +x "$STUB_AGY"

# A relay-drive stub that RECORDS being called. The whole point of the satisfied path is that the
# phase is not driven again, so "was the driver re-entered" is the observable that matters.
RD="$WORK/relay-drive-stub.sh"
cat > "$RD" <<'STUB'
#!/usr/bin/env bash
echo called >> "$RD_CALLS"
exit 0
STUB
chmod +x "$RD"
export RD_CALLS="$WORK/rd-calls"

BASE="MARATHON-P1-TURN"

seed_relay() {  # <recorded-task> — an Approved relay rendered for <recorded-task>
  mkdir -p "$A/phases/p1"
  printf '# Marathon Phase p1\nSTATUS: Approved\nNEXT: agy (Reviewer)\n\n<!-- marathon-drive: task=%s builder=claude reviewer=agy round-cap=5 -->\n\nbody\n' \
    "$1" > "$A/phases/p1/RELAY.md"
}

mk_token() {  # <task> <done|claimed>
  tick_a log task.created "$1" --agent marathon >/dev/null 2>&1 || true
  tick_a claim "$1" --agent claude --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
  [ "$2" = "done" ] && { tick_a done "$1" --agent claude >/dev/null 2>&1 || true; }
}

run_driver() {
  : > "$RD_CALLS"
  MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB_CLAUDE" AGY_BIN="$STUB_AGY" \
  python3 "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
    --reviewer agy --builder claude --pre-advance-cmd "true" 2>&1
}

reset_state() { rm -rf "$A/phases" "$A/.tick"; tick_a init >/dev/null 2>&1 || true; : > "$RD_CALLS"; }

# --- (1) THE BUG: completion recorded on -TURN-2, base token left on the failed attempt ----------
reset_state
seed_relay "${BASE}-2"
mk_token "$BASE" claimed      # the dead attempt, exactly as a crashed run leaves it
mk_token "${BASE}-2" done     # where the phase actually completed
out="$(run_driver)"; rc=$?
printf '%s' "$out" | grep -q "already reached a terminal relay" \
  && pass "a phase completed on a --retry token is recognized as satisfied" \
  || fail "GH-385 is back: the Approved phase rebuilt because the BASE token was read: $out"
[ ! -s "$RD_CALLS" ] \
  && pass "relay-drive was NOT re-entered (no builder + reviewer cycle re-run)" \
  || fail "the phase was driven again despite being Approved — the cost this issue is about"
[ "$rc" -eq 0 ] && pass "satisfied phase exits 0" || fail "satisfied phase exit=$rc: $out"

# --- (2) NEGATIVE CONTROL: nothing reached done, so the phase MUST still run ----------------------
# Without this, an implementation that always reported "satisfied" would pass case (1) and silently
# skip every phase in the fleet. The assertion above is only meaningful next to this one.
reset_state
seed_relay "${BASE}-2"
mk_token "$BASE" claimed
mk_token "${BASE}-2" claimed  # recorded task exists but never completed
out="$(run_driver)"
printf '%s' "$out" | grep -q "already reached a terminal relay" \
  && fail "a phase whose recorded token never reached done was skipped — satisfied is now unfalsifiable" \
  || pass "an un-completed recorded token does NOT satisfy the lane (the check can still fail)"

# --- (3) the ordinary no-retry path is unchanged --------------------------------------------------
reset_state
seed_relay "$BASE"
mk_token "$BASE" done
out="$(run_driver)"
printf '%s' "$out" | grep -q "already reached a terminal relay" \
  && pass "the plain base-token satisfied path still works" \
  || fail "regressed the ordinary satisfied path: $out"

# --- (4) a relay with no directive falls back to the base token ------------------------------------
# Relays rendered before the directive existed must keep working rather than being read as unsatisfied.
reset_state
mkdir -p "$A/phases/p1"
printf '# Marathon Phase p1\nSTATUS: Approved\nNEXT: agy\n\nbody\n' > "$A/phases/p1/RELAY.md"
mk_token "$BASE" done
out="$(run_driver)"
printf '%s' "$out" | grep -q "already reached a terminal relay" \
  && pass "a directive-less relay still resolves against the base token" \
  || fail "a pre-directive relay stopped being recognized as satisfied: $out"

exit 0
