# Marathon Phase r3p1
STATUS: Approved
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-R3P1-TURN builder=claude reviewer=codex round-cap=5 -->

## Phase Brief

# r3p1 — Stable multi-key sort

## Goal

Add `src/sort.js` exporting `sortEntries(entries, keys)` — order ledger entries by
several keys at once, stably.

## Requirements

1. `keys` is an array like `['date', '-amount', 'account']`. A leading `-` means
   descending for that key only.
2. The sort is STABLE: entries comparing equal on every key keep their original
   relative order. `Array.prototype.sort` is stable in modern V8, but do not rely
   on that silently — either state it in a comment or decorate with the original
   index.
3. Comparison is type-aware: `amount` compares numerically, everything else as a
   string with `localeCompare`. An unknown key name throws an `Error` with
   `code === 'E_SORTKEY'` naming the offending key.
4. Do not mutate the input array. Return a new one.
5. An empty `keys` array returns a copy in the original order.

## Acceptance

`test/sort.test.js` (`node:test`) covering: single key ascending, `-` descending,
multi-key tie-breaking, stability under a full tie (assert original order
survives), `E_SORTKEY`, input immutability, and the empty-keys case.
`npm test` green.

## Out of scope

Do not modify existing `src/` files. No dependencies.


## Debug mantra (auto-triggered — 1 prior attempt(s) on this phase did not reach Approved)

Before trying again, read `relay-automation/DEBUG-MANTRA.md` (relative to the harness root) and follow its four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.

---

▶ TAKE YOUR TURN (claude — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): src/sort.js,test/sort.test.js
2. Append a build block to this relay file: `### Round N · Builder · claude` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /home/arnoldadero/marathon-target/.xyz/bin/tick
   - /home/arnoldadero/marathon-target/.xyz/bin/tick claim MARATHON-R3P1-TURN --agent claude --paths "marathon-system/run3-hard-ambiguous--r3p1/RELAY.md,src/sort.js,test/sort.test.js"
   - /home/arnoldadero/marathon-target/.xyz/bin/tick ping MARATHON-R3P1-TURN --agent claude
   - /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R3P1-TURN --agent claude --to codex
4. Edit ONLY these paths: marathon-system/run3-hard-ambiguous--r3p1/RELAY.md and src/sort.js,test/sort.test.js. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/sort.js,test/sort.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: claude (Builder)`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R3P1-TURN --agent codex --to claude
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick done MARATHON-R3P1-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /home/arnoldadero/marathon-target/.xyz/bin/tick
   Edit ONLY marathon-system/run3-hard-ambiguous--r3p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

**Files touched:** `src/sort.js` (created), `test/sort.test.js` (created)

**Key decisions:**
- Defined `VALID_KEYS` set (`date`, `account`, `amount`, `currency`, `memo`, `lineNo`) for unknown-key validation; throws `Error` with `code === 'E_SORTKEY'` and the key name in the message.
- `NUMERIC_KEYS` set (`amount`, `lineNo`) drives numeric vs `localeCompare` dispatch.
- Stability guaranteed explicitly: entries are decorated with their original index `i` before sorting; the comparator falls back to `a.i - b.i` on full ties, making stability independent of the engine.
- Input not mutated: `entries.map(...)` creates a new array; the decorated array is sorted, then mapped back to entry objects.
- Empty `keys`: `parsed` is empty so the comparator body never fires, falling straight to `a.i - b.i`, preserving original order.

**Test results:** 7/7 pass — single-key asc, single-key desc (`-`), multi-key tie-break, full-tie stability, `E_SORTKEY`, immutability, empty-keys.

### Round 1 · Reviewer · codex

swept file: yes

**Finding (high):** `src/sort.js` includes `lineNo` in `NUMERIC_KEYS`, so it compares that field with subtraction. The brief is explicit that `amount` compares numerically and *everything else* compares as a string with `localeCompare`; `lineNo` must therefore use string ordering. Remove `lineNo` from `NUMERIC_KEYS` (it may remain a valid key) and add coverage that distinguishes lexical from numeric ordering for `lineNo`.

I swept both `src/sort.js` and `test/sort.test.js` in full. Apart from the finding above, the implementation correctly validates unknown keys with `E_SORTKEY`, decorates indexes for explicit stability, does not mutate the input array, and returns a copied array for empty keys. Focused verification: `node --test test/sort.test.js` passes (7 tests).

**Verdict:** Changes requested

### Round 2 · Builder · claude

**Files touched:** `src/sort.js` (updated), `test/sort.test.js` (updated)

**Key decisions:**
- Removed `lineNo` from `NUMERIC_KEYS`; only `amount` now compares numerically, per the brief ("amount compares numerically, everything else as a string with localeCompare"). Updated the comment accordingly.
- Added test `lineNo sorts lexically, not numerically`: uses lineNo values `'9'` and `'10'` — numerically 9 < 10, but lexically `'10'` < `'9'` — so the correct lexical ordering is unambiguous.

**Test results:** 8/8 pass.

### Round 2 · Reviewer · codex

swept file: yes

I swept `src/sort.js` and `test/sort.test.js` in full, including the pre-existing portions. The implementation now correctly treats only `amount` as numeric and compares `lineNo` lexically; the added regression test distinguishes those orderings. Unknown-key validation, explicit index-based stability, input-array immutability, and empty-key copy behavior meet the brief. I found no additional pre-existing defects in the swept files.

Focused verification: `node --test test/sort.test.js` passes (8 tests).

**Verdict:** Approved
