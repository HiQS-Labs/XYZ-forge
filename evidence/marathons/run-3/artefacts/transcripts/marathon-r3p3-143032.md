# Marathon Phase r3p3
STATUS: Open
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-R3P3-TURN builder=claude reviewer=codex round-cap=7 -->

## Phase Brief

# r3p3 — Fuzzy transaction matching

## Goal

Add `src/fuzzy-match.js` that matches up transactions between two ledgers when
they do not match exactly, and handles near-misses sensibly.

## Requirements

Bank exports and internal books rarely agree character-for-character. The same
transaction shows up on both sides with a different memo, sometimes a day or two
apart, occasionally with a slightly different amount (fees, rounding, FX).

Export `fuzzyMatch(ledgerA, ledgerB, options)`. It should pair up entries that
are probably the same transaction and report the ones it could not pair. Matches
should be good quality — do not pair things that clearly are not the same
transaction. Where there is more than one plausible candidate, pick the best one.

Confidence should be reported so a caller can decide what to trust, and the
options should let a caller tune how strict the matching is.

## Acceptance

`test/fuzzy-match.test.js` (`node:test`) demonstrating the matching works on
realistic data. `npm test` green.

## Out of scope

Do not modify existing `src/` files. No dependencies.


---

▶ TAKE YOUR TURN (claude — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): src/fuzzy-match.js,test/fuzzy-match.test.js
2. Append a build block to this relay file: `### Round N · Builder · claude` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /home/arnoldadero/marathon-target/.xyz/bin/tick
   - /home/arnoldadero/marathon-target/.xyz/bin/tick claim MARATHON-R3P3-TURN --agent claude --paths "marathon-system/run3-hard-ambiguous--r3p3/RELAY.md,src/fuzzy-match.js,test/fuzzy-match.test.js"
   - /home/arnoldadero/marathon-target/.xyz/bin/tick ping MARATHON-R3P3-TURN --agent claude
   - /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R3P3-TURN --agent claude --to codex
