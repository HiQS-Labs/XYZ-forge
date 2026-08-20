# Marathon Phase r1p1
STATUS: Approved
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-R1P1-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# r1p1 — CSV export

## Goal

Add `src/export-csv.js` exporting `toCSV(entries, options)`, which renders parsed
ledger entries (the shape `src/parse.js` produces) as RFC 4180 CSV.

## Requirements

1. Header row, exactly: `date,account,amount,currency,memo`.
2. One row per entry, in the order given.
3. Amounts render with exactly two decimal places (`-125.4` becomes `-125.40`).
4. RFC 4180 quoting, and this is the part that matters: a field containing a
   comma, a double quote, CR or LF must be wrapped in double quotes, and any
   embedded double quote must be doubled (`"` becomes `""`). Memos are free text
   and will contain all of these.
5. Line terminator is CRLF (`\r\n`), per RFC 4180. Do not emit a trailing CRLF
   after the final row.
6. `options.header === false` suppresses the header row. Default is to emit it.

## Acceptance

Add `test/export-csv.test.js` using `node:test` + `node:assert`, covering at
minimum: the plain case, a memo containing a comma, a memo containing a double
quote, a memo containing a newline, two-decimal formatting of an integer amount,
and `header: false`. `npm test` must be green.

## Out of scope

Do not modify `src/parse.js`, `src/validate.js`, or `src/index.js`. Do not add
dependencies — this repo has none and must keep none.


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): src/export-csv.js,test/export-csv.test.js
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /home/arnoldadero/marathon-target/.xyz/bin/tick
   - /home/arnoldadero/marathon-target/.xyz/bin/tick claim MARATHON-R1P1-TURN --agent agy --paths "marathon-system/run1-ledger-exports--r1p1/RELAY.md,src/export-csv.js,test/export-csv.test.js"
   - /home/arnoldadero/marathon-target/.xyz/bin/tick ping MARATHON-R1P1-TURN --agent agy
   - /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R1P1-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/run1-ledger-exports--r1p1/RELAY.md and src/export-csv.js,test/export-csv.test.js. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/export-csv.js,test/export-csv.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R1P1-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick done MARATHON-R1P1-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /home/arnoldadero/marathon-target/.xyz/bin/tick
   Edit ONLY marathon-system/run1-ledger-exports--r1p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
  - `src/export-csv.js`: Implemented `toCSV(entries, options)` formatting parsed ledger entries to RFC 4180 CSV with CRLF line endings (without trailing CRLF), two-decimal amount formatting, header suppression via `header: false`, and proper field escaping for commas, double quotes, and line breaks.
  - `test/export-csv.test.js`: Added comprehensive unit tests covering plain cases, comma in memo, double quote in memo, newlines in memo, two-decimal amount formatting for integer/fractional values, `header: false` option, empty list handling, and row ordering.
- **Key decisions:**
  - Standardized RFC 4180 field quoting (`"` -> `""` and wrapped in double quotes when containing `"`, `,`, `\r`, or `\n`).
  - Fixed amount precision to two decimals via `.toFixed(2)`.
  - Joined rows with `\r\n` without appending a trailing newline.
  - Verified tests with `node --test test/export-csv.test.js` (8/8 passing).

### Round 1 · Reviewer · codex

swept file: yes

- Reviewed the complete `src/export-csv.js` and `test/export-csv.test.js`; no other pre-existing defects were found in those files.
- `formatAmount` relies on `Number#toFixed(2)`, which renders magnitudes at or above `1e21` in exponential notation. For example, a valid numeric amount of `1e21` currently exports as `1e+21`, not the required exactly-two-decimal representation. Please use a decimal formatter that preserves fixed-point output for this range and add a regression test.
- The focused test command was run successfully: `node --test test/export-csv.test.js`.

**Verdict:** Changes requested

### Round 2 · Builder · agy

- **Files modified:**
  - `src/export-csv.js`: Switched amount formatting from `Number#toFixed(2)` to `Intl.NumberFormat('en-US', { useGrouping: false, minimumFractionDigits: 2, maximumFractionDigits: 2 })` so numbers with magnitude >= 1e21 remain in fixed-point decimal notation without switching to exponential notation, handling edge cases like 0 and negative zero cleanly.
  - `test/export-csv.test.js`: Added regression test verifying positive and negative amounts with magnitude >= 1e21 (e.g. `1e21` and `-1e21`) format properly with two decimals in fixed point.
- **Key decisions:**
  - Used built-in standard `Intl.NumberFormat` with `useGrouping: false` to avoid introducing third-party dependencies while properly handling arbitrary JS Number magnitudes.
- Verified tests with `node --test test/export-csv.test.js` (9/9 passing).

### Round 2 · Reviewer · codex

swept file: yes

- Reviewed the complete `src/export-csv.js` and `test/export-csv.test.js`; no pre-existing or newly introduced in-scope defects were found.
- The implementation emits the exact header, preserves input ordering, uses CRLF without a final terminator, applies RFC 4180 escaping to every field, supports `header: false`, and formats both ordinary and large finite numeric amounts as fixed two-decimal values.
- Focused verification passed: `node --test test/export-csv.test.js`.

**Verdict:** Approved

relay closed, no further turn needed
