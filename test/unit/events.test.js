'use strict';

// Direct unit tests for src/events.js (GH-5). The kernel previously had no unit
// runner at all — everything ran through bash acceptance suites — even though
// the modules are pure enough to test directly. Run with: npm run test:unit.

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const events = require('../../src/events');

function tmpRepo() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'tick-events-test.'));
}

test('appendEvent writes one parsable .jsonl file and readAllEvents returns it', () => {
  const root = tmpRepo();
  try {
    const { event } = events.appendEvent(root, {
      type: 'task.created', task: 'T1', agent: 'a1', note: 'hello',
    });
    assert.equal(event.type, 'task.created');
    const all = events.readAllEvents(root);
    assert.equal(all.length, 1);
    assert.equal(all[0].task, 'T1');
    assert.equal(all[0].agent, 'a1');
    assert.equal(all[0]._file.endsWith('.jsonl'), true);
  } finally { fs.rmSync(root, { recursive: true, force: true }); }
});

test('readAllEvents returns events in chronological (filename) order', () => {
  const root = tmpRepo();
  try {
    process.env.TICK_TS = '2026-01-01T00:00:01Z';
    events.appendEvent(root, { type: 'task.created', task: 'T1', agent: 'a1' });
    process.env.TICK_TS = '2026-01-01T00:00:02Z';
    events.appendEvent(root, { type: 'task.claimed', task: 'T1', agent: 'a1' });
    const all = events.readAllEvents(root);
    assert.deepEqual(all.map(e => e.type), ['task.created', 'task.claimed']);
  } finally {
    delete process.env.TICK_TS;
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test('GH-5: a corrupt .jsonl file is quarantined and does not break the read', () => {
  const root = tmpRepo();
  try {
    process.env.TICK_TS = '2026-01-01T00:00:01Z';
    events.appendEvent(root, { type: 'task.created', task: 'T1', agent: 'a1' });
    process.env.TICK_TS = '2026-01-01T00:00:02Z';
    events.appendEvent(root, { type: 'task.claimed', task: 'T1', agent: 'a1' });

    // A writer killed mid-write: truncated JSON.
    const dir = events.eventsDir(root);
    fs.writeFileSync(path.join(dir, '2026-01-01T00-00-03-a1-comment-T1.jsonl'), '{"type":"task.commen');

    const all = events.readAllEvents(root);
    assert.equal(all.length, 2, 'healthy events still served');
    assert.equal(fs.existsSync(path.join(dir, '2026-01-01T00-00-03-a1-comment-T1.jsonl')), false,
      'corrupt file renamed away');
    assert.equal(
      fs.existsSync(path.join(dir, '2026-01-01T00-00-03-a1-comment-T1.jsonl.corrupt')), true,
      'quarantine copy exists');
    // A second read is clean: the quarantined file is no longer in the .jsonl set.
    assert.equal(events.readAllEvents(root).length, 2);
  } finally {
    delete process.env.TICK_TS;
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test('an empty .jsonl file is skipped silently', () => {
  const root = tmpRepo();
  try {
    events.appendEvent(root, { type: 'task.created', task: 'T1', agent: 'a1' });
    fs.writeFileSync(path.join(events.eventsDir(root), '2026-01-01T00-00-02-a1-heartbeat-T1.jsonl'), '');
    const all = events.readAllEvents(root);
    assert.equal(all.length, 1);
  } finally { fs.rmSync(root, { recursive: true, force: true }); }
});

test('appendEvent rejects unknown event types and missing task/agent', () => {
  const root = tmpRepo();
  try {
    assert.throws(() => events.appendEvent(root, { type: 'task.exploded', task: 'T', agent: 'a' }),
      /unknown event type/);
    assert.throws(() => events.appendEvent(root, { type: 'task.created', task: '', agent: 'a' }),
      /task is required/);
    assert.throws(() => events.appendEvent(root, { type: 'task.created', task: 'T', agent: '' }),
      /agent is required/);
  } finally { fs.rmSync(root, { recursive: true, force: true }); }
});

test('readAllEvents on a repo with no .tick directory returns []', () => {
  const root = tmpRepo();
  try {
    assert.deepEqual(events.readAllEvents(root), []);
  } finally { fs.rmSync(root, { recursive: true, force: true }); }
});
