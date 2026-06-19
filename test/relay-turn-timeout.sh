#!/usr/bin/env bash
# relay-turn-timeout.sh — test the per-turn wall-clock cap added to rtl_run_bounded in
# relay-turn-lib.sh. Verifies that a hung CLI is killed and the shim exits 7 (not hung, not 0),
# and that a fast CLI under the same cap still succeeds (exit 0 — no false-positive kill).
# Tests all three shims (codex, gemini, claude) with a tiny cap (1s) and a stub that sleeps 5s.
source "$(dirname "$0")/_setup.sh" relay-turn-timeout
export TICK_BIN="$TICK"
tick_a init >/dev/null

# Committed relay-file baseline + .tick gitignore (mirrors production setup).
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf '.tick/\n' >"$A/.gitignore"
git -C "$A" add relay.md .gitignore >/dev/null 2>&1
git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1

# --- Stubs ------------------------------------------------------------------
# SLOW stub: sleeps longer than the cap to trigger a timeout-kill.
SLOW_STUB="$WORK/slow-cli"
cat >"$SLOW_STUB" <<'STUB_EOF'
#!/usr/bin/env bash
sleep 5
exit 0
STUB_EOF
chmod +x "$SLOW_STUB"

# FAST stub: exits immediately with success (used for false-positive check).
FAST_STUB="$WORK/fast-cli"
cat >"$FAST_STUB" <<'STUB_EOF'
#!/usr/bin/env bash
export TICK_REPO_ROOT="$A"
"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
"$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
printf '\n### Round 1 · %s (fast-stub)\n' "$RELAY_AGENT" >>"$RELAY_FILE"
"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to other >/dev/null 2>&1
exit 0
STUB_EOF
chmod +x "$FAST_STUB"

# Helper: seed a token handed to the target agent
seed_token() { tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to codex >/dev/null; }

# ============================================================================
# Codex shim timeout tests
# ============================================================================
CODEX_SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/codex-turn.sh"

# --- (1) SLOW codex: cap fires -> exit 7 (not hung, not 0) ------------------
seed_token RELAY-TURN-codex-slow
t_start="$(date +%s)"
RELAY_AGENT=codex RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-codex-slow \
  CODEX_AGENT=codex CODEX_BIN="$SLOW_STUB" CODEX_TURN_ROOT="$A" CODEX_LOG=/dev/null \
  RELAY_TURN_TIMEOUT_S=1 \
  bash "$CODEX_SHIM" >/dev/null 2>&1; rc=$?
t_end="$(date +%s)"
elapsed=$(( t_end - t_start ))
[ "$rc" -eq 7 ] && pass "codex: timed-out stub -> shim exits 7" || fail "codex: expected exit 7, got $rc"
[ "$elapsed" -lt 5 ] && pass "codex: turn killed fast (${elapsed}s < stub's 5s sleep)" || fail "codex: cap did not fire fast enough (${elapsed}s)"

# --- (2) FAST codex: completes before cap -> exit 0 (no false-positive kill) -
seed_token RELAY-TURN-codex-fast
RELAY_AGENT=codex RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-codex-fast \
  CODEX_AGENT=codex CODEX_BIN="$FAST_STUB" CODEX_TURN_ROOT="$A" CODEX_LOG=/dev/null \
  RELAY_TURN_TIMEOUT_S=1 \
  bash "$CODEX_SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "codex: fast stub under cap -> exit 0 (no false-positive kill)" || fail "codex: fast stub should exit 0, got $rc"

# ============================================================================
# Gemini shim timeout tests
# ============================================================================
GEMINI_SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/gemini-turn.sh"

# --- (3) SLOW gemini: cap fires -> exit 7 -----------------------------------
seed_token RELAY-TURN-gemini-slow
t_start="$(date +%s)"
RELAY_AGENT=gemini RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-gemini-slow \
  GEMINI_AGENT=gemini GEMINI_BIN="$SLOW_STUB" GEMINI_TURN_ROOT="$A" GEMINI_LOG=/dev/null \
  GOOGLE_GENAI_USE_GCA=false \
  RELAY_TURN_TIMEOUT_S=1 \
  bash "$GEMINI_SHIM" >/dev/null 2>&1; rc=$?
t_end="$(date +%s)"
elapsed=$(( t_end - t_start ))
[ "$rc" -eq 7 ] && pass "gemini: timed-out stub -> shim exits 7" || fail "gemini: expected exit 7, got $rc"
[ "$elapsed" -lt 5 ] && pass "gemini: turn killed fast (${elapsed}s < stub's 5s sleep)" || fail "gemini: cap did not fire fast enough (${elapsed}s)"

# --- (4) FAST gemini: completes before cap -> exit 0 -------------------------
# Re-seed token (slow run claimed then timed out; fast-stub token needs its own slot)
seed_token RELAY-TURN-gemini-fast
RELAY_AGENT=gemini RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-gemini-fast \
  GEMINI_AGENT=gemini GEMINI_BIN="$FAST_STUB" GEMINI_TURN_ROOT="$A" GEMINI_LOG=/dev/null \
  GOOGLE_GENAI_USE_GCA=false \
  RELAY_TURN_TIMEOUT_S=1 \
  bash "$GEMINI_SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "gemini: fast stub under cap -> exit 0 (no false-positive kill)" || fail "gemini: fast stub should exit 0, got $rc"

# ============================================================================
# Claude shim timeout tests
# ============================================================================
CLAUDE_SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/claude-turn.sh"

# --- (5) SLOW claude: cap fires -> exit 7 ------------------------------------
seed_token RELAY-TURN-claude-slow
t_start="$(date +%s)"
RELAY_AGENT=claude-a RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-claude-slow \
  CLAUDE_AGENT=claude-a CLAUDE_BIN="$SLOW_STUB" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG=/dev/null \
  CLAUDE_BLOCK_CMDS="" \
  RELAY_TURN_TIMEOUT_S=1 \
  bash "$CLAUDE_SHIM" >/dev/null 2>&1; rc=$?
t_end="$(date +%s)"
elapsed=$(( t_end - t_start ))
[ "$rc" -eq 7 ] && pass "claude: timed-out stub -> shim exits 7" || fail "claude: expected exit 7, got $rc"
[ "$elapsed" -lt 5 ] && pass "claude: turn killed fast (${elapsed}s < stub's 5s sleep)" || fail "claude: cap did not fire fast enough (${elapsed}s)"

# --- (6) FAST claude: completes before cap -> exit 0 -------------------------
seed_token RELAY-TURN-claude-fast
RELAY_AGENT=claude-a RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-claude-fast \
  CLAUDE_AGENT=claude-a CLAUDE_BIN="$FAST_STUB" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG=/dev/null \
  CLAUDE_BLOCK_CMDS="" \
  RELAY_TURN_TIMEOUT_S=1 \
  bash "$CLAUDE_SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "claude: fast stub under cap -> exit 0 (no false-positive kill)" || fail "claude: fast stub should exit 0, got $rc"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
