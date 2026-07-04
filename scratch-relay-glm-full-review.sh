#!/bin/bash
export OPENROUTER_API_KEY="$(< /Users/noelsaw/secrets/openrouter/openrouter.txt)"

for L in "${XYZ_HARNESS:+$XYZ_HARNESS/skills/relay-xyz/find-harness.sh}" \
         "$HOME/.claude/skills/relay-xyz/find-harness.sh" \
         "./.claude/skills/relay-xyz/find-harness.sh" \
         "$(git rev-parse --show-toplevel 2>/dev/null)/skills/relay-xyz/find-harness.sh"; do
  [ -n "$L" ] && [ -x "$L" ] && break
done
eval "$("$L" --env)"
cd "$HARNESS"

DIFF_FILE="/tmp/gh-glm-full-review-diff.txt"

RELAY_OUT="$(relay-automation/new-relay.sh --title "GLM 5.2 full review: GH-118/119/120+113/114 shipped work" --reviewer aider --artifact-file "$DIFF_FILE")"
RELAY=$(echo "$RELAY_OUT" | grep -o 'relay-system/.*\.md')

if [ -z "$RELAY" ]; then
    echo "Failed to create relay file."
    exit 1
fi

git add "$RELAY"

TASK="RELAY-$(basename "$RELAY" .md)"

"$TICK" log     task.created "$TASK" --agent claude-a
"$TICK" claim   "$TASK" --agent claude-a --paths "$RELAY"
"$TICK" release "$TASK" --agent claude-a --to aider

export AIDER_MODEL="openrouter/z-ai/glm-5.2"
export AIDER_AGENT="aider"
export ALLOW_PATHS=""
export AIDER_LOG="/tmp/aider-turn-$$.log"
export RELAY_WORKTREE_ISOLATION=1
export RELAY_PEER="claude-a"
export AIDER_FLAGS="--read .relay-artifacts/gh-glm-full-review-diff.txt --edit-format diff"
export RELAY_TURN_TIMEOUT_S=600

relay-automation/relay-drive.sh \
  --relay-file "$RELAY" \
  --relay-task "$TASK" \
  --artifact-file "$DIFF_FILE" \
  --agent-cmd relay-automation/aider-turn.sh \
  --round-cap 4 \
  --review-once
echo "relay-drive exit: $?"
