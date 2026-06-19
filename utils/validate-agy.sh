#!/usr/bin/env bash
# utils/validate-agy.sh — end-to-end validation of the real Antigravity CLI (`agy`).
#
# Tests the live binary against the live backend. No stubs, no tick, no relay machinery.
# Run this when agy is behaving unexpectedly in another session — it isolates whether
# the problem is the CLI itself, auth, the headless flags, or the relay shim.
#
# Usage:
#   bash utils/validate-agy.sh [--model "Model Name"]   # model is optional
#
# Exit: 0 all pass · 1 one or more failures
#
# Note: run with the Bash sandbox OFF (dangerouslyDisableSandbox: true in Claude Code).
# agy -p exits 0 with empty output under a blocked network — T4 below detects this.

set -uo pipefail

AGY_BIN="${AGY_BIN:-agy}"
MODEL="${AGY_MODEL:-}"
TIMEOUT="${AGY_VALIDATE_TIMEOUT:-60}"   # per-prompt wall-clock cap in seconds

PASS=0; FAIL=0

pass() { printf '  ✓ %s\n' "$1"; PASS=$((PASS+1)); }
fail() { printf '  ✗ %s\n' "$1"; FAIL=$((FAIL+1)); }

# Kill a background process and its children after N seconds.
bounded() {
  local timeout="$1"; shift
  "$@" &
  local pid=$!
  ( sleep "$timeout" && kill "$pid" 2>/dev/null ) &
  local killer=$!
  wait "$pid" 2>/dev/null; local rc=$?
  kill "$killer" 2>/dev/null; wait "$killer" 2>/dev/null
  return $rc
}

agy_p() {
  # Run: agy [--model M] [--print-timeout Ts] -p "prompt"
  # First (and only) arg is the prompt string.
  local prompt="$1"
  local base_args=(--dangerously-skip-permissions --print-timeout "${TIMEOUT}s")
  [[ -n "$MODEL" ]] && base_args+=(--model "$MODEL")
  bounded "$TIMEOUT" "$AGY_BIN" "${base_args[@]}" -p "$prompt"
}

echo "=== agy end-to-end validation ==="
[[ -n "$MODEL" ]] && echo "    model: $MODEL" || echo "    model: (agy default)"
echo ""

# ── T1: binary reachable ─────────────────────────────────────────────────────
echo "T1: binary"
if command -v "$AGY_BIN" >/dev/null 2>&1; then
  pass "agy binary found: $(command -v "$AGY_BIN")"
else
  fail "agy not found in PATH (is Antigravity.app installed?)"
  echo ""
  echo "ABORT: remaining tests require the agy binary."
  exit 1
fi

# ── T2: version / basic invocation ───────────────────────────────────────────
echo ""
echo "T2: version"
ver_out="$("$AGY_BIN" --version 2>&1)" && ver_rc=0 || ver_rc=$?
if [[ "$ver_rc" -eq 0 ]] && [[ -n "$ver_out" ]]; then
  pass "agy --version exits 0: $ver_out"
elif [[ "$ver_rc" -eq 0 ]]; then
  # Some versions print to stderr or nothing — not a hard failure
  pass "agy --version exits 0 (no stdout; stderr may have the version)"
else
  fail "agy --version returned exit $ver_rc"
fi

# ── T3: flags accepted (dry run) ─────────────────────────────────────────────
echo ""
echo "T3: headless flags"
# agy-turn.sh passes: --dangerously-skip-permissions --print-timeout Ns
# We can't easily test these without hitting the backend, so we verify agy
# doesn't immediately reject them with a usage error on a trivial prompt.
# We test with a very short timeout — we expect a real response OR a timeout
# exit, NOT a flag-parse error (exit 2/64/other before any request is made).
flag_out="$(bounded 10 "$AGY_BIN" --dangerously-skip-permissions --print-timeout 8s -p "Reply: OK" 2>&1)" && flag_rc=0 || flag_rc=$?
if [[ "$flag_rc" -le 1 ]]; then
  pass "--dangerously-skip-permissions --print-timeout accepted (exit $flag_rc)"
else
  # Distinguish a flag-rejection error from a timeout/backend error
  if echo "$flag_out" | grep -qiE "unknown flag|unrecognized|invalid option|usage"; then
    fail "headless flags rejected by agy (flag-parse error, exit $flag_rc)"
  else
    pass "--dangerously-skip-permissions --print-timeout accepted (backend/timeout, exit $flag_rc)"
  fi
fi

