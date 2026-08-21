# r2p1 — Exact money as integer minor units

## Goal

Add `src/money.js`. Every later phase in this run depends on it, so the contract
below is the contract they will be written against — get it exact.

`src/validate.js` currently stores amounts as JavaScript floats and papers over
the consequences with a `Math.abs(sum) > 0.005` tolerance. That tolerance is a
symptom. This module removes the need for it.

## Requirements

1. Export `fromString(s)` parsing a decimal string (`"-125.40"`, `"3"`, `"0.05"`)
   into an integer count of MINOR UNITS (cents). `"-125.40"` becomes `-12540`.
   Reject anything with more than 2 decimal places by throwing an `Error` with
   `code === 'E_PRECISION'`.
2. Do NOT implement this as `Math.round(parseFloat(s) * 100)`. That is exactly the
   bug being removed: `parseFloat("1.005") * 100` is `100.49999999999999`. Parse
   the string's digits directly.
3. Export `add(a, b)`, `sub(a, b)`, `neg(a)` and `sum(list)` over minor units.
4. Export `toString(minor)` rendering back to a 2-decimal string, sign preserved:
   `-12540` becomes `"-125.40"`, `5` becomes `"0.05"`, `0` becomes `"0.00"`.
5. Export `allocate(minor, ratios)` splitting an amount across integer ratios with
   NO cents lost: the parts must sum EXACTLY to the input. Distribute the
   remainder one minor unit at a time to the largest remainders first. This is the
   part that is easy to get subtly wrong — `allocate(1000, [1,1,1])` must return
   `[334, 333, 333]`, not three values that sum to 999.

## Acceptance

`test/money.test.js` (`node:test`) covering: the `1.005` case from requirement 2,
`E_PRECISION`, round-tripping through `toString`, negative rendering, and
`allocate` summing exactly for `[1,1,1]` over 1000 and over 1 minor unit.
`npm test` green.

## Out of scope

Do not modify `src/validate.js` — a later phase decides what consumes this. No
dependencies.
