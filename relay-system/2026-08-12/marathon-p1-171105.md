# Marathon Phase p1
STATUS: Open
NEXT: smallcode (Builder)

<!-- marathon-drive: task=MARATHON-P1-TURN builder=smallcode reviewer=codex round-cap=10 -->

## Phase Brief

# Fuzzing Target: GH-523
title:	Fix test/acorn-extract.sh missing 'acorn' module
state:	OPEN
author:	noelsaw1 (Noel Saw)
labels:	
comments:	0
assignees:	
projects:	
milestone:	
issue-type:	
parent:	
sub-issues:	
sub-issues-completed:	
blocked-by:	
blocking:	
number:	523
--
The test `test/acorn-extract.sh` is failing because the `acorn` module cannot be found. This needs to be resolved by ensuring the dependency is available or fixing the test script.


---

▶ TAKE YOUR TURN (smallcode — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Record your work directly in this relay file (relay-only phase — no source file to edit).
2. Append a build block to this relay file: `### Round N · Builder · smallcode` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/fuzzing-smallcode/bin/tick
   - /Users/noelsaw/Documents/GH Repos/fuzzing-smallcode/bin/tick claim MARATHON-P1-TURN --agent smallcode --paths "marathon-system/p1/RELAY.md"
   - /Users/noelsaw/Documents/GH Repos/fuzzing-smallcode/bin/tick ping MARATHON-P1-TURN --agent smallcode
   - /Users/noelsaw/Documents/GH Repos/fuzzing-smallcode/bin/tick release MARATHON-P1-TURN --agent smallcode --to codex
4. Edit ONLY marathon-system/p1/RELAY.md. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: smallcode (Builder)`, then: /Users/noelsaw/Documents/GH Repos/fuzzing-smallcode/bin/tick release MARATHON-P1-TURN --agent codex --to smallcode
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/fuzzing-smallcode/bin/tick done MARATHON-P1-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/fuzzing-smallcode/bin/tick
   Do NOT run git. Do NOT touch any other file.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to smallcode —
   smallcode, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.
