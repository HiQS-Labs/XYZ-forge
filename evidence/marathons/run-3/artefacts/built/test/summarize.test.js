'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { parse, summarize } = require('../src/index');

test('summarize totals per account and currency', () => {
  const entries = parse([
    '2026-01-04 | assets:cash | -100.00USD | a',
    '2026-01-05 | assets:cash | -25.00USD | b',
    '2026-01-04 | expenses:x | 100.00USD | a',
    '2026-01-05 | expenses:x | 25.00USD | b',
  ].join('\n'));
  const s = summarize(entries);
  assert.deepStrictEqual(s, [
    { account: 'assets:cash', currency: 'USD', total: -125 },
    { account: 'expenses:x', currency: 'USD', total: 125 },
  ]);
});
