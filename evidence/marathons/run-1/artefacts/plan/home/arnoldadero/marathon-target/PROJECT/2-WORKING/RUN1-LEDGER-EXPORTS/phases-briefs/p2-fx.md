# r1p2 — Currency normalization

## Goal

Add `src/fx.js` exporting `normalize(entries, rates, target)`, converting every
entry into a single target currency so cross-currency ledgers can be totalled.

## Requirements

1. `rates` is a plain object of `{ CUR: <units of target per 1 CUR> }`, e.g.
   `{ USD: 1, EUR: 1.08 }` when `target` is `'USD'`.
2. Return NEW entry objects. Do not mutate the input array or its members —
   the caller still needs the originals.
3. Each returned entry keeps every original field, sets `currency` to `target`,
   sets `amount` to the converted value, and additionally carries
   `originalAmount` and `originalCurrency`.
4. An entry already in `target` passes through with `amount` unchanged and a rate
   of exactly 1 — do not multiply it by a supplied rate that disagrees.
5. A missing rate is an error, not a silent skip: throw an `Error` with
   `code === 'E_RATE'` and a `currency` property naming the offender.
6. Converted amounts round to 2 decimal places, half away from zero. Note that
   JavaScript's `Math.round` is half-UP, not half-away-from-zero, so `-1.005`
   and `1.005` must not round in opposite magnitudes. Handle this deliberately.

## Acceptance

Add `test/fx.test.js` (`node:test`), covering: a straight conversion, the
identity case, input immutability, the `E_RATE` throw, and the negative
half-way rounding case from requirement 6. `npm test` green.

## Out of scope

Do not modify existing `src/` files. No new dependencies. No network — rates are
always passed in by the caller.