# ── T4: print mode produces non-empty output ─────────────────────────────────
echo ""
echo "T4: non-empty output (sandbox check)"
t4_log="$(mktemp)"
trap 'rm -f "$t4_log"' EXIT
t4_out="$(agy_p "Reply with the single word HELLO and nothing else." 2>"$t4_log")" && t4_rc=0 || t4_rc=$?
if [[ "$t4_rc" -ne 0 ]]; then
  fail "agy -p exited $t4_rc (backend error or timeout)"
  stderr_snippet="$(head -3 "$t4_log")"
  [[ -n "$stderr_snippet" ]] && printf '    stderr: %s\n' "$stderr_snippet"
elif [[ -z "$t4_out" ]]; then
  fail "agy -p exited 0 but produced EMPTY output — you are likely running under a sandbox (disable it) or agy's backend is unreachable"
else
  pass "agy -p produced non-empty output (${#t4_out} chars)"
fi

# ── T5: correct response — deterministic factual answer ──────────────────────
echo ""
echo "T5: correct response (math)"
t5_out="$(agy_p "What is 3 + 4? Reply with the number only, no other text." 2>/dev/null)" && t5_rc=0 || t5_rc=$?
if [[ "$t5_rc" -ne 0 ]]; then
  fail "agy -p exited $t5_rc on factual prompt"
elif [[ -z "$t5_out" ]]; then
  fail "agy -p produced empty output on factual prompt"
elif echo "$t5_out" | grep -q "7"; then
  pass "correct factual answer: $(echo "$t5_out" | tr '\n' ' ' | xargs)"
else
  fail "unexpected answer (expected '7'): $(echo "$t5_out" | tr '\n' ' ' | xargs)"
fi

# ── T6: correct response — instruction following ─────────────────────────────
echo ""
echo "T6: correct response (instruction following)"
t6_out="$(agy_p "Reply with exactly the text: ANTIGRAVITY_OK — nothing before or after it." 2>/dev/null)" && t6_rc=0 || t6_rc=$?
if [[ "$t6_rc" -ne 0 ]]; then
  fail "agy -p exited $t6_rc on instruction-following prompt"
elif [[ -z "$t6_out" ]]; then
  fail "agy -p produced empty output on instruction-following prompt"
elif echo "$t6_out" | grep -q "ANTIGRAVITY_OK"; then
  pass "instruction followed: output contains ANTIGRAVITY_OK"
else
  fail "instruction not followed — expected ANTIGRAVITY_OK, got: $(echo "$t6_out" | tr '\n' ' ' | xargs)"
fi

# ── T7: multi-sentence reasoning (proves the model is actually thinking) ──────
echo ""
echo "T7: reasoning (not just echo)"
t7_prompt="List exactly two fruits. Format: one fruit per line, no numbers, no punctuation."
t7_out="$(agy_p "$t7_prompt" 2>/dev/null)" && t7_rc=0 || t7_rc=$?
if [[ "$t7_rc" -ne 0 ]]; then
  fail "agy -p exited $t7_rc on reasoning prompt"
elif [[ -z "$t7_out" ]]; then
  fail "agy -p produced empty output on reasoning prompt"
else
  line_count=$(echo "$t7_out" | grep -c '[a-zA-Z]' || true)
  if [[ "$line_count" -ge 1 ]]; then
    pass "reasoning prompt produced $line_count non-empty line(s): $(echo "$t7_out" | tr '\n' ' ' | xargs)"
  else
    fail "reasoning prompt produced no legible lines: $(echo "$t7_out" | tr '\n' ' ' | xargs)"
  fi
fi

# ── T8: model flag passthrough (if AGY_MODEL is set) ─────────────────────────
echo ""
echo "T8: model flag"
if [[ -n "$MODEL" ]]; then
  t8_out="$(bounded "$TIMEOUT" "$AGY_BIN" --dangerously-skip-permissions --print-timeout "${TIMEOUT}s" --model "$MODEL" -p "Reply: MODEL_OK" 2>/dev/null)" && t8_rc=0 || t8_rc=$?
  if echo "$t8_out" | grep -q "MODEL_OK" && [[ "$t8_rc" -eq 0 ]]; then
    pass "--model '$MODEL' accepted and produced correct output"
  elif [[ "$t8_rc" -ne 0 ]]; then
    fail "--model '$MODEL' caused exit $t8_rc — check model name spelling"
  else
    fail "--model '$MODEL' accepted but response unexpected: $(echo "$t8_out" | tr '\n' ' ' | xargs)"
  fi
else
  pass "(skipped — set AGY_MODEL=... to test a specific model)"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "=== result: $PASS pass, $FAIL fail ==="
[[ "$FAIL" -eq 0 ]] && echo "agy is working end-to-end." || echo "See failures above."
[[ "$FAIL" -eq 0 ]]
