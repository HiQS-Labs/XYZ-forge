'use strict';

/**
 * Normalizes a memo string for comparison:
 * - Converts to lowercase
 * - Collapses runs of whitespace into a single space
 * - Trims leading and trailing whitespace
 *
 * @param {string|null|undefined} memo
 * @returns {string}
 */
function normalizeMemo(memo) {
  if (memo == null) return '';
  return String(memo).trim().toLowerCase().replace(/\s+/g, ' ');
}

/**
 * Builds a duplicate-matching key for a ledger entry.
 *
 * Note: lineNo is deliberately NOT part of the key. Two entries that match on
 * date, account, amount, currency, and (optionally) normalized memo are duplicate
 * records even if they sit on different line numbers in the ledger.
 *
 * @param {object} entry
 * @param {boolean} ignoreMemo
 * @returns {string}
 */
function makeKey(entry, ignoreMemo) {
  const base = `${entry.date}|${entry.account}|${entry.amount}|${entry.currency}`;
  if (ignoreMemo) {
    return base;
  }
  return `${base}|${normalizeMemo(entry.memo)}`;
}

/**
 * Identifies duplicate entries in a list of ledger entries.
 *
 * @param {Array<object>} [entries=[]]
 * @param {object} [options={}]
 * @param {boolean} [options.ignoreMemo=false]
 * @returns {Array<{ key: string, entries: Array<object>, count: number }>}
 */
function findDuplicates(entries = [], options = {}) {
  if (!entries || !Array.isArray(entries)) {
    return [];
  }

  const ignoreMemo = Boolean(options && options.ignoreMemo === true);
  const groupsByKey = new Map();

  for (let i = 0; i < entries.length; i++) {
    const entry = entries[i];
    if (!entry) continue;

    const key = makeKey(entry, ignoreMemo);
    let group = groupsByKey.get(key);
    if (!group) {
      group = {
        key,
        entries: [],
        count: 0,
        firstLineNo: entry.lineNo !== undefined ? entry.lineNo : null,
        firstIndex: i,
      };
      groupsByKey.set(key, group);
    }
    group.entries.push(entry);
    group.count = group.entries.length;
  }

  // Filter only duplicate groups (count >= 2)
  const duplicates = [];
  for (const group of groupsByKey.values()) {
    if (group.count >= 2) {
      duplicates.push({
        key: group.key,
        entries: group.entries,
        count: group.count,
        _firstLineNo: group.firstLineNo,
        _firstIndex: group.firstIndex,
      });
    }
  }

  // Sort groups by the line number of their first member, ascending
  duplicates.sort((a, b) => {
    const lineA = a._firstLineNo != null ? a._firstLineNo : a._firstIndex;
    const lineB = b._firstLineNo != null ? b._firstLineNo : b._firstIndex;
    if (lineA !== lineB) {
      return lineA - lineB;
    }
    return a._firstIndex - b._firstIndex;
  });

  // Strip internal sorting helpers so returned objects strictly match { key, entries, count }
  return duplicates.map(({ key, entries, count }) => ({ key, entries, count }));
}

module.exports = {
  findDuplicates,
  normalizeMemo,
};
