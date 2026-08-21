'use strict';

const test = require('node:test');
const assert = require('node:assert');
const { parse } = require('../src/parse');
const { reconcile } = require('../src/reconcile');
const { renderReport } = require('../src/report');

test('empty reconcile result renders all four sections with (none)', () => {
  const result = {
    matched: [],
    onlyInA: [],
    onlyInB: [],
    mismatched: [],
  };

  const report = renderReport(result);
  const expected = [
    'MATCHED',
    '  (none)',
    'ONLY IN A',
    '  (none)',
    'ONLY IN B',
    '  (none)',
    'MISMATCHED',
    '  (none)',
  ].join('\n');

  assert.strictEqual(report, expected);
});

test('fully reconciled result renders matched entries and (none) for discrepancies', () => {
  const result = {
    matched: [
      { date: '2026-01-04', currency: 'USD', totalMinor: 12540 },
      { date: '2026-01-05', currency: 'EUR', totalMinor: 5000 },
    ],
    onlyInA: [],
    onlyInB: [],
    mismatched: [],
  };

  const report = renderReport(result);
  const expected = [
    'MATCHED',
    '  2026-01-04  USD  125.40',
    '  2026-01-05  EUR   50.00',
    'ONLY IN A',
    '  (none)',
    'ONLY IN B',
    '  (none)',
    'MISMATCHED',
    '  (none)',
  ].join('\n');

  assert.strictEqual(report, expected);
});

test('mismatch rows show both sides and delta with exact money formatting', () => {
  const result = {
    matched: [],
    onlyInA: [],
    onlyInB: [],
    mismatched: [
      {
        date: '2026-01-04',
        currency: 'USD',
        aMinor: 12540,
        bMinor: 12000,
        deltaMinor: 540,
      },
      {
        date: '2026-01-05',
        currency: 'EUR',
        aMinor: -12540,
        bMinor: -12000,
        deltaMinor: -540,
      },
    ],
  };

  const report = renderReport(result);
  const expected = [
    'MATCHED',
    '  (none)',
    'ONLY IN A',
    '  (none)',
    'ONLY IN B',
    '  (none)',
    'MISMATCHED',
    '  2026-01-04  USD  A:  125.40  B:  120.00  delta:    5.40',
    '  2026-01-05  EUR  A: -125.40  B: -120.00  delta:   -5.40',
  ].join('\n');

  assert.strictEqual(report, expected);
});

test('column alignment holds across a wide magnitude range, signs, and date/currency lengths', () => {
  const result = {
    matched: [
      { date: '2026-01-01', currency: 'USD', totalMinor: 1 }, // 0.01 (len 4)
      { date: '2026-01-02', currency: 'USD', totalMinor: 100000000000 }, // 1000000000.00 (len 13)
      { date: '2026-01-03', currency: 'USD', totalMinor: -9999999900 }, // -99999999.00 (len 12)
    ],
    onlyInA: [
      { date: '2026-01-04', currency: 'USDT', totalMinor: 50 }, // 0.50 (len 4)
    ],
    onlyInB: [
      { date: '2026-01-05', currency: 'EUR', totalMinor: 2500 }, // 25.00 (len 5)
    ],
    mismatched: [
      {
        date: '2026-01-06',
        currency: 'GBP',
        aMinor: 500, // 5.00 (len 4)
        bMinor: 100000000000, // 1000000000.00 (len 13)
        deltaMinor: -99999999500, // -999999995.00 (len 13)
      },
    ],
  };

  const report = renderReport(result);
  const lines = report.split('\n');

  // Verify section headers
  assert.strictEqual(lines[0], 'MATCHED');
  assert.strictEqual(lines[4], 'ONLY IN A');
  assert.strictEqual(lines[6], 'ONLY IN B');
  assert.strictEqual(lines[8], 'MISMATCHED');

  // Max currency length is 4 ("USDT")
  // Max date length is 10 ("2026-01-01")
  // Max amount length is 13 ("1000000000.00" / "-999999995.00")
  assert.strictEqual(lines[1], '  2026-01-01  USD            0.01');
  assert.strictEqual(lines[2], '  2026-01-02  USD   1000000000.00');
  assert.strictEqual(lines[3], '  2026-01-03  USD    -99999999.00');
  assert.strictEqual(lines[5], '  2026-01-04  USDT           0.50');
  assert.strictEqual(lines[7], '  2026-01-05  EUR           25.00');
  assert.strictEqual(lines[9], '  2026-01-06  GBP   A:          5.00  B: 1000000000.00  delta: -999999995.00');

  // Verify decimal point and column alignment across all single-amount lines
  const singleRowIndices = [1, 2, 3, 5, 7];
  for (const idx of singleRowIndices) {
    const line = lines[idx];
    assert.strictEqual(line.length, 33);
    assert.strictEqual(line.slice(0, 2), '  ');
    // Date is at columns 2..11 (width 10)
    assert.strictEqual(line.slice(12, 14), '  ');
    // Currency is at columns 14..17 (width 4)
    assert.strictEqual(line.slice(18, 20), '  ');
    // Decimal point is always at column 30
    assert.strictEqual(line[30], '.');
  }
});

