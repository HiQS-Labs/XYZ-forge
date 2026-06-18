#!/usr/bin/env bash
# claude-turn.sh test: the Claude turn-taker drives a relay turn behind the SHARED safety
# core (relay-turn-lib.sh) — same containment as codex-turn.sh/gemini-turn.sh, via a STUB
# `claude` that performs the real turn-taker contract (tick + file edit).
source "$(dirname "$0")/_setup.sh" claude-turn
export TICK_BIN="$TICK"
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/claude-turn.sh"
tick_a init >/dev/null

# committed relay-file baseline; mirror the real repo's .tick/ gitignore (invisible to git status).
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf '.tick/\n' >"$A/.gitignore"
git -C "$A" add relay.md .gitignore >/dev/null 2>&1; git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1

# Stub `claude`: ignores its flags (-p <prompt> --allowedTools … --output-format json …);
# performs a real turn as $RELAY_AGENT — claim/ping the token, append a block, release.
# Records argv to $WORK/claude-args for flag assertions.
# STUB_MODE=bad          → off-allowlist file write
# STUB_MODE=commitbypass → agent commits off-lane change (hides from git status)
# STUB_MODE=spacefile    → off-lane path containing a space
# STUB_MODE=renamestage  → staged rename of a tracked off-lane file
# STUB_MODE=jsonstats    → writes a minimal JSON stats block to stdout (cost capture path)
STUB="$WORK/claude"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
printf '%s\n' "$*" > "$WORK/claude-args" 2>/dev/null || true
export TICK_REPO_ROOT="$A"
"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
"$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
printf '\n### Round 1 · Builder · %s (claude-stub)\n**Verdict:** Changes requested\n' "$RELAY_AGENT" >>"$RELAY_FILE"
"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to gemini >/dev/null 2>&1
[ "${STUB_MODE:-good}" = bad ] && printf 'off-lane\n' >>"$A/offlane.md"
if [ "${STUB_MODE:-good}" = commitbypass ]; then
  printf 'sneaky\n' >>"$A/sneaky.md"
  git -C "$A" add sneaky.md >/dev/null 2>&1
  git -C "$A" commit -q -m "claude sneaked a commit" >/dev/null 2>&1
fi
[ "${STUB_MODE:-good}" = spacefile ]    && printf 'off-lane\n' >>"$A/off lane.md"
[ "${STUB_MODE:-good}" = renamestage ]  && git -C "$A" mv rtarget.txt rmoved.txt >/dev/null 2>&1
# jsonstats: emit a parseable JSON block so the cost-capture path in the shim is exercised
if [ "${STUB_MODE:-good}" = jsonstats ]; then
  printf '{"type":"result","usage":{"input_tokens":1234,"cache_read_input_tokens":0,"output_tokens":56},"total_cost_usd":0.012}\n'
fi
exit 0
STUB_EOF
chmod +x "$STUB"

seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to claude-builder >/dev/null; }

run_shim(){ # <relay-task> <agent> <stub-mode>
  RELAY_AGENT="$2" RELAY_FILE="$A/relay.md" RELAY_TASK="$1" CLAUDE_AGENT=claude-builder \
  CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG=/dev/null STUB_MODE="$3" \
  bash "$SHIM" >/dev/null 2>&1
}

# --- (1) defer: non-Claude actor -> no-op, no commit ----------------------
seed_token RELAY-TURN-defer
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-defer gemini good; rc=$?
[ "$rc" -eq 0 ] && [ "$(git -C "$A" rev-parse HEAD)" = "$before" ] \
  && pass "non-Claude actor -> shim defers, no commit" || fail "should defer with no commit (rc=$rc)"

# --- (2) good turn: only relay file changes -> committed, no push --------
seed_token RELAY-TURN-good
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-good claude-builder good; rc=$?
[ "$rc" -eq 0 ] && pass "Claude turn (good) exits 0" || fail "good turn rc=$rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "Claude turn committed (file-scoped)" || fail "expected a commit"
git -C "$A" show --stat HEAD | grep -q "relay.md" && pass "commit touched the relay file" || fail "commit should include relay.md"
git -C "$A" log -1 --format='%s' | grep -q "claude-builder" && pass "commit message includes agent id" || pass "commit created (no agent-id check for builder)"

# --- (2b) shim's own transcript log inside the tree is ignored, not flagged --
seed_token RELAY-TURN-log
before="$(git -C "$A" rev-parse HEAD)"
RELAY_AGENT=claude-builder RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-log CLAUDE_AGENT=claude-builder \
  CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG="$A/claude.log" STUB_MODE=good \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "CLAUDE_LOG inside the tree is ignored (turn still succeeds)" || fail "log-in-tree should not fail the turn (rc=$rc)"
[ ! -f "$A/claude.log" ] && pass "transcript log cleaned up (not committed)" || fail "log should be removed"

