#!/usr/bin/env bash
# relay-turn-timeout.sh — test the per-turn wall-clock cap added to rtl_run_bounded in
# relay-turn-lib.sh. Verifies that a hung CLI is killed and the shim exits 7 (not hung, not 0),
# and that a fast CLI under the same cap still succeeds (exit 0 — no false-positive kill).
# Tests all three shims (codex, agy, claude) with a tiny cap (1s) and a stub that sleeps 5s.
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

# agy-specific stubs: agy-turn.sh runs an auth pre-flight (`agy whoami`, 5s default cap) BEFORE
# the real turn — unlike codex-turn.sh/claude-turn.sh, which have no such pre-flight. The shared
# SLOW/FAST stubs above sleep/exit unconditionally, so agy's pre-flight would itself hit the slow
# path and mask the timeout behavior this test targets. These variants answer `whoami` instantly
# (successful auth) and only then apply the slow/fast behavior to the REAL turn invocation.
AGY_SLOW_STUB="$WORK/agy-slow-cli"
cat >"$AGY_SLOW_STUB" <<'STUB_EOF'
#!/usr/bin/env bash
{ [ "${1:-}" = whoami ] || [ "${1:-}" = models ]; } && { echo ok; exit 0; }
sleep 5
exit 0
STUB_EOF
chmod +x "$AGY_SLOW_STUB"

AGY_FAST_STUB="$WORK/agy-fast-cli"
cat >"$AGY_FAST_STUB" <<'STUB_EOF'
#!/usr/bin/env bash
{ [ "${1:-}" = whoami ] || [ "${1:-}" = models ]; } && { echo ok; exit 0; }
printf 'agy-stub: fast-turn complete\n'   # agy-turn.sh treats an empty AGY_LOG as failure (exit 5)
export TICK_REPO_ROOT="$A"
"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
"$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
printf '\n### Round 1 · %s (fast-stub)\n' "$RELAY_AGENT" >>"$RELAY_FILE"
"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to other >/dev/null 2>&1
exit 0
STUB_EOF
chmod +x "$AGY_FAST_STUB"

# Helper: seed a token handed to the target agent
seed_token() { tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to "$2" >/dev/null; }

# ============================================================================
# Codex shim timeout tests
# ============================================================================
CODEX_SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/codex-turn.sh"

# --- (1) SLOW codex: cap fires -> exit 7 (not hung, not 0) ------------------
seed_token RELAY-TURN-codex-slow codex
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
seed_token RELAY-TURN-codex-fast codex
RELAY_AGENT=codex RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-codex-fast \
  CODEX_AGENT=codex CODEX_BIN="$FAST_STUB" CODEX_TURN_ROOT="$A" CODEX_LOG=/dev/null \
  RELAY_TURN_TIMEOUT_S=1 \
  bash "$CODEX_SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "codex: fast stub under cap -> exit 0 (no false-positive kill)" || fail "codex: fast stub should exit 0, got $rc"

# ============================================================================
# agy shim timeout tests (GH-114: agy-turn.sh is the permanent replacement for
# the deleted gemini-turn.sh — see relay-automation/README.md)
# ============================================================================
AGY_SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/agy-turn.sh"

# --- (3) SLOW agy: cap fires -> exit 7 --------------------------------------
seed_token RELAY-TURN-agy-slow agy
t_start="$(date +%s)"
RELAY_AGENT=agy RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-agy-slow \
  AGY_AGENT=agy AGY_BIN="$AGY_SLOW_STUB" AGY_TURN_ROOT="$A" AGY_LOG=/dev/null \
  RELAY_TURN_TIMEOUT_S=1 \
  bash "$AGY_SHIM" >/dev/null 2>&1; rc=$?
t_end="$(date +%s)"
elapsed=$(( t_end - t_start ))
[ "$rc" -eq 7 ] && pass "agy: timed-out stub -> shim exits 7" || fail "agy: expected exit 7, got $rc"
[ "$elapsed" -lt 5 ] && pass "agy: turn killed fast (${elapsed}s < stub's 5s sleep)" || fail "agy: cap did not fire fast enough (${elapsed}s)"

# --- (4) FAST agy: completes before cap -> exit 0 ----------------------------
# Re-seed token (slow run claimed then timed out; fast-stub token needs its own slot)
seed_token RELAY-TURN-agy-fast agy
RELAY_AGENT=agy RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-agy-fast \
  AGY_AGENT=agy AGY_BIN="$AGY_FAST_STUB" AGY_TURN_ROOT="$A" AGY_LOG="$WORK/agy-fast.log" \
  RELAY_TURN_TIMEOUT_S=1 \
  bash "$AGY_SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "agy: fast stub under cap -> exit 0 (no false-positive kill)" || fail "agy: fast stub should exit 0, got $rc"

# ============================================================================
# Claude shim timeout tests
# ============================================================================
CLAUDE_SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/claude-turn.sh"

# --- (5) SLOW claude: cap fires -> exit 7 ------------------------------------
seed_token RELAY-TURN-claude-slow claude-a
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
seed_token RELAY-TURN-claude-fast claude-a
RELAY_AGENT=claude-a RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-claude-fast \
  CLAUDE_AGENT=claude-a CLAUDE_BIN="$FAST_STUB" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG=/dev/null \
  CLAUDE_BLOCK_CMDS="" \
  RELAY_TURN_TIMEOUT_S=1 \
  bash "$CLAUDE_SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "claude: fast stub under cap -> exit 0 (no false-positive kill)" || fail "claude: fast stub should exit 0, got $rc"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
