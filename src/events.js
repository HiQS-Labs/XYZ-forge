'use strict';

const fs = require('fs');
const path = require('path');

// 0.2.0 — adds the optional `epoch` field to claim/mutation events (Part B
// Phase 1, R1 epoch fencing). Events without `epoch` are read as epoch 0, so
// pre-0.2.0 logs project identically. See decisions/2026-06-18-epoch-fencing.md.
const SCHEMA_VERSION = '0.2.0';

const EVENT_TYPES = new Set([
  'task.created',
  'task.claimed',
  'task.released',
  'task.scope_changed',
  'task.commented',
  'task.heartbeat',
  'task.done',
  'task.circuit_break',
  // Cost signals (Phase 1, COST-OBSERVABILITY-PLAN). Deterministic, additive, ignored by the
  // coordination metrics — they describe what a turn COST, not how it coordinated.
  'cost.tokens',
  'cost.human',
  // Marathon phase-chain signals (Phase 3, marathon-drive.sh). Emitted at phase boundaries by
  // marathon-drive, not by individual turn-takers. Not coordination signals — ignored by tick analyze.
  'marathon.phase.start',
  'marathon.phase.approved',
  'marathon.phase.escalated',
  'marathon.phase.revision',
  'marathon.complete',
]);

const CRITICAL_EVENTS = new Set([
  'task.claimed',
  'task.scope_changed',
  'task.released',
  'task.circuit_break',
  'task.done',
]);

function eventsDir(repoRoot) {
  return path.join(repoRoot, '.tick', 'events');
}

function ensureEventsDir(repoRoot) {
  fs.mkdirSync(eventsDir(repoRoot), { recursive: true });
}

function isoNow() {
  if (process.env.TICK_TS) return process.env.TICK_TS;
  return new Date().toISOString();
}

function tsForFilename(iso) {
  return iso.replace(/:/g, '-');
}

function safeSegment(s) {
  return String(s).replace(/[^A-Za-z0-9._-]/g, '_');
}

function appendEvent(repoRoot, {
  type, task, agent, note, paths, to_agent, reason, priority, epoch,
  tokens_in, tokens_out, tokens_total, human_minutes, tool,
}) {
  if (!EVENT_TYPES.has(type)) {
    throw new Error(`unknown event type: ${type}`);
  }
  if (!task) throw new Error('task is required');
  if (!agent) throw new Error('agent is required');

  ensureEventsDir(repoRoot);

  const ts = isoNow();
  const action = type.replace(/^(task|cost)\./, '');
  const fname = `${tsForFilename(ts)}-${safeSegment(agent)}-${safeSegment(action)}-${safeSegment(task)}.jsonl`;
  const fpath = path.join(eventsDir(repoRoot), fname);

  const event = {
    schema_version: SCHEMA_VERSION,
    ts,
    type,
    task,
    agent,
  };
  if (paths) event.paths = paths;
  if (note !== undefined) event.note = note;
  if (to_agent) event.to_agent = to_agent;
  if (reason !== undefined) event.reason = reason;
  if (priority !== undefined) event.priority = priority;
  // Epoch fencing token (R1). Stamped on task.claimed (the owner's epoch) and on
  // the owner's mutations; absent ⇒ epoch 0, so legacy events stay byte-stable.
  if (epoch !== undefined) event.epoch = epoch;
  // Cost fields — only stamped when present, so non-cost events stay byte-identical to before.
  if (tokens_in !== undefined) event.tokens_in = tokens_in;
  if (tokens_out !== undefined) event.tokens_out = tokens_out;
  if (tokens_total !== undefined) event.tokens_total = tokens_total;
  if (human_minutes !== undefined) event.human_minutes = human_minutes;
  if (tool !== undefined) event.tool = tool;

  fs.writeFileSync(fpath, JSON.stringify(event) + '\n');
  return { path: fpath, event };
}

function readAllEvents(repoRoot) {
  const dir = eventsDir(repoRoot);
  if (!fs.existsSync(dir)) return [];
  const files = fs.readdirSync(dir).filter(f => f.endsWith('.jsonl')).sort();
  return files.map(f => {
    const raw = fs.readFileSync(path.join(dir, f), 'utf8').trim();
    const ev = JSON.parse(raw);
    ev._file = f;
    return ev;
  });
}

module.exports = {
  SCHEMA_VERSION,
  EVENT_TYPES,
  CRITICAL_EVENTS,
  appendEvent,
  readAllEvents,
  eventsDir,
  ensureEventsDir,
  isoNow,
};
