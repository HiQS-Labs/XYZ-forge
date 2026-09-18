# Marathon Phase p7
STATUS: Open
NEXT: codex (Builder)

<!-- marathon-drive: task=MARATHON-P7-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

---
title: "L7 brief — #242 post-kill checkout state (Wave 2)"
status: "Brief (input to the GH-648 headless turn-timeout marathon — not a tracked plan)"
created: 2026-09-16
updated: 2026-09-16
owner: Noel Saw
goal: >
  A timeout-killed driven run leaves the operator checkout on the branch/HEAD it started on.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/648
---

# L7 — #242: timeout-killed run leaves the operator checkout switched (Wave 2)

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-16) | Lane fires when the marathon chain reaches this phase |

Umbrella: #648 · Issue: #242 · Wave 2 · depends_on L6

## Goal
A timeout-killed driven run must leave the operator's checkout on the branch/HEAD it started on. #242: the killed run left the operator checkout switched to development. Find the switch site in `utils/py/relay_drive.py` / `utils/py/rtl.py` (branch/worktree setup before the turn, no restore on the kill path), and make the kill path restore or never touch the operator checkout.

## Rules
Python twins authoritative. Register the suite in `validate.sh` TESTS. `bash validate.sh` green.

## Acceptance / Guard
`test/gh648-l7-checkout-aftermath.sh`: fixture run killed at a short cap → the fixture checkout's starting branch/HEAD is unchanged; a healthy run still switches as designed.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): utils/py/relay_drive.py, utils/py/rtl.py, test/gh648-l7-checkout-aftermath.sh, validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick claim MARATHON-P7-TURN --agent codex --paths "marathon-system/gh648-headless-turn-timeout--p7/RELAY.md,utils/py/relay_drive.py, utils/py/rtl.py, test/gh648-l7-checkout-aftermath.sh, validate.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick ping MARATHON-P7-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick release MARATHON-P7-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh648-headless-turn-timeout--p7/RELAY.md and utils/py/relay_drive.py, utils/py/rtl.py, test/gh648-l7-checkout-aftermath.sh, validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/relay_drive.py, utils/py/rtl.py, test/gh648-l7-checkout-aftermath.sh, validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick release MARATHON-P7-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick done MARATHON-P7-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick
   Edit ONLY marathon-system/gh648-headless-turn-timeout--p7/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
