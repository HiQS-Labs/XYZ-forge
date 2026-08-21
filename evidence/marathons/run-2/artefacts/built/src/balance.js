'use strict';

const { fromString, add } = require('./money');

/**
 * Computes exact per (date, currency) totals in minor units via src/money.js.
 *
 * @param {Iterable<Object>} entries Iterable of parsed ledger entries
 * @returns {{ groups: Array<{ date: string, currency: string, totalMinor: number, entryCount: number }>, unbalanced: Array<{ date: string, currency: string, totalMinor: number, entryCount: number }> }}
 */
function balanceOf(entries) {
  if (!entries || typeof entries[Symbol.iterator] !== 'function') {
    const err = new Error('balanceOf() expects an iterable of entry objects');
    err.code = 'E_INVALID';
    throw err;
  }

  // Map keyed by `${date}\0${currency}` to group record
  const groupMap = new Map();

  for (const entry of entries) {
    if (!entry || typeof entry !== 'object') {
      const err = new Error('Entry must be an object');
      err.code = 'E_INVALID';
      throw err;
    }

    const { date, currency, amount } = entry;
    if (typeof date !== 'string' || typeof currency !== 'string') {
      const err = new Error('Entry must have string date and currency');
      err.code = 'E_INVALID';
      throw err;
    }

    // Entries arrive from src/parse.js with amount as a NUMBER (float).
    // money.fromString expects a decimal string (e.g. "125.40") and parses
    // digits directly to integer cents without floating-point math inaccuracies.
    // We format the number using toFixed(2) to produce the standard 2-decimal string
    // before parsing, rather than passing the float directly.
    let amountMinor;
    if (typeof amount === 'number') {
      if (!Number.isFinite(amount)) {
        const err = new Error(`Invalid entry amount: ${amount}`);
        err.code = 'E_INVALID';
        throw err;
      }
      amountMinor = fromString(amount.toFixed(2));
    } else if (typeof amount === 'string') {
      amountMinor = fromString(amount);
    } else {
      const err = new Error(`Expected number or string amount, got ${typeof amount}`);
      err.code = 'E_INVALID';
      throw err;
    }

    const key = `${date}\0${currency}`;
    let group = groupMap.get(key);
    if (!group) {
      group = {
        date,
        currency,
        totalMinor: 0,
        entryCount: 0,
      };
      groupMap.set(key, group);
    }

    group.totalMinor = add(group.totalMinor, amountMinor);
    group.entryCount += 1;
  }

  const groups = Array.from(groupMap.values()).sort((a, b) => {
    const dateCmp = a.date.localeCompare(b.date);
    if (dateCmp !== 0) return dateCmp;
    return a.currency.localeCompare(b.currency);
  });

  const unbalanced = groups.filter((g) => g.totalMinor !== 0);

  return { groups, unbalanced };
}

/**
 * Returns whether all (date, currency) groups in the entries are balanced.
 *
 * @param {Iterable<Object>} entries Iterable of parsed ledger entries
 * @returns {boolean}
 */
function isBalanced(entries) {
  const { unbalanced } = balanceOf(entries);
  return unbalanced.length === 0;
}

module.exports = {
  balanceOf,
  isBalanced,
};
