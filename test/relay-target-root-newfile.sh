#!/usr/bin/env bash
# test/relay-target-root-newfile.sh — GH-29 regression: a cross-repo (--target-root) builder turn that
# CREATES new untracked files (the common case for new detectors/modules) must COMMIT them, not report
# "no tracked changes". The original bug batched `git add -- a b c`: one allowlist entry the turn never
# created (a path it was PERMITTED but didn't write) made the whole add abort and stage NOTHING — so even
# the modified tracked files were dropped. The fix stages each allowlisted path independently with `-A`.
source "$(dirname "$0")/_setup.sh" relay-target-root-newfile

export TICK_BIN="$TICK"
DRIVE="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-drive.sh"
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/claude-turn.sh"

# Coordination root = harness repo $A.
tick_a init >/dev/null

# Foreign target repo $B: seed relay.md + an existing tracked file the turn will MODIFY.
printf 'STATUS: Open\n# relay body\n' >"$B/relay.md"
printf 'seed\n' >"$B/existing.txt"
git -C "$B" add relay.md existing.txt >/dev/null 2>&1
git -C "$B" commit -q -m "seed B" >/dev/null 2>&1

# Stub builder. Under worktree isolation its CWD is the throwaway worktree of $B.
# It (a) MODIFIES the tracked existing.txt, (b) CREATES the new untracked newfile.txt, and crucially
# (c) NEVER writes never-created.txt — even though that path is on the allowlist. Pre-fix, (c) made the
# batched `git add` abort and nothing committed.
STUB="$WORK/agent-stub.sh"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
export TICK_REPO_ROOT="$A"
"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "existing.txt,newfile.txt" >/dev/null 2>&1
"$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
printf 'modified by builder\n' >> existing.txt        # tracked file change
printf 'brand new detector\n'  >  newfile.txt         # NEW untracked allowlisted file
printf '\n### Round 1 · Builder\n' >> relay.md
"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to reviewer >/dev/null 2>&1
printf '{"usage":{"input_tokens":1,"output_tokens":1},"total_cost_usd":0}\n'
exit 0
STUB_EOF
chmod +x "$STUB"

seed_token() { # <task>
  tick_a log task.created "$1" --agent claude --paths "existing.txt,newfile.txt" >/dev/null
  tick_a claim "$1" --agent dispatcher --paths "existing.txt,newfile.txt" >/dev/null 2>&1
  tick_a release "$1" --agent dispatcher --to claude >/dev/null 2>&1
}

# --- Cross-repo build that ADDS a file, with a never-created path on the allowlist (the GH-29 trigger) ---
seed_token RELAY-TURN-newfile
B_BEFORE="$(git -C "$B" rev-parse HEAD)"
A_BEFORE="$(git -C "$A" rev-parse HEAD)"

AGENT_CMD="RELAY_AGENT=claude RELAY_FILE=\"\$RELAY_TARGET_ROOT/relay.md\" RELAY_TASK=RELAY-TURN-newfile \
  CLAUDE_AGENT=claude CLAUDE_BIN=\"$STUB\" CLAUDE_TURN_ROOT=\"$A\" CLAUDE_LOG=\"$WORK/c.log\" \
  ALLOW_PATHS=\"existing.txt,newfile.txt,never-created.txt\" CLAUDE_BLOCK_CMDS=\"\" RELAY_WORKTREE_ISOLATION=1 \
  bash \"$SHIM\""

bash "$DRIVE" --relay-file "$B/relay.md" --relay-task RELAY-TURN-newfile \
  --target-root "$B" --agent-cmd "$AGENT_CMD" --round-cap 1 >/dev/null 2>&1

# 1. A commit must land in $B (pre-fix: HEAD unchanged → "no tracked changes").
[ "$(git -C "$B" rev-parse HEAD)" != "$B_BEFORE" ] && pass "GH-29: new-file build committed in foreign repo B" || fail "GH-29: no commit in B (new files dropped)"

# 2. The NEW file must be committed (tracked at HEAD), not just sitting untracked.
git -C "$B" cat-file -e "HEAD:newfile.txt" 2>/dev/null && pass "GH-29: new untracked file is committed (tracked at HEAD)" || fail "GH-29: newfile.txt not committed"
grep -q "brand new detector" <<<"$(git -C "$B" show "HEAD:newfile.txt" 2>/dev/null)" && pass "GH-29: committed new file has the build content" || fail "GH-29: newfile.txt content missing at HEAD"

# 3. The modified tracked file must also be committed (proves the whole batch wasn't aborted).
grep -q "modified by builder" <<<"$(git -C "$B" show "HEAD:existing.txt" 2>/dev/null)" && pass "GH-29: modified tracked file committed alongside the new file" || fail "GH-29: existing.txt change not committed"

# 4. The never-created allowlist entry must NOT block the commit and must not exist.
! git -C "$B" cat-file -e "HEAD:never-created.txt" 2>/dev/null && pass "GH-29: non-matching allowlist entry tolerated (not committed)" || fail "GH-29: never-created.txt unexpectedly committed"

# 5. The harness repo $A is untouched (containment preserved).
[ "$(git -C "$A" rev-parse HEAD)" = "$A_BEFORE" ] && pass "GH-29: harness repo A untouched" || fail "GH-29: harness repo A was modified"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
