'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { toCSV } = require('../src/export-csv');

test('plain case: single entry with default header', () => {
  const entries = [
    {
      date: '2026-01-04',
      account: 'assets:cash',
      amount: -125.4,
      currency: 'USD',
      memo: 'coffee beans',
    },
  ];
  const expected = 'date,account,amount,currency,memo\r\n2026-01-04,assets:cash,-125.40,USD,coffee beans';
  assert.strictEqual(toCSV(entries), expected);
});

test('memo containing a comma', () => {
  const entries = [
    {
      date: '2026-01-04',
      account: 'expenses:groceries',
      amount: 45.5,
      currency: 'USD',
      memo: 'apples, bananas, and oranges',
    },
  ];
  const expected = 'date,account,amount,currency,memo\r\n2026-01-04,expenses:groceries,45.50,USD,"apples, bananas, and oranges"';
  assert.strictEqual(toCSV(entries), expected);
});

test('memo containing a double quote', () => {
  const entries = [
    {
      date: '2026-01-04',
      account: 'expenses:books',
      amount: 15,
      currency: 'USD',
      memo: 'The book "Clean Code"',
    },
  ];
  const expected = 'date,account,amount,currency,memo\r\n2026-01-04,expenses:books,15.00,USD,"The book ""Clean Code"""';
  assert.strictEqual(toCSV(entries), expected);
});

test('memo containing newlines (LF and CRLF)', () => {
  const entriesLF = [
    {
      date: '2026-01-04',
      account: 'expenses:misc',
      amount: 10,
      currency: 'USD',
      memo: 'line one\nline two',
    },
  ];
  const expectedLF = 'date,account,amount,currency,memo\r\n2026-01-04,expenses:misc,10.00,USD,"line one\nline two"';
  assert.strictEqual(toCSV(entriesLF), expectedLF);

  const entriesCRLF = [
    {
      date: '2026-01-04',
      account: 'expenses:misc',
      amount: 10,
      currency: 'USD',
      memo: 'line one\r\nline two',
    },
  ];
  const expectedCRLF = 'date,account,amount,currency,memo\r\n2026-01-04,expenses:misc,10.00,USD,"line one\r\nline two"';
  assert.strictEqual(toCSV(entriesCRLF), expectedCRLF);
});

test('two-decimal formatting of integer amount and fractional amounts', () => {
  const entries = [
    {
      date: '2026-01-01',
      account: 'assets:bank',
      amount: 100,
      currency: 'USD',
      memo: 'deposit',
    },
    {
      date: '2026-01-02',
      account: 'expenses:fee',
      amount: 0,
      currency: 'USD',
      memo: 'zero fee',
    },
    {
      date: '2026-01-03',
      account: 'expenses:misc',
      amount: -5,
      currency: 'USD',
      memo: 'small debit',
    },
  ];
  const result = toCSV(entries);
  const rows = result.split('\r\n');
  assert.strictEqual(rows.length, 4);
  assert.strictEqual(rows[1], '2026-01-01,assets:bank,100.00,USD,deposit');
  assert.strictEqual(rows[2], '2026-01-02,expenses:fee,0.00,USD,zero fee');
  assert.strictEqual(rows[3], '2026-01-03,expenses:misc,-5.00,USD,small debit');
});

test('header: false suppresses the header row', () => {
  const entries = [
    {
      date: '2026-01-04',
      account: 'assets:cash',
      amount: -125.4,
      currency: 'USD',
      memo: 'coffee beans',
    },
  ];
  const expected = '2026-01-04,assets:cash,-125.40,USD,coffee beans';
  assert.strictEqual(toCSV(entries, { header: false }), expected);
});

test('empty entries list handling', () => {
  assert.strictEqual(toCSV([]), 'date,account,amount,currency,memo');
  assert.strictEqual(toCSV([], { header: false }), '');
});

test('multiple entries preserve order and have no trailing CRLF', () => {
  const entries = [
    { date: '2026-01-01', account: 'a', amount: 1, currency: 'USD', memo: 'm1' },
    { date: '2026-01-02', account: 'b', amount: 2, currency: 'USD', memo: 'm2' },
  ];
  const csv = toCSV(entries);
  assert.strictEqual(csv, 'date,account,amount,currency,memo\r\n2026-01-01,a,1.00,USD,m1\r\n2026-01-02,b,2.00,USD,m2');
  assert.strictEqual(csv.endsWith('\r\n'), false);
});

test('amounts with magnitude >= 1e21 format in fixed-point with two decimals', () => {
  const entries = [
    {
      date: '2026-01-01',
      account: 'assets:whale',
      amount: 1e21,
      currency: 'USD',
      memo: 'large positive amount',
    },
    {
      date: '2026-01-02',
      account: 'liabilities:debt',
      amount: -1e21,
      currency: 'USD',
      memo: 'large negative amount',
    },
  ];
  const csv = toCSV(entries, { header: false });
  const rows = csv.split('\r\n');
  assert.strictEqual(rows[0], '2026-01-01,assets:whale,1000000000000000000000.00,USD,large positive amount');
  assert.strictEqual(rows[1], '2026-01-02,liabilities:debt,-1000000000000000000000.00,USD,large negative amount');
});

