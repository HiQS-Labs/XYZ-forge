#!/usr/bin/env bash
# test/relay-target-root-paths.sh — epic GH-16 Phase 2 (tracks #11)
# The basic foreign-repo routing is covered by relay-target-root.sh. This test hardens it against the
# path shapes that break naive quoting: a --target-root whose path contains SPACES, and a NESTED
# artifact + relay file whose directory name also contains a space. It proves --target-root routes the
# worktree base, allowlist copy-back, file-scoped commit, and enforce to the foreign root for these
# shapes, and that .tick coordination stays in the harness root (never the target).
source "$(dirname "$0")/_setup.sh" relay-target-root-paths

export TICK_BIN="$TICK"
DRIVE="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-drive.sh"
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/claude-turn.sh"

# Coordination root = harness repo $A.
tick_a init >/dev/null

# Foreign target repo at a path WITH SPACES, holding a NESTED relay file + artifact (dir has a space).
TGT="$WORK/target repo with spaces"
REL_REL="relay-system/2026-06-24/thread.md"
ART_REL="src/sub dir/artifact.txt"
git init -q "$TGT"
git -C "$TGT" config user.email tgt@t
git -C "$TGT" config user.name tgt
mkdir -p "$TGT/$(dirname "$REL_REL")" "$TGT/$(dirname "$ART_REL")"
printf 'STATUS: Open\nNEXT: producer\n# relay body\n' >"$TGT/$REL_REL"
printf 'seed\n' >"$TGT/$ART_REL"
git -C "$TGT" add -A >/dev/null 2>&1
git -C "$TGT" commit -q -m "seed target" >/dev/null 2>&1

# Stub agent: CWD is the throwaway worktree of the target repo (worktree isolation ON).
# It claims the token in $A, edits the NESTED+SPACED allowlisted artifact + relay file, releases.
STUB="$WORK/agent-stub.sh"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
export TICK_REPO_ROOT="$A"   # coordination stays in the harness repo
"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "src/sub dir/artifact.txt" >/dev/null 2>&1
"$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
printf 'edited by agent\n' >> "src/sub dir/artifact.txt"
printf '\n### Round 1 · Agent\n' >> "relay-system/2026-06-24/thread.md"
"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to reviewer >/dev/null 2>&1
printf '{"usage":{"input_tokens":1,"output_tokens":1},"total_cost_usd":0}\n'
exit 0
STUB_EOF
chmod +x "$STUB"

seed_token() { # <task>
  tick_a log task.created "$1" --agent claude --paths "src/sub dir/artifact.txt" >/dev/null
  tick_a claim "$1" --agent dispatcher --paths "src/sub dir/artifact.txt" >/dev/null 2>&1
  tick_a release "$1" --agent dispatcher --to claude >/dev/null 2>&1
}

seed_token RELAY-TURN-spaced

TGT_BEFORE="$(git -C "$TGT" rev-parse HEAD)"
A_BEFORE="$(git -C "$A" rev-parse HEAD)"

AGENT_CMD="RELAY_AGENT=claude RELAY_FILE=\"\$RELAY_TARGET_ROOT/$REL_REL\" RELAY_TASK=RELAY-TURN-spaced \
  CLAUDE_AGENT=claude CLAUDE_BIN=\"$STUB\" CLAUDE_TURN_ROOT=\"$A\" CLAUDE_LOG=\"$WORK/c.log\" \
  ALLOW_PATHS=\"$ART_REL\" CLAUDE_BLOCK_CMDS=\"\" RELAY_WORKTREE_ISOLATION=1 \
  bash \"$SHIM\""

bash "$DRIVE" --relay-file "$TGT/$REL_REL" --relay-task RELAY-TURN-spaced \
  --target-root "$TGT" --agent-cmd "$AGENT_CMD" --round-cap 1 >/dev/null 2>&1

# 1. Commit landed in the foreign (spaced) target.
[ "$(git -C "$TGT" rev-parse HEAD)" != "$TGT_BEFORE" ] \
  && pass "spaced/nested target: commit created in foreign repo" || fail "no commit in spaced foreign target"

# 2. Harness repo $A untouched (no commit).
[ "$(git -C "$A" rev-parse HEAD)" = "$A_BEFORE" ] \
  && pass "spaced/nested target: harness repo untouched" || fail "harness repo was modified"

# 3. The nested+spaced artifact carries the edit (copy-back through a spaced path worked).
grep -q "edited by agent" "$TGT/$ART_REL" \
  && pass "spaced/nested target: nested artifact edited via copy-back" || fail "nested artifact not edited in target"

# 4. The edit is actually committed (file-scoped commit routed to the foreign root), not just left dirty.
git -C "$TGT" show HEAD:"$ART_REL" 2>/dev/null | grep -q "edited by agent" \
  && pass "spaced/nested target: edit is committed at the foreign root" || fail "edit not committed at foreign root"

# 5. .tick coordination stayed in the harness; the target tree has none.
[ ! -e "$TGT/.tick" ] \
  && pass "spaced/nested target: no .tick in the target repo (coordination stayed in harness)" || fail ".tick leaked into the target repo"

# 6. No harness/relay scaffolding leaked into the target's tracked tree beyond the scoped files.
#    (Only the relay file + artifact should differ from seed; both were allowlisted.)
LEAK="$(git -C "$TGT" log --name-only --format= "$TGT_BEFORE"..HEAD 2>/dev/null | grep -vE "^$REL_REL$|^$ART_REL$|^$" | head -1)"
[ -z "$LEAK" ] \
  && pass "spaced/nested target: commit touched only the scoped relay file + artifact" || fail "unexpected path in target commit: $LEAK"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
