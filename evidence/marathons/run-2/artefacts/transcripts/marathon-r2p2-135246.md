# Marathon Phase r2p2
STATUS: Approved
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-R2P2-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

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


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): src/balance.js,test/balance.test.js
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /home/arnoldadero/marathon-target/.xyz/bin/tick
   - /home/arnoldadero/marathon-target/.xyz/bin/tick claim MARATHON-R2P2-TURN --agent agy --paths "marathon-system/run2-reconcile-chain--r2p2/RELAY.md,src/balance.js,test/balance.test.js"
   - /home/arnoldadero/marathon-target/.xyz/bin/tick ping MARATHON-R2P2-TURN --agent agy
   - /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R2P2-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/run2-reconcile-chain--r2p2/RELAY.md and src/balance.js,test/balance.test.js. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/balance.js,test/balance.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R2P2-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick done MARATHON-R2P2-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /home/arnoldadero/marathon-target/.xyz/bin/tick
   Edit ONLY marathon-system/run2-reconcile-chain--r2p2/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
  - `src/balance.js`: Implemented `balanceOf(entries)` and `isBalanced(entries)` using exact minor unit arithmetic via `src/money.js`.
    - Converts parsed entry amounts (numbers from `src/parse.js`) to standard 2-decimal strings via `toFixed(2)` before passing to `money.fromString`, ensuring exact integer minor unit parsing without floating-point math inaccuracies. Included explanatory comment for why this intermediate formatting step exists.
    - Groups entries by unique `(date, currency)`, accumulating exact `totalMinor` via `money.add` and tracking `entryCount`.
    - Returns `{ groups, unbalanced }` where `groups` is sorted chronologically by `date` ascending and then alphabetically by `currency` ascending, and `unbalanced` is the subset with `totalMinor !== 0` (exact zero, no epsilon/tolerance).
    - Implemented `isBalanced(entries)` returning boolean (`unbalanced.length === 0`).
  - `test/balance.test.js`: Added comprehensive unit tests using `node:test` covering:
    - Balanced day returning zero `totalMinor` and empty `unbalanced` list.
    - Unbalanced day asserting the exact `totalMinor` delta.
    - Multiple currencies on the same day tracked independently and sorted by currency.
    - Floating-point drift case (three `0.10` entries vs `-0.30`) proving exact zero balance where float math drifts.
    - Sorting across multiple dates and currencies (date ascending, then currency ascending).
    - Empty entries list handling returning empty groups and unbalanced arrays (`isBalanced` true).
    - String amount support and input validation with `E_INVALID` / `E_PRECISION`.
- **Verification:**
  - Verified with `node --test test/balance.test.js` (8/8 passing).

### Round 1 · Reviewer · codex

swept file: yes

- Reviewed the complete `src/balance.js` and `test/balance.test.js`, including existing code; no pre-existing defects were found in either reviewed file.
- `balanceOf` formats numeric parsed amounts to two decimals before `money.fromString`, aggregates through safe integer `money.add`, groups and sorts by `(date, currency)`, and identifies imbalance with exact zero comparison. No epsilon/tolerance is present.
- The focused verification `node --test test/balance.test.js` passes (1 file, 8 subtests).

**Verdict:** Approved

relay closed, no further turn needed
