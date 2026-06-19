'use strict';

const { appendEvent, readAllEvents } = require('./events');
const { project, fold } = require('./project');

// Run 2: git transport removed. Every verb is now a pure local event append
// to the shared .tick/events/ dir, followed by a re-projection of STATE.md.

function emitEvent(repoRoot, type, payload) {
  appendEvent(repoRoot, { type, ...payload });
  project(repoRoot);
}

// Ownership guard for mutating verbs. Throws if:
//   - task doesn't exist
//   - task is not currently claimed
//   - the claimer doesn't match `agent`
// Only `reap` bypasses this (it explicitly operates on other agents' claims).
// Returns the claimed task `t` so callers can stamp the owner's epoch onto the
// mutation they emit (the fence in fold rejects any mutation whose epoch is
// below the current owner's).
function assertOwnership(repoRoot, task, agent) {
  const tasks = fold(readAllEvents(repoRoot));
  const t = tasks.get(task);
  if (!t) throw new Error(`task ${task} not found`);
  if (t.status !== 'claimed') throw new Error(`task ${task} is ${t.status} — only the claiming agent can mutate it`);
  if (t.claim.agent !== agent) throw new Error(`task ${task} is claimed by ${t.claim.agent}, not ${agent}`);
  return t;
}

function scope(repoRoot, { task, agent, paths }) {
  if (!paths || !paths.length) throw new Error('scope requires --paths');
  const t = assertOwnership(repoRoot, task, agent);
  emitEvent(repoRoot, 'task.scope_changed', { task, agent, paths, epoch: t.claim.epoch });
  return { ok: true };
}

function release(repoRoot, { task, agent, to_agent }) {
  const t = assertOwnership(repoRoot, task, agent);
  emitEvent(repoRoot, 'task.released', { task, agent, to_agent, epoch: t.claim.epoch });
  return { ok: true };
}

function circuitBreak(repoRoot, { task, agent, reason }) {
  const t = assertOwnership(repoRoot, task, agent);
  emitEvent(repoRoot, 'task.circuit_break', { task, agent, reason: reason || '', epoch: t.claim.epoch });
  return { ok: true };
}

function done(repoRoot, { task, agent, note }) {
  const t = assertOwnership(repoRoot, task, agent);
  emitEvent(repoRoot, 'task.done', { task, agent, note, epoch: t.claim.epoch });
  return { ok: true };
}

// Liveness heartbeat (Run 3). The claiming agent emits one of these while
// actively working a task so the post-run parked-claim check has a work-activity
// signal that does NOT depend on git author identity (which Run 2 removed). A
// claim window with no heartbeat for longer than the threshold is flagged as a
// suspected parked claim by `tick analyze`. Heartbeats never change projected
// state — they are pure liveness evidence. Ownership-guarded so an agent can
// only heartbeat a task it currently holds.
function heartbeat(repoRoot, { task, agent, note }) {
  assertOwnership(repoRoot, task, agent);
  emitEvent(repoRoot, 'task.heartbeat', { task, agent, note });
  return { ok: true };
}

// Manual liveness lever (P5). Release every active claim held by a (presumed
// crashed) agent so peers can pick the work back up. Each emitted
// task.released carries `agent = <crashed agent>` — that is what the
// projection needs to treat the claim as released — plus a note recording the
// reap. Coordinator-only, manual, logged: not auto-recovery.
function reap(repoRoot, { agent, by }) {
  const tasks = fold(readAllEvents(repoRoot));

  const held = [];
  const epochByTask = new Map();
  for (const t of tasks.values()) {
    if (t.status === 'claimed' && t.claim && t.claim.agent === agent) {
      held.push(t.id);
      epochByTask.set(t.id, t.claim.epoch);
    }
  }
  held.sort();

  const reapedBy = by || 'coordinator';
  for (const task of held) {
    appendEvent(repoRoot, {
      type: 'task.released',
      task,
      agent,
      epoch: epochByTask.get(task),
      note: `reaped by ${reapedBy}: agent presumed crashed`,
    });
  }

  project(repoRoot);
  return { reaped: held };
}

module.exports = { scope, release, circuitBreak, done, reap, heartbeat };
