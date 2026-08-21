# r3p2 — Exact decimal arithmetic without floats

## Goal

Add `src/decimal.js`: a small arbitrary-precision decimal type backed by
`BigInt`, so ledger arithmetic is exact at any scale rather than at a fixed two
places.

This one is genuinely hard. The failure modes below are the ones that actually
bite, and each is worth more than a passing test that avoids it.

## Requirements

1. `Decimal.from(value)` accepts a decimal STRING (`"-125.40"`, `"0.000001"`,
   `"1e-7"` in exponent form) or a `BigInt`. Represent it as
   `{ unscaled: BigInt, scale: number }` where the value is `unscaled / 10**scale`.
   Never route through `Number` — that is the whole point.
2. `add`, `sub`, `mul`. Adding operands of DIFFERENT scale must align them first;
   `mul` scales add (`scale(a*b) = scale(a) + scale(b)`).
3. `div(a, b, { scale, rounding })` — division needs an explicit target scale
   because the exact result may not terminate. Default rounding is HALF_EVEN
   (banker's rounding), which is the one most implementations get wrong. Support
   at least `HALF_EVEN` and `HALF_UP`. `1/3` at scale 4 is `0.3333`; `0.5`
   rounded to scale 0 HALF_EVEN is `0`, while `1.5` is `2` — assert both.
4. `cmp(a, b)` compares across differing scales. `eq` must treat `1.0` and `1.00`
   as EQUAL in value while `toString` preserves each one's own scale.
5. Division by zero throws with `code === 'E_DIVZERO'`.
6. Negative-value rounding must be symmetric: rounding `-0.5` at scale 0 HALF_EVEN
   is `-0`/`0`, and `-1.5` is `-2`. Sign handling around the rounding boundary is
   the single most common defect here — write the test that would catch it.

## Acceptance

`test/decimal.test.js` (`node:test`). Beyond the happy path, it MUST cover: the
different-scale addition, the two HALF_EVEN cases in requirement 3, the negative
rounding cases in requirement 6, `eq` across differing scales with `toString`
preserving scale, `E_DIVZERO`, and a value large enough to lose precision as a
float (e.g. `"9007199254740993.01"`) surviving a round trip exactly.
`npm test` green.

## Out of scope

No dependencies — `BigInt` is built in. Do not modify existing `src/` files.

## If you cannot fully satisfy this

Say so explicitly in the relay rather than shipping something that passes only
the tests you chose. A narrower, correct, clearly-stated subset is a better
outcome than a broad one that is quietly wrong — and state precisely which
requirements you did not meet.
