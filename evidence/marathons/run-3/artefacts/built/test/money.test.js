'use strict';

const test = require('node:test');
const assert = require('node:assert');
const {
  fromString,
  toString,
  add,
  sub,
  neg,
  sum,
  allocate,
} = require('../src/money');

test('fromString: parses positive and negative decimal strings into integer minor units', () => {
  assert.strictEqual(fromString('0'), 0);
  assert.strictEqual(fromString('0.00'), 0);
  assert.strictEqual(fromString('-0'), 0);
  assert.strictEqual(fromString('-0.00'), 0);
  assert.strictEqual(fromString('3'), 300);
  assert.strictEqual(fromString('3.0'), 300);
  assert.strictEqual(fromString('3.00'), 300);
  assert.strictEqual(fromString('0.05'), 5);
  assert.strictEqual(fromString('0.5'), 50);
  assert.strictEqual(fromString('0.50'), 50);
  assert.strictEqual(fromString('-125.40'), -12540);
  assert.strictEqual(fromString('-125.4'), -12540);
  assert.strictEqual(fromString('-0.05'), -5);
  assert.strictEqual(fromString('-0.50'), -50);
  assert.strictEqual(fromString('+12.34'), 1234);
  assert.strictEqual(fromString('  -125.40  '), -12540);
  assert.strictEqual(fromString('.50'), 50);
  assert.strictEqual(fromString('-.05'), -5);
});

test('fromString: rejects numbers with more than 2 decimal places with E_PRECISION', () => {
  // Requirement 2: 1.005 case from requirement 2
  assert.throws(
    () => {
      fromString('1.005');
    },
    (err) => {
      assert.strictEqual(err.code, 'E_PRECISION');
      assert.ok(err instanceof Error);
      return true;
    }
  );

  assert.throws(
    () => {
      fromString('-1.005');
    },
    (err) => {
      assert.strictEqual(err.code, 'E_PRECISION');
      return true;
    }
  );

  assert.throws(
    () => {
      fromString('0.001');
    },
    (err) => {
      assert.strictEqual(err.code, 'E_PRECISION');
      return true;
    }
  );

  assert.throws(
    () => {
      fromString('1.000');
    },
    (err) => {
      assert.strictEqual(err.code, 'E_PRECISION');
      return true;
    }
  );

  assert.throws(
    () => {
      fromString('123.4567');
    },
    (err) => {
      assert.strictEqual(err.code, 'E_PRECISION');
      return true;
    }
  );
});

test('fromString: direct digit parsing avoids JavaScript floating point inaccuracies', () => {
  // 1.14 * 100 in float is 113.99999999999999
  assert.strictEqual(fromString('1.14'), 114);
  // 0.07 * 100 in float is 7.000000000000001
  assert.strictEqual(fromString('0.07'), 7);
  // 1.13 * 100 in float is 112.99999999999999
  assert.strictEqual(fromString('1.13'), 113);
  // 1.15 * 100 in float is 114.99999999999999
  assert.strictEqual(fromString('1.15'), 115);
  // 1.16 * 100 in float is 115.99999999999999
  assert.strictEqual(fromString('1.16'), 116);
});

test('fromString: rejects invalid string formats with E_INVALID', () => {
  const invalidInputs = ['', '   ', 'abc', '12.34.56', 'NaN', 'Infinity', null, undefined, 123];
  for (const input of invalidInputs) {
    assert.throws(
      () => {
        fromString(input);
      },
      (err) => {
        assert.strictEqual(err.code, 'E_INVALID');
        return true;
      }
    );
  }
});

