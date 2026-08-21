# r1p4 — Duplicate-entry detection

## Goal

Add `src/dedupe.js` exporting `findDuplicates(entries, options)` — flag ledger
entries that look like the same transaction recorded twice.

## Requirements

1. Two entries are duplicates when `date`, `account`, `amount`, `currency` AND
   the NORMALIZED memo all match. Normalizing a memo means: lowercase, collapse
   internal whitespace runs to one space, and trim.
2. Return an array of groups. Each group is
   `{ key, entries: [...], count }`, where `entries` holds every member in input
   order and `count >= 2`. Entries appearing only once are not returned at all.
3. Groups come back sorted by the line number of their first member, ascending —
   so the report reads in file order.
4. `options.ignoreMemo === true` drops the memo from the match key entirely.
5. A legitimate repeat is not a duplicate: two entries that match on everything
   but sit on different `lineNo` values ARE still duplicates — `lineNo` is
   deliberately not part of the key. Say so in a comment so the next reader does
   not "fix" it.

## Acceptance

Add `test/dedupe.test.js` (`node:test`) covering: no duplicates, an exact
duplicate pair, a triple, memo normalization matching `"Coffee  Beans"` with
`"coffee beans"`, non-matching amounts staying separate, `ignoreMemo`, and the
input-order sort. `npm test` green.

## Out of scope

Do not modify existing `src/` files. No dependencies.
