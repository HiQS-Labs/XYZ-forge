# Marathon Phase r1p4
STATUS: Approved
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-R1P4-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# r1p4 — Duplicate-entry detection

## Goal

Add `src/dedupe.js` exporting `findDuplicates(entries, options)` — flag ledger
entries that look like the same transaction recorded twice.

## Requirements

1. Two entries are duplicates when `date`, `account`, `amount`, `currency` AND
   the NORMALIZED memo all match. Normalizing a memo means: lowercase, collapse
   internal whitespace runs to one space, and trim.
2. Return an array of groups. Each group is
   `{ key, entries: [...], count }`, where `entries` holds every member in input
   order and `count >= 2`. Entries appearing only once are not returned at all.
3. Groups come back sorted by the line number of their first member, ascending —
   so the report reads in file order.
4. `options.ignoreMemo === true` drops the memo from the match key entirely.
5. A legitimate repeat is not a duplicate: two entries that match on everything
   but sit on different `lineNo` values ARE still duplicates — `lineNo` is
   deliberately not part of the key. Say so in a comment so the next reader does
   not "fix" it.

## Acceptance

Add `test/dedupe.test.js` (`node:test`) covering: no duplicates, an exact
duplicate pair, a triple, memo normalization matching `"Coffee  Beans"` with
`"coffee beans"`, non-matching amounts staying separate, `ignoreMemo`, and the
input-order sort. `npm test` green.

## Out of scope

Do not modify existing `src/` files. No dependencies.


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): src/dedupe.js,test/dedupe.test.js
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /home/arnoldadero/marathon-target/.xyz/bin/tick
   - /home/arnoldadero/marathon-target/.xyz/bin/tick claim MARATHON-R1P4-TURN --agent agy --paths "marathon-system/run1-ledger-exports--r1p4/RELAY.md,src/dedupe.js,test/dedupe.test.js"
   - /home/arnoldadero/marathon-target/.xyz/bin/tick ping MARATHON-R1P4-TURN --agent agy
   - /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R1P4-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/run1-ledger-exports--r1p4/RELAY.md and src/dedupe.js,test/dedupe.test.js. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/dedupe.js,test/dedupe.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R1P4-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick done MARATHON-R1P4-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /home/arnoldadero/marathon-target/.xyz/bin/tick
   Edit ONLY marathon-system/run1-ledger-exports--r1p4/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

### Round 1 · Builder · agy

- Created `src/dedupe.js`:
  - Implemented `normalizeMemo(memo)` to lowercase, collapse internal whitespace runs to a single space, and trim.
  - Implemented `makeKey(entry, ignoreMemo)` combining `date`, `account`, `amount`, `currency`, and normalized `memo` (unless `options.ignoreMemo === true`). Noted in comments that `lineNo` is deliberately excluded from the duplicate key.
  - Implemented `findDuplicates(entries, options)` returning duplicate groups (`count >= 2`) with `{ key, entries, count }` where `entries` maintains input order, and groups are sorted ascending by the line number of their first member.
- Created `test/dedupe.test.js`:
  - Added unit tests covering: no duplicates, exact duplicate pair, duplicate triple, memo normalization matching `"Coffee  Beans"` with `"coffee beans"`, non-matching amounts staying separate, `ignoreMemo` behavior, and ascending line-number group sort / input order preservation.
- Verified with `node --test test/dedupe.test.js` (10/10 tests pass).

### Round 1 · Reviewer · codex

swept file: yes

Reviewed the complete contents of `src/dedupe.js` and `test/dedupe.test.js`, including pre-existing code in both files; no pre-existing defects found. The matching key includes all required fields with normalized memo unless `ignoreMemo` is exactly `true`; `lineNo` is explicitly excluded with the required rationale. Duplicate groups retain input order, exclude singletons, return only the specified public fields, and sort by the first member's line number. The tests cover every acceptance case listed in the brief.

**Verdict:** Approved

relay closed, no further turn needed
