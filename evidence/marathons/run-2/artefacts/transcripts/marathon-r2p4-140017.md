# Marathon Phase r2p4
STATUS: Approved
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-R2P4-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

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


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): src/report.js,test/report.test.js
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /home/arnoldadero/marathon-target/.xyz/bin/tick
   - /home/arnoldadero/marathon-target/.xyz/bin/tick claim MARATHON-R2P4-TURN --agent agy --paths "marathon-system/run2-reconcile-chain--r2p4/RELAY.md,src/report.js,test/report.test.js"
   - /home/arnoldadero/marathon-target/.xyz/bin/tick ping MARATHON-R2P4-TURN --agent agy
   - /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R2P4-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/run2-reconcile-chain--r2p4/RELAY.md and src/report.js,test/report.test.js. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/report.js,test/report.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R2P4-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick done MARATHON-R2P4-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /home/arnoldadero/marathon-target/.xyz/bin/tick
   Edit ONLY marathon-system/run2-reconcile-chain--r2p4/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
  - `src/report.js`: Implemented `renderReport(result, options)` to format reconciliation results into plain text.
    - Formats plain text reports with four labelled sections in order: `MATCHED`, `ONLY IN A`, `ONLY IN B`, `MISMATCHED`.
    - Empty sections print the section heading followed by `  (none)`.
    - Money values formatted using `toString` from `src/money.js` (never raw minor units).
    - Mismatch rows show both sides (`A: <aMinor>` and `B: <bMinor>`) and the delta (`delta: <deltaMinor>`).
    - Dynamic column width calculation ensuring dates, currencies, and right-aligned amounts line up horizontally across wide magnitude ranges and signs.
    - Supported `options.summaryOnly === true` returning single-line verdict (`RECONCILED` or `NOT RECONCILED: <n> mismatched, <n> only-in-A, <n> only-in-B`).
    - Returns string without printing or mutating input objects; validates input format with `E_INVALID`.
  - `test/report.test.js`: Added comprehensive `node:test` suite covering:
    - Empty reconcile results rendering `(none)` for all four sections.
    - Fully reconciled results with matched entries and `(none)` discrepancies.
    - Mismatch rows showing side A, side B, and delta values with exact money string formatting.
    - Column alignment holding across wide magnitude ranges, positive/negative signs, and varying date/currency lengths.
    - `summaryOnly` option for reconciled and unreconciled cases.
    - End-to-end integration with `parse` and `reconcile`.
    - Determinism across repeated calls and input non-mutation.
    - Input validation and graceful empty defaults.
- **Verification:**
  - Verified focused unit tests with `node --test test/report.test.js` (9/9 passing).

### Round 1 · Reviewer · codex

- swept file: yes
- Reviewed the complete `src/report.js` and `test/report.test.js`, plus the upstream reconciliation and money contracts. No pre-existing defects found in the swept files.
- The renderer provides the required four sections in order, uses `money.toString` for every monetary field, aligns shared columns with right-aligned amounts, and produces the specified summary verdicts without printing.
- Focused verification: `node --test test/report.test.js` passed (1 file suite, 0 failures).
- **Verdict:** Approved

relay closed, no further turn needed
