# Marathon Phase p3
STATUS: Approved
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-P3-TURN-R2 builder=codex reviewer=agy round-cap=5 -->

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


## Debug mantra (auto-triggered — 1 prior attempt(s) on this phase did not reach Approved)

Before trying again, read `relay-automation/DEBUG-MANTRA.md` (relative to the harness root) and follow its four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.
Last recorded reason (`marathon-system/gh648-headless-turn-timeout--p3/ESCALATION.md`): `pre-advance-failed`. Read it before re-guessing.

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/py/consult.py, test/gh648-l3-consult-cap.sh, validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick claim MARATHON-P3-TURN-R2 --agent codex --paths "marathon-system/gh648-headless-turn-timeout--p3/RELAY.md,utils/py/consult.py, test/gh648-l3-consult-cap.sh, validate.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick ping MARATHON-P3-TURN-R2 --agent codex
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick release MARATHON-P3-TURN-R2 --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh648-headless-turn-timeout--p3/RELAY.md and utils/py/consult.py, test/gh648-l3-consult-cap.sh, validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/consult.py, test/gh648-l3-consult-cap.sh, validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick release MARATHON-P3-TURN-R2 --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick done MARATHON-P3-TURN-R2 --agent agy
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


### Round 2 · Builder · codex

- Read the prior escalation: `pre-advance-failed`, gate red, no turn log. The existing focused suite passed before edits; the prior full-gate failure is not reproduced or explained by that result.
- Existing implementation already supplies the 600s default, env override, marked PARTIAL transcripts/stdout, and truthful L1 idle reason. Kept the documented kill-labeled policy: idle-unknown kills at the configured idle threshold rather than extending once.
- Fixed a demonstrated preservation gap in `utils/py/consult.py`: idle diagnostics previously appended plain text to JSON transcripts. JSON diagnostics now go to stderr; the existing PARTIAL sidecar and summary retain the reason and captured output, while raw JSON stays byte-identical.
- Extended `test/gh648-l3-consult-cap.sh` with a real stub-advisor idle JSON case asserting exact raw bytes, marked sidecar/stdout, and failure exit 5. Observed this assertion fail before the fix (exit 1), then the complete focused suite pass after it (exit 0).
- `validate.sh` already registers the focused suite at line 299; no registration edit needed. Files changed this round: consult.py, its focused test, and this relay file.
- Verification: `bash test/gh648-l3-consult-cap.sh` passed default 600s, override, wall partial, truthful idle kill, normal completion, and wall/idle JSON preservation. Local ephemeral logs: `.relay-scratch/gh648-l3-baseline.log`, `gh648-l3-red.log`, `gh648-l3-green.log`; these are not committed gate/provenance evidence.
- No git commands or full gate run. The harness still owes its full gate and agy owes independent review. Graph tools were unavailable; used direct source inspection. Reversibility: Easy; only output routing changes, with the existing markdown diagnostic path preserved.

Handing off to agy — agy, take your turn.

### Round 2 · Reviewer · agy

- swept file: yes
- I have reviewed `utils/py/consult.py`, `test/gh648-l3-consult-cap.sh`, and `validate.sh`.
- The changes in `utils/py/consult.py` appropriately consume the truthful label from `idle-unknown` (line 310) and properly format and capture the `PARTIAL` timeout/idle signals to `.PARTIAL.md` alongside the JSON payload. The logic correctly balances returning the raw JSON object and surfacing a human-readable partial error.
- The `wait_with_idle_bound` function propagates the killed-reason back properly and the timeout logic prints the truthful attribution.
- The new test `gh648-l3-consult-cap.sh` adequately covers the behaviors for 600s limits, partial walls, and truthful idle kill signals, and executed successfully.
- No pre-existing defects were identified in `consult.py`.
- **Verdict:** Approved

relay closed, no further turn needed

### Attestation · relay-drive — 2026-09-17T06:28:00Z
task: MARATHON-P3-TURN-R2
reviewer: agy
status: Approved
reviewed-head: a7c0a679682aebeb82b2963be9e9c19b2f667379
added-range: 8853+892
added-sha256: 457440536403e02fce1c75f471e9b8c85c890e3b7e07b73c756aa0f4eab9e793
