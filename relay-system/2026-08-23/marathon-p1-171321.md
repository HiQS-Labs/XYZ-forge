# Marathon Phase p1
STATUS: Open
NEXT: agy (Builder)

<!-- marathon-drive: task=TASK6 builder=agy reviewer=codex round-cap=1 -->

## Phase Brief

round-cap: 2


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Record your work directly in this relay file (relay-only phase — no source file to edit).
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/bulkhead-2026-08-23/gh-115-clean/bin/tick
   - /Users/noelsaw/marathon-clones/bulkhead-2026-08-23/gh-115-clean/bin/tick claim TASK6 --agent agy --paths "/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/tick-gh115-round-cap.XXXXXX.1CUgVfSj5N/agent-a/phases/p1/RELAY.md"
   - /Users/noelsaw/marathon-clones/bulkhead-2026-08-23/gh-115-clean/bin/tick ping TASK6 --agent agy
   - /Users/noelsaw/marathon-clones/bulkhead-2026-08-23/gh-115-clean/bin/tick release TASK6 --agent agy --to codex
4. Edit ONLY /var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/tick-gh115-round-cap.XXXXXX.1CUgVfSj5N/agent-a/phases/p1/RELAY.md. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/marathon-clones/bulkhead-2026-08-23/gh-115-clean/bin/tick release TASK6 --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/bulkhead-2026-08-23/gh-115-clean/bin/tick done TASK6 --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/bulkhead-2026-08-23/gh-115-clean/bin/tick
   Do NOT run git. Do NOT touch any other file.
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
