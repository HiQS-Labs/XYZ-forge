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

DIFF_FILE="/tmp/gh-116-117-diff.txt"
git show bb9138bef1b2967f0ccd0f3c39f7ac73a751b4e5 > "$DIFF_FILE"

RELAY_OUT="$(relay-automation/new-relay.sh --title "Review GH-116 and 117 (Nemotron test)" --reviewer aider --artifact-file "$DIFF_FILE")"
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

export AIDER_MODEL="openrouter/nvidia/nemotron-3-ultra-550b-a55b:free"
export AIDER_AGENT="aider"
export ALLOW_PATHS=""
export AIDER_LOG="/tmp/aider-turn-$$.log"
export RELAY_WORKTREE_ISOLATION=1
export RELAY_PEER="claude-a"
export AIDER_FLAGS="--read .relay-artifacts/gh-116-117-diff.txt"

relay-automation/relay-drive.sh \
  --relay-file "$RELAY" \
  --relay-task "$TASK" \
  --artifact-file "$DIFF_FILE" \
  --agent-cmd relay-automation/aider-turn.sh \
  --round-cap 4