test('summaryOnly option returns one-line verdict', () => {
  const reconciledResult = {
    matched: [{ date: '2026-01-04', currency: 'USD', totalMinor: 1000 }],
    onlyInA: [],
    onlyInB: [],
    mismatched: [],
  };

  assert.strictEqual(
    renderReport(reconciledResult, { summaryOnly: true }),
    'RECONCILED'
  );

  const emptyResult = {
    matched: [],
    onlyInA: [],
    onlyInB: [],
    mismatched: [],
  };

  assert.strictEqual(
    renderReport(emptyResult, { summaryOnly: true }),
    'RECONCILED'
  );

  const unreconciledResult = {
    matched: [{ date: '2026-01-04', currency: 'USD', totalMinor: 1000 }],
    onlyInA: [
      { date: '2026-01-05', currency: 'USD', totalMinor: 2000, entryCount: 1 },
    ],
    onlyInB: [
      { date: '2026-01-06', currency: 'USD', totalMinor: 3000, entryCount: 1 },
      { date: '2026-01-07', currency: 'EUR', totalMinor: 4000, entryCount: 1 },
    ],
    mismatched: [
      { date: '2026-01-08', currency: 'GBP', aMinor: 1000, bMinor: 2000, deltaMinor: -1000 },
    ],
  };

  assert.strictEqual(
    renderReport(unreconciledResult, { summaryOnly: true }),
    'NOT RECONCILED: 1 mismatched, 1 only-in-A, 2 only-in-B'
  );
});

test('end-to-end integration: parses ledgers, reconciles, and renders report', () => {
  const ledgerA = parse([
    '2026-01-01 | assets:bank | 100.00USD | salary',
    '2026-01-02 | assets:cash | 50.00EUR  | refund',
    '2026-01-03 | assets:bank | 200.00USD | bonus',
  ].join('\n'));

  const ledgerB = parse([
    '2026-01-01 | assets:bank | 100.00USD | salary',
    '2026-01-02 | assets:cash | 40.00EUR  | refund-less',
    '2026-01-04 | assets:bank | 300.00GBP | payment',
  ].join('\n'));

  const result = reconcile(ledgerA, ledgerB);
  const fullReport = renderReport(result);

  const expectedFull = [
    'MATCHED',
    '  2026-01-01  USD  100.00',
    'ONLY IN A',
    '  2026-01-03  USD  200.00',
    'ONLY IN B',
    '  2026-01-04  GBP  300.00',
    'MISMATCHED',
    '  2026-01-02  EUR  A:  50.00  B:  40.00  delta:  10.00',
  ].join('\n');

  assert.strictEqual(fullReport, expectedFull);

  const summary = renderReport(result, { summaryOnly: true });
  assert.strictEqual(summary, 'NOT RECONCILED: 1 mismatched, 1 only-in-A, 1 only-in-B');
});

test('determinism: running renderReport multiple times produces identical output without mutating input', () => {
  const result = {
    matched: [{ date: '2026-01-01', currency: 'USD', totalMinor: 1000 }],
    onlyInA: [{ date: '2026-01-02', currency: 'EUR', totalMinor: 2000, entryCount: 1 }],
    onlyInB: [{ date: '2026-01-03', currency: 'GBP', totalMinor: 3000, entryCount: 1 }],
    mismatched: [{ date: '2026-01-04', currency: 'CAD', aMinor: 4000, bMinor: 5000, deltaMinor: -1000 }],
  };

  const copy = JSON.parse(JSON.stringify(result));
  const out1 = renderReport(result);
  const out2 = renderReport(result);

  assert.strictEqual(out1, out2);
  assert.deepStrictEqual(result, copy);
});

test('error handling: throws E_INVALID if result is not an object', () => {
  assert.throws(() => renderReport(null), { code: 'E_INVALID' });
  assert.throws(() => renderReport(undefined), { code: 'E_INVALID' });
  assert.throws(() => renderReport('invalid'), { code: 'E_INVALID' });
  assert.throws(() => renderReport(123), { code: 'E_INVALID' });
});

test('gracefully handles missing result arrays by treating them as empty', () => {
  const report = renderReport({});
  const expected = [
    'MATCHED',
    '  (none)',
    'ONLY IN A',
    '  (none)',
    'ONLY IN B',
    '  (none)',
    'MISMATCHED',
    '  (none)',
  ].join('\n');

  assert.strictEqual(report, expected);
});
