'use strict';

// Direct unit tests for the fold kernel (GH-5). foldWithMeta is a pure function of
// the event set, so the invariants the chaos suites exercise end-to-end can be
// pinned here directly: projection idempotence, ownership election, epoch fencing
// and the terminality seal. Run with: npm run test:unit.

const test = require('node:test');
const assert = require('node:assert/strict');
const { foldWithMeta, fold, nextEpoch } = require('../../src/project');

const ev = (ts, fields) => Object.assign({ ts }, fields);

test('fold is idempotent: folding the same events twice yields the same tasks', () => {
  const events = [
    ev('2026-01-01T00:00:01Z', { type: 'task.created', task: 'T1', agent: 'a1' }),
    ev('2026-01-01T00:00:02Z', { type: 'task.claimed', task: 'T1', agent: 'a1', epoch: 1 }),
    ev('2026-01-01T00:00:03Z', { type: 'task.released', task: 'T1', agent: 'a1', epoch: 1 }),
    ev('2026-01-01T00:00:04Z', { type: 'task.claimed', task: 'T1', agent: 'a2', epoch: 2 }),
  ];
  const one = fold(events);
  const two = fold(events);
  assert.deepEqual([...one.entries()], [...two.entries()]);
});

test('claim/release/done project to the expected statuses', () => {
  const mk = (events) => fold(events).get('T1');

  const claimed = fold([
    ev('2026-01-01T00:00:01Z', { type: 'task.created', task: 'T1', agent: 'a1' }),
    ev('2026-01-01T00:00:02Z', { type: 'task.claimed', task: 'T1', agent: 'a1', epoch: 1 }),
  ]).get('T1');
  assert.equal(claimed.status, 'claimed');
  assert.equal(claimed.claim.agent, 'a1');

  const released = fold([
    ev('2026-01-01T00:00:01Z', { type: 'task.created', task: 'T1', agent: 'a1' }),
    ev('2026-01-01T00:00:02Z', { type: 'task.claimed', task: 'T1', agent: 'a1', epoch: 1 }),
    ev('2026-01-01T00:00:03Z', { type: 'task.released', task: 'T1', agent: 'a1', epoch: 1 }),
  ]).get('T1');
  assert.equal(released.status, 'open');
  assert.equal(released.claim, null);

  const done = fold([
    ev('2026-01-01T00:00:01Z', { type: 'task.created', task: 'T1', agent: 'a1' }),
    ev('2026-01-01T00:00:02Z', { type: 'task.claimed', task: 'T1', agent: 'a1', epoch: 1 }),
    ev('2026-01-01T00:00:03Z', { type: 'task.done', task: 'T1', agent: 'a1', epoch: 1 }),
  ]).get('T1');
  assert.equal(done.status, 'done');
  void mk;
});

test('epoch fencing: a stale-epoch mutation after ownership moved on is rejected', () => {
  // Same agent throughout: the keystone case is a revived writer replaying a mutation
  // at its own displaced epoch — different agent would be 'non-owner-agent' instead.
  const { tasks, rejections } = foldWithMeta([
    ev('2026-01-01T00:00:01Z', { type: 'task.created', task: 'T1', agent: 'a1' }),
    ev('2026-01-01T00:00:02Z', { type: 'task.claimed', task: 'T1', agent: 'a1', epoch: 1 }),
    ev('2026-01-01T00:00:03Z', { type: 'task.released', task: 'T1', agent: 'a1', epoch: 1 }),
    ev('2026-01-01T00:00:04Z', { type: 'task.claimed', task: 'T1', agent: 'a1', epoch: 2 }),
    // a1's pre-revival writer replays a mutation at its displaced epoch 1
    ev('2026-01-01T00:00:05Z', { type: 'task.scope_changed', task: 'T1', agent: 'a1', epoch: 1, paths: ['src/*'] }),
  ]);
  assert.equal(tasks.get('T1').claim.epoch, 2, 'epoch-2 claim stays the owner');
  assert.equal(rejections.length, 1, 'the stale write is recorded');
  assert.equal(rejections[0].reason, 'stale-epoch');
});

test('epoch fencing: a non-owner mutation is rejected as non-owner-agent', () => {
  const { rejections } = foldWithMeta([
    ev('2026-01-01T00:00:01Z', { type: 'task.created', task: 'T1', agent: 'a1' }),
    ev('2026-01-01T00:00:02Z', { type: 'task.claimed', task: 'T1', agent: 'a1', epoch: 1 }),
    ev('2026-01-01T00:00:03Z', { type: 'task.scope_changed', task: 'T1', agent: 'a2', epoch: 1, paths: ['x'] }),
  ]);
  assert.equal(rejections.length, 1);
  assert.equal(rejections[0].reason, 'non-owner-agent');
});

test('terminality seal: a release landing AFTER a done does not reopen the task', () => {
  const sealed = fold([
    ev('2026-01-01T00:00:01Z', { type: 'task.created', task: 'T1', agent: 'a1' }),
    ev('2026-01-01T00:00:02Z', { type: 'task.claimed', task: 'T1', agent: 'a1', epoch: 1 }),
    ev('2026-01-01T00:00:03Z', { type: 'task.done', task: 'T1', agent: 'a1', epoch: 1 }),
    // late release from the (now former) owner must not corrupt done -> open
    ev('2026-01-01T00:00:04Z', { type: 'task.released', task: 'T1', agent: 'a1', epoch: 1 }),
  ]).get('T1');
  assert.equal(sealed.status, 'done');
});

test('nextEpoch is one above the highest epoch any prior claim carried', () => {
  const events = [
    ev('2026-01-01T00:00:01Z', { type: 'task.created', task: 'T1', agent: 'a1' }),
    ev('2026-01-01T00:00:02Z', { type: 'task.claimed', task: 'T1', agent: 'a1', epoch: 1 }),
    ev('2026-01-01T00:00:03Z', { type: 'task.released', task: 'T1', agent: 'a1', epoch: 1 }),
    ev('2026-01-01T00:00:04Z', { type: 'task.claimed', task: 'T1', agent: 'a2', epoch: 2 }),
  ];
  assert.equal(nextEpoch(events, 'T1'), 3);
  assert.equal(nextEpoch([events[0]], 'T1'), 1, 'first claim gets epoch 1');
});

test('dependency.drift never seeds a projected task (phantom-open guard)', () => {
  const tasks = fold([
    ev('2026-01-01T00:00:01Z', { type: 'dependency.drift', task: 'post-commit', agent: 'a1', surface: 'src/x.js' }),
  ]);
  assert.equal(tasks.has('post-commit'), false);
});
