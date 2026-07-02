'use strict';

const fs = require('fs');
const path = require('path');
const { readAllEvents } = require('./events');

// Build deterministic state from all events.
//
// Ownership is fenced by a monotonic per-task EPOCH (R1, Part B Phase 1). Each
// task.claimed carries an `epoch`; a takeover (reap → reclaim) raises it. The
// current owner is the live claim with the HIGHEST epoch (ties: earliest ts,
// then lexicographically smallest agent id — the legacy tie-breaker, reached
// only when every epoch is equal, e.g. pre-0.2.0 logs that are all epoch 0).
//
// A mutating event (done / circuit_break / scope_changed / released) is honoured
// ONLY when it is emitted by the current owner at an epoch >= the owner's. A
// lower-epoch or non-owner mutation is REJECTED — recorded in the rejection log,
// never applied. This is the kernel fence that stops a revived zombie writer
// from advancing or corrupting a task it no longer owns: convention-free,
// replay-deterministic (the verdict is a pure function of the event set, so it
// is identical on every projection regardless of arrival order).

function epochOf(ev) {
  return Number.isFinite(ev.epoch) ? ev.epoch : 0;
}

function makeRejection(ev, winner, reason) {
  return {
    ts: ev.ts,
    task: ev.task,
    type: ev.type,
    fenced_agent: ev.agent,
    fenced_epoch: epochOf(ev),
    owner_agent: winner ? winner.agent : null,
    owner_epoch: winner ? epochOf(winner) : null,
    reason,
    file: ev._file || null,
  };
}

/**
 * Projects the ordered event log into current task state, applying the epoch
 * fence (see file header) to reject stale/non-owner mutations. Pure function
 * of the event set — replay-deterministic regardless of arrival order.
 * @param {Object[]} events - as returned by {@link module:events.readAllEvents}, chronological order
 * @returns {{tasks: Map<string, Object>, rejections: Object[]}} the projected
 *   task map (keyed by task id) and the deterministic, ts-sorted list of fenced
 *   (rejected) mutation events
 */
