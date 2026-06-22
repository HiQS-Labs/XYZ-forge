#!/usr/bin/env bash
# test/relay-target-root.sh — test that --target-root routes the worktree, allowlist, and commits to a foreign repo
source "$(dirname "$0")/_setup.sh" relay-target-root

export TICK_BIN="$TICK"
DRIVE="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-drive.sh"
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/claude-turn.sh"

# Initialize tick in the harness repo (coordination root $A)
tick_a init >/dev/null

# Prepare the foreign repository ($B)
# We must have some commits in $B so HEAD can be checked out and git worktree add works.
# In B: we need relay.md and artifact.txt
printf 'STATUS: Open\n# relay body\n' >"$B/relay.md"
printf 'seed\n' >"$B/artifact.txt"
git -C "$B" add relay.md artifact.txt >/dev/null 2>&1
git -C "$B" commit -q -m "seed B" >/dev/null 2>&1

# Prepare the harness repository ($A)
# (Note: $A is the default harness repo root)
printf 'STATUS: Open\n# relay body in A\n' >"$A/relay.md"
printf 'seed in A\n' >"$A/artifact.txt"
git -C "$A" add relay.md artifact.txt >/dev/null 2>&1
git -C "$A" commit -q -m "seed A" >/dev/null 2>&1

# Stub agent (CLAUDE_BIN) that performs turn changes.
# Under worktree isolation, its CWD is the throwaway worktree of the target repo.
# It claims the token, edits the allowlisted files, and releases the token.
STUB="$WORK/agent-stub.sh"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
# Coordination database is in $A
export TICK_REPO_ROOT="$A"

# Perform tick claims
"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "artifact.txt" >/dev/null 2>&1
"$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1

# Make changes relative to CWD
printf 'edited by agent\n' >> artifact.txt
printf '\n### Round 1 · Agent\n' >> relay.md

# Release token to finish turn
"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to reviewer >/dev/null 2>&1

printf '{"usage":{"input_tokens":1,"output_tokens":1},"total_cost_usd":0}\n'
exit 0
STUB_EOF
chmod +x "$STUB"

# Helper to seed token in harness repo ($A)
seed_token() { # <task>
  tick_a log task.created "$1" --agent claude --paths "artifact.txt" >/dev/null
  tick_a claim "$1" --agent dispatcher --paths "artifact.txt" >/dev/null 2>&1
  tick_a release "$1" --agent dispatcher --to claude >/dev/null 2>&1
}

# --- Test case 1: --target-root B is passed (foreign repo) ---
# Worktree isolation ON.
seed_token RELAY-TURN-foreign

# We run relay-drive.sh, pointing to $B as the target root.
# We expect the changes to be made and committed in $B, while $A remains untouched.
B_BEFORE="$(git -C "$B" rev-parse HEAD)"
A_BEFORE="$(git -C "$A" rev-parse HEAD)"

# Command to invoke the turn-taker:
# Note: CLAUDE_TURN_ROOT defaults to $1 in rtl_init, but we pass $A (harness) to the shim.
# Because RELAY_TARGET_ROOT is exported, it should override RTL_ROOT to $B inside the shim.
# The shim will run the stub inside the worktree of $B.
AGENT_CMD="RELAY_AGENT=claude RELAY_FILE=\"\$RELAY_TARGET_ROOT/relay.md\" RELAY_TASK=RELAY-TURN-foreign \
  CLAUDE_AGENT=claude CLAUDE_BIN=\"$STUB\" CLAUDE_TURN_ROOT=\"$A\" CLAUDE_LOG=\"$WORK/c.log\" \
  ALLOW_PATHS=\"artifact.txt\" CLAUDE_BLOCK_CMDS=\"\" RELAY_WORKTREE_ISOLATION=1 \
  bash \"$SHIM\""

bash "$DRIVE" --relay-file "$B/relay.md" --relay-task RELAY-TURN-foreign \
  --target-root "$B" --agent-cmd "$AGENT_CMD" --round-cap 1 >/dev/null 2>&1

# Assertions:
# 1. $B must have a new commit.
[ "$(git -C "$B" rev-parse HEAD)" != "$B_BEFORE" ] && pass "foreign repo target: commit created in foreign repo B" || fail "no commit in foreign repo B"

# 2. $A must NOT have a new commit.
[ "$(git -C "$A" rev-parse HEAD)" = "$A_BEFORE" ] && pass "foreign repo target: harness repo A untouched" || fail "harness repo A was modified"

# 3. $B/artifact.txt must contain the edit.
grep -q "edited by agent" "$B/artifact.txt" && pass "foreign repo target: artifact edited in B" || fail "artifact not edited in B"

# 4. $A/artifact.txt must NOT contain the edit.
! grep -q "edited by agent" "$A/artifact.txt" && pass "foreign repo target: artifact in A untouched" || fail "artifact was edited in A"

# --- Test case 2: Default unchanged (no --target-root) ---
# Worktree isolation ON.
seed_token RELAY-TURN-default

B_BEFORE="$(git -C "$B" rev-parse HEAD)"
A_BEFORE="$(git -C "$A" rev-parse HEAD)"

AGENT_CMD_DEFAULT="RELAY_AGENT=claude RELAY_FILE=\"$A/relay.md\" RELAY_TASK=RELAY-TURN-default \
  CLAUDE_AGENT=claude CLAUDE_BIN=\"$STUB\" CLAUDE_TURN_ROOT=\"$A\" CLAUDE_LOG=\"$WORK/c-default.log\" \
  ALLOW_PATHS=\"artifact.txt\" CLAUDE_BLOCK_CMDS=\"\" RELAY_WORKTREE_ISOLATION=1 \
  bash \"$SHIM\""

bash "$DRIVE" --relay-file "$A/relay.md" --relay-task RELAY-TURN-default \
  --agent-cmd "$AGENT_CMD_DEFAULT" --round-cap 1 >/dev/null 2>&1

# Assertions:
# 1. $A must have a new commit.
[ "$(git -C "$A" rev-parse HEAD)" != "$A_BEFORE" ] && pass "default path: commit created in harness repo A" || fail "no commit in harness repo A"

# 2. $B must NOT have a new commit.
[ "$(git -C "$B" rev-parse HEAD)" = "$B_BEFORE" ] && pass "default path: foreign repo B untouched" || fail "foreign repo B was modified"

# 3. $A/artifact.txt must contain the edit.
grep -q "edited by agent" "$A/artifact.txt" && pass "default path: artifact edited in A" || fail "artifact not edited in A"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
