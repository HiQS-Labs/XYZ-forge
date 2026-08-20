'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { parse } = require('../src/parse');
const { validate } = require('../src/validate');

test('a balanced day validates', () => {
  const entries = parse([
    '2026-01-04 | assets:cash | -125.40USD | coffee',
    '2026-01-04 | expenses:food | 125.40USD | coffee',
  ].join('\n'));
  const r = validate(entries);
  assert.strictEqual(r.ok, true, JSON.stringify(r.problems));
});

test('an unbalanced day is reported', () => {
  const entries = parse([
    '2026-01-04 | assets:cash | -125.40USD | coffee',
    '2026-01-04 | expenses:food | 120.00USD | coffee',
  ].join('\n'));
  const r = validate(entries);
  assert.strictEqual(r.ok, false);
  assert.strictEqual(r.problems[0].code, 'E_UNBALANCED');
});

test('currencies are balanced independently', () => {
  const entries = parse([
    '2026-01-04 | assets:cash | -100.00USD | a',
    '2026-01-04 | expenses:x | 100.00USD | a',
    '2026-01-04 | assets:eur | -50.00EUR | b',
    '2026-01-04 | expenses:y | 50.00EUR | b',
  ].join('\n'));
  assert.strictEqual(validate(entries).ok, true);
});
