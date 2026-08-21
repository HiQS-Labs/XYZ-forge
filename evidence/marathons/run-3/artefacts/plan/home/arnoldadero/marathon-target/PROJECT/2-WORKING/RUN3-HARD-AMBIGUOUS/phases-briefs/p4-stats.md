# r3p4 — Ledger statistics

## Goal

Add `src/stats.js` exporting `stats(entries)` — descriptive statistics over a
ledger, for a "does this look right?" glance.

## Requirements

1. Return `{ count, dateRange, byCurrency, topAccounts }`.
2. `dateRange` is `{ first, last }` as ISO date strings, or `null` for an empty
   input. An empty input must not throw anywhere in this function.
3. `byCurrency` maps each currency to
   `{ count, debits, credits, net, largestAbs }`, where `debits` sums the negative
   amounts, `credits` the positive, and `net` is their sum. State the sign
   convention in a comment.
4. `topAccounts` lists the 5 accounts with the largest absolute net movement, as
   `{ account, currency, net, absNet }`, descending by `absNet`. Ties break by
   account name ascending so output is deterministic.
5. Amounts round to 2 decimals on output only — do not round during accumulation.

## Acceptance

`test/stats.test.js` (`node:test`) covering: an empty ledger returning
`dateRange: null` without throwing, a multi-currency ledger, the debit/credit
sign convention, `topAccounts` capping at 5, and deterministic tie-breaking.
`npm test` green.

## Out of scope

Do not modify existing `src/` files. No dependencies.
