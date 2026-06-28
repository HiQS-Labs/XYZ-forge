#!/usr/bin/env bash
# Aggregate runner for all tick acceptance tests.
# Exit 0 = all pass; Exit 1 = at least one failed.
set -u

# Clean ambient variables that might interfere with tests inside the harness.
unset ALLOW_PATHS RELAY_FILE RELAY_TASK RELAY_AGENT RELAY_PEER RELAY_WORKTREE_ISOLATION

HERE="$(cd "$(dirname "$0")" && pwd)"
TESTS=(
  "projection-idempotent.sh"
  "concurrent-claim.sh"
  "chaos-stale-writer.sh"
  "chaos-concurrent-pollers.sh"
  "chaos-midturn-kill.sh"
  "path-overlap.sh"
  "scope-change.sh"
  "tick-foreign-cwd.sh"
  "handoff.sh"
  "handoff-exclusive.sh"
  "circuit-break.sh"
  "auto-sync.sh"
  "analyze.sh"
  "claim-cap.sh"
  "reap.sh"
  "heartbeat.sh"
  "cost.sh"
  "take.sh"
  "watchdog-liveness.sh"
  "runner-loop.sh"
  "poll-driver.sh"
  "relay-loop.sh"
  "poll-relay.sh"
  "watchdog-relay.sh"
  "codex-turn.sh"
  "gemini-turn.sh"
  "agy-turn.sh"
  "claude-turn.sh"
  "worktree-isolation.sh"
  "shim-worktree.sh"
  "marathon-yaml.sh"
  "marathon-drive.sh"
  "marathon.sh"
  "consult.sh"
  "skill-extract.sh"
  "path-integrity.sh"
  "relay-turn-timeout.sh"
  "relay-target-root.sh"
  "relay-target-root-paths.sh"
  "relay-target-root-relayfile.sh"
  "relay-target-root-newfile.sh"
  "relay-token-collision.sh"
  "relay-escalation-not-stall.sh"
  "relay-untracked-file-warn.sh"
  "relay-review-once.sh"
  "relay-artifact-file.sh"
  "new-relay.sh"
  "relay-concurrent-commit.sh"
  "relay-case-insensitive.sh"
  "relay-xyz-skill-guard.sh"
  "pdda-roadmap-coverage.sh"
  "swarm-preflight.sh"
  "roadmap-dashboard.sh"
  "queue-plan.sh"
  # Live-agent test — auto-skips when agy/codex not on PATH or RELAY_SELF_SUFFICIENCY_SKIP=1.
  # Set RELAY_SELF_SUFFICIENCY_SKIP=1 in CI / keyless environments to avoid the real API call.
  "relay-self-sufficiency.sh"
)

PASSED=()
FAILED=()

for t in "${TESTS[@]}"; do
  echo
  echo "==============================="
  echo "Running $t"
  echo "==============================="
  if bash "$HERE/test/$t"; then
    PASSED+=("$t")
  else
    FAILED+=("$t")
  fi
done

echo
echo "==============================="
echo "Summary"
echo "==============================="
echo "passed: ${#PASSED[@]} / ${#TESTS[@]}"
for t in "${PASSED[@]}"; do echo "  + $t"; done
if [ "${#FAILED[@]}" -gt 0 ]; then
  echo "failed:"
  for t in "${FAILED[@]}"; do echo "  - $t"; done
  exit 1
fi
exit 0
