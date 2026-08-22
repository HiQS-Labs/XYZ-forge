#!/usr/bin/env bash
# claude-turn.sh test: the Claude turn-taker drives a relay turn behind the SHARED safety
# core (relay-turn-lib.sh) — same containment as codex-turn.sh/gemini-turn.sh, via a STUB
# `claude` that performs the real turn-taker contract (tick + file edit).
source "$(dirname "$0")/_setup.sh" claude-turn
unset ALLOW_PATHS RELAY_FILE RELAY_TASK RELAY_AGENT RELAY_PEER RELAY_WORKTREE_ISOLATION
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
# tryspawn: model the dogfood rogue — try to spawn external models by bare name (PATH-resolved).
# The Phase 3.6 PATH-shadow should make these resolve to a blocking stub, not the real CLI.
if [ "${STUB_MODE:-good}" = tryspawn ]; then
  { gemini --version; echo "gemini_rc=$?"; codex --version; echo "codex_rc=$?"; } > "$WORK/spawn-result" 2>&1
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
grep -q "relay.md" <<<"$(git -C "$A" show --stat HEAD)" && pass "commit touched the relay file" || fail "commit should include relay.md"
grep -q "claude-builder" <<<"$(git -C "$A" log -1 --format='%s')" && pass "commit message includes agent id" || pass "commit created (no agent-id check for builder)"

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
grep -q "ambient.md" <<<"$(git -C "$A" show --stat HEAD)" && fail "commit must NOT include ambient WIP" || pass "commit excludes pre-existing ambient WIP"
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

# --- (7b) Phase 3.6: builder's claude -p cannot spawn external models (PATH-shadow) ---
# Regression for the 2026-06-17 dogfood, where the builder ran `consult` (real Codex+Gemini calls).
rm -f "$WORK/spawn-result"
seed_token RELAY-TURN-spawn
run_shim RELAY-TURN-spawn claude-builder tryspawn
grep -q "blocked:.*off-limits" "$WORK/spawn-result" 2>/dev/null \
  && pass "builder cannot spawn codex/gemini (PATH-shadow blocks them)" \
  || fail "PATH-shadow did not block external-model spawn: $(cat "$WORK/spawn-result" 2>/dev/null)"
# And the shadow must NOT leak into the shim's own env after the turn (scoped to the subprocess).
command -v gemini >/dev/null 2>&1 && real_gem=1 || real_gem=0
[ "$real_gem" -eq 1 ] && { gemini --version >/dev/null 2>&1 && pass "shadow is subprocess-scoped (real gemini still works outside the turn)" || pass "shadow scoped (gemini check inconclusive — ok)"; } || pass "shadow scoped (no real gemini on PATH to check — ok)"

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

filter_claude_from_path() {
  local new_path="" dir
  IFS=: read -ra parts <<< "$PATH"
  for dir in "${parts[@]}"; do
    [[ -n "$dir" ]] || continue
    if [[ ! -x "$dir/claude" ]]; then
      if [[ -z "$new_path" ]]; then
        new_path="$dir"
      else
        new_path="$new_path:$dir"
      fi
    fi
  done
  echo "$new_path"
}

# --- (10) GH-58: discovery + fail-fast when not found -----------------------
seed_token RELAY-TURN-missing
(
  empty_home="$WORK/empty-home"
  mkdir -p "$empty_home"
  err_log="$WORK/missing-err.log"
  
  clean_path="$(filter_claude_from_path)"
  
  PATH="$clean_path" HOME="$empty_home" RELAY_AGENT=claude-builder RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-missing \
    CLAUDE_AGENT=claude-builder CLAUDE_BIN="" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG=/dev/null \
    bash "$SHIM" >"$err_log" 2>&1; rc=$?
    
  [ "$rc" -eq 3 ] && pass "GH-58: missing claude -> exit 3" || fail "expected exit 3, got $rc"
  grep -q "claude CLI not found on PATH; set CLAUDE_BIN or use a codex/agy builder" "$err_log" \
    && pass "GH-58: clear error message printed" || fail "missing or incorrect error message: $(cat "$err_log")"
) || exit 1

