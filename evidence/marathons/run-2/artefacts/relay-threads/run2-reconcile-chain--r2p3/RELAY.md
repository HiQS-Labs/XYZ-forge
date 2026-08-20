# Marathon Phase r2p3
STATUS: Approved
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-R2P3-TURN builder=agy reviewer=codex round-cap=7 -->

## Phase Brief

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


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): src/reconcile.js,test/reconcile.test.js
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /home/arnoldadero/marathon-target/.xyz/bin/tick
   - /home/arnoldadero/marathon-target/.xyz/bin/tick claim MARATHON-R2P3-TURN --agent agy --paths "marathon-system/run2-reconcile-chain--r2p3/RELAY.md,src/reconcile.js,test/reconcile.test.js"
   - /home/arnoldadero/marathon-target/.xyz/bin/tick ping MARATHON-R2P3-TURN --agent agy
   - /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R2P3-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/run2-reconcile-chain--r2p3/RELAY.md and src/reconcile.js,test/reconcile.test.js. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/reconcile.js,test/reconcile.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R2P3-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick done MARATHON-R2P3-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /home/arnoldadero/marathon-target/.xyz/bin/tick
   Edit ONLY marathon-system/run2-reconcile-chain--r2p3/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
  - `src/reconcile.js`: Implemented `reconcile(ledgerA, ledgerB)` and `isReconciled(result)`.
    - Uses `src/balance.js` (`balanceOf`) to compute balance groups for both sides.
    - Groups are matched by `(date, currency)`. When present on both sides with equal `totalMinor`, records are placed in `matched` with `{ date, currency, totalMinor }`.
    - When present on both sides with differing totals, records are placed in `mismatched` with `{ date, currency, aMinor, bMinor, deltaMinor }` where `deltaMinor = sub(aMinor, bMinor)` computed via `src/money.js` (`sub`).
    - Groups present on one side only are placed in `onlyInA` and `onlyInB` respectively.
    - All four result arrays (`matched`, `onlyInA`, `onlyInB`, `mismatched`) are sorted chronologically by `date` ascending and then alphabetically by `currency` ascending, ensuring deterministic, byte-identical outputs across runs.
    - Implemented `isReconciled(result)` returning boolean `true` if and only if `onlyInA`, `onlyInB`, and `mismatched` are all empty.
  - `test/reconcile.test.js`: Added comprehensive test suite with `node:test` covering:
    - Identical ledgers returning matching groups and `isReconciled: true`.
    - One-sided date returning items in `onlyInA` and `onlyInB` and `isReconciled: false`.
    - Same-date total mismatch with exact `deltaMinor` asserted (positive and negative deltas).
    - Currency present on only one side for the same date.
    - Determinism across repeated runs and input order permutations.
    - Sorting across all four output arrays (date ascending then currency ascending).
    - Floating-point drift resistance with exact money arithmetic.
    - Empty ledgers handling.
    - `isReconciled` helper validation.
    - Invalid input error propagation (`E_INVALID`).
- **Verification:**
  - Verified with `node --test test/reconcile.test.js` (11/11 passing).

### Round 1 · Reviewer · codex

swept file: yes

Reviewed the complete `src/reconcile.js` and `test/reconcile.test.js`, plus the
`balanceOf` and money-arithmetic interfaces on which reconciliation depends.
The implementation computes groups through `balanceOf`, uses `sub()` for each
delta, returns the specified four collections, and sorts each deterministically
by date then currency. The tests cover every acceptance case, including an exact
delta and repeated-run determinism. The focused command
`node --test test/reconcile.test.js` passes (11/11). No pre-existing in-scope
defects found in the swept artifact files.

**Verdict:** Approved
