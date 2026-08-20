'use strict';

const test = require('node:test');
const assert = require('node:assert');
const { parse } = require('../src/parse');
const { reconcile, isReconciled } = require('../src/reconcile');

test('identical ledgers produce only matched groups and isReconciled true', () => {
  const ledgerA = parse([
    '2026-01-04 | assets:cash | -125.40USD | coffee',
    '2026-01-04 | expenses:food | 125.40USD | coffee',
    '2026-01-05 | assets:bank | -50.00EUR | lunch',
    '2026-01-05 | expenses:food | 50.00EUR | lunch',
  ].join('\n'));

  const ledgerB = parse([
    '2026-01-04 | assets:cash | -125.40USD | coffee beans',
    '2026-01-04 | expenses:food | 125.40USD | coffee beans',
    '2026-01-05 | assets:bank | -50.00EUR | lunch meal',
    '2026-01-05 | expenses:food | 50.00EUR | lunch meal',
  ].join('\n'));

  const result = reconcile(ledgerA, ledgerB);

  assert.deepStrictEqual(result.matched, [
    { date: '2026-01-04', currency: 'USD', totalMinor: 0 },
    { date: '2026-01-05', currency: 'EUR', totalMinor: 0 },
  ]);
  assert.deepStrictEqual(result.onlyInA, []);
  assert.deepStrictEqual(result.onlyInB, []);
  assert.deepStrictEqual(result.mismatched, []);
  assert.strictEqual(isReconciled(result), true);
});

test('a one-sided date appears in onlyInA or onlyInB', () => {
  const ledgerA = parse([
    '2026-01-04 | assets:cash | 100.00USD | deposit',
    '2026-01-05 | assets:cash | 200.00USD | deposit',
  ].join('\n'));

  const ledgerB = parse([
    '2026-01-04 | assets:cash | 100.00USD | deposit',
    '2026-01-06 | assets:cash | 300.00USD | deposit',
  ].join('\n'));

  const result = reconcile(ledgerA, ledgerB);

  assert.deepStrictEqual(result.matched, [
    { date: '2026-01-04', currency: 'USD', totalMinor: 10000 },
  ]);
  assert.strictEqual(result.onlyInA.length, 1);
  assert.deepStrictEqual(result.onlyInA[0], {
    date: '2026-01-05',
    currency: 'USD',
    totalMinor: 20000,
    entryCount: 1,
  });
  assert.strictEqual(result.onlyInB.length, 1);
  assert.deepStrictEqual(result.onlyInB[0], {
    date: '2026-01-06',
    currency: 'USD',
    totalMinor: 30000,
    entryCount: 1,
  });
  assert.deepStrictEqual(result.mismatched, []);
  assert.strictEqual(isReconciled(result), false);
});

test('a same-date total mismatch asserts the exact deltaMinor', () => {
  const ledgerA = parse([
    '2026-01-04 | assets:cash | 125.40USD | sales',
  ].join('\n'));

  const ledgerB = parse([
    '2026-01-04 | assets:cash | 120.00USD | sales',
  ].join('\n'));

  const result = reconcile(ledgerA, ledgerB);

  assert.deepStrictEqual(result.matched, []);
  assert.deepStrictEqual(result.onlyInA, []);
  assert.deepStrictEqual(result.onlyInB, []);
  assert.strictEqual(result.mismatched.length, 1);
  // delta = a - b = 12540 - 12000 = 540
  assert.deepStrictEqual(result.mismatched[0], {
    date: '2026-01-04',
    currency: 'USD',
    aMinor: 12540,
    bMinor: 12000,
    deltaMinor: 540,
  });
  assert.strictEqual(isReconciled(result), false);
});

test('a negative deltaMinor when ledger B has a larger amount than ledger A', () => {
  const ledgerA = parse([
    '2026-01-04 | assets:cash | -125.40USD | expense',
  ].join('\n'));

  const ledgerB = parse([
    '2026-01-04 | assets:cash | -120.00USD | expense',
  ].join('\n'));

  const result = reconcile(ledgerA, ledgerB);

  assert.strictEqual(result.mismatched.length, 1);
  // delta = a - b = -12540 - (-12000) = -540
  assert.deepStrictEqual(result.mismatched[0], {
    date: '2026-01-04',
    currency: 'USD',
    aMinor: -12540,
    bMinor: -12000,
    deltaMinor: -540,
  });
  assert.strictEqual(isReconciled(result), false);
});

test('a currency present on only one side on the same date', () => {
  const ledgerA = parse([
    '2026-01-04 | assets:cash | 100.00USD | usd entry',
    '2026-01-04 | assets:fx | 50.00EUR | eur entry',
  ].join('\n'));

  const ledgerB = parse([
    '2026-01-04 | assets:cash | 100.00USD | usd entry',
    '2026-01-04 | assets:fx | 75.00GBP | gbp entry',
  ].join('\n'));

  const result = reconcile(ledgerA, ledgerB);

  assert.deepStrictEqual(result.matched, [
    { date: '2026-01-04', currency: 'USD', totalMinor: 10000 },
  ]);
  assert.strictEqual(result.onlyInA.length, 1);
  assert.deepStrictEqual(result.onlyInA[0], {
    date: '2026-01-04',
    currency: 'EUR',
    totalMinor: 5000,
    entryCount: 1,
  });
  assert.strictEqual(result.onlyInB.length, 1);
  assert.deepStrictEqual(result.onlyInB[0], {
    date: '2026-01-04',
    currency: 'GBP',
    totalMinor: 7500,
    entryCount: 1,
  });
  assert.deepStrictEqual(result.mismatched, []);
  assert.strictEqual(isReconciled(result), false);
});

