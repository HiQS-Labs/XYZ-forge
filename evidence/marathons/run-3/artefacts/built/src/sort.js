'use strict';

// only amount compares numerically; everything else (including lineNo) uses localeCompare
const NUMERIC_KEYS = new Set(['amount']);
const VALID_KEYS = new Set(['date', 'account', 'amount', 'currency', 'memo', 'lineNo']);

function sortEntries(entries, keys) {
  for (const rawKey of keys) {
    const key = rawKey.startsWith('-') ? rawKey.slice(1) : rawKey;
    if (!VALID_KEYS.has(key)) {
      const err = new Error(`unknown sort key: ${key}`);
      err.code = 'E_SORTKEY';
      err.key = key;
      throw err;
    }
  }

  const parsed = keys.map(rawKey => {
    const desc = rawKey.startsWith('-');
    return { field: desc ? rawKey.slice(1) : rawKey, dir: desc ? -1 : 1 };
  });

  // Decorate with original index so the comparator's tie-break is stable
  // regardless of the engine's internal sort stability guarantee.
  const decorated = entries.map((entry, i) => ({ entry, i }));

  decorated.sort((a, b) => {
    for (const { field, dir } of parsed) {
      const av = a.entry[field];
      const bv = b.entry[field];
      const cmp = NUMERIC_KEYS.has(field) ? av - bv : String(av).localeCompare(String(bv));
      if (cmp !== 0) return cmp * dir;
    }
    return a.i - b.i;
  });

  return decorated.map(d => d.entry);
}

module.exports = { sortEntries };
