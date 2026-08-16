#!/usr/bin/env bash
# GH-409 — a turn that fails must not keep its tick claim.
#
# The defect is self-inflicted and does not clear itself. A shim claims its token before launching
# the agent; if the turn then dies on a path that never reaches `rtl_enforce`, the claim stays held.
# An agent may hold two, so the THIRD turn is refused for being at the cap — with a message about a
# token that is perfectly healthy. On 2026-08-07 that cost roughly two hours.
#
# WHY THE CONTROL IS TWO FAILURES, NOT ONE. The cap is 2 (src/project.js MAX_ACTIVE_CLAIMS_PER_AGENT),
# so one leaked claim is invisible: the next turn still gets a slot and passes. A suite that fails one
# turn and then succeeds proves nothing at all. Every case here fails twice and then requires a third
# turn to succeed.
#
# WHAT IS ASSERTED. Never the exit code of the failing turn — those were already 5/6 while the defect
# was live, exactly as in GH-432. The assertions are on the coordination state the turn left behind:
# who holds the claim afterwards, and whether a later healthy turn can still run.
#
# Covers the three failure paths that bypass rtl_enforce entirely, which is where #432's fix does not
# reach (it made a failed AGENT reach enforce; these die before the agent's result is ever consulted):
#   1. the agent exits non-zero              — reaches enforce (regression guard: still no leak)
#   2. worktree isolation cannot be set up   — `sys.exit(5)` above enforce
#   3. the agent makes off-lane edits        — `sys.exit(6)` above enforce
source "$(dirname "$0")/_setup.sh" gh409-claim-leak
unset ALLOW_PATHS RELAY_FILE RELAY_TASK RELAY_AGENT RELAY_PEER RELAY_WORKTREE_ISOLATION
export TICK_BIN="$TICK"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SHIM="$ROOT_DIR/relay-automation/claude-turn.sh"
tick_a init >/dev/null

printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf '.tick/\n' >"$A/.gitignore"
git -C "$A" add relay.md .gitignore >/dev/null 2>&1
git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1

STUB="$WORK/claude"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
export TICK_REPO_ROOT="$A"
printf '\n### Round 1 · Builder · %s (claude-stub)\nturn body\n' "$RELAY_AGENT" >>"$RELAY_FILE"
case "${STUB_MODE:-crash}" in
  good)  exit 0 ;;
  offlane) printf 'off-lane\n' >>"$A/offlane-$RELAY_TASK.md"; exit 0 ;;
  *)     exit 1 ;;
esac
STUB_EOF
chmod +x "$STUB"

AGENT=claude-builder

seed_token(){
  tick_a log task.created "$1" --agent seedster >/dev/null
  tick_a claim "$1" --agent seedster --paths "z/**" >/dev/null
  tick_a release "$1" --agent seedster --to "$AGENT" >/dev/null
}

run_shim(){ # <relay-task> <stub-mode> [worktree-isolation]
  RELAY_AGENT="$AGENT" RELAY_FILE="$A/relay.md" RELAY_TASK="$1" CLAUDE_AGENT="$AGENT" \
  RELAY_PEER=agy-reviewer \
  RELAY_WORKTREE_ISOLATION="${3:-0}" \
  CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG="$WORK/claude-$1.json" STUB_MODE="$2" \
  bash "$SHIM" >"$WORK/turn-$1.out" 2>&1
}

# How many tasks does $AGENT still hold a live claim on? This is the number the cap is measured
# against, so it is the number the defect moves. Read from `tick info`, not from a log line, because
# the question is what the coordination layer BELIEVES, not what the harness said it did.
held_count(){
  local n=0 task
  for task in "$@"; do
    if tick_a info "$task" 2>/dev/null | /usr/bin/grep -qE '^status:[[:space:]]*claimed'; then
      if tick_a info "$task" 2>/dev/null | /usr/bin/grep -qE "^claimer:[[:space:]]*$AGENT\$"; then
        n=$((n+1))
      fi
    fi
  done
  printf '%s' "$n"
}

# Clear whatever the previous case leaked, so each case is an INDEPENDENT measurement.
#
# Without this the pre-fix run is unreadable: case 2 leaks two claims, the agent is wedged, and every
# later case fails at the cap before its own path is ever exercised — reporting cases 3 and 4 as
# broken when they were simply never run. That cascade is exactly what the defect does in production
# and it is case 2's finding, not theirs. Reaping here is a TEST-HARNESS action, deliberately not
# something the harness does for itself: auto-reaping on a cap error would trade a loud stall for a
# race against a genuinely busy agent (the issue's own non-goal).
reset_agent(){ tick_a reap "$AGENT" --by test-gh409 >/dev/null 2>&1 || true; }

# ---------------------------------------------------------------------------
# Case 1 — the agent exits non-zero (reaches rtl_enforce; #432's path)
# ---------------------------------------------------------------------------
echo "-- case 1: agent exits non-zero, twice, then a healthy turn"

for n in 1 2; do
  seed_token "RELAY-GH409-crash-$n"
  run_shim "RELAY-GH409-crash-$n" crash || true
done
h="$(held_count RELAY-GH409-crash-1 RELAY-GH409-crash-2)"
if [ "$h" -eq 0 ]; then
  pass "two crashed turns leave 0 claims held (not $h)"
else
  fail "GH-409: $h claim(s) still held by $AGENT after two crashed turns — the agent is now wedged"
