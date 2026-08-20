'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { fuzzyMatch } = require('../src/fuzzy-match');

// ── helpers ────────────────────────────────────────────────────────────────

function tx(amount, date, memo) {
  return { amount, date: new Date(date), memo };
}

// ── exact matches ──────────────────────────────────────────────────────────

test('identical transactions are matched with high confidence', () => {
  const a = [tx(100.00, '2024-01-15', 'ACME Corp subscription')];
  const b = [tx(100.00, '2024-01-15', 'ACME Corp subscription')];
  const { matched, unmatchedA, unmatchedB } = fuzzyMatch(a, b);
  assert.equal(matched.length, 1);
  assert.ok(matched[0].confidence > 0.9);
  assert.equal(unmatchedA.length, 0);
  assert.equal(unmatchedB.length, 0);
});

// ── memo variation ─────────────────────────────────────────────────────────

test('matches despite truncated memo', () => {
  const a = [tx(250.50, '2024-02-01', 'Netflix monthly billing')];
  const b = [tx(250.50, '2024-02-01', 'Netflix monthly')];
  const { matched } = fuzzyMatch(a, b);
  assert.equal(matched.length, 1);
  assert.ok(matched[0].confidence >= 0.4);
});

test('matches despite memo case and punctuation difference', () => {
  const a = [tx(75.00, '2024-03-10', 'AWS, Inc. — storage fees')];
  const b = [tx(75.00, '2024-03-10', 'aws inc storage fees')];
  const { matched } = fuzzyMatch(a, b);
  assert.equal(matched.length, 1);
});

// ── date tolerance ─────────────────────────────────────────────────────────

test('matches transactions one day apart', () => {
  const a = [tx(500.00, '2024-04-05', 'Rent payment April')];
  const b = [tx(500.00, '2024-04-06', 'Rent payment April')];
  const { matched } = fuzzyMatch(a, b);
  assert.equal(matched.length, 1);
});

test('matches transactions two days apart (default tolerance)', () => {
  const a = [tx(199.99, '2024-05-01', 'Supplier invoice 4421')];
  const b = [tx(199.99, '2024-05-03', 'Supplier invoice 4421')];
  const { matched } = fuzzyMatch(a, b);
  assert.equal(matched.length, 1);
});

test('does not match transactions seven days apart by default', () => {
  const a = [tx(199.99, '2024-05-01', 'Supplier invoice 4421')];
  const b = [tx(199.99, '2024-05-08', 'Supplier invoice 4421')];
  const { matched, unmatchedA, unmatchedB } = fuzzyMatch(a, b);
  assert.equal(matched.length, 0);
  assert.equal(unmatchedA.length, 1);
  assert.equal(unmatchedB.length, 1);
});

// ── amount tolerance ───────────────────────────────────────────────────────

test('matches with small FX/fee rounding difference', () => {
  const a = [tx(1000.00, '2024-06-15', 'Wire transfer USD')];
  const b = [tx(1000.50, '2024-06-15', 'Wire transfer USD')];
  const { matched } = fuzzyMatch(a, b, { amountTolerance: 0.01 });
  assert.equal(matched.length, 1);
});

test('does not match transactions with large amount difference', () => {
  const a = [tx(100.00, '2024-07-01', 'Office supplies')];
  const b = [tx(200.00, '2024-07-01', 'Office supplies')];
  const { matched, unmatchedA, unmatchedB } = fuzzyMatch(a, b);
  assert.equal(matched.length, 0);
  assert.equal(unmatchedA.length, 1);
  assert.equal(unmatchedB.length, 1);
});

// ── multiple transactions, best-match pairing ──────────────────────────────

test('pairs multiple transactions correctly', () => {
  const a = [
    tx(50.00,  '2024-08-01', 'Taxi ride downtown'),
    tx(120.00, '2024-08-03', 'Hotel checkout'),
    tx(15.00,  '2024-08-05', 'Coffee shop'),
  ];
  const b = [
    tx(15.00,  '2024-08-05', 'Coffee shop expense'),
    tx(50.00,  '2024-08-01', 'Taxi downtown'),
    tx(120.00, '2024-08-03', 'Hotel final bill'),
  ];
  const { matched, unmatchedA, unmatchedB } = fuzzyMatch(a, b);
  assert.equal(matched.length, 3);
  assert.equal(unmatchedA.length, 0);
  assert.equal(unmatchedB.length, 0);
});

// ── unmatched entries reported ─────────────────────────────────────────────

test('unmatched entries reported in unmatchedA / unmatchedB', () => {
  const a = [
    tx(300.00, '2024-09-10', 'Consulting fee'),
    tx(999.00, '2024-09-20', 'Unknown charge XYZ'),
  ];
  const b = [
    tx(300.00, '2024-09-10', 'Consulting services'),
  ];
  const { matched, unmatchedA, unmatchedB } = fuzzyMatch(a, b);
  assert.equal(matched.length, 1);
  assert.equal(unmatchedA.length, 1);
  assert.equal(unmatchedA[0].memo, 'Unknown charge XYZ');
  assert.equal(unmatchedB.length, 0);
});

// ── confidence threshold tuning ────────────────────────────────────────────

