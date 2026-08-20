'use strict';

const test = require('node:test');
const assert = require('node:assert');
const { normalize, roundHalfAway } = require('../src/fx');

test('straight conversion: converts entries into target currency', () => {
  const entries = [
    {
      date: '2026-01-04',
      account: 'expenses:food',
      amount: 100,
      currency: 'EUR',
      memo: 'lunch in Paris',
      lineNo: 1,
    },
    {
      date: '2026-01-04',
      account: 'expenses:travel',
      amount: 50,
      currency: 'GBP',
      memo: 'train ticket',
      lineNo: 2,
    },
  ];

  const rates = {
    EUR: 1.08,
    GBP: 1.25,
  };

  const result = normalize(entries, rates, 'USD');

  assert.strictEqual(result.length, 2);

  assert.deepStrictEqual(result[0], {
    date: '2026-01-04',
    account: 'expenses:food',
    amount: 108.00,
    currency: 'USD',
    originalAmount: 100,
    originalCurrency: 'EUR',
    memo: 'lunch in Paris',
    lineNo: 1,
  });

  assert.deepStrictEqual(result[1], {
    date: '2026-01-04',
    account: 'expenses:travel',
    amount: 62.50,
    currency: 'USD',
    originalAmount: 50,
    originalCurrency: 'GBP',
    memo: 'train ticket',
    lineNo: 2,
  });
});

test('identity case: entry already in target passes through unchanged with rate 1', () => {
  const entries = [
    {
      date: '2026-01-04',
      account: 'assets:cash',
      amount: 125.405,
      currency: 'USD',
      memo: 'cash deposit',
    },
  ];

  // Even if rates object has a conflicting rate or omits USD, USD must pass through unchanged
  const rates = {
    USD: 999.99,
  };

  const result = normalize(entries, rates, 'USD');

  assert.strictEqual(result.length, 1);
  assert.strictEqual(result[0].amount, 125.405);
  assert.strictEqual(result[0].currency, 'USD');
  assert.strictEqual(result[0].originalAmount, 125.405);
  assert.strictEqual(result[0].originalCurrency, 'USD');
  assert.strictEqual(result[0].account, 'assets:cash');
  assert.strictEqual(result[0].memo, 'cash deposit');

  // Also verify when rates is empty
  const resultEmptyRates = normalize(entries, {}, 'USD');
  assert.strictEqual(resultEmptyRates[0].amount, 125.405);
  assert.strictEqual(resultEmptyRates[0].currency, 'USD');
});

test('input immutability: returns new array and new entry objects without mutating inputs', () => {
  const originalEntry = {
    date: '2026-01-04',
    account: 'assets:bank',
    amount: 200,
    currency: 'EUR',
    memo: 'transfer',
  };
  const entries = [originalEntry];
  const rates = { EUR: 1.1 };

  const result = normalize(entries, rates, 'USD');

  assert.notStrictEqual(result, entries);
  assert.notStrictEqual(result[0], originalEntry);

  // Verify original entry was not modified
  assert.strictEqual(originalEntry.amount, 200);
  assert.strictEqual(originalEntry.currency, 'EUR');
  assert.strictEqual(originalEntry.originalAmount, undefined);
  assert.strictEqual(originalEntry.originalCurrency, undefined);

  // Modifying result does not affect input
  result[0].amount = 999;
  assert.strictEqual(originalEntry.amount, 200);
});

test('missing rate throws Error with code E_RATE and currency property', () => {
  const entries = [
    {
      date: '2026-01-04',
      account: 'expenses:supplies',
      amount: 100,
      currency: 'JPY',
    },
  ];

  const rates = {
    EUR: 1.08,
  };

  assert.throws(
    () => {
      normalize(entries, rates, 'USD');
    },
    (err) => {
      assert.strictEqual(err.code, 'E_RATE');
      assert.strictEqual(err.currency, 'JPY');
      assert.ok(err instanceof Error);
      return true;
    }
  );

  // Missing rates parameter / null rates
  assert.throws(
    () => {
      normalize(entries, null, 'USD');
    },
    (err) => {
      assert.strictEqual(err.code, 'E_RATE');
      assert.strictEqual(err.currency, 'JPY');
      return true;
    }
  );
});

test('negative half-way rounding case: rounds half away from zero symmetrically', () => {
  // Requirement 6: Converted amounts round to 2 decimal places, half away from zero.
  // -1.005 and 1.005 must not round in opposite magnitudes.
  const posEntry = [{ amount: 1.005, currency: 'EUR' }];
  const negEntry = [{ amount: -1.005, currency: 'EUR' }];
  const rates = { EUR: 1 };

  const posResult = normalize(posEntry, rates, 'USD');
  const negResult = normalize(negEntry, rates, 'USD');

  assert.strictEqual(posResult[0].amount, 1.01);
  assert.strictEqual(negResult[0].amount, -1.01);

  // Test other half-way cases
  const halfCases = [
    { amount: 0.005, expected: 0.01 },
    { amount: -0.005, expected: -0.01 },
    { amount: 35.855, expected: 35.86 },
    { amount: -35.855, expected: -35.86 },
    { amount: 1.004, expected: 1.00 },
    { amount: -1.004, expected: -1.00 },
    { amount: 1.006, expected: 1.01 },
    { amount: -1.006, expected: -1.01 },
    { amount: 125.40, rate: 1.08, expected: 135.43 },
    { amount: -125.40, rate: 1.08, expected: -135.43 },
  ];

  for (const c of halfCases) {
    const res = normalize([{ amount: c.amount, currency: 'EUR' }], { EUR: c.rate || 1 }, 'USD');
    assert.strictEqual(res[0].amount, c.expected, `Failed for amount ${c.amount} (rate ${c.rate || 1})`);
  }
});

test('empty entries array returns empty array', () => {
  assert.deepStrictEqual(normalize([], { EUR: 1.08 }, 'USD'), []);
});