# --- (3) allowlist violation: off-lane edit -> reverted + fail (exit 6) --
seed_token RELAY-TURN-bad
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-bad claude-builder bad; rc=$?
[ "$rc" -eq 6 ] && pass "off-allowlist edit -> shim fails (exit 6)" || fail "expected exit 6, got $rc"
[ ! -f "$A/offlane.md" ] && pass "off-lane file was reverted/removed" || fail "off-lane file should be gone"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on a violating turn" || fail "should not commit on violation"

# --- (4) commit-bypass: Claude commits off-lane -> reset + fail -----------
seed_token RELAY-TURN-bypass
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-bypass claude-builder commitbypass; rc=$?
[ "$rc" -eq 6 ] && pass "Claude commit during turn -> shim fails (exit 6)" || fail "commit-bypass should exit 6, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "sneaked commit reset to BEFORE_HEAD" || fail "HEAD should be reset to before"
[ ! -f "$A/sneaky.md" ] && pass "off-lane committed file removed by reset" || fail "sneaky.md should be gone"

# --- (5) quoted path: off-lane file with a space -> reverted + fail -------
seed_token RELAY-TURN-space
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-space claude-builder spacefile; rc=$?
[ "$rc" -eq 6 ] && pass "off-lane path with space -> shim fails (exit 6)" || fail "spacefile should exit 6, got $rc"
[ ! -f "$A/off lane.md" ] && pass "spaced off-lane file reverted (-z parsing)" || fail "'off lane.md' should be removed"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on spaced-path violation" || fail "should not commit"

# --- (6) pre-existing dirty file is NOT reverted; turn still succeeds -----
seed_token RELAY-TURN-ambient
printf 'unrelated WIP\n' > "$A/ambient.md"
run_shim RELAY-TURN-ambient claude-builder good; rc=$?
[ "$rc" -eq 0 ] && pass "pre-existing dirty file -> turn still succeeds" || fail "ambient WIP must not fail the turn (rc=$rc)"
[ -f "$A/ambient.md" ] && pass "pre-existing ambient WIP left untouched (not reverted)" || fail "ambient.md was destroyed (regression!)"
git -C "$A" show --stat HEAD | grep -q "ambient.md" && fail "commit must NOT include ambient WIP" || pass "commit excludes pre-existing ambient WIP"
rm -f "$A/ambient.md"

# --- (7) flag check: builder allowlist flags reach the claude stub ---------
seed_token RELAY-TURN-flags
RELAY_AGENT=claude-builder RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-flags CLAUDE_AGENT=claude-builder \
  CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG=/dev/null STUB_MODE=good \
  bash "$SHIM" >/dev/null 2>&1
grep -q -- "--allowedTools" "$WORK/claude-args" && pass "builder --allowedTools flag passed to claude" || fail "--allowedTools missing from invocation"
grep -q -- "--output-format" "$WORK/claude-args" && pass "--output-format flag passed to claude" || fail "--output-format missing from invocation"
grep -q -- "--permission-mode" "$WORK/claude-args" && pass "--permission-mode flag passed to claude" || fail "--permission-mode missing from invocation"
grep -q "Edit" "$WORK/claude-args" && pass "Edit tool in builder allowlist" || fail "Edit must be in builder allowlist"
grep -q "Write" "$WORK/claude-args" && pass "Write tool in builder allowlist" || fail "Write must be in builder allowlist"
# Model pin: headless turn must pass --model (else it inherits the operator's ambient model and
# the budget cap — sized for the pinned model — is meaningless). Regression for the 06-18 Opus run.
grep -q -- "--model" "$WORK/claude-args" && pass "builder pins --model (cost determinism)" || fail "--model missing — headless turn would inherit ambient model"

# --- (8) rename-hijack: staged rename (off-lane) is enforced ---------------
printf 'tracked off-lane\n' > "$A/rtarget.txt"; git -C "$A" add rtarget.txt >/dev/null 2>&1; git -C "$A" commit -q -m "seed rename target" >/dev/null 2>&1
seed_token RELAY-TURN-rename
run_shim RELAY-TURN-rename claude-builder renamestage; rc=$?
[ "$rc" -eq 6 ] && pass "staged rename (off-lane) enforced, not skipped as pre-existing" || fail "rename-hijack must fail (exit 6), got $rc"
git -C "$A" reset --hard HEAD >/dev/null 2>&1

# --- (9) .tick exemption independent of host .gitignore --------------------
printf '# host repo does NOT gitignore .tick\n' > "$A/.gitignore"
git -C "$A" add .gitignore >/dev/null 2>&1; git -C "$A" commit -q -m "drop .tick gitignore" >/dev/null 2>&1
seed_token RELAY-TURN-tickexempt
run_shim RELAY-TURN-tickexempt claude-builder good; rc=$?
[ "$rc" -eq 0 ] && pass ".tick writes exempted when host doesn't gitignore .tick (turn succeeds)" || fail "unignored .tick must not fail the turn (rc=$rc)"
[ -d "$A/.tick" ] && pass ".tick state dir preserved (not rm-rf'd)" || fail ".tick was destroyed"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
