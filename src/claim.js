'use strict';

const { appendEvent, readAllEvents } = require('./events');
const { project, fold, nextEpoch, activeClaimsForAgent, MAX_ACTIVE_CLAIMS_PER_AGENT } = require('./project');
const { withClaimLock } = require('./lock');

// Local-transport claim (Run 2: git transport removed).
//
// `.tick/events/` is a shared local directory; the per-clone lock serialises
// claim calls. Together that makes `tick claim` a real mutex: read current
// state, decide, append — atomically. No git, no deterministic tie-breaker,
// no auto-release. Those existed only to reconcile the old distributed
// fetch/rebase/push transport's races, which no longer exist.
/**
 * Attempts to claim `task` for `agent`, declaring the path globs it intends to
 * touch. Serialized per-clone via {@link withClaimLock} so two concurrent
 * claims can't both pass the cap check before either writes.
 * @param {string} repoRoot - absolute path to the repo root
 * @param {Object} opts
 * @param {string} opts.task - task id
 * @param {string} opts.agent - claiming agent id
 * @param {string[]} opts.paths - glob patterns the agent intends to touch (required, non-empty)
 * @returns {{won: boolean, task: string, winner?: string, unavailable?: string, limitReached?: boolean, holding?: string[]}}
 * @throws {Error} if `paths` is missing or empty
 */
function claim(repoRoot, { task, agent, paths }) {
  if (!paths || !paths.length) {
    throw new Error('claim requires --paths (declare every glob you intend to touch)');
  }

  return withClaimLock(repoRoot, () => {
    const events = readAllEvents(repoRoot);
    const tasks = fold(events);
    const t = tasks.get(task);

    // Already terminal — not claimable.
    if (t && (t.status === 'done' || t.status === 'circuit_broken')) {
      return { won: false, task, winner: null, unavailable: t.status };
    }

    // Already claimed.
    if (t && t.status === 'claimed') {
      if (t.claim.agent === agent) {
        return { won: true, task }; // idempotent — you already hold it
      }
      return { won: false, task, winner: t.claim.agent };
    }

    // Reserved for someone else.
    if (t && t.handoff_to && t.handoff_to !== agent) {
      return { won: false, task, unavailable: 'reserved for another agent' };
    }

    // Per-agent claim cap.
    const held = activeClaimsForAgent(tasks, agent);
    if (held.length >= MAX_ACTIVE_CLAIMS_PER_AGENT) {
      return { won: false, limitReached: true, holding: held, task };
    }

    // Monotonic epoch: strictly above any prior claim on this task, so a
    // reclaim after reap fences the displaced owner's stale writes.
    appendEvent(repoRoot, { type: 'task.claimed', task, agent, paths, epoch: nextEpoch(events, task) });
    project(repoRoot);
    return { won: true, task };
  });
}

module.exports = { claim };
