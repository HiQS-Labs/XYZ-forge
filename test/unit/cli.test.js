'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

function tmpRepo() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'tick-cli-test-'));
}

const TICK_BIN = path.resolve(__dirname, '../../bin/tick');

test('cli priority and epoch bounds checking', () => {
  const root = tmpRepo();
  try {
    // init
    execFileSync(TICK_BIN, ['init'], { cwd: root, env: { ...process.env, TICK_REPO_ROOT: root } });

    // --priority abc (reject)
    assert.throws(() => {
      execFileSync(TICK_BIN, ['log', 'task.created', 'T1', '--agent', 'A', '--priority', 'abc'], { cwd: root, env: { ...process.env, TICK_REPO_ROOT: root }, stdio: 'pipe' });
    }, /invalid priority: "abc"/);

    // --epoch -1 (reject)
    assert.throws(() => {
      execFileSync(TICK_BIN, ['log', 'task.created', 'T2', '--agent', 'A', '--epoch', '-1'], { cwd: root, env: { ...process.env, TICK_REPO_ROOT: root }, stdio: 'pipe' });
    }, /invalid epoch: "-1"/);

    // --epoch 1.5 (reject)
    assert.throws(() => {
      execFileSync(TICK_BIN, ['log', 'task.created', 'T2.5', '--agent', 'A', '--epoch', '1.5'], { cwd: root, env: { ...process.env, TICK_REPO_ROOT: root }, stdio: 'pipe' });
    }, /invalid epoch: "1.5"/);

    // --priority 3 (accept)
    execFileSync(TICK_BIN, ['log', 'task.created', 'T3', '--agent', 'A', '--priority', '3'], { cwd: root, env: { ...process.env, TICK_REPO_ROOT: root } });

    // verify it wrote T3
    const events = require('../../src/events').readAllEvents(root);
    assert.equal(events.length, 1);
    assert.equal(events[0].task, 'T3');
    assert.equal(events[0].priority, 3);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test('cli rejects malformed task/agent strings', () => {
  const root = tmpRepo();
  try {
    execFileSync(TICK_BIN, ['init'], { cwd: root, env: { ...process.env, TICK_REPO_ROOT: root } });

    assert.throws(() => {
      execFileSync(TICK_BIN, ['log', 'task.created', 'bad/task', '--agent', 'A'], { cwd: root, env: { ...process.env, TICK_REPO_ROOT: root }, stdio: 'pipe' });
    }, /invalid task format: "bad\/task"/);

    assert.throws(() => {
      execFileSync(TICK_BIN, ['log', 'task.created', 'T1', '--agent', 'bad agent'], { cwd: root, env: { ...process.env, TICK_REPO_ROOT: root }, stdio: 'pipe' });
    }, /invalid agent format: "bad agent"/);

  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});
