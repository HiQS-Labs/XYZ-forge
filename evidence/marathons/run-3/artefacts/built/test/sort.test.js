'use strict';

const test = require('node:test');
const assert = require('node:assert');
const { sortEntries } = require('../src/sort');

const E = (date, account, amount, memo = '') =>
  ({ date, account, amount, currency: 'USD', memo, lineNo: 1 });

test('single key ascending by date', () => {
  const entries = [
    E('2026-01-03', 'assets:cash', 100),
    E('2026-01-01', 'assets:cash', 200),
    E('2026-01-02', 'assets:cash', 150),
  ];
  const result = sortEntries(entries, ['date']);
  assert.strictEqual(result[0].date, '2026-01-01');
  assert.strictEqual(result[1].date, '2026-01-02');
  assert.strictEqual(result[2].date, '2026-01-03');
});

test('single key descending by amount', () => {
  const entries = [
    E('2026-01-01', 'assets:cash', 100),
    E('2026-01-01', 'assets:cash', 300),
    E('2026-01-01', 'assets:cash', 200),
  ];
  const result = sortEntries(entries, ['-amount']);
  assert.strictEqual(result[0].amount, 300);
  assert.strictEqual(result[1].amount, 200);
  assert.strictEqual(result[2].amount, 100);
});

test('multi-key tie-breaking: date asc then amount desc', () => {
  const entries = [
    E('2026-01-01', 'assets:cash', 100),
    E('2026-01-02', 'assets:cash', 50),
    E('2026-01-01', 'assets:cash', 300),
    E('2026-01-02', 'assets:cash', 200),
  ];
  const result = sortEntries(entries, ['date', '-amount']);
  assert.strictEqual(result[0].date, '2026-01-01');
  assert.strictEqual(result[0].amount, 300);
  assert.strictEqual(result[1].date, '2026-01-01');
  assert.strictEqual(result[1].amount, 100);
  assert.strictEqual(result[2].date, '2026-01-02');
  assert.strictEqual(result[2].amount, 200);
  assert.strictEqual(result[3].date, '2026-01-02');
  assert.strictEqual(result[3].amount, 50);
});

test('stability: full tie preserves original order', () => {
  const entries = [
    E('2026-01-01', 'assets:cash', 100, 'first'),
    E('2026-01-01', 'assets:cash', 100, 'second'),
    E('2026-01-01', 'assets:cash', 100, 'third'),
  ];
  const result = sortEntries(entries, ['date', 'amount']);
  assert.strictEqual(result[0].memo, 'first');
  assert.strictEqual(result[1].memo, 'second');
  assert.strictEqual(result[2].memo, 'third');
});

test('unknown key throws E_SORTKEY', () => {
  const entries = [E('2026-01-01', 'assets:cash', 100)];
  assert.throws(
    () => sortEntries(entries, ['bogusKey']),
    (err) => {
      assert.strictEqual(err.code, 'E_SORTKEY');
      assert(err.message.includes('bogusKey'));
      return true;
    }
  );
});

test('input array is not mutated', () => {
  const entries = [
    E('2026-01-03', 'assets:cash', 100),
    E('2026-01-01', 'assets:cash', 200),
  ];
  const before0 = entries[0];
  const before1 = entries[1];
  sortEntries(entries, ['date']);
  assert.strictEqual(entries[0], before0);
  assert.strictEqual(entries[1], before1);
});

test('lineNo sorts lexically, not numerically', () => {
  // If lineNo were numeric, 9 < 10; lexically '10' < '9', so order differs.
  const a = { date: '2026-01-01', account: 'a', amount: 1, currency: 'USD', memo: '', lineNo: '9' };
  const b = { date: '2026-01-01', account: 'a', amount: 1, currency: 'USD', memo: '', lineNo: '10' };
  const result = sortEntries([a, b], ['lineNo']);
  // lexical: '10' < '9' so b comes first
  assert.strictEqual(result[0].lineNo, '10');
  assert.strictEqual(result[1].lineNo, '9');
});

test('empty keys returns a copy in original order', () => {
  const entries = [
    E('2026-01-03', 'assets:cash', 100),
    E('2026-01-01', 'assets:cash', 200),
    E('2026-01-02', 'assets:cash', 150),
  ];
  const result = sortEntries(entries, []);
  assert.notStrictEqual(result, entries);
  assert.strictEqual(result.length, entries.length);
  assert.strictEqual(result[0], entries[0]);
  assert.strictEqual(result[1], entries[1]);
  assert.strictEqual(result[2], entries[2]);
});