test('toString: formats minor units into 2-decimal string with sign preserved', () => {
  assert.strictEqual(toString(-12540), '-125.40');
  assert.strictEqual(toString(5), '0.05');
  assert.strictEqual(toString(0), '0.00');
  assert.strictEqual(toString(300), '3.00');
  assert.strictEqual(toString(50), '0.50');
  assert.strictEqual(toString(-5), '-0.05');
  assert.strictEqual(toString(-50), '-0.50');
  assert.strictEqual(toString(-300), '-3.00');
  assert.strictEqual(toString(1), '0.01');
  assert.strictEqual(toString(-1), '-0.01');
  assert.strictEqual(toString(1000000), '10000.00');
  assert.strictEqual(toString(-1000000), '-10000.00');
});

test('toString: rejects non-integer input with E_INVALID', () => {
  assert.throws(
    () => {
      toString(12.34);
    },
    (err) => {
      assert.strictEqual(err.code, 'E_INVALID');
      return true;
    }
  );
  assert.throws(
    () => {
      toString('100');
    },
    (err) => {
      assert.strictEqual(err.code, 'E_INVALID');
      return true;
    }
  );
});

test('round-tripping: fromString and toString round trip accurately', () => {
  const values = [
    0, 1, -1, 5, -5, 50, -50, 99, -99, 100, -100,
    12540, -12540, 999999, -999999,
  ];

  for (const minor of values) {
    const str = toString(minor);
    const parsed = fromString(str);
    assert.strictEqual(parsed, minor, `Failed round trip for minor: ${minor}`);
  }

  const canonicalStrings = [
    '0.00', '0.01', '-0.01', '0.05', '-0.05', '0.50', '-0.50',
    '3.00', '-3.00', '125.40', '-125.40', '10000.00', '-10000.00',
  ];

  for (const str of canonicalStrings) {
    const parsed = fromString(str);
    const formatted = toString(parsed);
    assert.strictEqual(formatted, str, `Failed round trip for string: ${str}`);
  }
});

test('arithmetic: add, sub, neg, sum operate on minor units', () => {
  // add
  assert.strictEqual(add(12540, 5), 12545);
  assert.strictEqual(add(-100, 100), 0);
  assert.strictEqual(add(-50, -50), -100);

  // sub
  assert.strictEqual(sub(12545, 5), 12540);
  assert.strictEqual(sub(100, 200), -100);
  assert.strictEqual(sub(-100, -100), 0);

  // neg
  assert.strictEqual(neg(12540), -12540);
  assert.strictEqual(neg(-12540), 12540);
  assert.strictEqual(neg(0), 0);

  // sum
  assert.strictEqual(sum([]), 0);
  assert.strictEqual(sum([100, 200, 300]), 600);
  assert.strictEqual(sum([100, -100, 50, -50]), 0);
  assert.strictEqual(sum([-12540, 40, 12500]), 0);
  assert.strictEqual(sum(new Set([10, 20, 30])), 60);
});

test('arithmetic: validates inputs with E_INVALID', () => {
  assert.throws(() => add(1.5, 2), { code: 'E_INVALID' });
  assert.throws(() => add(1, '2'), { code: 'E_INVALID' });
  assert.throws(() => sub(1, '2'), { code: 'E_INVALID' });
  assert.throws(() => sub(1.5, 2), { code: 'E_INVALID' });
  assert.throws(() => neg(NaN), { code: 'E_INVALID' });
  assert.throws(() => neg(1.5), { code: 'E_INVALID' });
  assert.throws(() => sum([1, 2.5]), { code: 'E_INVALID' });
  assert.throws(() => sum([1, '2']), { code: 'E_INVALID' });
  assert.throws(() => sum(null), { code: 'E_INVALID' });
});

test('allocate: splits 1000 minor units over [1, 1, 1] without losing cents', () => {
  // Requirement 5 acceptance: allocate(1000, [1,1,1]) must return [334, 333, 333]
  const result = allocate(1000, [1, 1, 1]);
  assert.deepStrictEqual(result, [334, 333, 333]);
  assert.strictEqual(sum(result), 1000);
});

