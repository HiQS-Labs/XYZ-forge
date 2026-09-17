# Marathon Phase p6
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-P6-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

---
title: "L6 brief — #521 muse stall attribution (investigation)"
status: "Brief (input to the GH-648 headless turn-timeout marathon — not a tracked plan)"
created: 2026-09-16
updated: 2026-09-16
owner: Noel Saw
goal: >
  Make muse stall/timeout reporting state what was observed using L1's reason model; attribution only, not kill policy.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/648
---

# L6 — #521: muse stall attribution (investigation)

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-16) | Lane fires when the marathon chain reaches this phase |

Umbrella: #648 · Issue: #521 · Wave 1 · depends_on L5

## Goal
#521: driven muse turns stall at cpu=0.00 with no relay block; four hypotheses already ruled out in-issue; the issue's own residual is the turn prompt. Grounded review found muse has NO idle-oracle kill path — `utils/py/muse-turn.py` delegates the wall cap to `rtl_run_bounded` (~`:279`) and uses `TurnDiagnostics` only for post-cap attribution (~`:267`).

So this lane is **attribution, not kill policy**: make muse's stall/timeout reporting state what was actually observed (stall vs cap vs unknown) using L1's reason model, and fix whatever mislabels a stalled muse turn in the run log. If the investigation confirms the issue's residual (the turn prompt itself), record that as the receipt — the code change stays attribution-only.

## Rules
Write-set: `utils/py/muse-turn.py` + suite. Python twin authoritative; register the suite in `validate.sh` TESTS; `bash validate.sh` green.

## Acceptance / Guard
`test/gh648-l6-muse-attribution.sh`: a stubbed muse-shaped stall produces a termination record whose label matches what happened (stall-unknown, not "no progress" and not a bare cap); a healthy muse turn is unaffected.

### Round 1 · Builder · codex

- Changed `utils/py/muse-turn.py`, `test/gh648-l6-muse-attribution.sh`, and the TESTS registration in `validate.sh`.
- Source trace: Muse uses `rtl_run_bounded` for its wall cap and `TurnDiagnostics` for attribution; it has no idle-kill policy. Previously its classification appeared only on stderr, leaving no structured termination in the Muse run log. Graph tools were unavailable; inspected the adapter, bounded runner, and L1 diagnostics source directly.
- Reused L1's emitter to append one `turn-termination` record to the Muse log: `termination=wall-cap`, with the observed reason (`timeout-idle-unknown` for the brief's stall-unknown case). The same record supplies stderr attribution. Emission precedes worktree cleanup so containment exit 6 does not erase an observed cap. Exit precedence and kill policy are unchanged. Reversibility: Easy, localized reporting change.
- Focused verification: `bash test/gh648-l6-muse-attribution.sh` passed (exit 0): seven behavior cases covering unknown stall, possible backend wait, failed/missing probe, cap followed by containment, healthy completion, and banner-only failure; two mutations rejected (old no-progress label and missing record). The pre-fix run failed at `termination record count` with zero records, establishing the regression oracle. Local output is in `.relay-scratch/l6-before.log` and `.relay-scratch/l6-after.log` (scratch is not durable or committed evidence).
- Test boundary: real Muse-shaped subprocesses and the actual bounded runner; deterministic observations exercise the real L1 classifier/serializer. Coordination, worktree operations, telemetry, and visibility lookup are stubbed; no git, live model, or network calls. All test artifacts stay under `.relay-scratch/`.
- Investigation limit: this confirms the reporting gap, not the cause of the historical #521 stall. The registry documents four ruled-out hypotheses and a residual turn-prompt hypothesis; no live Muse replay was performed, so that residual remains unconfirmed.
- Full gate deliberately not run per this turn's instructions; harness verification and independent agy review remain outstanding.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/py/muse-turn.py, test/gh648-l6-muse-attribution.sh, validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick claim MARATHON-P6-TURN --agent codex --paths "marathon-system/gh648-headless-turn-timeout--p6/RELAY.md,utils/py/muse-turn.py, test/gh648-l6-muse-attribution.sh, validate.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick ping MARATHON-P6-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick release MARATHON-P6-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh648-headless-turn-timeout--p6/RELAY.md and utils/py/muse-turn.py, test/gh648-l6-muse-attribution.sh, validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/muse-turn.py, test/gh648-l6-muse-attribution.sh, validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick release MARATHON-P6-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick done MARATHON-P6-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick
   Edit ONLY marathon-system/gh648-headless-turn-timeout--p6/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
