'use strict';

const { balanceOf } = require('./balance');
const { sub } = require('./money');

/**
 * Reconciles two independently-kept ledgers of the same account.
 *
 * @param {Iterable<Object>} ledgerA First ledger entries iterable
 * @param {Iterable<Object>} ledgerB Second ledger entries iterable
 * @returns {{
 *   matched: Array<{ date: string, currency: string, totalMinor: number }>,
 *   onlyInA: Array<{ date: string, currency: string, totalMinor: number, entryCount: number }>,
 *   onlyInB: Array<{ date: string, currency: string, totalMinor: number, entryCount: number }>,
 *   mismatched: Array<{ date: string, currency: string, aMinor: number, bMinor: number, deltaMinor: number }>
 * }}
 */
function reconcile(ledgerA, ledgerB) {
  const { groups: groupsA } = balanceOf(ledgerA);
  const { groups: groupsB } = balanceOf(ledgerB);

  const mapA = new Map();
  for (const group of groupsA) {
    const key = `${group.date}\0${group.currency}`;
    mapA.set(key, group);
  }

  const mapB = new Map();
  for (const group of groupsB) {
    const key = `${group.date}\0${group.currency}`;
    mapB.set(key, group);
  }

  const matched = [];
  const onlyInA = [];
  const onlyInB = [];
  const mismatched = [];

  for (const [key, groupA] of mapA.entries()) {
    if (mapB.has(key)) {
      const groupB = mapB.get(key);
      if (groupA.totalMinor === groupB.totalMinor) {
        matched.push({
          date: groupA.date,
          currency: groupA.currency,
          totalMinor: groupA.totalMinor,
        });
      } else {
        const deltaMinor = sub(groupA.totalMinor, groupB.totalMinor);
        mismatched.push({
          date: groupA.date,
          currency: groupA.currency,
          aMinor: groupA.totalMinor,
          bMinor: groupB.totalMinor,
          deltaMinor,
        });
      }
    } else {
      onlyInA.push(groupA);
    }
  }

  for (const [key, groupB] of mapB.entries()) {
    if (!mapA.has(key)) {
      onlyInB.push(groupB);
    }
  }

  const compareDateCurrency = (a, b) => {
    const dateCmp = a.date.localeCompare(b.date);
    if (dateCmp !== 0) return dateCmp;
    return a.currency.localeCompare(b.currency);
  };

  matched.sort(compareDateCurrency);
  onlyInA.sort(compareDateCurrency);
  onlyInB.sort(compareDateCurrency);
  mismatched.sort(compareDateCurrency);

  return {
    matched,
    onlyInA,
    onlyInB,
    mismatched,
  };
}

/**
 * Checks whether a reconciliation result indicates complete agreement between ledgers.
 *
 * @param {Object} result Reconciliation result from reconcile()
 * @returns {boolean} True if and only if onlyInA, onlyInB, and mismatched are all empty
 */
function isReconciled(result) {
  if (!result || typeof result !== 'object') {
    return false;
  }
  const { onlyInA, onlyInB, mismatched } = result;
  return (
    Array.isArray(onlyInA) && onlyInA.length === 0 &&
    Array.isArray(onlyInB) && onlyInB.length === 0 &&
    Array.isArray(mismatched) && mismatched.length === 0
  );
}

module.exports = {
  reconcile,
  isReconciled,
};
