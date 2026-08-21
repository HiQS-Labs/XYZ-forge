'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { parse } = require('../src/parse');
const { findDuplicates, normalizeMemo } = require('../src/dedupe');

test('returns empty array when no duplicates exist', () => {
  const entries = parse([
    '2026-01-04 | assets:cash | -10.00USD | lunch',
    '2026-01-04 | assets:cash | -20.00USD | dinner',
    '2026-01-05 | assets:cash | -10.00USD | lunch',
  ].join('\n'));

  const duplicates = findDuplicates(entries);
  assert.deepStrictEqual(duplicates, []);
});

test('handles empty input gracefully', () => {
  assert.deepStrictEqual(findDuplicates([]), []);
  assert.deepStrictEqual(findDuplicates(null), []);
  assert.deepStrictEqual(findDuplicates(undefined), []);
});

test('detects an exact duplicate pair', () => {
  const entries = parse([
    '2026-01-04 | assets:cash | -125.40USD | coffee beans',
    '2026-01-04 | expenses:food | 125.40USD | coffee beans',
    '2026-01-04 | assets:cash | -125.40USD | coffee beans',
  ].join('\n'));

  const duplicates = findDuplicates(entries);
  assert.strictEqual(duplicates.length, 1);
  assert.strictEqual(duplicates[0].count, 2);
  assert.strictEqual(duplicates[0].entries.length, 2);
  assert.strictEqual(duplicates[0].entries[0].lineNo, 1);
  assert.strictEqual(duplicates[0].entries[1].lineNo, 3);
  assert.strictEqual(duplicates[0].key, '2026-01-04|assets:cash|-125.4|USD|coffee beans');
});

test('detects a duplicate triple', () => {
  const entries = parse([
    '2026-01-04 | assets:cash | -50.00USD | groceries',
    '2026-01-04 | assets:cash | -50.00USD | groceries',
    '2026-01-04 | assets:cash | -50.00USD | groceries',
  ].join('\n'));

  const duplicates = findDuplicates(entries);
  assert.strictEqual(duplicates.length, 1);
  assert.strictEqual(duplicates[0].count, 3);
  assert.strictEqual(duplicates[0].entries.length, 3);
  assert.strictEqual(duplicates[0].entries[0].lineNo, 1);
  assert.strictEqual(duplicates[0].entries[1].lineNo, 2);
  assert.strictEqual(duplicates[0].entries[2].lineNo, 3);
});

test('normalizes memo whitespace and case matching "Coffee  Beans" with "coffee beans"', () => {
  const entries = parse([
    '2026-01-04 | assets:cash | -125.40USD | Coffee  Beans',
    '2026-01-04 | assets:cash | -125.40USD | coffee beans',
    '2026-01-04 | assets:cash | -125.40USD |   COFFEE   BEANS  ',
  ].join('\n'));

  const duplicates = findDuplicates(entries);
  assert.strictEqual(duplicates.length, 1);
  assert.strictEqual(duplicates[0].count, 3);
  assert.strictEqual(duplicates[0].entries.length, 3);
  assert.strictEqual(duplicates[0].key, '2026-01-04|assets:cash|-125.4|USD|coffee beans');
});

test('normalizeMemo helper function behavior', () => {
  assert.strictEqual(normalizeMemo('Coffee  Beans'), 'coffee beans');
  assert.strictEqual(normalizeMemo('   hello   world   '), 'hello world');
  assert.strictEqual(normalizeMemo(null), '');
  assert.strictEqual(normalizeMemo(undefined), '');
});

test('keeps non-matching amounts separate', () => {
  const entries = parse([
    '2026-01-04 | assets:cash | -125.40USD | coffee beans',
    '2026-01-04 | assets:cash | 125.40USD | coffee beans',
    '2026-01-04 | assets:cash | -125.00USD | coffee beans',
    '2026-01-04 | assets:cash | -125.40USD | coffee beans',
  ].join('\n'));

  const duplicates = findDuplicates(entries);
  assert.strictEqual(duplicates.length, 1);
  assert.strictEqual(duplicates[0].count, 2);
  assert.strictEqual(duplicates[0].entries[0].lineNo, 1);
  assert.strictEqual(duplicates[0].entries[1].lineNo, 4);
});

test('drops memo from match key when ignoreMemo is true', () => {
  const entries = parse([
    '2026-01-04 | assets:cash | -125.40USD | Coffee beans',
    '2026-01-04 | assets:cash | -125.40USD | Office supplies',
  ].join('\n'));

  const withoutOption = findDuplicates(entries);
  assert.deepStrictEqual(withoutOption, []);

  const withOption = findDuplicates(entries, { ignoreMemo: true });
  assert.strictEqual(withOption.length, 1);
  assert.strictEqual(withOption[0].count, 2);
  assert.strictEqual(withOption[0].key, '2026-01-04|assets:cash|-125.4|USD');
});

test('sorts groups by the line number of their first member ascending (input-order sort)', () => {
  const entries = [
    { date: '2026-01-01', account: 'a:1', amount: 10, currency: 'USD', memo: 'first', lineNo: 2 },
    { date: '2026-01-02', account: 'a:2', amount: 20, currency: 'USD', memo: 'second', lineNo: 5 },
    { date: '2026-01-03', account: 'a:3', amount: 30, currency: 'USD', memo: 'third', lineNo: 10 },
    { date: '2026-01-01', account: 'a:1', amount: 10, currency: 'USD', memo: 'first', lineNo: 15 },
    { date: '2026-01-03', account: 'a:3', amount: 30, currency: 'USD', memo: 'third', lineNo: 20 },
    { date: '2026-01-02', account: 'a:2', amount: 20, currency: 'USD', memo: 'second', lineNo: 25 },
  ];

  const duplicates = findDuplicates(entries);
  assert.strictEqual(duplicates.length, 3);
  assert.strictEqual(duplicates[0].entries[0].lineNo, 2);
  assert.strictEqual(duplicates[1].entries[0].lineNo, 5);
  assert.strictEqual(duplicates[2].entries[0].lineNo, 10);
});

test('preserves input order of entries within duplicate groups', () => {
  const e1 = { date: '2026-01-01', account: 'a', amount: 10, currency: 'USD', memo: 'x', lineNo: 3 };
  const e2 = { date: '2026-01-01', account: 'a', amount: 10, currency: 'USD', memo: 'x', lineNo: 7 };
  const e3 = { date: '2026-01-01', account: 'a', amount: 10, currency: 'USD', memo: 'x', lineNo: 12 };

  const duplicates = findDuplicates([e1, e2, e3]);
  assert.strictEqual(duplicates.length, 1);
  assert.deepStrictEqual(duplicates[0].entries, [e1, e2, e3]);
});