# --- (11) GH-58: discovery succeeds with ~/.claude/local/claude ------------
seed_token RELAY-TURN-localpath
(
  local_home="$WORK/local-home"
  mkdir -p "$local_home/.claude/local"
  
  cp "$STUB" "$local_home/.claude/local/claude"
  chmod +x "$local_home/.claude/local/claude"
  
  clean_path="$(filter_claude_from_path)"
  
  PATH="$clean_path" HOME="$local_home" RELAY_AGENT=claude-builder RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-localpath \
    CLAUDE_AGENT=claude-builder CLAUDE_BIN="" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG=/dev/null \
    bash "$SHIM" >/dev/null 2>&1; rc=$?
    
  [ "$rc" -eq 0 ] && pass "GH-58: resolves ~/.claude/local/claude -> exit 0" || fail "expected exit 0, got $rc"
) || exit 1

# --- (12) GH-58: resolves explicitly set CLAUDE_BIN ------------------------
seed_token RELAY-TURN-explicit
(
  RELAY_AGENT=claude-builder RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-explicit \
    CLAUDE_AGENT=claude-builder CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG=/dev/null \
    bash "$SHIM" >/dev/null 2>&1; rc=$?
    
  [ "$rc" -eq 0 ] && pass "GH-58: resolves explicit CLAUDE_BIN -> exit 0" || fail "expected exit 0, got $rc"
) || exit 1

# --- (13) GH-172: vendored/root-split Claude uses the harness tick binary for cost capture -----
printf 'STATUS: Open\n# vendored relay body\n' >"$B/relay-vendored.md"
git -C "$B" add relay-vendored.md >/dev/null 2>&1; git -C "$B" commit -q -m "seed vendored relay" >/dev/null 2>&1
tick_a log task.created RELAY-TURN-vendored --agent dispatcher >/dev/null
tick_a claim RELAY-TURN-vendored --agent dispatcher --paths "relay-vendored.md" >/dev/null
tick_a release RELAY-TURN-vendored --agent dispatcher --to claude-builder >/dev/null
before_b="$(git -C "$B" rev-parse HEAD)"
(
  env -u TICK_BIN RELAY_AGENT=claude-builder RELAY_FILE="$B/relay-vendored.md" RELAY_TASK=RELAY-TURN-vendored \
    CLAUDE_AGENT=claude-builder CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$B" CLAUDE_LOG="$WORK/claude-vendored.json" \
    STUB_MODE=jsonstats TICK_REPO_ROOT="$A" bash "$SHIM" >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 0 ] && pass "GH-172: vendored/root-split Claude turn succeeds without TICK_BIN" || fail "vendored/root-split Claude turn should succeed, got $rc"
) || exit 1
[ "$(git -C "$B" rev-parse HEAD)" != "$before_b" ] && pass "GH-172: vendored/root-split Claude turn still commits the target repo" || fail "vendored/root-split Claude turn should commit in the target repo"
find "$A/.tick/events" -maxdepth 1 -type f -name '*RELAY-TURN-vendored*' -print0 2>/dev/null \
  | xargs -0 grep -l '"type":"cost.tokens".*"task":"RELAY-TURN-vendored".*"tool":"claude"' >/dev/null 2>&1 \
  && pass "GH-172: vendored/root-split Claude cost event lands in the coordination repo .tick" \
  || fail "GH-172: coordination repo .tick missing Claude cost event for vendored/root-split run"

