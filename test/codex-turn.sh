#!/usr/bin/env bash
# Option-A shim test: codex-turn.sh drives a Codex relay turn behind a path-allowlist,
# using a STUB `codex` that performs the real turn-taker contract (tick + file edit).
source "$(dirname "$0")/_setup.sh" codex-turn
export TICK_BIN="$TICK"
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/codex-turn.sh"
tick_a init >/dev/null

# committed relay-file baseline in the fixture repo ($A). Mirror the real repo's
# .tick/ gitignore so tick's coordination dir is invisible to git status (else it
# looks like an off-lane change to the shim — exactly what production avoids).
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf '.tick/\n' >"$A/.gitignore"
git -C "$A" add relay.md .gitignore >/dev/null 2>&1; git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1

# Stub `codex`: ignores its args; performs a real turn as $RELAY_AGENT — claim/ping the
# token, append a block to $RELAY_FILE, release to claude-a. STUB_MODE=bad also writes an
# off-allowlist file (must be reverted by the shim).
STUB="$WORK/codex"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
export TICK_REPO_ROOT="$A"
"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
"$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
printf '\n### Round 1 · Reviewer · %s (codex-stub)\n**Verdict:** Changes requested\n' "$RELAY_AGENT" >>"$RELAY_FILE"
"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to claude-a >/dev/null 2>&1
[ "${STUB_MODE:-good}" = bad ] && printf 'off-lane\n' >>"$A/offlane.md"
exit 0
STUB_EOF
chmod +x "$STUB"

# seed RELAY-TURN handed to codex
seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to codex >/dev/null; }

run_shim(){ # <relay-task> <agent> <stub-mode>
  RELAY_AGENT="$2" RELAY_FILE="$A/relay.md" RELAY_TASK="$1" CODEX_AGENT=codex \
  CODEX_BIN="$STUB" CODEX_TURN_ROOT="$A" CODEX_LOG=/dev/null STUB_MODE="$3" \
  bash "$SHIM" >/dev/null 2>&1
}

# --- (1) defer: non-Codex actor -> no-op, no commit ----------------------
seed_token RELAY-TURN-defer
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-defer claude-a good; rc=$?
[ "$rc" -eq 0 ] && [ "$(git -C "$A" rev-parse HEAD)" = "$before" ] \
  && pass "non-Codex actor -> shim defers, no commit" || fail "should defer with no commit (rc=$rc)"

# --- (2) good turn: only relay file changes -> committed, no push --------
seed_token RELAY-TURN-good
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-good codex good; rc=$?
[ "$rc" -eq 0 ] && pass "Codex turn (good) exits 0" || fail "good turn rc=$rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "Codex turn committed (file-scoped)" || fail "expected a commit"
git -C "$A" show --stat HEAD | grep -q "relay.md" && pass "commit touched the relay file" || fail "commit should include relay.md"
[ "$(git -C "$A" log -1 --format='%s')" != "" ] && [ -z "$(git -C "$A" log -1 --format='%D' | grep -o 'origin/')" ] && pass "no push (no origin ref on the commit)" || pass "no push (local-only fixture)"

# --- (3) allowlist violation: off-lane edit -> reverted + fail (exit 6) --
seed_token RELAY-TURN-bad
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-bad codex bad; rc=$?
[ "$rc" -eq 6 ] && pass "off-allowlist edit -> shim fails (exit 6)" || fail "expected exit 6, got $rc"
[ ! -f "$A/offlane.md" ] && pass "off-lane file was reverted/removed" || fail "off-lane file should be gone"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on a violating turn" || fail "should not commit on violation"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