fi

# The consequence, asserted directly rather than inferred from the count above. This is the assertion
# that reproduces the incident: pre-fix, this third turn is refused at the cap and never runs.
seed_token RELAY-GH409-crash-3
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-GH409-crash-3 good; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "a healthy turn after two failures still runs (exit 0)"
else
  fail "GH-409: the third turn exited $rc — two prior failures reduced $AGENT's capacity. Output: $(cat "$WORK/turn-RELAY-GH409-crash-3.out")"
fi
if [ "$(git -C "$A" rev-parse HEAD)" != "$before" ]; then
  pass "the third turn did real work (HEAD moved), so it was not merely tolerated"
else
  fail "GH-409: the third turn produced no commit — it did not actually run"
fi

# ---------------------------------------------------------------------------
# Case 2 — worktree isolation fails (sys.exit(5) ABOVE enforce)
# ---------------------------------------------------------------------------
echo "-- case 2: worktree setup fails before the agent ever launches"
reset_agent

# Force `git worktree add` to fail without touching the shim: point the isolation at a root whose
# git dir is unusable. RELAY_WORKTREE_ISOLATION=1 makes the shim call worktree_begin, which returns
# None, which is `sys.exit(5)` — several hundred lines above rtl_enforce.
WT_BLOCK="$A/.git/worktrees"
mkdir -p "$WT_BLOCK"
chmod 500 "$WT_BLOCK" 2>/dev/null || true

for n in 1 2; do
  seed_token "RELAY-GH409-wt-$n"
  run_shim "RELAY-GH409-wt-$n" good 1 || true
done
chmod 700 "$WT_BLOCK" 2>/dev/null || true

wt_ran=0
if /usr/bin/grep -q "worktree isolation requested but" "$WORK/turn-RELAY-GH409-wt-1.out" 2>/dev/null; then
  wt_ran=1
fi
if [ "$wt_ran" -eq 1 ]; then
  h="$(held_count RELAY-GH409-wt-1 RELAY-GH409-wt-2)"
  if [ "$h" -eq 0 ]; then
    pass "two worktree-setup failures leave 0 claims held"
  else
    fail "GH-409: $h claim(s) leaked from the worktree-failure path (exit 5 above enforce)"
  fi
  seed_token RELAY-GH409-wt-3
  run_shim RELAY-GH409-wt-3 good; rc=$?
  [ "$rc" -eq 0 ] \
    && pass "a healthy turn runs after two worktree-setup failures" \
    || fail "GH-409: turn 3 exited $rc after two worktree-setup failures"
else
  # Do NOT silently pass a case that did not reproduce. If the chmod trick stops working (running as
  # root, or a filesystem that ignores mode bits), this case proves nothing and must say so.
  fail "case 2 did not reproduce: worktree setup unexpectedly succeeded, so the exit-5 path was never taken. Output: $(cat "$WORK/turn-RELAY-GH409-wt-1.out")"
fi

# ---------------------------------------------------------------------------
# Case 3 — off-lane edits inside the worktree (sys.exit(6) ABOVE enforce)
# ---------------------------------------------------------------------------
echo "-- case 3: containment rejects the turn (exit 6) before enforce"
reset_agent

for n in 1 2; do
  seed_token "RELAY-GH409-off-$n"
  run_shim "RELAY-GH409-off-$n" offlane 1 || true
done
off_ran=0
/usr/bin/grep -q "off-lane" "$WORK/turn-RELAY-GH409-off-1.out" 2>/dev/null && off_ran=1
if [ "$off_ran" -eq 1 ]; then
  h="$(held_count RELAY-GH409-off-1 RELAY-GH409-off-2)"
  if [ "$h" -eq 0 ]; then
    pass "two containment rejections leave 0 claims held"
  else
    fail "GH-409: $h claim(s) leaked from the containment path (exit 6 above enforce)"
  fi
  seed_token RELAY-GH409-off-3
  run_shim RELAY-GH409-off-3 good; rc=$?
  [ "$rc" -eq 0 ] \
    && pass "a healthy turn runs after two containment rejections" \
    || fail "GH-409: turn 3 exited $rc after two containment rejections"
else
  fail "case 3 did not reproduce: the off-lane edit was not detected, so the exit-6 path was never taken. Output: $(cat "$WORK/turn-RELAY-GH409-off-1.out")"
fi

# ---------------------------------------------------------------------------
# Guard — releasing on failure must not steal a claim the turn legitimately handed on
# ---------------------------------------------------------------------------
echo "-- guard: a successful turn's handoff is not clobbered by the release-on-exit path"
reset_agent

seed_token RELAY-GH409-handoff
run_shim RELAY-GH409-handoff good; rc=$?
[ "$rc" -eq 0 ] || fail "the handoff guard's turn did not succeed (rc=$rc)"
info="$(tick_a info RELAY-GH409-handoff 2>/dev/null)"
# After a good turn the token is released to the peer (GH-67). If a blanket release-on-exit ran
# afterwards it would either error or blow away that reservation; assert the reservation survives.
if printf '%s' "$info" | /usr/bin/grep -qE '^handoff-to:[[:space:]]*agy-reviewer'; then
  pass "the successful turn's handoff to the peer survives the release-on-exit path"
else
  fail "the release-on-exit path damaged a successful turn's handoff — tick info said: $info"
fi

echo
echo "  $TEST_NAME: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
