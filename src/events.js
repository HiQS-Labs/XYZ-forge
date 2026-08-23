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
  'cost.memory',
  // Marathon phase-chain signals (Phase 3, marathon-drive.sh). Emitted at phase boundaries by
  // marathon-drive, not by individual turn-takers. Not coordination signals — ignored by tick analyze.
  'marathon.phase.start',
  'marathon.phase.approved',
  'marathon.phase.escalated',
  'marathon.phase.revision',
  'marathon.complete',
  // Cross-agent dependency-drift signal (GH-68, warn-only Phase 1). Emitted by relay-turn-lib.sh
  // post-commit when a landed turn changes a shared surface, so the NEXT agent's shim can inject a
  // heads-up. Purely informational: carries no epoch, claims no task, is NOT a state-transition —
  // the projection kernel ignores it exactly like cost.*/marathon.* signals.
  // See decisions/2026-07-01-cross-agent-dep-conflict.md.
  'dependency.drift',
]);

const CRITICAL_EVENTS = new Set([
  'task.claimed',
  'task.scope_changed',
  'task.released',
  'task.circuit_break',
  'task.done',
]);

/**
 * Path to the shared local event-log directory for a repo clone.
 * @param {string} repoRoot - absolute path to the repo root
 * @returns {string} absolute path to `<repoRoot>/.tick/events`
 */
function eventsDir(repoRoot) {
  return path.join(repoRoot, '.tick', 'events');
}

/**
 * Creates the events directory (and any missing parents) if it doesn't exist yet.
 * @param {string} repoRoot - absolute path to the repo root
 * @returns {void}
 */
function ensureEventsDir(repoRoot) {
  fs.mkdirSync(eventsDir(repoRoot), { recursive: true });
}

/**
 * Current timestamp in ISO-8601, overridable via `TICK_TS` for deterministic tests.
 * @returns {string} ISO-8601 timestamp
 */
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

/**
 * Appends one event to the log as a new `.jsonl` file (one event per file — the
 * projection's unit of atomicity). Fields present in the event depend on `type`;
 * unset optional fields are omitted from the written JSON, not written as null,
 * so unrelated event types stay byte-identical across schema additions.
 *
 * Publication is atomic (GH-14): the document is written to a `.tmp` name that
 * {@link readAllEvents}' `.jsonl` filter never matches, then `rename(2)`d onto
 * the final path, so concurrent readers either do not see the event yet or see
 * the complete document — never a partial/empty file.
 * @param {string} repoRoot - absolute path to the repo root
 * @param {Object} fields
 * @param {string} fields.type - one of {@link EVENT_TYPES}
 * @param {string} fields.task - task id
 * @param {string} fields.agent - acting agent id
 * @param {string} [fields.note]
 * @param {string[]} [fields.paths] - glob patterns the event declares/claims
 * @param {string} [fields.to_agent] - handoff target (task.released)
 * @param {string} [fields.reason] - circuit-break reason
 * @param {number} [fields.priority]
 * @param {number} [fields.epoch] - monotonic per-task ownership fence (R1)
 * @param {number} [fields.tokens_in]
 * @param {number} [fields.tokens_out]
 * @param {number} [fields.tokens_total]
 * @param {number} [fields.human_minutes]
 * @param {string} [fields.tool]
 * @param {string} [fields.surface] - dependency.drift: the shared surface that changed
 * @param {string} [fields.prior_sha]
 * @param {string} [fields.current_sha]
 * @param {number} [fields.diff_lines]
 * @param {string} [fields.turn]
 * @returns {{path: string, event: Object}} the written file path and the event object
 * @throws {Error} if `type` is unrecognized, or `task`/`agent` is missing
 */
function appendEvent(repoRoot, {
  type, task, agent, note, paths, to_agent, reason, priority, epoch, force,
  tokens_in, tokens_out, tokens_total, human_minutes, tool,
  compressor_mb, swap_free_mb, peak_rss_mb,
  surface, prior_sha, current_sha, diff_lines, turn,
}) {
  if (!EVENT_TYPES.has(type)) {
    throw new Error(`unknown event type: ${type}`);
  }
  if (!task) throw new Error('task is required');
  if (typeof task !== 'string' || !/^[A-Za-z0-9._-]+$/.test(task)) {
    throw new Error(`invalid task format: "${task}" (must be alphanumeric, dash, underscore, or dot)`);
  }
  if (!agent) throw new Error('agent is required');
  if (typeof agent !== 'string' || !/^[A-Za-z0-9._-]+$/.test(agent)) {
    throw new Error(`invalid agent format: "${agent}" (must be alphanumeric, dash, underscore, or dot)`);
  }

  if (priority !== undefined) {
    if (typeof priority !== 'number' || !Number.isFinite(priority)) {
      throw new Error(`invalid priority: "${priority}" (must be a finite number)`);
    }
  }
  if (epoch !== undefined) {
    if (typeof epoch !== 'number' || Number.isNaN(epoch) || epoch < 0 || !Number.isInteger(epoch)) {
      throw new Error(`invalid epoch: "${epoch}" (must be a non-negative integer)`);
    }
  }

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
  // Emergency override provenance (GH-23). Stamped when a claim or scope expansion
  // explicitly used --force to bypass path-overlap validation.
  if (force !== undefined) event.force = force;
  // Cost fields — only stamped when present, so non-cost events stay byte-identical to before.
  if (tokens_in !== undefined) event.tokens_in = tokens_in;
  if (tokens_out !== undefined) event.tokens_out = tokens_out;
  if (tokens_total !== undefined) event.tokens_total = tokens_total;
  if (human_minutes !== undefined) event.human_minutes = human_minutes;
  if (tool !== undefined) event.tool = tool;
  if (compressor_mb !== undefined) event.compressor_mb = compressor_mb;
  if (swap_free_mb !== undefined) event.swap_free_mb = swap_free_mb;
  if (peak_rss_mb !== undefined) event.peak_rss_mb = peak_rss_mb;
  // Dependency-drift fields (GH-68) — only stamped for dependency.drift events, so every other
  // event type stays byte-identical to before.
  if (surface !== undefined) event.surface = surface;
  if (prior_sha !== undefined) event.prior_sha = prior_sha;
  if (current_sha !== undefined) event.current_sha = current_sha;
  if (diff_lines !== undefined) event.diff_lines = diff_lines;
  if (turn !== undefined) event.turn = turn;

  // Atomic publish (GH-14): write to a name readAllEvents' `.jsonl` filter never
  // matches, then rename(2) into place — rename is atomic within a filesystem, so
  // a concurrent reader observes either no file or the complete document, never a
  // torn one. A crash between the two calls leaves at most an invisible `.tmp`.
  const tmp = fpath + '.tmp';
  fs.writeFileSync(tmp, JSON.stringify(event) + '\n');
  fs.renameSync(tmp, fpath);
  return { path: fpath, event };
}

/**
 * Reads every event in the log, sorted by filename (which encodes ISO timestamp),
 * so callers see events in chronological arrival order.
 * @param {string} repoRoot - absolute path to the repo root
 * @returns {Object[]} parsed event objects, each carrying a `_file` provenance field
 */
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
