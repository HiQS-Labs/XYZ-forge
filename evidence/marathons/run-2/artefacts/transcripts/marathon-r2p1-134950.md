# Marathon Phase r2p1
STATUS: Approved
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-R2P1-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

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


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): src/money.js,test/money.test.js
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /home/arnoldadero/marathon-target/.xyz/bin/tick
   - /home/arnoldadero/marathon-target/.xyz/bin/tick claim MARATHON-R2P1-TURN --agent agy --paths "marathon-system/run2-reconcile-chain--r2p1/RELAY.md,src/money.js,test/money.test.js"
   - /home/arnoldadero/marathon-target/.xyz/bin/tick ping MARATHON-R2P1-TURN --agent agy
   - /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R2P1-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/run2-reconcile-chain--r2p1/RELAY.md and src/money.js,test/money.test.js. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/money.js,test/money.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R2P1-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick done MARATHON-R2P1-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /home/arnoldadero/marathon-target/.xyz/bin/tick
   Edit ONLY marathon-system/run2-reconcile-chain--r2p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to agy —
   agy, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

---

### Round 1 · Builder · agy

- **Files created:**
  - `src/money.js`: Implemented exact money operations using integer minor units (cents).
    - `fromString(s)`: Parses decimal strings directly without floating-point math, rejecting numbers with > 2 decimal places with `code === 'E_PRECISION'`.
    - `toString(minor)`: Formats integer minor units to 2-decimal strings with sign preserved using exact integer division/modulo.
    - `add(a, b)`, `sub(a, b)`, `neg(a)`, `sum(list)`: Safe integer arithmetic operations over minor units.
    - `allocate(minor, ratios)`: Distributes minor units across integer ratios with zero cents lost, assigning remainder minor units one-by-one to largest remainders first (using index order as stable tie-breaker).
  - `test/money.test.js`: Added comprehensive unit tests using `node:test` covering `1.005` rejection via `E_PRECISION`, direct digit parsing avoiding float inaccuracies, canonical round-tripping through `toString`, negative rendering, exact remainder distribution with `allocate(1000, [1,1,1])` and `allocate(1, [1,1,1])`, zero and negative amount allocations, and input validation.
- **Key decisions:**
  - Direct string parsing in `fromString` parses the whole and fractional parts directly from string digits to avoid `parseFloat`/floating-point rounding inaccuracies.
  - Used exact integer math with `BigInt` formatting in `toString` to avoid exponential notation for arbitrary magnitudes.
  - Remainder distribution in `allocate` uses stable remainder sorting descending by remainder with original index tie-breaking, ensuring exact summation for any ratio set.
- Verified tests with `node --test test/money.test.js` (16/16 passing).

### Round 1 · Reviewer · codex

swept file: yes

- Reviewed the complete `src/money.js` and `test/money.test.js`; no pre-existing defects were present because both files are newly created in this round.
- `node --test test/money.test.js` passes (16/16), and the required ordinary-range parsing, formatting, arithmetic, and allocation behavior is covered.
- **High — exactness is lost for valid-looking amounts and arithmetic beyond `Number.MAX_SAFE_INTEGER`.** `fromString()` uses `parseInt()` and `whole * 100`, while all operations accept `Number.isInteger()` rather than `Number.isSafeInteger()`. For example, parsing `"90071992547409.93"` produces a rounded minor-unit number that `toString()` renders as `"90071992547409.92"`; it silently loses one cent. `allocate()` has the same issue in `absMinor * ratio` and `totalRatio` accumulation. This violates the phase's exact-money goal. Please either make the module consistently BigInt-based (including its documented contract/tests) or retain number results but reject out-of-safe-range inputs/intermediate arithmetic with `E_INVALID`, and add boundary regression tests for parsing and allocation/arithmetic overflow.

**Verdict:** Changes requested

handing off to agy — agy, take your turn

### Round 2 · Builder · agy

- **Files updated:**
  - `src/money.js`:
    - Updated `fromString()`, `toString()`, `add()`, `sub()`, `neg()`, `sum()`, and `allocate()` to strictly validate safe integer boundaries using `Number.isSafeInteger()`.
    - `fromString()` parses whole and fractional digits directly into `BigInt` to compute minor units without intermediate float/precision loss, and validates that the parsed minor unit count falls within `[Number.MIN_SAFE_INTEGER, Number.MAX_SAFE_INTEGER]`, throwing `E_INVALID` if out of bounds (such as `"90071992547409.93"`).
    - `add()`, `sub()`, `neg()`, and `sum()` perform intermediate arithmetic using `BigInt` to detect overflow/underflow against `[Number.MIN_SAFE_INTEGER, Number.MAX_SAFE_INTEGER]`, throwing `E_INVALID` on unsafe results.
    - `allocate()` accumulates ratios and performs `absMinor * ratio` products, shares, and remainder calculations in `BigInt` to avoid overflow for large safe integer amounts and large ratios, throwing `E_INVALID` if inputs or results are outside safe integer range.
  - `test/money.test.js`:
    - Added boundary regression tests verifying safe integer limits (`Number.MAX_SAFE_INTEGER` and `Number.MIN_SAFE_INTEGER`), rejection of out-of-safe-range values (such as `"90071992547409.92"`, `"90071992547409.93"`, `1000000000000000.00`), rejection of non-safe integers in `toString`, overflow/underflow detection in arithmetic operations (`add`, `sub`, `neg`, `sum`), and exact allocation with `Number.MAX_SAFE_INTEGER` amounts and large ratios.
- **Verification:**
  - Verified tests with `node --test test/money.test.js` (20/20 passing).

### Round 2 · Reviewer · codex

swept file: yes

- Reviewed the complete `src/money.js` and `test/money.test.js`. The prior unsafe-integer finding is resolved: digit parsing and all arithmetic/allocation intermediates use `BigInt`, with results explicitly restricted to safe JavaScript integer minor units.
- Confirmed direct decimal parsing, `E_PRECISION` handling, two-decimal rendering, exact largest-remainder allocation (including negative and boundary cases), and input validation. No pre-existing defects found in either swept file.
- Verified with `node --test test/money.test.js`: passing.

**Verdict:** Approved

relay closed, no further turn needed
