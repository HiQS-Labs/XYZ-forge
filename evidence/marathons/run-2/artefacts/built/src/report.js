'use strict';

const { toString } = require('./money');
const { isReconciled } = require('./reconcile');

/**
 * Turns a reconcile() result object into formatted human-readable plain text.
 *
 * @param {Object} result Reconciliation result from reconcile()
 * @param {Object} [options] Formatting options
 * @param {boolean} [options.summaryOnly] When true, returns a single verdict line
 * @returns {string} Plain-text report
 */
function renderReport(result, options = {}) {
  if (!result || typeof result !== 'object') {
    const err = new Error('renderReport() expects a result object');
    err.code = 'E_INVALID';
    throw err;
  }

  const matched = Array.isArray(result.matched) ? result.matched : [];
  const onlyInA = Array.isArray(result.onlyInA) ? result.onlyInA : [];
  const onlyInB = Array.isArray(result.onlyInB) ? result.onlyInB : [];
  const mismatched = Array.isArray(result.mismatched) ? result.mismatched : [];

  if (options && options.summaryOnly === true) {
    if (isReconciled(result) || (mismatched.length === 0 && onlyInA.length === 0 && onlyInB.length === 0)) {
      return 'RECONCILED';
    }
    return `NOT RECONCILED: ${mismatched.length} mismatched, ${onlyInA.length} only-in-A, ${onlyInB.length} only-in-B`;
  }

  const matchedRows = matched.map((r) => ({
    date: String(r.date || ''),
    currency: String(r.currency || ''),
    amountStr: toString(r.totalMinor),
  }));

  const onlyInARows = onlyInA.map((r) => ({
    date: String(r.date || ''),
    currency: String(r.currency || ''),
    amountStr: toString(r.totalMinor),
  }));

  const onlyInBRows = onlyInB.map((r) => ({
    date: String(r.date || ''),
    currency: String(r.currency || ''),
    amountStr: toString(r.totalMinor),
  }));

  const mismatchedRows = mismatched.map((r) => ({
    date: String(r.date || ''),
    currency: String(r.currency || ''),
    aStr: toString(r.aMinor),
    bStr: toString(r.bMinor),
    deltaStr: toString(r.deltaMinor),
  }));

  const allDates = [
    ...matchedRows.map((r) => r.date),
    ...onlyInARows.map((r) => r.date),
    ...onlyInBRows.map((r) => r.date),
    ...mismatchedRows.map((r) => r.date),
  ];

  const allCurrencies = [
    ...matchedRows.map((r) => r.currency),
    ...onlyInARows.map((r) => r.currency),
    ...onlyInBRows.map((r) => r.currency),
    ...mismatchedRows.map((r) => r.currency),
  ];

  const allAmounts = [
    ...matchedRows.map((r) => r.amountStr),
    ...onlyInARows.map((r) => r.amountStr),
    ...onlyInBRows.map((r) => r.amountStr),
    ...mismatchedRows.map((r) => r.aStr),
    ...mismatchedRows.map((r) => r.bStr),
    ...mismatchedRows.map((r) => r.deltaStr),
  ];

  const maxDateLen = allDates.reduce((max, d) => Math.max(max, d.length), 0);
  const maxCurrencyLen = allCurrencies.reduce((max, c) => Math.max(max, c.length), 0);
  const maxAmountLen = allAmounts.reduce((max, a) => Math.max(max, a.length), 0);

  const renderSingleRow = (r) => {
    const dateStr = r.date.padEnd(maxDateLen);
    const currStr = r.currency.padEnd(maxCurrencyLen);
    const amtStr = r.amountStr.padStart(maxAmountLen);
    return `  ${dateStr}  ${currStr}  ${amtStr}`;
  };

  const renderMismatchRow = (r) => {
    const dateStr = r.date.padEnd(maxDateLen);
    const currStr = r.currency.padEnd(maxCurrencyLen);
    const aAmtStr = r.aStr.padStart(maxAmountLen);
    const bAmtStr = r.bStr.padStart(maxAmountLen);
    const deltaAmtStr = r.deltaStr.padStart(maxAmountLen);
    return `  ${dateStr}  ${currStr}  A: ${aAmtStr}  B: ${bAmtStr}  delta: ${deltaAmtStr}`;
  };

  const lines = [];

  // 1. MATCHED
  lines.push('MATCHED');
  if (matchedRows.length === 0) {
    lines.push('  (none)');
  } else {
    for (const r of matchedRows) {
      lines.push(renderSingleRow(r));
    }
  }

  // 2. ONLY IN A
  lines.push('ONLY IN A');
  if (onlyInARows.length === 0) {
    lines.push('  (none)');
  } else {
    for (const r of onlyInARows) {
      lines.push(renderSingleRow(r));
    }
  }

  // 3. ONLY IN B
  lines.push('ONLY IN B');
  if (onlyInBRows.length === 0) {
    lines.push('  (none)');
  } else {
    for (const r of onlyInBRows) {
      lines.push(renderSingleRow(r));
    }
  }

  // 4. MISMATCHED
  lines.push('MISMATCHED');
  if (mismatchedRows.length === 0) {
    lines.push('  (none)');
  } else {
    for (const r of mismatchedRows) {
      lines.push(renderMismatchRow(r));
    }
  }

  return lines.join('\n');
}

module.exports = {
  renderReport,
};
