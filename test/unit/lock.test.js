'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { appendEvent } = require('../../src/events');

function tmpRepo() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'tick-lock-test-'));
}

test('lock rejects malformed task/agent at write time', () => {
  const root = tmpRepo();
  try {
    assert.throws(() => {
      appendEvent(root, { type: 'task.created', task: 'foo/bar', agent: 'A' });
    }, /invalid task format: "foo\/bar"/);

    assert.throws(() => {
      appendEvent(root, { type: 'task.created', task: 'T1', agent: 'foo/bar' });
    }, /invalid agent format: "foo\/bar"/);

    // valid
    appendEvent(root, { type: 'task.created', task: 'T1', agent: 'A' });

    assert.throws(() => {
      appendEvent(root, { type: 'task.created', task: 'T2', agent: 'B', priority: 'abc' });
    }, /invalid priority: "abc"/);

    assert.throws(() => {
      appendEvent(root, { type: 'task.created', task: 'T2', agent: 'B', priority: NaN });
    }, /invalid priority: "NaN"/);

    assert.throws(() => {
      appendEvent(root, { type: 'task.created', task: 'T2', agent: 'B', epoch: -1 });
    }, /invalid epoch: "-1"/);

    assert.throws(() => {
      appendEvent(root, { type: 'task.created', task: 'T2', agent: 'B', epoch: 1.5 });
    }, /invalid epoch: "1.5"/);

  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});