test('allocate: splits 1 minor unit over [1, 1, 1] without losing cents', () => {
  // Requirement 5 acceptance: allocate over 1 minor unit for [1,1,1]
  const result = allocate(1, [1, 1, 1]);
  assert.deepStrictEqual(result, [1, 0, 0]);
  assert.strictEqual(sum(result), 1);
});

test('allocate: distributes remainders to largest remainders first', () => {
  // 100 over [1, 2] -> total 3:
  // 100 * 1 / 3 = 33 rem 1
  // 100 * 2 / 3 = 66 rem 2 (larger remainder gets extra 1)
  const result1 = allocate(100, [1, 2]);
  assert.deepStrictEqual(result1, [33, 67]);
  assert.strictEqual(sum(result1), 100);

  // 100 over [2, 1]
  const result2 = allocate(100, [2, 1]);
  assert.deepStrictEqual(result2, [67, 33]);
  assert.strictEqual(sum(result2), 100);

  // 100 over [1, 2, 3] -> total 6:
  // 100 * 1 / 6 = 16 rem 4 (gets +1 -> 17)
  // 100 * 2 / 6 = 33 rem 2
  // 100 * 3 / 6 = 50 rem 0
  const result3 = allocate(100, [1, 2, 3]);
  assert.deepStrictEqual(result3, [17, 33, 50]);
  assert.strictEqual(sum(result3), 100);
});

test('allocate: handles zero amount and negative amounts symmetrically', () => {
  assert.deepStrictEqual(allocate(0, [1, 1, 1]), [0, 0, 0]);
  assert.deepStrictEqual(allocate(-1000, [1, 1, 1]), [-334, -333, -333]);
  assert.strictEqual(sum(allocate(-1000, [1, 1, 1])), -1000);

  assert.deepStrictEqual(allocate(-1, [1, 1, 1]), [-1, 0, 0]);
  assert.strictEqual(sum(allocate(-1, [1, 1, 1])), -1);

  assert.deepStrictEqual(allocate(-100, [1, 2]), [-33, -67]);
  assert.strictEqual(sum(allocate(-100, [1, 2])), -100);
});

test('allocate: handles zero ratio components', () => {
  assert.deepStrictEqual(allocate(100, [0, 1]), [0, 100]);
  assert.deepStrictEqual(allocate(100, [1, 0]), [100, 0]);
  assert.deepStrictEqual(allocate(100, [0, 1, 0]), [0, 100, 0]);
});

test('allocate: single ratio gets entire amount', () => {
  assert.deepStrictEqual(allocate(100, [1]), [100]);
  assert.deepStrictEqual(allocate(-100, [5]), [-100]);
  assert.deepStrictEqual(allocate(0, [1]), [0]);
});

test('allocate: validates inputs with E_INVALID', () => {
  assert.throws(() => allocate(100.5, [1, 1]), { code: 'E_INVALID' });
  assert.throws(() => allocate(100, []), { code: 'E_INVALID' });
  assert.throws(() => allocate(100, 'invalid'), { code: 'E_INVALID' });
  assert.throws(() => allocate(100, [0, 0]), { code: 'E_INVALID' });
  assert.throws(() => allocate(100, [-1, 2]), { code: 'E_INVALID' });
  assert.throws(() => allocate(100, [1, 1.5]), { code: 'E_INVALID' });
});

test('safe integer boundaries: fromString rejects amounts beyond safe integer range', () => {
  // Number.MAX_SAFE_INTEGER is 9007199254740991 (90071992547409.91)
  assert.strictEqual(fromString('90071992547409.91'), Number.MAX_SAFE_INTEGER);
  assert.strictEqual(fromString('-90071992547409.91'), Number.MIN_SAFE_INTEGER);

  // Values exceeding Number.MAX_SAFE_INTEGER / below MIN_SAFE_INTEGER throw E_INVALID
  assert.throws(() => fromString('90071992547409.92'), { code: 'E_INVALID' });
  assert.throws(() => fromString('90071992547409.93'), { code: 'E_INVALID' });
  assert.throws(() => fromString('-90071992547409.92'), { code: 'E_INVALID' });
  assert.throws(() => fromString('1000000000000000.00'), { code: 'E_INVALID' });
});

