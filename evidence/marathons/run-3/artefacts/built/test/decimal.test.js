'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { Decimal, add, sub, mul, div, cmp, eq, HALF_EVEN, HALF_UP } = require('../src/decimal.js');

// Decimal.from — string parsing
test('from integer string', () => {
  const d = Decimal.from('42');
  assert.equal(d.unscaled, 42n);
  assert.equal(d.scale, 0);
  assert.equal(d.toString(), '42');
});

test('from decimal string preserves scale', () => {
  const d = Decimal.from('-125.40');
  assert.equal(d.unscaled, -12540n);
  assert.equal(d.scale, 2);
  assert.equal(d.toString(), '-125.40');
});

test('from small decimal', () => {
  const d = Decimal.from('0.000001');
  assert.equal(d.unscaled, 1n);
  assert.equal(d.scale, 6);
  assert.equal(d.toString(), '0.000001');
});

test('from scientific notation negative exponent', () => {
  const d = Decimal.from('1e-7');
  assert.equal(d.toString(), '0.0000001');
});

test('from scientific notation positive exponent', () => {
  const d = Decimal.from('1.5e3');
  // 1.5 * 1000 = 1500
  assert.equal(d.toString(), '1500');
});

test('from BigInt', () => {
  const d = Decimal.from(99n);
  assert.equal(d.unscaled, 99n);
  assert.equal(d.scale, 0);
});

// Large value that loses precision as a float
test('large value round-trip exact', () => {
  const s = '9007199254740993.01';
  const d = Decimal.from(s);
  assert.equal(d.toString(), s);
  // Verify exact unscaled BigInt — float would collapse these two integer parts
  assert.equal(d.unscaled, 900719925474099301n);
  assert.equal(d.scale, 2);
});

// add — same scale
test('add same scale', () => {
  const a = Decimal.from('1.50');
  const b = Decimal.from('2.25');
  assert.equal(add(a, b).toString(), '3.75');
});

// add — different scales (key acceptance requirement)
test('add different scales', () => {
  const a = Decimal.from('1.5');   // scale 1
  const b = Decimal.from('0.25'); // scale 2
  const result = add(a, b);
  assert.equal(result.toString(), '1.75');
});

test('add negative', () => {
  const a = Decimal.from('-1.00');
  const b = Decimal.from('0.50');
  assert.equal(add(a, b).toString(), '-0.50');
});

// sub
test('sub', () => {
  const a = Decimal.from('10.00');
  const b = Decimal.from('3.75');
  assert.equal(sub(a, b).toString(), '6.25');
});

// mul — scales add
test('mul scales add', () => {
  const a = Decimal.from('1.5');  // scale 1
  const b = Decimal.from('2.0'); // scale 1
  const r = mul(a, b);
  assert.equal(r.scale, 2);
  assert.equal(r.toString(), '3.00');
});

test('mul large', () => {
  const a = Decimal.from('100.00');
  const b = Decimal.from('3.00');
  assert.equal(mul(a, b).toString(), '300.0000');
});

// div — 1/3 at scale 4
test('div 1/3 at scale 4 HALF_EVEN', () => {
  const a = Decimal.from('1');
  const b = Decimal.from('3');
  const r = div(a, b, { scale: 4, rounding: HALF_EVEN });
  assert.equal(r.toString(), '0.3333');
});

// div HALF_EVEN: 0.5 → 0, 1.5 → 2
test('div HALF_EVEN: 0.5 rounds to 0', () => {
  const half = Decimal.from('0.5');
  const one = Decimal.from('1');
  const r = div(half, one, { scale: 0, rounding: HALF_EVEN });
  // 0.5 is exactly halfway between 0 and 1; 0 is even
  assert.equal(r.toString(), '0');
});

test('div HALF_EVEN: 1.5 rounds to 2', () => {
  const a = Decimal.from('1.5');
  const one = Decimal.from('1');
  const r = div(a, one, { scale: 0, rounding: HALF_EVEN });
  // 1.5 is exactly halfway between 1 and 2; 2 is even
  assert.equal(r.toString(), '2');
});

// div HALF_UP
test('div HALF_UP: 0.5 rounds to 1', () => {
  const half = Decimal.from('0.5');
  const one = Decimal.from('1');
  const r = div(half, one, { scale: 0, rounding: HALF_UP });
  assert.equal(r.toString(), '1');
});

// Negative rounding — requirement 6
test('div HALF_EVEN: -0.5 rounds to 0', () => {
  const a = Decimal.from('-0.5');
  const one = Decimal.from('1');
  const r = div(a, one, { scale: 0, rounding: HALF_EVEN });
  // -0.5 rounds to 0 (even) in HALF_EVEN
  assert.equal(r.toString(), '0');
});

test('div HALF_EVEN: -1.5 rounds to -2', () => {
  const a = Decimal.from('-1.5');
  const one = Decimal.from('1');
  const r = div(a, one, { scale: 0, rounding: HALF_EVEN });
  // -1.5: midpoint between -1 and -2; -2 is even
  assert.equal(r.toString(), '-2');
});

test('div HALF_EVEN: -2.5 rounds to -2', () => {
  const a = Decimal.from('-2.5');
  const one = Decimal.from('1');
  const r = div(a, one, { scale: 0, rounding: HALF_EVEN });
  // -2.5: midpoint between -2 and -3; -2 is even
  assert.equal(r.toString(), '-2');
});

// cmp and eq across differing scales
test('cmp equal values different scales', () => {
  const a = Decimal.from('1.0');
  const b = Decimal.from('1.00');
  assert.equal(cmp(a, b), 0);
});

test('eq 1.0 === 1.00', () => {
  const a = Decimal.from('1.0');
  const b = Decimal.from('1.00');
  assert.ok(eq(a, b));
});

test('toString preserves each decimal scale', () => {
  const a = Decimal.from('1.0');
  const b = Decimal.from('1.00');
  assert.equal(a.toString(), '1.0');
  assert.equal(b.toString(), '1.00');
});

test('cmp less than', () => {
  assert.equal(cmp(Decimal.from('0.9'), Decimal.from('1.0')), -1);
});

test('cmp greater than', () => {
  assert.equal(cmp(Decimal.from('1.1'), Decimal.from('1.0')), 1);
});

// E_DIVZERO
test('div by zero throws E_DIVZERO', () => {
  const a = Decimal.from('5');
  const b = Decimal.from('0');
  assert.throws(() => div(a, b, { scale: 2 }), (err) => {
    assert.equal(err.code, 'E_DIVZERO');
    return true;
  });
});

// Never route through Number — BigInt path
test('from BigInt no float', () => {
  const d = Decimal.from(9007199254740993n);
  assert.equal(d.unscaled, 9007199254740993n);
});
