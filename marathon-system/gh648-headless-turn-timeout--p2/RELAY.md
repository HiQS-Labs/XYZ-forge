# Marathon Phase p2
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-P2-TURN-R4 builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

---
title: "L2 brief — #241 no peer token release on timeout-kill"
status: "Brief (input to the GH-648 headless turn-timeout marathon — not a tracked plan)"
created: 2026-09-16
updated: 2026-09-16
owner: Noel Saw
goal: >
  A timeout-killed commandcode turn must leave the token recoverable for a same-role retry, never released to the peer.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/648
---

# L2 — #241: no peer token release on a timeout-killed turn

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-16) | Lane fires when the marathon chain reaches this phase |

Umbrella: #648 · Issue: #241 · Wave 1 · depends_on L1

## Goal
In `utils/py/commandcode-turn.py`: when the turn is timeout-killed (exit 7 path), the shim must NOT `tick release --to <peer>`. Leave the token recoverable for a retry of the SAME role (release back to the driver/claimer, or a `task.failed`-style event) so the relay's NEXT: header and the token agree and a retry needs no fresh task id.

## Facts
#241's log sequence: killed at 900s cap (`timeout-idle-no-progress`, cpu=0.00, empty transcript) → "produced no tracked changes" → `tick release --to` peer — a failed review became a silent skip, and the spent task id was unclaimable. Codex verified the mechanism: `rtl.enforce` is called after the timeout (`commandcode-turn.py:91,120`) and its normal nonterminal path releases to the peer (`relay-turn-lib.sh:1530`). Route the killed path around that release.

## Rules
Python twin authoritative (`utils/py/commandcode-turn.py`; the `.sh` is a frozen twin). Register the suite in `validate.sh` TESTS. `bash validate.sh` green before done.

## Acceptance / Guard
`test/gh648-l2-token-aftermath.sh`: fixture turn killed at a short cap → token state shows NOT released to the peer; same-role retry is possible without a fresh task id; a healthy turn still releases normally (no regression).


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): utils/py/commandcode-turn.py, test/gh648-l2-token-aftermath.sh, validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick claim MARATHON-P2-TURN-R4 --agent codex --paths "marathon-system/gh648-headless-turn-timeout--p2/RELAY.md,utils/py/commandcode-turn.py, test/gh648-l2-token-aftermath.sh, validate.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick ping MARATHON-P2-TURN-R4 --agent codex
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick release MARATHON-P2-TURN-R4 --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh648-headless-turn-timeout--p2/RELAY.md and utils/py/commandcode-turn.py, test/gh648-l2-token-aftermath.sh, validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/commandcode-turn.py, test/gh648-l2-token-aftermath.sh, validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick release MARATHON-P2-TURN-R4 --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick done MARATHON-P2-TURN-R4 --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick
   Edit ONLY marathon-system/gh648-headless-turn-timeout--p2/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

The existing L2 implementation is retained; this turn adds the reported empty-transcript timeout regression case.

- Files changed this turn: `test/gh648-l2-token-aftermath.sh` and this relay (required NEXT routing header plus appended block). `utils/py/commandcode-turn.py` already guards timeout enforcement with an empty RELAY_FILE; `validate.sh` already registers the suite.
- Source trace: TimeoutExpired records timed_out independently of bounded_rc; worktree containment can overwrite the exit with 6 without losing the timeout guard. Enforcement still runs, its automatic done/peer-release branch is disabled, and the existing ownership-checked atexit cleanup releases the claim without a peer. Healthy turns retain normal release/done behavior.
- The new fixture emits zero transcript bytes before the one-second timeout and asserts zero bytes, open token/no peer handoff, same-role claim, and a healthy adapter retry with the same task ID. Seven cases now cover timeout, empty timeout, interrupted approval, off-lane aftermath, enforcement exit 6, healthy handoff, and healthy approval.
- Focused verification: `bash test/gh648-l2-token-aftermath.sh` exited 0 (7/7); shell syntax check exited 0. Negative control: a scratch copy with the timeout RELAY_FILE suppression disabled exited 1 at the no-handoff assertion, showing `handoff-to: agy`. Local transient logs are under `.relay-scratch/l2-green.log` and `.relay-scratch/l2-negative.log`; these are not committed provenance artifacts.
- Evidence limits: fixture uses real timed child execution, production claim/exit cleanup, real tick projection, and the extracted production token-handoff block; Git/diagnostic/telemetry boundaries are stubbed. No Git commands or full gate were run. The harness owns final gate and commit.
- Graph lookup found only another checkout's stale 2026-09-01 generation; coverage flagged changed/missing paths. Conclusions above use current on-disk source, including the drifted relay-turn-lib handoff block.
- Reversibility: Easy for this test-only addition. Remaining reviewer check: evaluate the inherited timeout implementation and broader enforcement behavior before approval.

handing off to agy — agy, take your turn.
