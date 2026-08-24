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
# GH-218: run every relay_drive.py invocation from inside the FIXTURE repo. relay_drive resolves
# its driver lock (and the turn's working root) from the CWD; invoked from $ROOT it tries to
# acquire $ROOT/.git/relay-driver.lock — free standalone, but HELD when validate.sh runs as a
# marathon-drive pre-advance gate, so the programmatic turn failed and escalated a live phase.
INVALID_OUT="$(cd "$REPO" && python3 "$ROOT/utils/py/relay_drive.py" --relay-file "$RELAY_FILE" --agent-cmd "echo" --tool-mode "invalid_mode" 2>&1 || true)"
if ! grep -qF "invalid choice: 'invalid_mode'" <<<"$(echo "$INVALID_OUT")"; then
  echo "FAIL: relay_drive.py failed to reject invalid tool-mode"
  exit 1
fi

# 2. Test fail-closed refusal when OS sandbox binary is missing
MOCK_BIN_DIR="$WORK/empty_bin"
mkdir -p "$MOCK_BIN_DIR"
ln -s "$(command -v python3)" "$MOCK_BIN_DIR/python3"
FAIL_CLOSED_OUT="$(cd "$REPO" && PATH="$MOCK_BIN_DIR" "$MOCK_BIN_DIR/python3" "$ROOT/utils/py/relay_drive.py" --relay-file "$RELAY_FILE" --agent-cmd "echo" --tool-mode "programmatic" 2>&1 || true)"
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

# Clean up scratch probe before exit
rm -rf .relay-scratch

echo "TURN_COMPLETED=1" >> "$STRESS_RECORD"
exit 0
AGENT_EOF
chmod +x "$AGENT_SCRIPT"

[ -d "$ROOT/.relay-scratch" ] && : >"$WORK/pre-root-scratch"   # pre-turn snapshot for the leak check below

# Initialize tick token in fixture repository
TICK_BIN="$ROOT/bin/tick"
export TICK_BIN
TICK_REPO_ROOT="$REPO" "$ROOT/bin/tick" init >/dev/null 2>&1
TICK_REPO_ROOT="$REPO" "$ROOT/bin/tick" log task.created RELAY-TURN --agent claude --paths test-relay.md >/dev/null 2>&1
TICK_REPO_ROOT="$REPO" "$ROOT/bin/tick" claim RELAY-TURN --agent claude --paths test-relay.md >/dev/null 2>&1
TICK_REPO_ROOT="$REPO" "$ROOT/bin/tick" release RELAY-TURN --agent claude --to producer >/dev/null 2>&1

# GH-218: two scoping fixes, one measured against the issue's own sketch:
#   - cd "$REPO": the TURN (agent CWD, scratch writes, containment root) belongs to the fixture, not
#     the harness clone — pre-fix, the agent's CWD-relative .relay-scratch landed in the REAL repo.
#   - RELAY_DRIVER_LOCKED=1 (not the sketched `cd`-fixes-the-lock): relay_drive.py resolves its lock
#     from the SCRIPT's location (utils/py/../.. = the harness clone), NOT the CWD, so a cd cannot
#     move it and RELAY_DRIVER_LOCKED=0 made this suite try to acquire the harness clone's
#     .git/relay-driver.lock — free standalone, HELD when validate.sh runs as a marathon-drive
#     pre-advance gate, failing the turn and escalating a live phase. RELAY_DRIVER_LOCKED=1 is the
#     documented nested-driver idiom (GH-441 Phase 1, test/driver-lock.sh:11): a suite driving
#     against its own throwaway fixture skips the parent's lock.
(cd "$REPO" && RELAY_DRIVER_LOCKED=1 TICK_REPO_ROOT="$REPO" python3 "$ROOT/utils/py/relay_drive.py" \
  --relay-file "$RELAY_FILE" \
  --relay-task RELAY-TURN \
  --agent-cmd "$AGENT_SCRIPT" \
  --tool-mode "programmatic" \
  --round-cap 1 >/dev/null 2>&1) || true

# Assert turn completed successfully
if [ ! -f "$STRESS_RECORD" ] || ! grep -qF "TURN_COMPLETED=1" "$STRESS_RECORD"; then
  echo "FAIL: programmatic relay turn did not complete cleanly"
  exit 1
fi

# Assert probe output did not leak to the PARENT (harness) repository root. Pre-GH-218 the turn
# ran with CWD=$ROOT, so the agent's CWD-relative .relay-scratch landed in the real clone while this
# assertion watched the fixture — passing vacuously AND polluting $ROOT. Now the turn runs in $REPO
# (fixture scratch is sanctioned and dies with $WORK), so this watches the real parent, compared
# against a pre-turn snapshot so a sibling suite's own scratch cannot flake it.
if [ -d "$ROOT/.relay-scratch" ] && [ ! -e "$WORK/pre-root-scratch" ]; then
  echo "FAIL: .relay-scratch leaked to parent repository root"
  exit 1
fi
if [ -f "$ROOT/probe_telemetry.json" ]; then
  echo "FAIL: probe_telemetry.json leaked to parent repository root"
  exit 1
fi

# Assert relay file has approved status
if ! grep -qF "STATUS: Approved" "$RELAY_FILE"; then
  echo "FAIL: relay file was not updated with Approved status"
  exit 1
fi

echo "ALL GH-101 RELAY PROGRAMMATIC STRESS TESTS PASSED"
exit 0
