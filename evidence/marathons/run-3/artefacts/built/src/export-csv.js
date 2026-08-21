'use strict';

function escapeField(value) {
  const str = value == null ? '' : String(value);
  if (/[",\r\n]/.test(str)) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

const amountFormatter = new Intl.NumberFormat('en-US', {
  useGrouping: false,
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

function formatAmount(amount) {
  if (amount == null) {
    return '';
  }
  const n = Number(amount);
  if (Number.isNaN(n) || !Number.isFinite(n)) {
    return escapeField(amount);
  }
  const val = n === 0 ? 0 : n;
  return amountFormatter.format(val);
}

function toCSV(entries = [], options = {}) {
  const rows = [];
  if (!options || options.header !== false) {
    rows.push('date,account,amount,currency,memo');
  }

  if (entries && (Array.isArray(entries) || typeof entries[Symbol.iterator] === 'function')) {
    for (const entry of entries) {
      if (!entry) continue;
      const row = [
        escapeField(entry.date),
        escapeField(entry.account),
        formatAmount(entry.amount),
        escapeField(entry.currency),
        escapeField(entry.memo),
      ].join(',');
      rows.push(row);
    }
  }

  return rows.join('\r\n');
}

module.exports = { toCSV };
