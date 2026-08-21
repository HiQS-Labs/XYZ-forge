# r2p2 — Balance sheets built on Money

## Depends on

`src/money.js` from phase r2p1. **Read that file before starting** — use its
actual exported names and semantics, not what you would have called them.

## Goal

Add `src/balance.js` exporting `balanceOf(entries)`, which computes exact per
`(date, currency)` totals in minor units via `src/money.js`.

## Requirements

1. Convert each entry's `amount` through `money.fromString`. Entries arrive from
   `src/parse.js` with `amount` as a NUMBER, so render it to a fixed 2-decimal
   string before parsing rather than passing the float in directly. Say in a
   comment why that intermediate step exists.
2. Return `{ groups, unbalanced }`. `groups` is an array of
   `{ date, currency, totalMinor, entryCount }` sorted by date then currency.
   `unbalanced` is the subset whose `totalMinor !== 0`.
3. Exact zero, not a tolerance. There must be no epsilon anywhere in this file —
   that is the entire point of building on r2p1.
4. Export `isBalanced(entries)` returning a boolean.

## Acceptance

`test/balance.test.js` (`node:test`) covering: a balanced day, an unbalanced day
with the exact `totalMinor` delta asserted, independent currencies, and a case
whose float arithmetic would drift (three entries of `0.10` against one of
`-0.30`) proving exact zero. `npm test` green.

## Out of scope

Do not modify `src/money.js`, `src/validate.js`, or anything from run 1.
