'use strict';

/**
 * Rounds a number to a given number of decimal places using half-away-from-zero rounding.
 * (e.g. 1.005 -> 1.01 and -1.005 -> -1.01)
 *
 * @param {number} val
 * @param {number} [decimals=2]
 * @returns {number}
 */
function roundHalfAway(val, decimals = 2) {
  if (!Number.isFinite(val)) return val;
  const sign = val < 0 ? -1 : 1;
  const abs = Math.abs(val);
  let [mantissa, exponent] = abs.toString().split('e');
  const shifted = Math.round(Number(mantissa + 'e' + (exponent ? Number(exponent) + decimals : decimals)));
  [mantissa, exponent] = shifted.toString().split('e');
  const result = Number(mantissa + 'e' + (exponent ? Number(exponent) - decimals : -decimals));
  const signedResult = sign * result;
  return Object.is(signedResult, -0) ? 0 : signedResult;
}

/**
 * Normalizes an array of ledger entries into a single target currency.
 *
 * @param {Array<object>} entries
 * @param {Record<string, number>} rates Plain object mapping currency code to units of target per 1 CUR.
 * @param {string} target Target currency code.
 * @returns {Array<object>} New array of normalized entries.
 */
function normalize(entries, rates, target) {
  if (!Array.isArray(entries)) {
    return [];
  }

  return entries.map((entry) => {
    const origCurrency = entry.currency;
    const origAmount = entry.amount;

    let convertedAmount;
    if (origCurrency === target) {
      // An entry already in target passes through with amount unchanged and a rate of exactly 1
      convertedAmount = origAmount;
    } else {
      if (
        !rates ||
        typeof rates !== 'object' ||
        !(origCurrency in rates) ||
        typeof rates[origCurrency] !== 'number' ||
        !Number.isFinite(rates[origCurrency])
      ) {
        const err = new Error(`Missing exchange rate for currency: ${origCurrency}`);
        err.code = 'E_RATE';
        err.currency = origCurrency;
        throw err;
      }
      const rate = rates[origCurrency];
      convertedAmount = roundHalfAway(origAmount * rate, 2);
    }

    return {
      ...entry,
      amount: convertedAmount,
      currency: target,
      originalAmount: origAmount,
      originalCurrency: origCurrency,
    };
  });
}

module.exports = {
  normalize,
  roundHalfAway,
};
