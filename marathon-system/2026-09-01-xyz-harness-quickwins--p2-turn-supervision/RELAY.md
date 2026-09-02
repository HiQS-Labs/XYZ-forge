# Marathon Phase p2-turn-supervision
STATUS: Open
NEXT: codex (Builder)

<!-- marathon-drive: task=MARATHON-P2-TURN-SUPERVISION-TURN builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

---
title: "p2 brief — process-group turn cap (#369) + worktree progress telemetry (#370)"
status: "Brief (input to the 2026-09-01 xyz-harness-quickwins marathon — not a tracked plan)"
created: 2026-09-01
updated: 2026-09-01
owner: Noel Saw
goal: >
  A turn can no longer run silently past its cap with nothing observable: enforce the
  wall-clock cap on the whole process group, and emit worktree progress during the turn.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/369
  - https://github.com/HiQS-Labs/XYZ-forge/issues/370
---

# p2 — turn supervision

## Status

| What was just completed | What's next |
|---|---|
| Phase brief authored. | Marathon phase execution. |

Read the capture docs first: `PROJECT/2-WORKING/GH-369-TURN-CAP-PROCESS-GROUP-KILL.md`
and `PROJECT/2-WORKING/GH-370-WORKTREE-PROGRESS-TELEMETRY.md`.

## #369 — kill the process group

`rtl_run_bounded` (in `relay-automation/relay-turn-lib.sh`, mirrored in
`utils/py/rtl.py`) kills only the launched PID; its own comment flags the gap ("a
multi-process CLI whose children outlive the leader is a known gap"). Observed: an agy
turn ran 78 minutes past a 2400 s cap; the CLI had re-exec'd, so the watchdog killed a
dead leader. `relay_drive.py` launches the agent-cmd with `start_new_session=True` — the
fix must resolve and kill the child's actual PGID (`ps -o pgid= -p <pid>` then
`kill -9 -PGID`) in BOTH lanes (Bash lib and Python twin) so neither drifts.

Test: `test/gh369-group-kill.sh` — spawn a child that forks a grandchild which outlives
the leader, run it under the bounded runner with a 1-2 s cap, assert the grandchild is
dead shortly after (this is exactly the observed failure shape; `test/gh460-pipe-buffer-sigpipe.sh`
shows the fixture style).

## #370 — progress telemetry

The supervisor poll loop in `utils/py/relay_drive.py` (`while proc.poll() is None`)
already samples `ps` RSS. Add a throttled (~60 s) `git -C <turn-worktree> status
--porcelain | wc -l` sample logged to the run log, so a spinning turn (0-byte log,
0 changed files for an hour — the observed case) is distinguishable from a productive
one at a glance. Keep it warn-only: telemetry, not enforcement. If the turn runs without
worktree isolation, sample the main tree's artifact paths instead and say which.

Test: `test/gh370-progress-telemetry.sh` — run a stub agent-cmd that sleeps past one
telemetry interval against a fixture worktree; assert the run log contains the
changed-count line.

## Constraints

- Leave a `GH-369` marker in relay-turn-lib.sh and a `GH-370` marker in relay_drive.py
  at the change sites (preflight probes key on them).
- The Bash/Python lanes must stay behaviorally identical — update both or neither.
- Gate: `bash validate.sh`. In-turn, run only the two new tests plus files you edit.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/relay-turn-lib.sh,utils/py/rtl.py,utils/py/relay_drive.py,test/gh369-group-kill.sh,test/gh370-progress-telemetry.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick
   - /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick claim MARATHON-P2-TURN-SUPERVISION-TURN --agent codex --paths "marathon-system/2026-09-01-xyz-harness-quickwins--p2-turn-supervision/RELAY.md,relay-automation/relay-turn-lib.sh,utils/py/rtl.py,utils/py/relay_drive.py,test/gh369-group-kill.sh,test/gh370-progress-telemetry.sh"
   - /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick ping MARATHON-P2-TURN-SUPERVISION-TURN --agent codex
   - /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick release MARATHON-P2-TURN-SUPERVISION-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/2026-09-01-xyz-harness-quickwins--p2-turn-supervision/RELAY.md and relay-automation/relay-turn-lib.sh,utils/py/rtl.py,utils/py/relay_drive.py,test/gh369-group-kill.sh,test/gh370-progress-telemetry.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/relay-turn-lib.sh,utils/py/rtl.py,utils/py/relay_drive.py,test/gh369-group-kill.sh,test/gh370-progress-telemetry.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick release MARATHON-P2-TURN-SUPERVISION-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick done MARATHON-P2-TURN-SUPERVISION-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick
   Edit ONLY marathon-system/2026-09-01-xyz-harness-quickwins--p2-turn-supervision/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
