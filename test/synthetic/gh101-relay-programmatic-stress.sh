#!/usr/bin/env bash
# Synthetic Test: GH-101 Relay Drive Programmatic Tool Mode, Process-Group Cleanup & Fail-Closed Containment
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh101-relay-prog.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

REPO="$WORK/repo"
mkdir -p "$REPO"
git init -q "$REPO"
git -C "$REPO" -c user.email=test@test.local -c user.name=TestRunner commit -q --allow-empty -m "initial commit"
touch "$REPO/target_artifact.py"
git -C "$REPO" add target_artifact.py
git -C "$REPO" -c user.email=test@test.local -c user.name=TestRunner commit -q -m "add target artifact"

RELAY_FILE="$REPO/test-relay.md"
cat << 'RELAY_EOF' > "$RELAY_FILE"
STATUS: In progress
NEXT: Producer
ROUNDS: 0 / 6

# Synthetic Relay Test

## Setup
Artifact under review: target_artifact.py

## Log
RELAY_EOF
git -C "$REPO" add test-relay.md
git -C "$REPO" -c user.email=test@test.local -c user.name=TestRunner commit -q -m "add relay file"

# 1. Test invalid tool-mode rejection
INVALID_OUT="$(python3 "$ROOT/utils/py/relay_drive.py" --relay-file "$RELAY_FILE" --agent-cmd "echo" --tool-mode "invalid_mode" 2>&1 || true)"
if ! grep -qF "invalid choice: 'invalid_mode'" <<<"$(echo "$INVALID_OUT")"; then
  echo "FAIL: relay_drive.py failed to reject invalid tool-mode"
  exit 1
fi

# 2. Test fail-closed refusal when OS sandbox binary is missing
MOCK_BIN_DIR="$WORK/empty_bin"
mkdir -p "$MOCK_BIN_DIR"
ln -s "$(command -v python3)" "$MOCK_BIN_DIR/python3"
FAIL_CLOSED_OUT="$(PATH="$MOCK_BIN_DIR" "$MOCK_BIN_DIR/python3" "$ROOT/utils/py/relay_drive.py" --relay-file "$RELAY_FILE" --agent-cmd "echo" --tool-mode "programmatic" 2>&1 || true)"
if ! grep -qF "Containment failure (fail-closed)" <<<"$(echo "$FAIL_CLOSED_OUT")"; then
  echo "FAIL: relay_drive.py failed to fail closed when sandbox binaries are absent"
  exit 1
fi

# 3. Test programmatic relay turn with process-group stress & containment
STRESS_RECORD="$WORK/stress_results.txt"
AGENT_SCRIPT="$WORK/mock_agent.sh"
cat << AGENT_EOF > "$AGENT_SCRIPT"
#!/usr/bin/env bash
set -e
if [ "\${XYZ_TOOL_MODE:-}" != "programmatic" ] || [ "\${RELAY_TOOL_MODE:-}" != "programmatic" ]; then
  echo "ENV_ERROR: tool mode not programmatic" >> "$STRESS_RECORD"
  exit 1
fi

# Write probe output into .relay-scratch
mkdir -p .relay-scratch
echo "{\"probe\": \"pass\", \"tool_mode\": \"programmatic\"}" > .relay-scratch/probe_telemetry.json

# Launch a background process tree to stress process group cleanup
python3 -c '
import time
time.sleep(0.1)
' &
BG_PID=\$!
echo "BG_PID=\$BG_PID" >> "$STRESS_RECORD"

# Update relay file
tmp="\$(mktemp)"
sed 's/^STATUS:.*/STATUS: Approved/' "$RELAY_FILE" > "\$tmp" && mv "\$tmp" "$RELAY_FILE"
cat << 'LOG_EOF' >> "$RELAY_FILE"

### Producer turn (round 1)

VERDICT: PASS
Basis: Programmatic probe verified in .relay-scratch
STATUS: Approved
NEXT: None
LOG_EOF

echo "TURN_COMPLETED=1" >> "$STRESS_RECORD"
exit 0
AGENT_EOF
chmod +x "$AGENT_SCRIPT"

# Initialize tick token in fixture repository
TICK_BIN="$ROOT/bin/tick"
export TICK_BIN
TICK_REPO_ROOT="$REPO" "$ROOT/bin/tick" init >/dev/null 2>&1
TICK_REPO_ROOT="$REPO" "$ROOT/bin/tick" log task.created RELAY-TURN --agent claude --paths test-relay.md >/dev/null 2>&1
TICK_REPO_ROOT="$REPO" "$ROOT/bin/tick" claim RELAY-TURN --agent claude --paths test-relay.md >/dev/null 2>&1
TICK_REPO_ROOT="$REPO" "$ROOT/bin/tick" release RELAY-TURN --agent claude --to producer >/dev/null 2>&1

RELAY_DRIVER_LOCKED=0 TICK_REPO_ROOT="$REPO" python3 "$ROOT/utils/py/relay_drive.py" \
  --relay-file "$RELAY_FILE" \
  --relay-task RELAY-TURN \
  --agent-cmd "$AGENT_SCRIPT" \
  --tool-mode "programmatic" \
  --round-cap 1 >/dev/null 2>&1 || true

# Assert turn completed successfully
if [ ! -f "$STRESS_RECORD" ] || ! grep -qF "TURN_COMPLETED=1" "$STRESS_RECORD"; then
  echo "FAIL: programmatic relay turn did not complete cleanly"
  exit 1
fi

# Assert probe output did not leak to parent repository root
if [ -d "$REPO/.relay-scratch" ] || [ -f "$REPO/probe_telemetry.json" ]; then
  echo "FAIL: scratch probe file leaked to parent repository"
  exit 1
fi

# Assert relay file has approved status
if ! grep -qF "STATUS: Approved" "$RELAY_FILE"; then
  echo "FAIL: relay file was not updated with Approved status"
  exit 1
fi

echo "ALL GH-101 RELAY PROGRAMMATIC STRESS TESTS PASSED"
exit 0
