'use strict';

const HALF_EVEN = 'HALF_EVEN';
const HALF_UP = 'HALF_UP';

function pow10(n) {
  return BigInt(10) ** BigInt(n);
}

class Decimal {
  constructor(unscaled, scale) {
    this.unscaled = BigInt(unscaled);
    this.scale = scale;
  }

  static from(value) {
    if (typeof value === 'bigint') {
      return new Decimal(value, 0);
    }
    if (typeof value !== 'string') {
      throw new TypeError('Decimal.from requires a string or BigInt');
    }

    // Handle scientific notation e.g. "1e-7", "1.5e3"
    const eIdx = value.toLowerCase().indexOf('e');
    if (eIdx !== -1) {
      const mantissa = value.slice(0, eIdx);
      const exp = parseInt(value.slice(eIdx + 1), 10);
      const base = Decimal.from(mantissa);
      if (exp >= 0) {
        // multiply by 10^exp — reduce scale or increase unscaled
        const shift = BigInt(exp);
        if (BigInt(base.scale) >= shift) {
          return new Decimal(base.unscaled, base.scale - Number(shift));
        } else {
          const extra = shift - BigInt(base.scale);
          return new Decimal(base.unscaled * pow10(Number(extra)), 0);
        }
      } else {
        // negative exponent: increase scale
        return new Decimal(base.unscaled, base.scale + Math.abs(exp));
      }
    }

    // Plain decimal string e.g. "-125.40", "0.000001"
    let s = value.trim();
    let negative = false;
    if (s.startsWith('-')) {
      negative = true;
      s = s.slice(1);
    } else if (s.startsWith('+')) {
      s = s.slice(1);
    }

    const dotIdx = s.indexOf('.');
    let intPart, fracPart;
    let scale;
    if (dotIdx === -1) {
      intPart = s;
      fracPart = '';
      scale = 0;
    } else {
      intPart = s.slice(0, dotIdx);
      fracPart = s.slice(dotIdx + 1);
      scale = fracPart.length;
    }

    const digits = intPart + fracPart;
    let unscaled = BigInt(digits === '' ? '0' : digits);
    if (negative) unscaled = -unscaled;

    return new Decimal(unscaled, scale);
  }

  // Align two decimals to the same scale, returning [a_unscaled, b_unscaled, scale]
  static _align(a, b) {
    if (a.scale === b.scale) return [a.unscaled, b.unscaled, a.scale];
    if (a.scale > b.scale) {
      const diff = a.scale - b.scale;
      return [a.unscaled, b.unscaled * pow10(diff), a.scale];
    } else {
      const diff = b.scale - a.scale;
      return [a.unscaled * pow10(diff), b.unscaled, b.scale];
    }
  }

  toString() {
    if (this.scale === 0) return this.unscaled.toString();
    const neg = this.unscaled < 0n;
    const abs = neg ? -this.unscaled : this.unscaled;
    let s = abs.toString().padStart(this.scale + 1, '0');
    const intLen = s.length - this.scale;
    const result = s.slice(0, intLen) + '.' + s.slice(intLen);
    return neg ? '-' + result : result;
  }

  toNumber() {
    return Number(this.unscaled) / Math.pow(10, this.scale);
  }
}

function add(a, b) {
  const [au, bu, scale] = Decimal._align(a, b);
  return new Decimal(au + bu, scale);
}

function sub(a, b) {
  const [au, bu, scale] = Decimal._align(a, b);
  return new Decimal(au - bu, scale);
}

function mul(a, b) {
  return new Decimal(a.unscaled * b.unscaled, a.scale + b.scale);
}

function div(a, b, { scale, rounding = HALF_EVEN } = {}) {
  if (b.unscaled === 0n) {
    const err = new Error('Division by zero');
    err.code = 'E_DIVZERO';
    throw err;
  }
  if (scale == null) {
    throw new TypeError('div requires an explicit scale option');
  }

  // Compute a / b rounded to `scale` decimal places.
  // We compute: floor(a.unscaled * 10^(scale + b.scale) / (b.unscaled * 10^a.scale))
  // then round.

  // Numerator adjusted so result is in units of 10^-scale
  // a / b = (a.unscaled / 10^a.scale) / (b.unscaled / 10^b.scale)
  //       = (a.unscaled * 10^b.scale) / (b.unscaled * 10^a.scale)
  // We want result with `scale` decimal places, so we compute:
  // quotient_unscaled = round((a.unscaled * 10^b.scale * 10^scale) / (b.unscaled * 10^a.scale))

  const num = a.unscaled * pow10(b.scale + scale);
  const den = b.unscaled * pow10(a.scale);

  // BigInt division truncates toward zero; we need floor/ceiling for rounding
  const q = num / den;
  const r = num - q * den; // remainder (same sign as num for BigInt)

  // To determine how to round, we need to know |remainder| vs |den/2|
  // We compare 2*|r| vs |den|
  const absR2 = r < 0n ? -r * 2n : r * 2n;
  const absDen = den < 0n ? -den : den;

  let rounded = q;
  const negative = (a.unscaled < 0n) !== (b.unscaled < 0n);

  if (rounding === HALF_UP) {
    // Round half away from zero
    if (absR2 >= absDen) {
      // |r| >= |den/2|, round away from zero
      if (!negative) {
        rounded = q + 1n;
      } else {
        rounded = q - 1n;
      }
    }
  } else if (rounding === HALF_EVEN) {
    if (absR2 > absDen) {
      // |r| > |den/2|, round away from zero
      if (!negative) {
        rounded = q + 1n;
      } else {
        rounded = q - 1n;
      }
    } else if (absR2 === absDen) {
      // Exactly halfway — round to even
      if (q % 2n !== 0n) {
        // q is odd, round away from zero
        if (!negative) {
          rounded = q + 1n;
        } else {
          rounded = q - 1n;
        }
      }
      // else q is already even, leave it
    }
  } else {
    throw new TypeError(`Unknown rounding mode: ${rounding}`);
  }

  return new Decimal(rounded, scale);
}

function cmp(a, b) {
  const [au, bu] = Decimal._align(a, b);
  if (au < bu) return -1;
  if (au > bu) return 1;
  return 0;
}

function eq(a, b) {
  return cmp(a, b) === 0;
}

module.exports = { Decimal, add, sub, mul, div, cmp, eq, HALF_EVEN, HALF_UP };
