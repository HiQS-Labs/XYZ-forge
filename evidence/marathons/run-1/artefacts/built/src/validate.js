'use strict';

// A ledger is balanced when, per (date, currency), the amounts sum to zero.
// Real double-entry: every movement has a counterpart.
function groupKey(entry) {
  return `${entry.date} ${entry.currency}`;
}

function validate(entries) {
  const problems = [];
  const groups = new Map();

  for (const e of entries) {
    if (!Number.isFinite(e.amount)) {
      problems.push({ code: 'E_AMOUNT', lineNo: e.lineNo, message: `non-finite amount on line ${e.lineNo}` });
      continue;
    }
    const k = groupKey(e);
    if (!groups.has(k)) groups.set(k, []);
    groups.get(k).push(e);
  }

  for (const [k, members] of groups) {
    const [date, currency] = k.split(' ');
    const sum = members.reduce((acc, e) => acc + e.amount, 0);
    // Money is stored as a float here; tolerate sub-cent drift.
    if (Math.abs(sum) > 0.005) {
      problems.push({
        code: 'E_UNBALANCED',
        date,
        currency,
        delta: sum,
        message: `${date} ${currency} does not balance: delta ${sum.toFixed(4)}`,
      });
    }
  }

  return { ok: problems.length === 0, problems };
}

module.exports = { validate, groupKey };
