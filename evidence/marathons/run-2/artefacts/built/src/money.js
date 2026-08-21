'use strict';

const MIN_SAFE_MINOR = BigInt(Number.MIN_SAFE_INTEGER);
const MAX_SAFE_MINOR = BigInt(Number.MAX_SAFE_INTEGER);

/**
 * Parses a decimal string (e.g. "-125.40", "3", "0.05") into an integer count of MINOR UNITS (cents).
 * Rejects numbers with more than 2 decimal places by throwing an Error with code === 'E_PRECISION'.
 * Rejects amounts outside safe integer range or invalid formats with code === 'E_INVALID'.
 * Parses digits directly without floating-point math.
 *
 * @param {string} s
 * @returns {number} Minor units as integer
 */
function fromString(s) {
  if (typeof s !== 'string') {
    const err = new Error(`Expected string, got ${typeof s}`);
    err.code = 'E_INVALID';
    throw err;
  }

  const str = s.trim();
  if (str === '') {
    const err = new Error('Cannot parse empty string as money');
    err.code = 'E_INVALID';
    throw err;
  }

  const match = str.match(/^([+-])?(?:(\d+)(?:\.(\d+))?|\.(\d+))$/);
  if (!match) {
    const decMatch = str.match(/^([+-])?(?:\d+)?\.(\d+)$/);
    if (decMatch && decMatch[2].length > 2) {
      const err = new Error(`Too many decimal places in money amount: ${str}`);
      err.code = 'E_PRECISION';
      throw err;
    }
    const err = new Error(`Invalid money string format: "${str}"`);
    err.code = 'E_INVALID';
    throw err;
  }

  const isNeg = match[1] === '-';
  const wholeStr = match[2] || '0';
  const fracStr = match[3] || match[4] || '';

  if (fracStr.length > 2) {
    const err = new Error(`Too many decimal places in money amount: ${str}`);
    err.code = 'E_PRECISION';
    throw err;
  }

  let bFrac = 0n;
  if (fracStr.length === 1) {
    bFrac = BigInt(fracStr) * 10n;
  } else if (fracStr.length === 2) {
    bFrac = BigInt(fracStr);
  }

  const bWhole = BigInt(wholeStr);
  const bMinor = (isNeg ? -1n : 1n) * (bWhole * 100n + bFrac);

  if (bMinor < MIN_SAFE_MINOR || bMinor > MAX_SAFE_MINOR) {
    const err = new Error(`Money amount exceeds safe integer range: ${str}`);
    err.code = 'E_INVALID';
    throw err;
  }

  const minor = Number(bMinor);
  return Object.is(minor, -0) ? 0 : minor;
}

/**
 * Renders safe integer minor units to a 2-decimal string with sign preserved.
 * e.g. -12540 -> "-125.40", 5 -> "0.05", 0 -> "0.00"
 *
 * @param {number} minor
 * @returns {string}
 */
function toString(minor) {
  if (!Number.isSafeInteger(minor)) {
    const err = new Error(`Expected safe integer minor units, got ${minor}`);
    err.code = 'E_INVALID';
    throw err;
  }

  const isNeg = minor < 0;
  const bMinor = BigInt(minor);
  const bAbs = bMinor < 0n ? -bMinor : bMinor;
  const bWhole = bAbs / 100n;
  const bCents = bAbs % 100n;
  const centsStr = String(bCents).padStart(2, '0');
  const signStr = isNeg ? '-' : '';

  return `${signStr}${bWhole.toString()}.${centsStr}`;
}

/**
 * Adds two minor unit amounts.
 *
 * @param {number} a
 * @param {number} b
 * @returns {number}
 */
function add(a, b) {
  if (!Number.isSafeInteger(a) || !Number.isSafeInteger(b)) {
    const err = new Error(`add() expects safe integer arguments, got ${a}, ${b}`);
    err.code = 'E_INVALID';
    throw err;
  }
  const bRes = BigInt(a) + BigInt(b);
  if (bRes < MIN_SAFE_MINOR || bRes > MAX_SAFE_MINOR) {
    const err = new Error(`add() result exceeds safe integer range: ${a} + ${b}`);
    err.code = 'E_INVALID';
    throw err;
  }
  const res = Number(bRes);
  return Object.is(res, -0) ? 0 : res;
}

/**
 * Subtracts minor unit amount b from a.
 *
 * @param {number} a
 * @param {number} b
 * @returns {number}
 */
function sub(a, b) {
  if (!Number.isSafeInteger(a) || !Number.isSafeInteger(b)) {
    const err = new Error(`sub() expects safe integer arguments, got ${a}, ${b}`);
    err.code = 'E_INVALID';
    throw err;
  }
  const bRes = BigInt(a) - BigInt(b);
  if (bRes < MIN_SAFE_MINOR || bRes > MAX_SAFE_MINOR) {
    const err = new Error(`sub() result exceeds safe integer range: ${a} - ${b}`);
    err.code = 'E_INVALID';
    throw err;
  }
  const res = Number(bRes);
  return Object.is(res, -0) ? 0 : res;
}