test('determinism: running reconcile twice yields byte-identical results and deep equality', () => {
  const textA = [
    '2026-01-03 | assets:a | 10.00USD | t1',
    '2026-01-01 | assets:b | 20.00EUR | t2',
    '2026-01-02 | assets:c | 30.00GBP | t3',
  ].join('\n');

  const textB = [
    '2026-01-02 | assets:c | 30.00GBP | t3',
    '2026-01-01 | assets:b | 25.00EUR | t2-diff',
    '2026-01-04 | assets:d | 40.00USD | t4-only-b',
  ].join('\n');

  const ledgerA1 = parse(textA);
  const ledgerB1 = parse(textB);
  const result1 = reconcile(ledgerA1, ledgerB1);

  const ledgerA2 = parse(textA);
  const ledgerB2 = parse(textB);
  const result2 = reconcile(ledgerA2, ledgerB2);

  assert.deepStrictEqual(result1, result2);
  assert.strictEqual(JSON.stringify(result1), JSON.stringify(result2));
});

test('all output arrays are sorted chronologically by date, then currency ascending', () => {
  const ledgerA = [
    { date: '2026-01-05', currency: 'USD', amount: 10.00 },
    { date: '2026-01-02', currency: 'USD', amount: 20.00 },
    { date: '2026-01-02', currency: 'EUR', amount: 30.00 },
    { date: '2026-01-01', currency: 'USD', amount: 50.00 },
    { date: '2026-01-03', currency: 'CAD', amount: 70.00 },
  ];

  const ledgerB = [
    { date: '2026-01-05', currency: 'USD', amount: 15.00 }, // mismatched
    { date: '2026-01-02', currency: 'USD', amount: 20.00 }, // matched
    { date: '2026-01-02', currency: 'EUR', amount: 30.00 }, // matched
    { date: '2026-01-04', currency: 'AUD', amount: 90.00 }, // only in B
  ];

  const result = reconcile(ledgerA, ledgerB);

  assert.deepStrictEqual(result.matched, [
    { date: '2026-01-02', currency: 'EUR', totalMinor: 3000 },
    { date: '2026-01-02', currency: 'USD', totalMinor: 2000 },
  ]);

  assert.deepStrictEqual(result.onlyInA, [
    { date: '2026-01-01', currency: 'USD', totalMinor: 5000, entryCount: 1 },
    { date: '2026-01-03', currency: 'CAD', totalMinor: 7000, entryCount: 1 },
  ]);

  assert.deepStrictEqual(result.onlyInB, [
    { date: '2026-01-04', currency: 'AUD', totalMinor: 9000, entryCount: 1 },
  ]);

  assert.deepStrictEqual(result.mismatched, [
    { date: '2026-01-05', currency: 'USD', aMinor: 1000, bMinor: 1500, deltaMinor: -500 },
  ]);

  assert.strictEqual(isReconciled(result), false);
});

test('floating-point drift case: 0.10 + 0.10 + 0.10 vs 0.30 reconciles to exact zero mismatch', () => {
  const ledgerA = [
    { date: '2026-01-04', currency: 'USD', amount: 0.10 },
    { date: '2026-01-04', currency: 'USD', amount: 0.10 },
    { date: '2026-01-04', currency: 'USD', amount: 0.10 },
  ];

  const ledgerB = [
    { date: '2026-01-04', currency: 'USD', amount: 0.30 },
  ];

  const result = reconcile(ledgerA, ledgerB);

  assert.strictEqual(result.matched.length, 1);
  assert.deepStrictEqual(result.matched[0], {
    date: '2026-01-04',
    currency: 'USD',
    totalMinor: 30,
  });
  assert.deepStrictEqual(result.mismatched, []);
  assert.strictEqual(isReconciled(result), true);
});

test('empty ledgers reconcile with all empty arrays and isReconciled true', () => {
  const result = reconcile([], []);
  assert.deepStrictEqual(result.matched, []);
  assert.deepStrictEqual(result.onlyInA, []);
  assert.deepStrictEqual(result.onlyInB, []);
  assert.deepStrictEqual(result.mismatched, []);
  assert.strictEqual(isReconciled(result), true);
});

test('isReconciled returns false for non-empty discrepancies or invalid result objects', () => {
  assert.strictEqual(isReconciled(null), false);
  assert.strictEqual(isReconciled(undefined), false);
  assert.strictEqual(isReconciled({}), false);
  assert.strictEqual(isReconciled({ matched: [], onlyInA: [{}], onlyInB: [], mismatched: [] }), false);
  assert.strictEqual(isReconciled({ matched: [], onlyInA: [], onlyInB: [{}], mismatched: [] }), false);
  assert.strictEqual(isReconciled({ matched: [], onlyInA: [], onlyInB: [], mismatched: [{}] }), false);
  assert.strictEqual(isReconciled({ matched: [{ date: '2026-01-01', currency: 'USD', totalMinor: 100 }], onlyInA: [], onlyInB: [], mismatched: [] }), true);
});

test('reconcile throws E_INVALID if inputs are not iterables', () => {
  assert.throws(() => reconcile(null, []), { code: 'E_INVALID' });
  assert.throws(() => reconcile([], null), { code: 'E_INVALID' });
  assert.throws(() => reconcile('not iterable', []), { code: 'E_INVALID' });
});
