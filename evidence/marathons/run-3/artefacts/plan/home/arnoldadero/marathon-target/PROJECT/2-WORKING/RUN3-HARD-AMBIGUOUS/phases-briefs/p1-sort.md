# r3p1 — Stable multi-key sort

## Goal

Add `src/sort.js` exporting `sortEntries(entries, keys)` — order ledger entries by
several keys at once, stably.

## Requirements

1. `keys` is an array like `['date', '-amount', 'account']`. A leading `-` means
   descending for that key only.
2. The sort is STABLE: entries comparing equal on every key keep their original
   relative order. `Array.prototype.sort` is stable in modern V8, but do not rely
   on that silently — either state it in a comment or decorate with the original
   index.
3. Comparison is type-aware: `amount` compares numerically, everything else as a
   string with `localeCompare`. An unknown key name throws an `Error` with
   `code === 'E_SORTKEY'` naming the offending key.
4. Do not mutate the input array. Return a new one.
5. An empty `keys` array returns a copy in the original order.

## Acceptance

`test/sort.test.js` (`node:test`) covering: single key ascending, `-` descending,
multi-key tie-breaking, stability under a full tie (assert original order
survives), `E_SORTKEY`, input immutability, and the empty-keys case.
`npm test` green.

## Out of scope

Do not modify existing `src/` files. No dependencies.