/**
 * Negates a minor unit amount.
 *
 * @param {number} a
 * @returns {number}
 */
function neg(a) {
  if (!Number.isSafeInteger(a)) {
    const err = new Error(`neg() expects a safe integer argument, got ${a}`);
    err.code = 'E_INVALID';
    throw err;
  }
  const bRes = -BigInt(a);
  if (bRes < MIN_SAFE_MINOR || bRes > MAX_SAFE_MINOR) {
    const err = new Error(`neg() result exceeds safe integer range: -(${a})`);
    err.code = 'E_INVALID';
    throw err;
  }
  const res = Number(bRes);
  return Object.is(res, -0) ? 0 : res;
}

/**
 * Sums an iterable of minor unit amounts.
 *
 * @param {Iterable<number>} list
 * @returns {number}
 */
function sum(list) {
  if (!list || typeof list[Symbol.iterator] !== 'function') {
    const err = new Error('sum() expects an iterable of safe integers');
    err.code = 'E_INVALID';
    throw err;
  }
  let bTotal = 0n;
  for (const item of list) {
    if (!Number.isSafeInteger(item)) {
      const err = new Error(`sum() element must be a safe integer, got ${item}`);
      err.code = 'E_INVALID';
      throw err;
    }
    bTotal += BigInt(item);
  }
  if (bTotal < MIN_SAFE_MINOR || bTotal > MAX_SAFE_MINOR) {
    const err = new Error('sum() result exceeds safe integer range');
    err.code = 'E_INVALID';
    throw err;
  }
  const total = Number(bTotal);
  return Object.is(total, -0) ? 0 : total;
}

/**
 * Splits an amount across integer ratios with no cents lost.
 * The parts sum exactly to the input amount. Remainder is distributed
 * one minor unit at a time to the largest remainders first.
 *
 * @param {number} minor Total minor units to allocate
 * @param {number[]} ratios Array of non-negative integer ratios
 * @returns {number[]} Allocated minor units per ratio
 */
function allocate(minor, ratios) {
  if (!Number.isSafeInteger(minor)) {
    const err = new Error(`Expected safe integer minor units, got ${minor}`);
    err.code = 'E_INVALID';
    throw err;
  }
  if (!Array.isArray(ratios) || ratios.length === 0) {
    const err = new Error('Ratios must be a non-empty array');
    err.code = 'E_INVALID';
    throw err;
  }

  let totalRatio = 0n;
  for (let i = 0; i < ratios.length; i++) {
    const r = ratios[i];
    if (!Number.isSafeInteger(r) || r < 0) {
      const err = new Error(`Ratio at index ${i} must be a non-negative safe integer, got ${r}`);
      err.code = 'E_INVALID';
      throw err;
    }
    totalRatio += BigInt(r);
  }

  if (totalRatio === 0n) {
    const err = new Error('Sum of ratios must be greater than 0');
    err.code = 'E_INVALID';
    throw err;
  }

  const isNeg = minor < 0;
  const bMinor = BigInt(minor);
  const bAbsMinor = bMinor < 0n ? -bMinor : bMinor;

  const results = new Array(ratios.length);
  const remainders = new Array(ratios.length);
  let totalAllocated = 0n;

  for (let i = 0; i < ratios.length; i++) {
    const r = BigInt(ratios[i]);
    const product = bAbsMinor * r;
    const share = product / totalRatio;
    const rem = product % totalRatio;
    results[i] = share;
    remainders[i] = { index: i, rem };
    totalAllocated += share;
  }

  const leftover = bAbsMinor - totalAllocated;

  // Sort remainder objects by remainder descending, then index ascending (stable tie-breaker)
  remainders.sort((a, b) => {
    if (b.rem !== a.rem) {
      return b.rem > a.rem ? 1 : -1;
    }
    return a.index - b.index;
  });

  const numLeftover = Number(leftover);
  for (let i = 0; i < numLeftover; i++) {
    results[remainders[i].index] += 1n;
  }

  const finalResults = new Array(ratios.length);
  for (let i = 0; i < results.length; i++) {
    let share = results[i];
    if (isNeg) {
      share = -share;
    }
    if (share < MIN_SAFE_MINOR || share > MAX_SAFE_MINOR) {
      const err = new Error('allocate() share exceeds safe integer range');
      err.code = 'E_INVALID';
      throw err;
    }
    const num = Number(share);
    finalResults[i] = Object.is(num, -0) ? 0 : num;
  }

  return finalResults;
}

module.exports = {
  fromString,
  toString,
  add,
  sub,
  neg,
  sum,
  allocate,
};

