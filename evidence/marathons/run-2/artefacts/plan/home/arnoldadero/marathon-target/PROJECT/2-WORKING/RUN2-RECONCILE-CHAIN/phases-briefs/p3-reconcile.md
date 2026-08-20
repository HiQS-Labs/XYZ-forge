# r2p3 — Two-ledger reconciler over balances

## Depends on

`src/balance.js` (r2p2) and transitively `src/money.js` (r2p1). Read both.

## Goal

Add `src/reconcile.js` exporting `reconcile(ledgerA, ledgerB)` — compare two
independently-kept ledgers of the same account and report where they disagree.

## Requirements

1. Both inputs are entry arrays from `src/parse.js`. Compute each side's balance
   groups via `src/balance.js`.
2. Return `{ matched, onlyInA, onlyInB, mismatched }`:
   - `matched` — `(date, currency)` present on both sides with equal `totalMinor`.
   - `onlyInA` / `onlyInB` — groups present on one side only.
   - `mismatched` — present on both, different totals. Each carries
     `{ date, currency, aMinor, bMinor, deltaMinor }` where `delta = a - b`.
3. All four arrays sorted by date then currency. Deterministic output: the same
   inputs must produce byte-identical results across runs.
4. Export `isReconciled(result)` — true only when `onlyInA`, `onlyInB` and
   `mismatched` are all empty.
5. Do the arithmetic through `src/money.js`, not with `-` on raw numbers.

## Acceptance

`test/reconcile.test.js` (`node:test`) covering: identical ledgers, a
one-sided date, a same-date total mismatch with the exact `deltaMinor` asserted,
a currency present on only one side, and determinism (reconcile twice, deep-equal
the results). `npm test` green.

## Out of scope

Do not modify `src/money.js` or `src/balance.js`. If either has a defect that
blocks you, say so in the relay rather than editing it — that is a finding.