test('safe integer boundaries: toString formats boundary values and rejects unsafe integers', () => {
  assert.strictEqual(toString(Number.MAX_SAFE_INTEGER), '90071992547409.91');
  assert.strictEqual(toString(Number.MIN_SAFE_INTEGER), '-90071992547409.91');
  assert.throws(() => toString(Number.MAX_SAFE_INTEGER + 1), { code: 'E_INVALID' });
  assert.throws(() => toString(Number.MIN_SAFE_INTEGER - 1), { code: 'E_INVALID' });
  assert.throws(() => toString(Infinity), { code: 'E_INVALID' });
  assert.throws(() => toString(-Infinity), { code: 'E_INVALID' });
});

test('safe integer boundaries: arithmetic detects overflow and rejects unsafe integers', () => {
  assert.strictEqual(add(Number.MAX_SAFE_INTEGER - 1, 1), Number.MAX_SAFE_INTEGER);
  assert.throws(() => add(Number.MAX_SAFE_INTEGER, 1), { code: 'E_INVALID' });
  assert.throws(() => add(Number.MIN_SAFE_INTEGER, -1), { code: 'E_INVALID' });

  assert.strictEqual(sub(Number.MIN_SAFE_INTEGER + 1, 1), Number.MIN_SAFE_INTEGER);
  assert.throws(() => sub(Number.MIN_SAFE_INTEGER, 1), { code: 'E_INVALID' });
  assert.throws(() => sub(Number.MAX_SAFE_INTEGER, -1), { code: 'E_INVALID' });

  assert.strictEqual(neg(Number.MAX_SAFE_INTEGER), Number.MIN_SAFE_INTEGER);
  assert.strictEqual(neg(Number.MIN_SAFE_INTEGER), Number.MAX_SAFE_INTEGER);
  assert.throws(() => neg(Number.MAX_SAFE_INTEGER + 1), { code: 'E_INVALID' });

  assert.strictEqual(sum([Number.MAX_SAFE_INTEGER, -Number.MAX_SAFE_INTEGER]), 0);
  assert.throws(() => sum([Number.MAX_SAFE_INTEGER, 1]), { code: 'E_INVALID' });
  assert.throws(() => sum([Number.MIN_SAFE_INTEGER, -1]), { code: 'E_INVALID' });
  assert.throws(() => sum([Number.MAX_SAFE_INTEGER + 1]), { code: 'E_INVALID' });
});

test('safe integer boundaries: allocate handles large safe integer amounts and ratios exactly', () => {
  // Exact allocation at MAX_SAFE_INTEGER
  const maxAlloc = allocate(Number.MAX_SAFE_INTEGER, [1, 2]);
  assert.deepStrictEqual(maxAlloc, [3002399751580330, 6004799503160661]);
  assert.strictEqual(sum(maxAlloc), Number.MAX_SAFE_INTEGER);

  const minAlloc = allocate(Number.MIN_SAFE_INTEGER, [1, 2]);
  assert.deepStrictEqual(minAlloc, [-3002399751580330, -6004799503160661]);
  assert.strictEqual(sum(minAlloc), Number.MIN_SAFE_INTEGER);

  // Large safe integer ratios
  const ratioAlloc = allocate(100, [Number.MAX_SAFE_INTEGER, Number.MAX_SAFE_INTEGER]);
  assert.deepStrictEqual(ratioAlloc, [50, 50]);
  assert.strictEqual(sum(ratioAlloc), 100);

  // Unsafe inputs
  assert.throws(() => allocate(Number.MAX_SAFE_INTEGER + 1, [1, 1]), { code: 'E_INVALID' });
  assert.throws(() => allocate(100, [Number.MAX_SAFE_INTEGER + 1]), { code: 'E_INVALID' });
});

