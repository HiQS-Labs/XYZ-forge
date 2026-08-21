# Marathon Phase r3p2
STATUS: Approved
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-R3P2-TURN builder=claude reviewer=codex round-cap=7 -->

## Phase Brief

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


---

▶ TAKE YOUR TURN (claude — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): src/decimal.js,test/decimal.test.js
2. Append a build block to this relay file: `### Round N · Builder · claude` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /home/arnoldadero/marathon-target/.xyz/bin/tick
   - /home/arnoldadero/marathon-target/.xyz/bin/tick claim MARATHON-R3P2-TURN --agent claude --paths "marathon-system/run3-hard-ambiguous--r3p2/RELAY.md,src/decimal.js,test/decimal.test.js"
   - /home/arnoldadero/marathon-target/.xyz/bin/tick ping MARATHON-R3P2-TURN --agent claude
   - /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R3P2-TURN --agent claude --to codex
4. Edit ONLY these paths: marathon-system/run3-hard-ambiguous--r3p2/RELAY.md and src/decimal.js,test/decimal.test.js. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

### Round 1 · Builder · claude

**Files touched:** `src/decimal.js`, `test/decimal.test.js`

**Implementation summary:**

- `Decimal` class stores `{ unscaled: BigInt, scale: number }` — never routes through `Number`.
- `Decimal.from(value)` parses decimal strings (positive, negative, leading/trailing zeros) and scientific notation (`1e-7`, `1.5e3`) without touching `Number`; also accepts `BigInt` directly.
- `_align(a, b)` scales up the operand with the smaller scale before add/sub.
- `mul` adds scales (`scale(a*b) = scale(a) + scale(b)`).
- `div(a, b, { scale, rounding })` uses exact BigInt arithmetic with 2×remainder vs denominator comparison for halfway detection. Supports `HALF_EVEN` (banker's) and `HALF_UP`. Negative-value rounding is handled via sign detection before adjustment — `-0.5` → `0`, `-1.5` → `-2`, `-2.5` → `-2`.
- `cmp`/`eq` align before comparing; `toString` always preserves the original scale.
- Division by zero throws `Error` with `code === 'E_DIVZERO'`.

**Tests (27, all green):** happy path, different-scale add, both HALF_EVEN cases (0.5→0, 1.5→2), both negative HALF_EVEN cases (-0.5→0, -1.5→-2, -2.5→-2), HALF_UP, eq across differing scales, toString scale preservation, E_DIVZERO, large-value exact round-trip (`9007199254740993.01`).

### Round 1 · Reviewer · codex

swept file: yes

Reviewed all of `src/decimal.js` and `test/decimal.test.js`, including the pre-existing contents; no defects found. The implementation uses `BigInt` for significands, preserves per-instance scale in `toString`, aligns operands for value comparison/arithmetic, and implements symmetric HALF_EVEN/HALF_UP rounding. The focused decimal suite passes all 27 tests.

**Verdict:** Approved

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/decimal.js,test/decimal.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: claude (Builder)`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R3P2-TURN --agent codex --to claude
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick done MARATHON-R3P2-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /home/arnoldadero/marathon-target/.xyz/bin/tick
   Edit ONLY marathon-system/run3-hard-ambiguous--r3p2/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to claude —
   claude, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.
