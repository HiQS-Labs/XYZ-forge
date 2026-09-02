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
