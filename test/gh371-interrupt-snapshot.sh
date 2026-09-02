#!/usr/bin/env bash
# GH-371 — kill an active phase and preserve its dirty main tree in the incident record.
set -euo pipefail
source "$(dirname "$0")/_setup.sh" gh371-interrupt-snapshot

ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
HARNESS="$WORK/harness"
mkdir -p "$HARNESS/utils/py" "$HARNESS/relay-automation"
cp "$ROOT_REPO/utils/py/marathon_drive.py" "$ROOT_REPO/utils/py/relay_drive.py" "$ROOT_REPO/utils/py/rtl.py" "$HARNESS/utils/py/"
cp "$ROOT_REPO/relay-automation/relay-turn-lib.sh" "$ROOT_REPO/relay-automation/durable-log-lib.sh" "$ROOT_REPO/relay-automation/non-durable-log-roots.conf" "$HARNESS/relay-automation/"
chmod +x "$HARNESS/utils/py/relay_drive.py"
RELAY_DRIVE="$WORK/relay-drive"
printf '#!/usr/bin/env bash\nexec python3 "'"$HARNESS"'"/utils/py/relay_drive.py "$@"\n' >"$RELAY_DRIVE"
chmod +x "$RELAY_DRIVE"

git init -q "$HARNESS"
git -C "$HARNESS" config user.email gh371@t
git -C "$HARNESS" config user.name gh371
printf '.tick/\nrelay-system/logs/\n' >"$HARNESS/.gitignore"
printf '## fixture brief\n' >"$HARNESS/brief.md"
git -C "$HARNESS" add .gitignore brief.md >/dev/null
git -C "$HARNESS" commit -q -m seed

STUB_BIN="$WORK/stub-bin"
printf '#!/usr/bin/env bash\nexit 0\n' >"$STUB_BIN"
chmod +x "$STUB_BIN"
HANG="$WORK/dirty-hang"
cat >"$HANG" <<'EOF'
#!/usr/bin/env bash
printf 'partial change\n' >"$RELAY_TARGET_ROOT/main-tree-dirty.txt"
printf 'started\n' >"$RELAY_TARGET_ROOT/started"
sleep 300
EOF
chmod +x "$HANG"

set +e
MARATHON_ROOT="$HARNESS" MARATHON_RELAY_DRIVE="$RELAY_DRIVE" MARATHON_AGENT_CMD="$HANG" TICK_REPO_ROOT="$HARNESS" TICK_BIN="$TICK" CODEX_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" MARATHON_ALLOW_TRUNK_COMMIT=1 RELAY_TARGET_ROOT="$HARNESS" python3 -c 'import os,sys; os.setsid(); os.execvp(sys.argv[1], sys.argv[1:])' python3 "$HARNESS/utils/py/marathon_drive.py" --phase-id interrupted --phase-brief "$HARNESS/brief.md" --phases-dir "$HARNESS/phases" --builder codex --reviewer agy --round-cap 1 --pre-advance-cmd true >"$WORK/drive.out" 2>&1 &
DRIVE_PID=$!
set -e

started=0
for _ in $(seq 1 80); do
  if [ -f "$HARNESS/started" ]; then started=1; break; fi
  sleep 0.1
done
if [ "$started" -eq 1 ]; then
  kill -TERM "$DRIVE_PID" 2>/dev/null || true
  wait "$DRIVE_PID" 2>/dev/null || true
  kill -TERM -"$DRIVE_PID" 2>/dev/null || true
  REC="$(find "$HARNESS/phases" -name PHASE-INTERRUPTED.md -type f | head -n 1)"
  grep -q 'Uncommitted tree snapshot (GH-371)' "$REC" && pass "the interrupted phase contains a tree snapshot section" || fail "GH-371: no snapshot section — $(cat "$REC" 2>/dev/null)"
  grep -q '?? main-tree-dirty.txt' "$REC" && pass "the untracked main-tree edit is preserved in porcelain form" || fail "GH-371: main-tree dirt is absent — $(cat "$REC" 2>/dev/null)"
else
  kill -TERM "$DRIVE_PID" 2>/dev/null || true
  wait "$DRIVE_PID" 2>/dev/null || true
  fail "GH-371 fixture never reached its dirty interrupted turn — $(cat "$WORK/drive.out")"
fi

echo "gh371-interrupt-snapshot: $PASS pass, $FAIL fail"
