#!/usr/bin/env bash
# GH-372 — an escalation must preserve the actual failing turn tail, or name its absence.
set -euo pipefail
source "$(dirname "$0")/_setup.sh" gh372-escalation-log-tail

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
git -C "$HARNESS" config user.email gh372@t
git -C "$HARNESS" config user.name gh372
printf '.tick/\nrelay-system/logs/\n' >"$HARNESS/.gitignore"
printf '## fixture brief\n' >"$HARNESS/brief.md"
git -C "$HARNESS" add .gitignore brief.md >/dev/null
git -C "$HARNESS" commit -q -m seed

STUB_BIN="$WORK/stub-bin"
printf '#!/usr/bin/env bash\nexit 0\n' >"$STUB_BIN"
chmod +x "$STUB_BIN"
FAIL_WITH_LOG="$WORK/fail-with-log"
cat >"$FAIL_WITH_LOG" <<'EOF'
#!/usr/bin/env bash
for i in $(seq -w 1 45); do printf 'failure-line-%s\n' "$i"; done >"$CODEX_LOG"
exit 5
EOF
chmod +x "$FAIL_WITH_LOG"
FAIL_NO_LOG="$WORK/fail-no-log"
printf '#!/usr/bin/env bash\nexit 5\n' >"$FAIL_NO_LOG"
chmod +x "$FAIL_NO_LOG"

run_phase() {
  local phase="$1" agent="$2"
  set +e
  MARATHON_ROOT="$HARNESS" MARATHON_RELAY_DRIVE="$RELAY_DRIVE" MARATHON_AGENT_CMD="$agent" TICK_REPO_ROOT="$HARNESS" TICK_BIN="$TICK" CODEX_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" MARATHON_ALLOW_TRUNK_COMMIT=1 python3 "$HARNESS/utils/py/marathon_drive.py" --phase-id "$phase" --phase-brief "$HARNESS/brief.md" --phases-dir "$HARNESS/phases-$phase" --builder codex --reviewer agy --round-cap 1 --pre-advance-cmd true >"$WORK/$phase.out" 2>&1
  set -e
}

run_phase with-log "$FAIL_WITH_LOG"
ESC="$(find "$HARNESS/phases-with-log" -name ESCALATION.md -type f | head -n 1)"
grep -q 'Last 40 lines of failing turn log' "$ESC" && pass "the escalation contains a collapsed failing-turn tail" || fail "GH-372: missing collapsed log tail — $(cat "$ESC" 2>/dev/null); driver: $(cat "$WORK/with-log.out")"
grep -q 'failure-line-06' "$ESC" && ! grep -q 'failure-line-05' "$ESC" && pass "the record keeps the last 40 lines, not an unbounded transcript" || fail "GH-372: tail boundaries are wrong — $(cat "$ESC")"

run_phase no-log "$FAIL_NO_LOG"
ESC_NO_LOG="$(find "$HARNESS/phases-no-log" -name ESCALATION.md -type f | head -n 1)"
grep -q 'no turn log was created' "$ESC_NO_LOG" && pass "a failure before transcript creation is explicitly diagnosed" || fail "GH-372: no-log escalation is ambiguous — $(cat "$ESC_NO_LOG" 2>/dev/null); driver: $(cat "$WORK/no-log.out")"

echo "gh372-escalation-log-tail: $PASS pass, $FAIL fail"
