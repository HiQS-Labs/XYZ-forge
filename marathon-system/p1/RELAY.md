# Marathon Phase p1
STATUS: Open
NEXT: codex (Builder)

<!-- marathon-drive: task=MARATHON-P1-TURN builder=codex reviewer=agy round-cap=2 -->

## Phase Brief

# brief

Update src/feature.js and append the relay.


## Debug mantra (auto-triggered — 2 prior attempt(s) on this phase did not reach Approved)

Before trying again, read `relay-automation/DEBUG-MANTRA.md` (relative to the harness root) and follow its four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.
Last recorded reason (`marathon-system/p1/ESCALATION.md`): `cap-progressing-extended`. Read it before re-guessing.

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): src/feature.js
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/tick-marathon-drive.XXXXXX.lWQtVk96oQ/vendor-consumer/.xyz/bin/tick
   - /var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/tick-marathon-drive.XXXXXX.lWQtVk96oQ/vendor-consumer/.xyz/bin/tick claim MARATHON-P1-TURN --agent codex --paths "marathon-system/p1/RELAY.md,src/feature.js"
   - /var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/tick-marathon-drive.XXXXXX.lWQtVk96oQ/vendor-consumer/.xyz/bin/tick ping MARATHON-P1-TURN --agent codex
   - /var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/tick-marathon-drive.XXXXXX.lWQtVk96oQ/vendor-consumer/.xyz/bin/tick release MARATHON-P1-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/p1/RELAY.md and src/feature.js. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/feature.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/tick-marathon-drive.XXXXXX.lWQtVk96oQ/vendor-consumer/.xyz/bin/tick release MARATHON-P1-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/tick-marathon-drive.XXXXXX.lWQtVk96oQ/vendor-consumer/.xyz/bin/tick done MARATHON-P1-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/tick-marathon-drive.XXXXXX.lWQtVk96oQ/vendor-consumer/.xyz/bin/tick
   Edit ONLY marathon-system/p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
   may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.