# --- (14) GH-172: Python Claude port refuses an unowned token before any edit ------------------
printf 'STATUS: Open\n# python vendored relay body\n' >"$B/relay-py.md"
git -C "$B" add relay-py.md >/dev/null 2>&1; git -C "$B" commit -q -m "seed python vendored relay" >/dev/null 2>&1
tick_a log task.created RELAY-TURN-py-unowned --agent dispatcher >/dev/null
tick_a claim RELAY-TURN-py-unowned --agent intruder --paths "relay-py.md" >/dev/null
before_b="$(git -C "$B" rev-parse HEAD)"
before_relay_b="$(cksum "$B/relay-py.md")"
(
  env -u TICK_BIN RELAY_AGENT=claude-builder RELAY_FILE="$B/relay-py.md" RELAY_TASK=RELAY-TURN-py-unowned \
    CLAUDE_AGENT=claude-builder CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$B" CLAUDE_LOG="$WORK/claude-py-unowned.json" \
    STUB_MODE=good TICK_REPO_ROOT="$A" XYZ_PYTHON=1 bash "$SHIM" >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 5 ] && pass "GH-172: XYZ_PYTHON=1 Claude turn refuses an unowned token (exit 5)" || fail "python Claude unowned-token guard should exit 5, got $rc"
) || exit 1
[ "$(git -C "$B" rev-parse HEAD)" = "$before_b" ] && pass "GH-172: python Claude guard blocks commits before mutation" || fail "python Claude guard must not commit"
[ "$(cksum "$B/relay-py.md")" = "$before_relay_b" ] && pass "GH-172: python Claude guard leaves the relay file untouched" || fail "python Claude guard should not edit the relay file"

# --- (15) GH-296 follow-up: with CLAUDE_TURN_ROOT unset, claude-turn.py's own pre-launch `tick
# claim --paths` call (claim_paths_for_turn, native Python — NOT bridged through relay-turn-lib.sh's
# already-toplevel-correcting rtl_init/GH-160) computes the claim path via os.path.relpath(relay_file,
# root). Before this fix `root` fell back to XYZ_ROOT (this repo's own top level, __file__-derived)
# instead of the CWD's git toplevel, producing an escaping "../../.../relay.md" claim path instead of
# a clean repo-relative one. Driven with CWD=$A (no CLAUDE_TURN_ROOT override) and forced Python
# runtime; asserts on `tick info`'s recorded paths (a full end-to-end run isn't discriminating here —
# relay-turn-lib.sh's own worktree/containment logic already self-corrects a wrong root, GH-160).
seed_token RELAY-TURN-gh296claude
(
  cd "$A" && env RELAY_AGENT=claude-builder RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-gh296claude \
    CLAUDE_AGENT=claude-builder CLAUDE_BIN="$STUB" CLAUDE_LOG="$WORK/claude-gh296.json" \
    STUB_MODE=good XYZ_PYTHON=1 bash "$SHIM" >/dev/null 2>&1
); rc=$?
[ "$rc" -eq 0 ] && pass "GH-296: Python Claude turn (CLAUDE_TURN_ROOT unset) exits 0" || fail "GH-296: Claude turn should exit 0, got $rc"
# The shim's own PRE-LAUNCH claim (claim_paths_for_turn's real computed value) is the EARLIEST
# claude-builder-claimed event for this task — chronologically before the stub's own claim inside
# the turn — find it by filename (ISO-timestamp-prefixed, sorts correctly) rather than `tick info`'s
# current/post-release state (which shows "(none)" once the token is released).
first_claim_file="$(find "$A/.tick/events" -maxdepth 1 -name '*-claude-builder-claimed-RELAY-TURN-gh296claude.jsonl' 2>/dev/null | sort | head -1)"
claimed_paths="$(cat "$first_claim_file" 2>/dev/null | sed -n 's/.*"paths":\[\([^]]*\)\].*/\1/p')"
case "$claimed_paths" in
  *..*) fail "GH-296: claude-turn.py's claim --paths escaped root (got: $claimed_paths) — root did not resolve to the CWD's git toplevel" ;;
  "") fail "GH-296: no claim event found to assert on — test setup broken" ;;
  *) pass "GH-296: claude-turn.py's claim --paths stayed repo-relative, no root-escaping '..' (got: $claimed_paths)" ;;
esac

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
