#!/usr/bin/env bash
# Proves the runner's injectable verdict loop: claim via handoff, resume/retry on
# FAIL, and stop without done when the round cap is exceeded.
source "$(dirname "$0")/_setup.sh" runner-loop

# GH-84
export RUNNER_ROOT_DIR="$A"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER="$(cd "$HERE/.." && pwd)/relay-automation/runner.sh"

make_log() {
  local path="$1"
  : >"$path"
}

run_runner() {
  local task="$1"
  local log_file="$2"
  local agent_cmd="$3"
  local round_cap="${4:-3}"

  TICK_BIN="$TICK" TICK_REPO_ROOT="$A" "$RUNNER" \
    --task "$task" \
    --agent codex \
    --round-cap "$round_cap" \
    --poll-seconds 0 \
    --log-file "$log_file" \
    --agent-cmd "$agent_cmd" \
    -- README.md
}

status_of() {
  tick_a info "$1" | awk -F': *' '$1=="status" { print $2 }'
}

tick_a init >/dev/null

# 1. PASS via the claim path: the task is open but handed off to codex, so the
# runner must claim it by name, run the agent command once, then emit task.done.
PASS_LOG="$WORK/pass.log"
PASS_CMD="$WORK/pass-agent.sh"
make_log "$PASS_LOG"
cat >"$PASS_CMD" <<'EOF'
#!/usr/bin/env bash
printf 'VERDICT: PASS\n'
EOF
chmod +x "$PASS_CMD"

TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-PASS --agent dispatcher --priority 10 --paths "README.md" >/dev/null
TICK_TS=2026-05-04T10:00:01.000Z tick_a claim TASK-PASS --agent alice --paths "README.md" >/dev/null
TICK_TS=2026-05-04T10:00:02.000Z tick_a release TASK-PASS --agent alice --to codex >/dev/null

if run_runner TASK-PASS "$PASS_LOG" "$PASS_CMD"; then
  pass "runner exits 0 on VERDICT: PASS"
else
  fail "runner did not exit 0 on PASS"
fi

DONE_EVENTS=$(ls "$A/.tick/events/" | grep -c "codex-done-TASK-PASS" || true)
if [ "$DONE_EVENTS" = "1" ] && [ "$(status_of TASK-PASS)" = "done" ]; then
  pass "runner claims the handed-off task and emits task.done"
else
  fail "expected TASK-PASS done by codex, got status=$(status_of TASK-PASS) done_events=$DONE_EVENTS"
fi

# 2. FAIL then PASS via the resume path: the task is already claimed by codex.
RETRY_LOG="$WORK/retry.log"
RETRY_CMD="$WORK/fail-then-pass.sh"
RETRY_STATE="$WORK/retry-count.txt"
make_log "$RETRY_LOG"
cat >"$RETRY_CMD" <<EOF
#!/usr/bin/env bash
count_file="$RETRY_STATE"
count=0
if [ -f "\$count_file" ]; then
  count=\$(cat "\$count_file")
fi
count=\$((count + 1))
printf '%s\n' "\$count" >"\$count_file"
if [ "\$count" -eq 1 ]; then
  printf 'VERDICT: FAIL\n'
else
  printf 'VERDICT: PASS\n'
fi
EOF
chmod +x "$RETRY_CMD"

TICK_TS=2026-05-04T10:01:00.000Z tick_a log task.created TASK-RETRY --agent dispatcher --priority 8 --paths "README.md" >/dev/null
TICK_TS=2026-05-04T10:01:01.000Z tick_a claim TASK-RETRY --agent codex --paths "README.md" >/dev/null

if run_runner TASK-RETRY "$RETRY_LOG" "$RETRY_CMD" 3; then
  pass "runner retries after FAIL and eventually exits 0 on PASS"
else
  fail "runner did not recover from FAIL then PASS"
fi

if [ "$(cat "$RETRY_STATE")" = "2" ] && [ "$(status_of TASK-RETRY)" = "done" ]; then
  pass "runner retried exactly once before emitting task.done"
else
  fail "expected TASK-RETRY to take 2 runs and end done"
fi

# 3. Round cap exceeded: repeated FAILs return non-zero and MUST NOT emit task.done.
CAP_LOG="$WORK/cap.log"
CAP_CMD="$WORK/always-fail.sh"
make_log "$CAP_LOG"
cat >"$CAP_CMD" <<'EOF'
#!/usr/bin/env bash
printf 'VERDICT: FAIL\n'
EOF
chmod +x "$CAP_CMD"

TICK_TS=2026-05-04T10:02:00.000Z tick_a log task.created TASK-CAP --agent dispatcher --priority 6 --paths "README.md" >/dev/null
TICK_TS=2026-05-04T10:02:01.000Z tick_a claim TASK-CAP --agent codex --paths "README.md" >/dev/null

if run_runner TASK-CAP "$CAP_LOG" "$CAP_CMD" 2 >"$WORK/cap.out" 2>&1; then
  fail "runner unexpectedly succeeded despite repeated FAIL verdicts"
else
  pass "runner exits non-zero when the round cap is exceeded"
fi

CAP_DONE_EVENTS=$(ls "$A/.tick/events/" | grep -c "codex-done-TASK-CAP" || true)
if [ "$CAP_DONE_EVENTS" = "0" ] && [ "$(status_of TASK-CAP)" = "claimed" ]; then
  pass "runner leaves the task claimed and emits no done event on round-cap failure"
else
  fail "expected TASK-CAP to stay claimed with no done event"
fi

# 4. Regression: with a deliberately-dirtied tracked file in the REAL repo,
# run_runner still passes (proving the guard no longer reaches the real tree).
# GH-84
README_BAK="$WORK/README.md.bak"
REAL_README="$HERE/../README.md"
cp "$REAL_README" "$README_BAK"
cleanup() {
  if [ -f "$README_BAK" ]; then
    cp "$README_BAK" "$REAL_README"
  fi
  rm -rf "$WORK"
}
trap cleanup EXIT

echo "dirty" >> "$REAL_README"

# Create a clean task in $A. The runner should pass despite the real README.md being dirty.
TICK_TS=2026-05-04T10:03:00.000Z tick_a log task.created TASK-REGRESSION --agent dispatcher --priority 5 --paths "README.md" >/dev/null
TICK_TS=2026-05-04T10:03:01.000Z tick_a claim TASK-REGRESSION --agent alice --paths "README.md" >/dev/null
TICK_TS=2026-05-04T10:03:02.000Z tick_a release TASK-REGRESSION --agent alice --to codex >/dev/null

REG_LOG="$WORK/regression.log"
make_log "$REG_LOG"

if run_runner TASK-REGRESSION "$REG_LOG" "$PASS_CMD"; then
  pass "runner passes regression test with dirty real repo tracked file"
else
  # Restore before failing so we don't leave the repo dirty
  cp "$README_BAK" "$REAL_README"
  fail "runner failed regression test with dirty real repo tracked file"
fi

# Restore README.md
cp "$README_BAK" "$REAL_README"
rm -f "$README_BAK"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