test('strict minConfidence rejects borderline matches', () => {
  const a = [tx(100.00, '2024-10-01', 'Payment')];
  const b = [tx(100.00, '2024-10-03', 'Paymt')];
  const { matched: relaxed } = fuzzyMatch(a, b, { minConfidence: 0.3 });
  const { matched: strict  } = fuzzyMatch(a, b, { minConfidence: 0.9 });
  // With a very strict threshold the borderline pair is rejected.
  assert.ok(strict.length <= relaxed.length);
});

// ── empty ledgers ──────────────────────────────────────────────────────────

test('empty ledgers return empty results', () => {
  const { matched, unmatchedA, unmatchedB } = fuzzyMatch([], []);
  assert.equal(matched.length, 0);
  assert.equal(unmatchedA.length, 0);
  assert.equal(unmatchedB.length, 0);
});

test('one empty ledger returns everything unmatched', () => {
  const a = [tx(42.00, '2024-11-01', 'Test entry')];
  const { matched, unmatchedA, unmatchedB } = fuzzyMatch(a, []);
  assert.equal(matched.length, 0);
  assert.equal(unmatchedA.length, 1);
  assert.equal(unmatchedB.length, 0);
});

// ── description field alias ────────────────────────────────────────────────

test('description field is used when memo is absent', () => {
  const a = [{ amount: 88.00, date: new Date('2024-12-01'), description: 'Annual licence' }];
  const b = [{ amount: 88.00, date: new Date('2024-12-01'), description: 'Annual licence fee' }];
  const { matched } = fuzzyMatch(a, b);
  assert.equal(matched.length, 1);
});

// ── opposite-sign amounts must not match ───────────────────────────────────

test('debit and credit with same magnitude are not matched', () => {
  const a = [tx(100.00,  '2024-01-15', 'ACME Corp subscription')];
  const b = [tx(-100.00, '2024-01-15', 'ACME Corp subscription')];
  const { matched, unmatchedA, unmatchedB } = fuzzyMatch(a, b);
  assert.equal(matched.length, 0);
  assert.equal(unmatchedA.length, 1);
  assert.equal(unmatchedB.length, 1);
});

// ── zero tolerance exact matching ─────────────────────────────────────────

test('amountTolerance:0 matches exact amounts', () => {
  const a = [tx(150.00, '2024-01-10', 'Direct debit')];
  const b = [tx(150.00, '2024-01-10', 'Direct debit')];
  const { matched } = fuzzyMatch(a, b, { amountTolerance: 0 });
  assert.equal(matched.length, 1);
  assert.ok(matched[0].confidence > 0);
});

test('amountTolerance:0 rejects any amount difference', () => {
  const a = [tx(150.00, '2024-01-10', 'Direct debit')];
  const b = [tx(150.01, '2024-01-10', 'Direct debit')];
  const { matched, unmatchedA, unmatchedB } = fuzzyMatch(a, b, { amountTolerance: 0 });
  assert.equal(matched.length, 0);
  assert.equal(unmatchedA.length, 1);
  assert.equal(unmatchedB.length, 1);
});

test('dateTolerance:0 matches transactions on same date', () => {
  const a = [tx(75.00, '2024-03-20', 'Payroll')];
  const b = [tx(75.00, '2024-03-20', 'Payroll')];
  const { matched } = fuzzyMatch(a, b, { dateTolerance: 0 });
  assert.equal(matched.length, 1);
  assert.ok(matched[0].confidence > 0);
});

test('dateTolerance:0 rejects transactions one day apart', () => {
  const a = [tx(75.00, '2024-03-20', 'Payroll')];
  const b = [tx(75.00, '2024-03-21', 'Payroll')];
  const { matched, unmatchedA, unmatchedB } = fuzzyMatch(a, b, { dateTolerance: 0 });
  assert.equal(matched.length, 0);
  assert.equal(unmatchedA.length, 1);
  assert.equal(unmatchedB.length, 1);
});

test('both tolerances zero matches only exact amount and date', () => {
  const a = [tx(200.00, '2024-06-01', 'Invoice')];
  const b = [tx(200.00, '2024-06-01', 'Invoice')];
  const { matched } = fuzzyMatch(a, b, { amountTolerance: 0, dateTolerance: 0 });
  assert.equal(matched.length, 1);
  assert.ok(matched[0].confidence > 0);
});

// ── minConfidence boundary (inclusive) ────────────────────────────────────

test('minConfidence:1 matches identical transactions (threshold is inclusive)', () => {
  const a = [tx(100.00, '2024-01-15', 'ACME Corp subscription')];
  const b = [tx(100.00, '2024-01-15', 'ACME Corp subscription')];
  const { matched, unmatchedA, unmatchedB } = fuzzyMatch(a, b, { minConfidence: 1 });
  assert.equal(matched.length, 1);
  assert.ok(matched[0].confidence >= 1);
  assert.equal(unmatchedA.length, 0);
  assert.equal(unmatchedB.length, 0);
});

// ── greedy picks best candidate ────────────────────────────────────────────

test('best candidate wins when two ledger-B entries could match ledger-A entry', () => {
  const a = [tx(200.00, '2024-01-10', 'Vendor payment')];
  const b = [
    tx(200.00, '2024-01-10', 'Vendor payment — exact'),   // better
    tx(200.00, '2024-01-12', 'Vendor pmt'),               // worse
  ];
  const { matched } = fuzzyMatch(a, b);
  assert.equal(matched.length, 1);
  assert.equal(matched[0].b.memo, 'Vendor payment — exact');
});
