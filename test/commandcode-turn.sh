#!/usr/bin/env bash
# commandcode-turn.sh test: Command Code turn-taker drives a relay turn behind the
# shared safety core (relay-turn-lib.sh) via a STUB `cmd`.
source "$(dirname "$0")/_setup.sh" commandcode-turn
export TICK_BIN="$TICK"
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/commandcode-turn.sh"
tick_a init >/dev/null

mkdir -p "$A/bin"; ln -sf "$TICK" "$A/bin/tick"

printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf '.tick/\nbin/\n' >"$A/.gitignore"
git -C "$A" add relay.md .gitignore >/dev/null 2>&1; git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1

STUB="$WORK/cmd"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
printf '%s\n' "$*" > "$WORK/cmd-args" 2>/dev/null || true
export TICK_REPO_ROOT="$A"
if [ "${STUB_MODE:-good}" = fail ]; then
  printf 'commandcode fake failure\n'
  "$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
  "$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
  printf '\n### Round 1 · Reviewer · %s (cmd-stub-fail)\n**Verdict:** Changes requested\n' "$RELAY_AGENT" >>"$RELAY_FILE"
  "$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to claude-a >/dev/null 2>&1
  exit 1
fi
if [ "${STUB_MODE:-good}" = empty ]; then
  exit 0
fi
if [ "${STUB_MODE:-good}" != notick ]; then
  "$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
  "$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
fi
printf 'commandcode output for %s\n' "$RELAY_AGENT"
printf '\n### Round 1 · Reviewer · %s (cmd-stub)\n**Verdict:** Changes requested\n' "$RELAY_AGENT" >>"$RELAY_FILE"
if [ "${STUB_MODE:-good}" != notick ]; then
  "$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to claude-a >/dev/null 2>&1
fi
[ "${STUB_MODE:-good}" = slowafterrelease ] && sleep "${STUB_SLEEP_S:-2}"
[ "${STUB_MODE:-good}" = bad ] && printf 'off-lane\n' >>"$A/offlane.md"
if [ "${STUB_MODE:-good}" = commitbypass ]; then
  printf 'sneaky\n' >>"$A/sneaky.md"
  git -C "$A" add sneaky.md >/dev/null 2>&1
  git -C "$A" commit -q -m "cmd sneaked a commit" >/dev/null 2>&1
fi
exit 0
STUB_EOF
chmod +x "$STUB"

seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to commandcode >/dev/null; }
tok_field(){ tick_a info "$1" 2>/dev/null | sed -n "s/^$2:[[:space:]]*//p" | head -1; }

run_shim(){ # <relay-task> <agent> <stub-mode> [extra env assignments...]
  local task="$1" agent="$2" mode="$3"; shift 3
  local log="$WORK/cmd-log-$task.log"; : >"$log"
  env RELAY_AGENT="$agent" RELAY_FILE="$A/relay.md" RELAY_TASK="$task" COMMANDCODE_AGENT=commandcode \
    COMMANDCODE_BIN="$STUB" COMMANDCODE_TURN_ROOT="$A" COMMANDCODE_LOG="$log" STUB_MODE="$mode" "$@" \
    bash "$SHIM" >/dev/null 2>&1
}

# --- (1) defer: non-Commandcode actor -> no-op, no commit ----------------------
seed_token RELAY-TURN-defer
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-defer claude-a good; rc=$?
[ "$rc" -eq 0 ] && [ "$(git -C "$A" rev-parse HEAD)" = "$before" ] \
  && pass "non-Commandcode actor -> shim defers, no commit" || fail "should defer with no commit (rc=$rc)"

