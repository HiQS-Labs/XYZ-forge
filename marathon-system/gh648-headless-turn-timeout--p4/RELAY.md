# Marathon Phase p4
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-P4-TURN-R2 builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

---
title: "L4 brief — #285 revalidate whether the cap kills the child at HEAD"
status: "Brief (input to the GH-648 headless turn-timeout marathon — not a tracked plan)"
created: 2026-09-16
updated: 2026-09-16
owner: Noel Saw
goal: >
  Fixture-prove agy-turn's cap behavior at HEAD; close #285 as already-fixed or fix what still reproduces.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/648
---

# L4 — #285 revalidate: does the cap kill the child at HEAD?

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-16) | Lane fires when the marathon chain reaches this phase |

Umbrella: #648 · Issue: #285 · Wave 1 · depends_on L3

## Goal
#285 claimed `agy-turn` returns exit 7 at the cap but never kills the child (fixture: `RELAY_TURN_TIMEOUT_S=1` vs 5s stub; codex-turn killed, agy didn't). At HEAD, `utils/py/agy-turn.py` ~`:500` calls `_kill_turn_group(proc)` at the wall cap, so the issue may already be fixed in the Python twin.

First build `test/gh648-l4-285-revalidate.sh` (same fixture shape: short cap vs sleeping stub, both agy and codex twins). Then:
- If agy's cap fires fast (child group dead well before the stub's natural end): close #285 citing the commit that fixed it — put the sha in the suite receipt and the issue close. NO production change.
- If it still reproduces: fix in `utils/py/agy-turn.py` (Python twin only) and keep the suite red→green.

## Rules
`utils/py/agy-turn.py` is in your write-set ONLY for the still-reproduces branch. Register the suite in `validate.sh` TESTS. `bash validate.sh` green.

## Acceptance / Guard
The suite asserts the cap fires fast for BOTH twins (agy, codex) and records which case happened (already-fixed close vs fix landed).


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/py/agy-turn.py, test/gh648-l4-285-revalidate.sh, validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick claim MARATHON-P4-TURN-R2 --agent codex --paths "marathon-system/gh648-headless-turn-timeout--p4/RELAY.md,utils/py/agy-turn.py, test/gh648-l4-285-revalidate.sh, validate.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick ping MARATHON-P4-TURN-R2 --agent codex
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick release MARATHON-P4-TURN-R2 --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh648-headless-turn-timeout--p4/RELAY.md and utils/py/agy-turn.py, test/gh648-l4-285-revalidate.sh, validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/agy-turn.py, test/gh648-l4-285-revalidate.sh, validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick release MARATHON-P4-TURN-R2 --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick done MARATHON-P4-TURN-R2 --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick
   Edit ONLY marathon-system/gh648-headless-turn-timeout--p4/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.


### Round 2 · Builder · codex

- Inspected the existing `test/gh648-l4-285-revalidate.sh`, its registration in
  `validate.sh` TESTS, and the timeout paths in both Python adapters. The requested
  fixture and registration were already present at turn entry. No production or
  test edits were needed; this turn changes only this relay record.
- Focused verification: `bash test/gh648-l4-285-revalidate.sh` exited 0. The real
  five-second stub exited 7 at 1.008s for codex and 2.004s for agy in both pipe and
  PTY modes, with the launched child dead and no natural-completion marker. The
  agy cases also asserted that the process group no longer existed. This is the
  simple sleeping-child fixture; it does not establish resistant-descendant behavior.
- Witnessed negative control: replacing agy's `_kill_turn_group` with a no-op
  returned exit 7 at 2.007s while the child was still alive. The containment
  assertion rejected it before fixture cleanup. Exit 7 alone cannot pass this test.
- Outcome: already fixed at the tested source; no production change. Source SHA256:
  agy `7ba49c671f963cc420fade4ed98bec78f2ed51b076d02488a33b253205878c38`;
  codex `f5c7dfc0f4332a0adc9917cc26cc3300c4168761b0b1aade0050b4bdc2cabb84`.
- Ephemeral run output and JSON receipt are under `.relay-scratch/gh648-l4-run.log`
  and `.relay-scratch/gh648-l4-receipt.json`. They are not committed provenance and
  must not be cited as durable issue-close evidence. The fixing commit remains
  unresolved in the receipt: this turn explicitly forbids Git commands. No issue
  was closed. The outer orchestrator must identify the historical fixing SHA and
  retain durable evidence before closing #285.
- Full gate deliberately not run under the turn constraint; the harness owns it.
  Graph tools were unavailable, so verification used direct source reads. No Git
  commands, real agent launches, or network calls were used for the fixture.

Handing off to agy for review of the existing implementation and this revalidation;
remaining closeout requirements are explicit above.