function foldWithMeta(events) {
  // Bucket events per task in chronological order (events are pre-sorted by
  // filename, which encodes ISO ts).
  const byTask = new Map();
  for (const ev of events) {
    // dependency.drift (GH-68) is a purely informational cross-agent signal: it claims no task and is
    // not a coordination event, so it must never seed or mutate a projected task — its synthetic task
    // id (e.g. 'post-commit') would otherwise surface as a phantom `open` task in `tick project`/`next`.
    // It is consumed directly from .tick/events/ by the shims' drift-brief reader, never via the fold.
    // See decisions/2026-07-01-cross-agent-dep-conflict.md.
    if (ev.type === 'dependency.drift') continue;
    if (!byTask.has(ev.task)) byTask.set(ev.task, []);
    byTask.get(ev.task).push(ev);
  }

  const tasks = new Map();
  const rejections = [];

  for (const [taskId, evs] of byTask) {
    const t = {
      id: taskId,
      priority: 0,
      paths: [],
      status: 'open',
      claim: null,
      break: null,
      handoff_to: null,
    };

    // Determine the live-claim winner: among claims whose agent has not
    // subsequently released (ts >= the claim's), the highest epoch wins.
    const claims = evs.filter(e => e.type === 'task.claimed');
    const releases = evs.filter(e => e.type === 'task.released');
    // A release retires a claim only if it is from the same agent, at or after
    // the claim, AND at an epoch >= the claim's. The epoch guard is load-bearing:
    // without it a revived writer's replayed lower-epoch release would retire the
    // current (higher-epoch) claim it shares an id with — the same-id keystone.
    const liveClaims = claims.filter(c =>
      !releases.some(r => r.agent === c.agent && r.ts >= c.ts && epochOf(r) >= epochOf(c))
    );
    liveClaims.sort((a, b) => {
      const ea = epochOf(a), eb = epochOf(b);
      if (ea !== eb) return eb - ea; // highest epoch is the current owner
      if (a.ts !== b.ts) return a.ts < b.ts ? -1 : 1;
      return a.agent < b.agent ? -1 : a.agent > b.agent ? 1 : 0;
    });
    const winner = liveClaims[0] || null;
    const ownerEpoch = winner ? epochOf(winner) : 0;
    const maxClaimEpoch = claims.reduce((m, c) => Math.max(m, epochOf(c)), 0);
    // A handoff (release --to) is honoured only from the latest epoch — the
    // current owner, or (once released) the most recent epoch-holder. This stops
    // a displaced writer from redirecting the reservation to an accomplice.
    const handoffThreshold = winner ? ownerEpoch : maxClaimEpoch;

    // Why the `ev.ts > winner.ts` guard on logging: an event that predates the
    // current owner's claim is legitimate prior-epoch history (the reap/handoff
    // release that retired the old claim, the old owner's scope) and is silently
    // superseded — not a fence-firing. Only a mutation that lands AFTER ownership
    // moved on is a genuine stale-writer attempt worth recording.
    const isStaleWrite = (ev) => winner && ev.ts > winner.ts &&
      (ev.agent !== winner.agent || epochOf(ev) < ownerEpoch);
    // Most-specific reason: a different agent is a non-owner; a same-id writer
    // below the owner's epoch is the keystone stale-epoch case.
    const staleReason = (ev) =>
      ev.agent !== winner.agent ? 'non-owner-agent' : 'stale-epoch';

    // Terminal (done/break) — FENCED. Only the current owner, at an epoch >= the
    // owner's, may terminate the task. This is the keystone: even a revived
    // writer with the SAME agent id is stopped, because its epoch is below the
    // current owner's. Stale / non-owner terminals are rejected, never applied.
    let terminal = null;
    for (const ev of evs) {
      if (ev.type !== 'task.done' && ev.type !== 'task.circuit_break') continue;
      const authorized = winner && ev.agent === winner.agent && epochOf(ev) >= ownerEpoch;
      if (authorized) { terminal = ev; continue; } // last surviving terminal wins
      if (!winner) { rejections.push(makeRejection(ev, null, 'no-live-owner')); continue; }
      if (isStaleWrite(ev)) rejections.push(makeRejection(ev, winner, staleReason(ev)));
    }

    // Walk events to set priority, paths, handoff_to, and (if winner exists)
    // apply scope_changed updates from the current owner at the current epoch.
    for (const ev of evs) {
      switch (ev.type) {
        case 'task.created':
          if (ev.priority !== undefined) t.priority = ev.priority;
          if (ev.paths) t.paths = ev.paths;
          break;
        case 'task.released':
          // Releases are agent-scoped (a displaced owner's release only retires
          // its own already-dead claim), so a stale release is inert against the
          // current claim — but its handoff is fenced (threshold) and a genuine
          // post-takeover replay is recorded for the audit log.
          if (ev.to_agent && epochOf(ev) >= handoffThreshold) t.handoff_to = ev.to_agent;
          if (isStaleWrite(ev)) rejections.push(makeRejection(ev, winner, 'stale-epoch-inert'));
          break;
        case 'task.scope_changed':
          if (!ev.paths) break;
          if (winner && ev.agent === winner.agent && epochOf(ev) >= ownerEpoch && ev.ts >= winner.ts) {
            // Latest in-epoch scope_changed wins (replacement semantics).
            t._scopedPaths = ev.paths;
          } else if (isStaleWrite(ev)) {
            rejections.push(makeRejection(ev, winner, staleReason(ev)));
          }
          break;
      }
    }

    if (terminal) {
      if (terminal.type === 'task.done') {
        t.status = 'done';
      } else {
        t.status = 'circuit_broken';
        t.break = { agent: terminal.agent, reason: terminal.reason || '' };
      }
    } else if (winner) {
      t.status = 'claimed';
      t.claim = {
        agent: winner.agent,
        paths: t._scopedPaths || winner.paths || [],
        ts: winner.ts,
        epoch: ownerEpoch,
      };
      // Once claimed, clear handoff_to (handoff was satisfied by the new claim).
      // But if the latest event is a release-with-handoff after this claim,
      // keep it. Walk events: take the last release.to_agent that occurred
      // AFTER the winning claim.
      let lateHandoff = null;
      for (const ev of evs) {
        // Only the current owner at the current epoch may re-hand-off a claimed
        // task; a stale/foreign late release cannot redirect the reservation.
        if (ev.type === 'task.released' && ev.to_agent && ev.ts > winner.ts
            && ev.agent === winner.agent && epochOf(ev) >= ownerEpoch) {
          lateHandoff = ev.to_agent;
        }
      }
      t.handoff_to = lateHandoff; // null if no late handoff
    }

    delete t._scopedPaths;
    tasks.set(taskId, t);
  }

  // Stable, arrival-order-independent ordering for the audit log.
  rejections.sort((a, b) => {
    if (a.ts !== b.ts) return a.ts < b.ts ? -1 : 1;
    if (a.task !== b.task) return a.task < b.task ? -1 : 1;
    if (a.type !== b.type) return a.type < b.type ? -1 : 1;
    return a.fenced_agent < b.fenced_agent ? -1 : a.fenced_agent > b.fenced_agent ? 1 : 0;
  });

  return { tasks, rejections };
}

/**
 * Back-compat thin wrapper over {@link foldWithMeta} that returns just the task map.
 * @param {Object[]} events - as returned by {@link module:events.readAllEvents}
 * @returns {Map<string, Object>} the projected task map, keyed by task id
 */
function fold(events) {
  return foldWithMeta(events).tasks;
}

