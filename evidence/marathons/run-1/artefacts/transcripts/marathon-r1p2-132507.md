# Marathon Phase r1p2
STATUS: Approved
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-R1P2-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# r1p2 — Currency normalization

## Goal

Add `src/fx.js` exporting `normalize(entries, rates, target)`, converting every
entry into a single target currency so cross-currency ledgers can be totalled.

## Requirements

1. `rates` is a plain object of `{ CUR: <units of target per 1 CUR> }`, e.g.
   `{ USD: 1, EUR: 1.08 }` when `target` is `'USD'`.
2. Return NEW entry objects. Do not mutate the input array or its members —
   the caller still needs the originals.
3. Each returned entry keeps every original field, sets `currency` to `target`,
   sets `amount` to the converted value, and additionally carries
   `originalAmount` and `originalCurrency`.
4. An entry already in `target` passes through with `amount` unchanged and a rate
   of exactly 1 — do not multiply it by a supplied rate that disagrees.
5. A missing rate is an error, not a silent skip: throw an `Error` with
   `code === 'E_RATE'` and a `currency` property naming the offender.
6. Converted amounts round to 2 decimal places, half away from zero. Note that
   JavaScript's `Math.round` is half-UP, not half-away-from-zero, so `-1.005`
   and `1.005` must not round in opposite magnitudes. Handle this deliberately.

## Acceptance

Add `test/fx.test.js` (`node:test`), covering: a straight conversion, the
identity case, input immutability, the `E_RATE` throw, and the negative
half-way rounding case from requirement 6. `npm test` green.

## Out of scope

Do not modify existing `src/` files. No new dependencies. No network — rates are
always passed in by the caller.


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): src/fx.js,test/fx.test.js
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /home/arnoldadero/marathon-target/.xyz/bin/tick
   - /home/arnoldadero/marathon-target/.xyz/bin/tick claim MARATHON-R1P2-TURN --agent agy --paths "marathon-system/run1-ledger-exports--r1p2/RELAY.md,src/fx.js,test/fx.test.js"
   - /home/arnoldadero/marathon-target/.xyz/bin/tick ping MARATHON-R1P2-TURN --agent agy
   - /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R1P2-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/run1-ledger-exports--r1p2/RELAY.md and src/fx.js,test/fx.test.js. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/fx.js,test/fx.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R1P2-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick done MARATHON-R1P2-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /home/arnoldadero/marathon-target/.xyz/bin/tick
   Edit ONLY marathon-system/run1-ledger-exports--r1p2/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

- Created `src/fx.js` exporting `normalize(entries, rates, target)` and `roundHalfAway(val, decimals)`.
- Key decisions / implementations:
  - Preserved input immutability: returns new array of new entry objects carrying `originalAmount` and `originalCurrency`.
  - Implemented identity handling: entries already in `target` pass through with unchanged `amount` and rate 1 without failing if `rates` lacks the target currency or has a conflicting rate.
  - Implemented error handling: throws `Error` with `code === 'E_RATE'` and `currency` set to the missing currency name when an entry requires an exchange rate not present in `rates`.
  - Implemented half-away-from-zero rounding to 2 decimal places using robust exponential shifting so positive and negative tie values (e.g. `1.005` and `-1.005`) round symmetrically away from zero (`1.01` and `-1.01`).
- Created `test/fx.test.js` using `node:test` and `node:assert`, covering straight conversions, identity cases, input immutability, `E_RATE` error throwing, and symmetric negative/positive half-way rounding edge cases.

### Round 1 · Reviewer · codex

- swept file: yes
- Reviewed the complete `src/fx.js` and `test/fx.test.js`; no pre-existing defects found in either reviewed file.
- `normalize` returns fresh entry objects, preserves source fields, handles target-currency entries without applying a conflicting rate, supplies the specified `E_RATE` metadata for missing rates, and uses sign-aware rounding for converted values.
- Verified with `node --test test/fx.test.js`: 6 passing, 0 failing.

**Verdict:** Approved

relay closed, no further turn needed
