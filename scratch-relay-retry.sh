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
RELAY="relay-system/2026-07-03/review-gh-116-and-117.md"
TASK="RELAY-review-gh-116-and-117"

export AIDER_MODEL="openrouter/z-ai/glm-5.2"
export AIDER_AGENT="aider"
export ALLOW_PATHS=""
export AIDER_LOG="/tmp/aider-turn-$$.log"
export RELAY_WORKTREE_ISOLATION=1
export RELAY_PEER="claude-a"
export AIDER_FLAGS="--read .relay-artifacts/gh-116-117-diff.txt --edit-format diff"

relay-automation/relay-drive.sh \
  --relay-file "$RELAY" \
  --relay-task "$TASK" \
  --artifact-file "$DIFF_FILE" \
  --agent-cmd relay-automation/aider-turn.sh \
  --round-cap 4 \
  --force