/**
 * Next monotonic epoch for a fresh claim on `taskId`: one above the highest
 * epoch any prior claim on that task has carried (so a reclaim after release/
 * reap always strictly exceeds the displaced owner's). First claim ⇒ 1.
 * @param {Object[]} events - as returned by {@link module:events.readAllEvents}
 * @param {string} taskId
 * @returns {number}
 */
function nextEpoch(events, taskId) {
  let max = 0;
  for (const ev of events) {
    if (ev.type === 'task.claimed' && ev.task === taskId) {
      const e = epochOf(ev);
      if (e > max) max = e;
    }
  }
  return max + 1;
}

/**
 * Renders the projected task map as the human-readable `STATE.md` body.
 * @param {Map<string, Object>} tasks - as returned by {@link fold}
 * @returns {string} markdown, grouped into Open / Claimed / Done / Circuit-Broken
 */
function renderState(tasks) {
  const lines = [];
  lines.push('<!-- AUTO-GENERATED by `tick project` from .tick/events/. Do not edit by hand. -->');
  lines.push('');
  lines.push('# Coordination State');
  lines.push('');

  const all = Array.from(tasks.values()).sort((a, b) => a.id.localeCompare(b.id));
  const open = all.filter(t => t.status === 'open');
  const claimed = all.filter(t => t.status === 'claimed');
  const done = all.filter(t => t.status === 'done');
  const broken = all.filter(t => t.status === 'circuit_broken');

  lines.push('## Open');
  if (!open.length) lines.push('_(none)_');
  for (const t of open) {
    const handoff = t.handoff_to ? ` [handoff_to: ${t.handoff_to}]` : '';
    const paths = t.paths.length ? ` paths: ${JSON.stringify(t.paths)}` : '';
    lines.push(`- ${t.id} (priority: ${t.priority})${paths}${handoff}`);
  }
  lines.push('');

  lines.push('## Claimed');
  if (!claimed.length) lines.push('_(none)_');
  for (const t of claimed) {
    const paths = t.claim.paths.length ? ` paths: ${JSON.stringify(t.claim.paths)}` : '';
    lines.push(`- ${t.id} by ${t.claim.agent}${paths}`);
  }
  lines.push('');

  lines.push('## Done');
  if (!done.length) lines.push('_(none)_');
  for (const t of done) lines.push(`- ${t.id}`);
  lines.push('');

  lines.push('## Circuit-Broken');
  if (!broken.length) lines.push('_(none)_');
  for (const t of broken) {
    lines.push(`- ${t.id} by ${t.break.agent} — reason: ${JSON.stringify(t.break.reason)}`);
  }
  lines.push('');

  return lines.join('\n');
}

/**
 * Reads the event log, projects it, and writes both `.tick/STATE.md` (the
 * human-readable state) and `.tick/rejected.jsonl` (the fenced-event audit
 * log, fully rewritten each call so it's always a deterministic mirror of the
 * current event set).
 * @param {string} repoRoot - absolute path to the repo root
 * @returns {{tasks: Map<string, Object>, stateFile: string, rejections: Object[], rejectedFile: string}}
 */
function project(repoRoot) {
  const events = readAllEvents(repoRoot);
  const { tasks, rejections } = foldWithMeta(events);
  const body = renderState(tasks);
  const stateFile = path.join(repoRoot, '.tick', 'STATE.md');
  fs.writeFileSync(stateFile, body);

  // Fenced-event audit log (R1 / R4). Rewritten in full each projection so it is
  // a deterministic mirror of the current event set — one JSON object per line,
  // ready for SIEM ingestion. Always truncate-write (empty when nothing fenced)
  // so a stale log never lingers.
  const rejectedFile = path.join(repoRoot, '.tick', 'rejected.jsonl');
  fs.writeFileSync(rejectedFile, rejections.map(r => JSON.stringify(r)).join('\n') + (rejections.length ? '\n' : ''));

  return { tasks, stateFile, rejections, rejectedFile };
}

// --- Per-agent claim cap (Run 2, P1) ------------------------------------
// An agent may hold at most this many simultaneously-active claims.
// Hardcoded for the spike; a config knob is Phase 2.
const MAX_ACTIVE_CLAIMS_PER_AGENT = 2;

/**
 * Task ids currently actively claimed by `agent` (status === 'claimed').
 * @param {Map<string, Object>} tasks - as returned by {@link fold}
 * @param {string} agent
 * @returns {string[]} sorted task ids
 */
function activeClaimsForAgent(tasks, agent) {
  const held = [];
  for (const t of tasks.values()) {
    if (t.status === 'claimed' && t.claim && t.claim.agent === agent) {
      held.push(t.id);
    }
  }
  return held.sort();
}

module.exports = {
  project,
  fold,
  foldWithMeta,
  nextEpoch,
  renderState,
  activeClaimsForAgent,
  MAX_ACTIVE_CLAIMS_PER_AGENT,
};
