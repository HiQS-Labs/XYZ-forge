'use strict';

const test = require('node:test');
const assert = require('node:assert');
const { parse } = require('../src/parse');
const { balanceOf, isBalanced } = require('../src/balance');

test('a balanced day returns zero totalMinor and empty unbalanced list', () => {
  const entries = parse([
    '2026-01-04 | assets:cash | -125.40USD | coffee',
    '2026-01-04 | expenses:food | 125.40USD | coffee',
  ].join('\n'));

  const result = balanceOf(entries);
  assert.strictEqual(result.groups.length, 1);
  assert.deepStrictEqual(result.groups[0], {
    date: '2026-01-04',
    currency: 'USD',
    totalMinor: 0,
    entryCount: 2,
  });
  assert.deepStrictEqual(result.unbalanced, []);
  assert.strictEqual(isBalanced(entries), true);
});

test('an unbalanced day asserts the exact totalMinor delta', () => {
  const entries = parse([
    '2026-01-04 | assets:cash | -125.40USD | coffee',
    '2026-01-04 | expenses:food | 120.00USD | coffee',
  ].join('\n'));

  const result = balanceOf(entries);
  assert.strictEqual(result.groups.length, 1);
  // -12540 + 12000 = -540 cents (-$5.40)
  assert.deepStrictEqual(result.groups[0], {
    date: '2026-01-04',
    currency: 'USD',
    totalMinor: -540,
    entryCount: 2,
  });
  assert.strictEqual(result.unbalanced.length, 1);
  assert.deepStrictEqual(result.unbalanced[0], {
    date: '2026-01-04',
    currency: 'USD',
    totalMinor: -540,
    entryCount: 2,
  });
  assert.strictEqual(isBalanced(entries), false);
});

test('currencies on the same day are tracked independently and sorted by currency', () => {
  const entries = parse([
    '2026-01-04 | assets:cash | -100.00USD | a',
    '2026-01-04 | expenses:x | 100.00USD | a',
    '2026-01-04 | assets:eur | -50.00EUR | b',
    '2026-01-04 | expenses:y | 50.00EUR | b',
  ].join('\n'));

  const result = balanceOf(entries);
  assert.strictEqual(result.groups.length, 2);
  // EUR sorted before USD
  assert.deepStrictEqual(result.groups[0], {
    date: '2026-01-04',
    currency: 'EUR',
    totalMinor: 0,
    entryCount: 2,
  });
  assert.deepStrictEqual(result.groups[1], {
    date: '2026-01-04',
    currency: 'USD',
    totalMinor: 0,
    entryCount: 2,
  });
  assert.deepStrictEqual(result.unbalanced, []);
  assert.strictEqual(isBalanced(entries), true);
});

test('floating-point drift case: three entries of 0.10 against -0.30 proves exact zero', () => {
  // In IEEE-754 float: 0.1 + 0.1 + 0.1 - 0.3 === 5.551115123125783e-17 !== 0
  // With money minor units: 10 + 10 + 10 + (-30) === 0
  const entries = [
    { date: '2026-01-04', currency: 'USD', amount: 0.10 },
    { date: '2026-01-04', currency: 'USD', amount: 0.10 },
    { date: '2026-01-04', currency: 'USD', amount: 0.10 },
    { date: '2026-01-04', currency: 'USD', amount: -0.30 },
  ];

  const result = balanceOf(entries);
  assert.strictEqual(result.groups.length, 1);
  assert.strictEqual(result.groups[0].totalMinor, 0);
  assert.strictEqual(result.groups[0].entryCount, 4);
  assert.deepStrictEqual(result.unbalanced, []);
  assert.strictEqual(isBalanced(entries), true);
});

test('groups are sorted by date ascending, then currency ascending', () => {
  const entries = [
    { date: '2026-01-05', currency: 'USD', amount: 10.00 },
    { date: '2026-01-02', currency: 'USD', amount: 20.00 },
    { date: '2026-01-02', currency: 'EUR', amount: 30.00 },
    { date: '2026-01-05', currency: 'GBP', amount: 40.00 },
  ];

  const result = balanceOf(entries);
  assert.deepStrictEqual(result.groups, [
    { date: '2026-01-02', currency: 'EUR', totalMinor: 3000, entryCount: 1 },
    { date: '2026-01-02', currency: 'USD', totalMinor: 2000, entryCount: 1 },
    { date: '2026-01-05', currency: 'GBP', totalMinor: 4000, entryCount: 1 },
    { date: '2026-01-05', currency: 'USD', totalMinor: 1000, entryCount: 1 },
  ]);
  assert.strictEqual(result.unbalanced.length, 4);
  assert.strictEqual(isBalanced(entries), false);
});

test('empty entries list returns empty groups and unbalanced array', () => {
  const result = balanceOf([]);
  assert.deepStrictEqual(result.groups, []);
  assert.deepStrictEqual(result.unbalanced, []);
  assert.strictEqual(isBalanced([]), true);
});

test('supports string amounts in addition to number amounts', () => {
  const entries = [
    { date: '2026-01-01', currency: 'USD', amount: '125.40' },
    { date: '2026-01-01', currency: 'USD', amount: '-125.40' },
  ];
  const result = balanceOf(entries);
  assert.strictEqual(result.groups[0].totalMinor, 0);
  assert.strictEqual(isBalanced(entries), true);
});

test('rejects invalid inputs with E_INVALID or E_PRECISION', () => {
  assert.throws(() => balanceOf(null), { code: 'E_INVALID' });
  assert.throws(() => balanceOf('not iterable'), { code: 'E_INVALID' });
  assert.throws(() => balanceOf([null]), { code: 'E_INVALID' });
  assert.throws(() => balanceOf([{ date: 123, currency: 'USD', amount: 10 }]), { code: 'E_INVALID' });
  assert.throws(() => balanceOf([{ date: '2026-01-01', currency: 123, amount: 10 }]), { code: 'E_INVALID' });
  assert.throws(() => balanceOf([{ date: '2026-01-01', currency: 'USD', amount: NaN }]), { code: 'E_INVALID' });
  assert.throws(() => balanceOf([{ date: '2026-01-01', currency: 'USD', amount: Infinity }]), { code: 'E_INVALID' });
  assert.throws(() => balanceOf([{ date: '2026-01-01', currency: 'USD', amount: '12.345' }]), { code: 'E_PRECISION' });
});