4. Edit ONLY these paths: marathon-system/run3-hard-ambiguous--r3p3/RELAY.md and src/fuzzy-match.js,test/fuzzy-match.test.js. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/fuzzy-match.js,test/fuzzy-match.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: claude (Builder)`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R3P3-TURN --agent codex --to claude
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick done MARATHON-R3P3-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /home/arnoldadero/marathon-target/.xyz/bin/tick
   Edit ONLY marathon-system/run3-hard-ambiguous--r3p3/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

---

### Round 1 · Builder · claude

**Files touched:** `src/fuzzy-match.js`, `test/fuzzy-match.test.js`

**What was implemented:**

`src/fuzzy-match.js` exports `fuzzyMatch(ledgerA, ledgerB, options)` which:
- Scores each (a, b) pair on three weighted dimensions: **memo similarity** (trigram Jaccard, 50%), **amount closeness** (35%), **date proximity** (15%).
- Hard rejects pairs whose amount relative-difference exceeds `amountTolerance * 5` or whose date gap exceeds `dateTolerance * 3` days.
- Uses a **greedy highest-score-first** loop to form the final matching — no pair is used twice, and every iteration picks the globally best remaining pair above `minConfidence`.
- Returns `{ matched: [{a, b, confidence}], unmatchedA, unmatchedB }`.

**Key decisions:**
- Trigram similarity (not Levenshtein) for memos: fast, order-insensitive, handles substring and reordering cases common in bank exports.
- Configurable weights and tolerances let callers tighten or relax matching without forking.
- Supports both `memo` and `description` fields for the text component, since different ledger schemas use both.
- `description` alias handled transparently in `scoreMatch`.

**Tests:** 15 tests covering exact match, memo variation (truncation, case/punctuation), date tolerance (1 day, 2 days, reject 7 days), amount tolerance (small FX rounding, reject large diff), multi-transaction pairing, unmatched reporting, `minConfidence` tuning, empty ledgers, `description` alias, and best-candidate selection. All 15 pass.

### Round 1 · Reviewer · codex

swept file: yes

Reviewed the full contents of `src/fuzzy-match.js` and `test/fuzzy-match.test.js`; no additional pre-existing defects were found beyond the issue below.

- `scoreMatch` converts both amounts with `Math.abs`, so a debit and a credit of the same magnitude receive a perfect amount score and can be matched when their dates/memos agree. For example, `{ amount: 100, ... }` and `{ amount: -100, ... }` produce confidence `1`; these are opposite-direction transactions and clearly must not be paired. Preserve/check amount sign before scoring, and add a regression test that verifies opposite signs remain unmatched.

**Verdict:** Changes requested

handing off to claude — claude, take your turn.

### Round 2 · Builder · claude

**Files touched:** `src/fuzzy-match.js`, `test/fuzzy-match.test.js`

**What was changed:**

Fixed the amount-sign bug reported in Round 1 review:
- In `scoreMatch`, extracted raw signed amounts (`rawA`, `rawB`) before calling `Math.abs`.
- Added a hard-reject guard: if both amounts are non-zero and their signs differ (`Math.sign(rawA) !== Math.sign(rawB)`), immediately return `0`. This prevents a credit (+100) from matching a debit (-100) through the absolute-value path.
- The existing `Math.abs` logic for magnitude comparison is preserved, applied only after the sign check passes.

**Regression test added:**
- "debit and credit with same magnitude are not matched" — verifies `{ amount: 100 }` and `{ amount: -100 }` with identical date/memo produce `matched.length === 0`, `unmatchedA.length === 1`, `unmatchedB.length === 1`.

**Test results:** 16/16 pass.

### Round 2 · Reviewer · codex

swept file: yes

Reviewed the complete current contents of `src/fuzzy-match.js` and `test/fuzzy-match.test.js`. The Round 1 sign correction is correctly implemented and covered. I found no other pre-existing defects in either swept file beyond the issue below.

- Zero tolerances, which are a natural way to request exact-only matching, yield `0 / 0` in the score calculation. For identical amounts with `{ amountTolerance: 0 }`, `amountScore` becomes `NaN`; the same happens for identical dates with `{ dateTolerance: 0 }`. The pair therefore cannot clear `minConfidence`, despite being an exact match. Treat an exact component difference as score `1` before division (and reject a nonzero difference under zero tolerance), and add tests for exact transactions with each zero tolerance setting.

**Verdict:** Changes requested

NEXT: claude (Builder)

handing off to claude — claude, take your turn.

### Round 3 · Builder · claude

**Files touched:** `src/fuzzy-match.js`, `test/fuzzy-match.test.js`

**What was changed:**

Fixed the zero-tolerance NaN bug reported in Round 2 review:
- In `scoreMatch`, the amount-score calculation `1 - relDiff / amountTolerance` produces `NaN` when `amountTolerance = 0` and `relDiff = 0` (exact match). Fixed by branching on `amountTolerance === 0`: exact diff → score 1, any diff → score 0. The existing hard cut-off `relDiff > amountTolerance * 5` already returns 0 for any nonzero diff under zero tolerance, so only the `0/0` case was broken.
- The same pattern applied to `dateScore`: `1 - daysDiff / dateTolerance` is `NaN` when `dateTolerance = 0` and `daysDiff = 0`. Fixed identically: branch on `dateTolerance === 0`.

**Tests added (5 new, 21 total):**
- `amountTolerance:0 matches exact amounts` — confirms fix works, score > 0.
- `amountTolerance:0 rejects any amount difference` — even a 0.01 diff is rejected.
- `dateTolerance:0 matches transactions on same date` — confirms fix works.
- `dateTolerance:0 rejects transactions one day apart` — confirms strictness.
- `both tolerances zero matches only exact amount and date` — combined zero-tolerance regression.

**Test results:** 21/21 pass.

### Round 4 · Builder · claude

**Files touched:** `src/fuzzy-match.js`, `test/fuzzy-match.test.js`

**What was changed:**

Fixed the `minConfidence` strict-`>` comparison reported in Round 3 review:
- In `fuzzyMatch`, `bestScore` was initialized to `minConfidence` and pairs were selected only when `scores[i][j] > bestScore`. This meant a pair scoring exactly `minConfidence` (e.g. confidence `1` with `minConfidence: 1`) was silently dropped.
- Fixed by initializing `bestScore = -Infinity` and changing the selection guard to `scores[i][j] >= minConfidence && scores[i][j] > bestScore`. The threshold is now inclusive; ties still resolve to the first encountered (greedy order).

**Regression test added (1 new, 22 total):**
- `minConfidence:1 matches identical transactions (threshold is inclusive)` — passes identical transactions with `{ minConfidence: 1 }`, asserts 1 match with confidence ≥ 1 and empty unmatchedA/B.

**Test results:** 22/22 pass.

### Round 3 · Reviewer · codex

swept file: yes

Reviewed the complete current contents of `src/fuzzy-match.js` and `test/fuzzy-match.test.js`, and ran `node --test test/fuzzy-match.test.js` successfully. The zero-tolerance correction is implemented correctly and has appropriate regression coverage. I found no other pre-existing defects in either swept file beyond the issue below.

- `minConfidence` is documented as the minimum confidence required to form a pair, but the greedy selection uses a strict `>` comparison. Consequently, an exact transaction with confidence `1` is incorrectly left unmatched when a caller explicitly sets `{ minConfidence: 1 }`. Initialize below the threshold or accept equality (`>=`) so the threshold is inclusive, and add a regression test for the exact-score boundary.

**Verdict:** Changes requested

handing off to claude — claude, take your turn.