# --- (2) good turn: only relay file changes -> committed, no push, token handoff ---
seed_token RELAY-TURN-good
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-good commandcode good RELAY_PEER=claude-a; rc=$?
[ "$rc" -eq 0 ] && pass "Commandcode turn (good) exits 0" || fail "good turn rc=$rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "Commandcode turn committed (file-scoped)" || fail "expected a commit"
git -C "$A" show --stat HEAD | grep -q "relay.md" && pass "commit touched the relay file" || fail "commit should include relay.md"
[ "$(tok_field RELAY-TURN-good status)" = "open" ] && [ "$(tok_field RELAY-TURN-good handoff-to)" = "claude-a" ] \
  && pass "good turn handed token to peer" || fail "token not handed off: status=$(tok_field RELAY-TURN-good status) handoff=$(tok_field RELAY-TURN-good handoff-to)"
grep -q -- "--no-session" "$WORK/cmd-args" && pass "default COMMANDCODE_FLAGS reaches cmd" || fail "default flags missing"
grep -q -- "--model" "$WORK/cmd-args" && grep -q -- "meta/muse-spark-1.2-contributor" "$WORK/cmd-args" && pass "default COMMANDCODE_MODEL reaches cmd" || fail "model flag missing"
grep -q -- "--print" "$WORK/cmd-args" && pass "--print flag reaches cmd" || fail "--print missing"

# --- (2b) Python-only entry point ignores an old global Bash opt-out ---------------
seed_token RELAY-TURN-python-entry
run_shim RELAY-TURN-python-entry commandcode good RELAY_PEER=claude-a XYZ_PYTHON=0; rc=$?
[ "$rc" -eq 0 ] && pass "Commandcode entry point remains Python-authoritative when XYZ_PYTHON=0" \
  || fail "XYZ_PYTHON=0 should not disable the new Python-only shim (rc=$rc)"

# --- (3) failed CLI: non-zero exit -> shim fails (exit 5) ----------------------
seed_token RELAY-TURN-fail
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-fail commandcode fail; rc=$?
[ "$rc" -eq 5 ] && pass "failed CLI -> shim fails (exit 5)" || fail "failed CLI should exit 5, got $rc"

# --- (4) empty CLI output: exit 0 but no transcript -> shim fails (exit 5) ---
seed_token RELAY-TURN-empty
git -C "$A" add -A >/dev/null 2>&1; git -C "$A" commit -q -m "flush dirty" >/dev/null 2>&1 || true
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-empty commandcode empty; rc=$?
[ "$rc" -eq 5 ] && pass "empty CLI output -> shim fails (exit 5)" || fail "empty output should exit 5, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on empty turn" || fail "empty turn must not commit"

# --- (5) timeout: killed at wall-clock cap -> exit 7, but still committed/handed off ---
seed_token RELAY-TURN-timeout
before="$(git -C "$A" rev-parse HEAD)"
RELAY_TURN_TIMEOUT_S=1 run_shim RELAY-TURN-timeout commandcode slowafterrelease RELAY_PEER=claude-a; rc=$?
[ "$rc" -eq 7 ] && pass "turn killed at RELAY_TURN_TIMEOUT_S exits 7" || fail "timeout should exit 7, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "timeout can still commit before exit 7" || fail "timeout should still commit"

# --- (6) off-allowlist edit -> reverted + fail (exit 6) -----------------------
seed_token RELAY-TURN-bad
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-bad commandcode bad; rc=$?
[ "$rc" -eq 6 ] && pass "off-allowlist edit -> shim fails (exit 6)" || fail "expected exit 6, got $rc"
[ ! -f "$A/offlane.md" ] && pass "off-lane file was reverted/removed" || fail "off-lane file should be gone"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on violating turn" || fail "should not commit on violation"

# --- (7) default timeout is 900s ------------------------------------------------
grep -q 'RELAY_TURN_TIMEOUT_S:-900' "$SHIM" 2>/dev/null || grep -q 'RELAY_TURN_TIMEOUT_S", 900' "$(cd "$(dirname "$0")/.." && pwd)/utils/py/commandcode-turn.py" \
  && pass "default RELAY_TURN_TIMEOUT_S is 900s" || fail "expected 900s default"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
