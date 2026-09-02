#!/usr/bin/env bash
# GH-370: the default Python relay supervisor reports changed-file progress during a live turn.
source "$(dirname "$0")/_setup.sh" gh370-progress-telemetry

ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
DRIVER="$ROOT_REPO/utils/py/relay_drive.py"
RELAY="$A/relay.md"
TASK="GH370-PROGRESS"

tick_a init >/dev/null
printf 'STATUS: Open\nNEXT: codex (Builder)\n' > "$RELAY"
printf '.tick/\n' > "$A/.gitignore"
git -C "$A" add .gitignore relay.md
git -C "$A" commit -qm "fixture relay"
tick_a log task.created "$TASK" --agent seed --paths relay.md >/dev/null
tick_a claim "$TASK" --agent seed --paths relay.md >/dev/null
tick_a release "$TASK" --agent seed --to codex >/dev/null

AGENT="$WORK/progress-agent.sh"
cat > "$AGENT" <<'AGENT_EOF'
#!/usr/bin/env bash
printf 'changed while turn is live\n' > "$PROGRESS_FIXTURE/progress.txt"
sleep 2
"$TICK_BIN" claim "$RELAY_TASK" --agent codex --paths relay.md >/dev/null
sed -i.bak 's/^STATUS:.*/STATUS: Approved/' "$RELAY_FILE"
rm -f "${RELAY_FILE}.bak"
"$TICK_BIN" done "$RELAY_TASK" --agent codex >/dev/null
AGENT_EOF
chmod +x "$AGENT"

out="$(
  TICK_REPO_ROOT="$A" TICK_BIN="$TICK" PROGRESS_FIXTURE="$A" \
  RELAY_WORKTREE_ISOLATION=0 RELAY_PROGRESS_INTERVAL_S=1 RELAY_COST_SUMMARY=0 \
  RELAY_DRIVER_LOCKED=1 python3 "$DRIVER" \
    --relay-file "$RELAY" --relay-task "$TASK" --agent-cmd "$AGENT" 2>&1
)"
rc=$?

[ "$rc" -eq 0 ] \
  && pass "fixture relay completes successfully" \
  || fail "fixture relay exited $rc: $out"
printf '%s\n' "$out" | grep -Fq 'GH-370 progress (main tree fallback:' \
  && pass "progress telemetry identifies the non-isolated main-tree fallback" \
  || fail "progress telemetry did not name its sample root: $out"
printf '%s\n' "$out" | grep -Fq 'changed-files=1' \
  && pass "progress telemetry records the fixture worktree's changed-file count" \
  || fail "progress telemetry did not record changed-files=1: $out"
grep -q 'GH-370' "$DRIVER" \
  && pass "Python supervisor change site retains the GH-370 preflight marker" \
  || fail "Python supervisor lost its GH-370 marker"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
