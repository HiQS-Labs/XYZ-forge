# Marathon Phase r1p3
STATUS: Approved
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-R1P3-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# r1p3 — CLI with JSON output

## Goal

Add `src/cli.js` exposing `run(argv, io)` — a testable command-line entry point
over the existing parse/validate/summarize functions.

## Requirements

1. Signature `run(argv, io)` where `argv` is the argument array (no `node`/script
   prefix) and `io` is `{ stdout, stderr, readFile }`. Injecting `io` is what
   makes this testable — do not read `process.argv` or call `console.log`
   directly inside `run`.
2. Usage: `ledgerkit <file> [--json] [--summary]`.
3. Default (no flags): validate the file and print a human-readable report — one
   line per problem, or `OK: N entries, balanced` when clean.
4. `--summary`: print the `summarize()` table instead, one line per row.
5. `--json`: print a single JSON object to stdout instead of any human text:
   `{ ok, entries, problems, summary }`. `--json` wins over `--summary`.
6. Return an exit code, do not call `process.exit`: `0` clean, `1` validation
   problems, `2` usage error (missing file argument, unknown flag), `3` parse
   error (`E_PARSE` from the parser — report the failing line number on stderr).

## Acceptance

Add `test/cli.test.js` (`node:test`) driving `run()` with a fake `io` that
captures output into strings and serves file contents from memory. Cover each of
the four exit codes and both output modes. `npm test` green.

## Out of scope

Do not modify existing `src/` files. No dependencies. No `bin` entry in
package.json — this phase delivers the library-side entry point only.


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): src/cli.js,test/cli.test.js
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /home/arnoldadero/marathon-target/.xyz/bin/tick
   - /home/arnoldadero/marathon-target/.xyz/bin/tick claim MARATHON-R1P3-TURN --agent agy --paths "marathon-system/run1-ledger-exports--r1p3/RELAY.md,src/cli.js,test/cli.test.js"
   - /home/arnoldadero/marathon-target/.xyz/bin/tick ping MARATHON-R1P3-TURN --agent agy
   - /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R1P3-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/run1-ledger-exports--r1p3/RELAY.md and src/cli.js,test/cli.test.js. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/cli.js,test/cli.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick release MARATHON-R1P3-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /home/arnoldadero/marathon-target/.xyz/bin/tick done MARATHON-R1P3-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /home/arnoldadero/marathon-target/.xyz/bin/tick
   Edit ONLY marathon-system/run1-ledger-exports--r1p3/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

- Created `src/cli.js` exposing `run(argv, io)`.
- Key decisions / implementations:
  - Injected IO: accepts `{ stdout, stderr, readFile }` without calling `process.exit`, `console.log`, or reading `process.argv`.
  - Supports output modes:
    - Default mode (no flags): validates entries and prints `OK: N entries, balanced` or one line per validation problem.
    - `--summary` mode: prints the `summarize()` table with one line per row (`<account> <currency> <total>`).
    - `--json` mode: prints `{ ok, entries, problems, summary }` as a single JSON object to stdout; wins over `--summary` when both flags are supplied.
  - Return exit codes:
    - `0`: clean validation / balanced.
    - `1`: validation problems.
    - `2`: usage error (missing file, unknown flag, extra arguments, unreadable file).
    - `3`: parse error (`E_PARSE` from parser, reporting failing line number on stderr).
  - Created `test/cli.test.js` using `node:test` and `node:assert`, driving `run()` with memory-based fake IO covering all 4 exit codes (0, 1, 2, 3), default/summary/json output modes, `--json` precedence over `--summary`, usage error scenarios, parse error line reporting, and functional IO stream adapters.

### Round 1 · Reviewer · codex

swept file: yes

- Reviewed the complete `src/cli.js` and `test/cli.test.js`; no pre-existing defects were found beyond the issue below.
- Verified with `node --test test/cli.test.js` (pass).
- `src/cli.js` treats any thrown error carrying `lineNo` as a parse failure and returns exit code 3. The brief reserves exit code 3 for parser errors with `code === 'E_PARSE'`; a different error with `lineNo` must not be misclassified. Restrict that branch to `err.code === 'E_PARSE'` (and add a focused regression test, if retaining a fallback error classification).

**Verdict:** Changes requested
 
### Round 2 · Builder · agy

- Restricted the parse error catch block in `src/cli.js` so that exit code 3 is returned strictly when `err.code === 'E_PARSE'`, rethrowing non-`E_PARSE` exceptions.
- Added regression test in `test/cli.test.js` to ensure non-`E_PARSE` errors thrown during parsing propagate rather than being handled as exit code 3.
- Verified with `node --test test/cli.test.js` (15/15 tests passing).

### Round 2 · Reviewer · codex

swept file: yes

- Reviewed the complete `src/cli.js` and `test/cli.test.js`, including their interaction with the existing parser, validator, and summarizer; no pre-existing defects were found.
- The prior finding is resolved: only parser errors marked `E_PARSE` map to exit code 3, while other exceptions propagate.
- Verified with `node --test test/cli.test.js` (pass).

**Verdict:** Approved
