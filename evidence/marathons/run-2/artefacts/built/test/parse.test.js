'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { parse, parseLine } = require('../src/parse');

test('parses a well-formed line', () => {
  const e = parseLine('2026-01-04 | assets:cash | -125.40USD | coffee beans', 1);
  assert.strictEqual(e.date, '2026-01-04');
  assert.strictEqual(e.account, 'assets:cash');
  assert.strictEqual(e.amount, -125.4);
  assert.strictEqual(e.currency, 'USD');
  assert.strictEqual(e.memo, 'coffee beans');
});

test('skips blanks and comments', () => {
  assert.strictEqual(parseLine('', 1), null);
  assert.strictEqual(parseLine('   ', 2), null);
  assert.strictEqual(parseLine('# a comment', 3), null);
});

test('rejects a malformed line with E_PARSE', () => {
  assert.throws(() => parseLine('nonsense', 7), (err) => err.code === 'E_PARSE' && err.lineNo === 7);
});

test('parses a multi-line document', () => {
  const doc = [
    '# opening',
    '2026-01-04 | assets:cash | -125.40USD | coffee beans',
    '2026-01-04 | expenses:food | 125.40USD | coffee beans',
  ].join('\n');
  const entries = parse(doc);
  assert.strictEqual(entries.length, 2);
  assert.strictEqual(entries[0].lineNo, 2);
});
