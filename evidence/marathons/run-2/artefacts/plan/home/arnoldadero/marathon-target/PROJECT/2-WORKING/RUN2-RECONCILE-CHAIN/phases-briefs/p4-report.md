# r2p4 — Reconciliation report renderer

## Depends on

`src/reconcile.js` (r2p3), and through it r2p2 and r2p1. Read them.

## Goal

Add `src/report.js` exporting `renderReport(result, options)` — turn a
`reconcile()` result into text a human reads.

## Requirements

1. Plain-text report with four labelled sections in this order: `MATCHED`,
   `ONLY IN A`, `ONLY IN B`, `MISMATCHED`. A section with no rows prints its
   heading followed by `  (none)`.
2. Money renders through `money.toString`, never as raw minor units. Mismatch rows
   show both sides and the delta.
3. Columns align: dates, currencies and amounts line up regardless of magnitude
   or sign. Amounts right-aligned.
4. `options.summaryOnly === true` prints only a one-line verdict:
   `RECONCILED` or `NOT RECONCILED: <n> mismatched, <n> only-in-A, <n> only-in-B`.
5. Return the string; do not print. The caller decides where it goes.

## Acceptance

`test/report.test.js` (`node:test`) covering: a fully reconciled result, empty
sections rendering `(none)`, a mismatch row showing both sides and the delta,
alignment holding across a wide magnitude range, and `summaryOnly`. `npm test`
green.

## Out of scope

Do not modify any upstream module in this chain.
