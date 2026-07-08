#!/usr/bin/env bash
# test/test-agy-isolation.sh — GH-178 B1: verify the post-hoc agy isolation breach detection.
# Both consult.sh and agy-turn.sh should fail the turn (exit 5) if the agy transcript contains
# the absolute path to the real repo root, which proves agy escaped its assigned worktree.

source "$(dirname "$0")/_setup.sh" test-agy-isolation

CONSULT="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/consult.sh"
AGY_TURN="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/agy-turn.sh"

MOCK_AGY_BREACH="$A/mock-agy-breach.sh"
cat << 'INNER_EOF' > "$MOCK_AGY_BREACH"
#!/usr/bin/env bash
if [[ "$1" == "whoami" ]]; then exit 0; fi
if [[ "$1" == "models" ]]; then echo "mock-model"; exit 0; fi
# Simulate a breach by outputting the real repo root
echo "I found the file at $ROOT"
INNER_EOF
chmod +x "$MOCK_AGY_BREACH"

MOCK_AGY_SAFE="$A/mock-agy-safe.sh"
cat << 'INNER_EOF' > "$MOCK_AGY_SAFE"
#!/usr/bin/env bash
if [[ "$1" == "whoami" ]]; then exit 0; fi
if [[ "$1" == "models" ]]; then echo "mock-model"; exit 0; fi
# Safe output, no real root cited
echo "I found the file in the worktree"
INNER_EOF
chmod +x "$MOCK_AGY_SAFE"

# --- 1. consult.sh (breach) ---
out_dir="$A/consult-out"
export AGY_BIN="$MOCK_AGY_BREACH"
# We export ROOT here so the mock can read it, simulating agy finding it internally.
export ROOT="$A"

"$CONSULT" --prompt "hello" --models agy --out "$out_dir" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 5 ]; then
  pass "consult.sh: properly failed the run when agy breached isolation (exit 5)"
else
  fail "consult.sh: did NOT fail the run on isolation breach (expected exit 5, got $rc)"
fi

log_file="$(ls "$out_dir"/*/*.agy.md 2>/dev/null | head -1)"
if [ -n "$log_file" ] && grep -q "isolation breach" "$log_file"; then
  pass "consult.sh: wrote isolation breach failure message to transcript"
else
  fail "consult.sh: missing isolation breach failure message in transcript"
fi

# --- 2. consult.sh (safe) ---
out_dir_safe="$A/consult-out-safe"
export AGY_BIN="$MOCK_AGY_SAFE"

"$CONSULT" --prompt "hello" --models agy --out "$out_dir_safe" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then
  pass "consult.sh: allowed a safe agy run (exit 0)"
else
  fail "consult.sh: incorrectly failed a safe agy run (expected exit 0, got $rc)"
fi

# --- 3. agy-turn.sh (breach) ---
export RELAY_FILE="$A/relay.md"
export RELAY_AGENT="agy"
export AGY_AGENT="agy"
export AGY_BIN="$MOCK_AGY_BREACH"
export AGY_MODEL="mock-model"
export RELAY_WORKTREE_ISOLATION=1
echo "NEXT: agy" > "$RELAY_FILE"

out_log="$A/agy-turn.log"
export AGY_LOG="$out_log"

"$AGY_TURN" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 5 ]; then
  pass "agy-turn.sh: properly failed the turn when agy breached isolation (exit 5)"
else
  fail "agy-turn.sh: did NOT fail the turn on isolation breach (expected exit 5, got $rc)"
fi

if grep -q "isolation breach" "$out_log"; then
  pass "agy-turn.sh: wrote isolation breach failure message to transcript"
else
  fail "agy-turn.sh: missing isolation breach failure message in transcript"
fi

# --- 4. agy-turn.sh (safe) ---
export AGY_BIN="$MOCK_AGY_SAFE"
echo "NEXT: agy" > "$RELAY_FILE"
out_log_safe="$A/agy-turn-safe.log"
export AGY_LOG="$out_log_safe"

"$AGY_TURN" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then
  pass "agy-turn.sh: allowed a safe agy turn (exit 0)"
else
  fail "agy-turn.sh: incorrectly failed a safe agy turn (expected exit 0, got $rc)"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
