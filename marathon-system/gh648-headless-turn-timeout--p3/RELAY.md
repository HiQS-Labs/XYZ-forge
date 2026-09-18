# Marathon Phase p3
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-P3-TURN-R4 builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

---
title: "L3 brief — #276/#480 consult cap policy (partial results, 600s default, truthful kills)"
status: "Brief (input to the GH-648 headless turn-timeout marathon — not a tracked plan)"
created: 2026-09-16
updated: 2026-09-16
owner: Noel Saw
goal: >
  Consult surfaces a marked PARTIAL answer at the cap, raises the default cap to 600s, and kills only with truthful reason labels.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/648
---

# L3 — #276 + #480: consult cap policy (partial results, bigger default, truthful kills)

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-16) | Lane fires when the marathon chain reaches this phase |

Umbrella: #648 · Issues: #276, #480 · Wave 1 · depends_on L2

## Goal
In `utils/py/consult.py`:
1. Default per-advisor cap 300s → 600s (env override `CONSULT_TIMEOUT` stays).
2. On cap: surface the advisor's PARTIAL output — flush the transcript's substantive content marked `PARTIAL — hit the Ns cap, no verdict` — instead of the bare `advisor failed or exceeded the cap` line. #480's receipt: 5,505 lines of genuine audit work discarded at the cap.
3. Consume L1's reason model at the kill site (`consult.py:306`): a kill justified by an idle signal must carry the truthful label (`idle-unknown` when no in-flight check succeeded). Decide in-lane whether `idle-unknown` extends once or kills-labeled — either is fine; document the choice in the suite.

## Rules
Python twin authoritative (`utils/py/consult.py`; `relay-automation/consult.sh` is frozen). Register the suite in `validate.sh` TESTS. `bash validate.sh` green.

## Acceptance / Guard
`test/gh648-l3-consult-cap.sh`: (a) default cap reads 600; (b) a stub advisor killed at the cap leaves a marked PARTIAL answer the consumer can read; (c) an idle-killed advisor's failure line carries the truthful reason label; (d) a completing advisor is unaffected.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): utils/py/consult.py, test/gh648-l3-consult-cap.sh, validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick claim MARATHON-P3-TURN-R4 --agent codex --paths "marathon-system/gh648-headless-turn-timeout--p3/RELAY.md,utils/py/consult.py, test/gh648-l3-consult-cap.sh, validate.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick ping MARATHON-P3-TURN-R4 --agent codex
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick release MARATHON-P3-TURN-R4 --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh648-headless-turn-timeout--p3/RELAY.md and utils/py/consult.py, test/gh648-l3-consult-cap.sh, validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/consult.py, test/gh648-l3-consult-cap.sh, validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick release MARATHON-P3-TURN-R4 --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick done MARATHON-P3-TURN-R4 --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick
   Edit ONLY marathon-system/gh648-headless-turn-timeout--p3/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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


### Round 4 · Builder · codex

The supplied checkout already implements the L3 behavior in `utils/py/consult.py` and registers `gh648-l3-consult-cap.sh` in `validate.sh`. Preserved that implementation; this turn strengthens `test/gh648-l3-consult-cap.sh` and updates this relay only.

- Added a process-exit assertion before fixture cleanup so cleanup cannot conceal a missed advisor kill. Added checks for suite registration and absence of PARTIAL output on normal completion.
- Retained the kill-labeled idle policy: use L1's classification, including `timeout-idle-unknown` when no in-flight check establishes a request. Wall expiry retains `PARTIAL — hit the Ns cap, no verdict`; interrupted work remains failed rather than becoming a completed answer. JSON raw transcripts retain their separate readable PARTIAL sidecar.
- Reversibility: Easy; test-only assertions, no runtime behavior change. Existing runtime files were read directly because graph tools are unavailable in this session.
- Focused verification: `bash test/gh648-l3-consult-cap.sh` passed before and after the test change (default 600s, override, wall partial, truthful idle kill, normal completion, wall/idle JSON preservation).
- Negative controls: isolated copies beneath `.relay-scratch/` each failed with AssertionError when independently mutating the default to 300, dropping substantive partial content, replacing the idle reason with `backend-hung`, or skipping the wall-cap kill. The missed-kill control specifically failed the new pre-cleanup assertion (`wall`). These scratch logs are ephemeral turn diagnostics, not committed provenance or full-gate evidence.
- No Git commands or full gate were run. The focused suite stubs all repository operations and uses only local stub advisors. Full gate and final commit remain the harness's responsibility.

Ready for agy review.
