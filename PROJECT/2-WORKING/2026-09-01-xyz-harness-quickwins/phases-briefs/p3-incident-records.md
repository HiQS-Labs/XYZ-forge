---
title: "p3 brief — interrupted-phase tree snapshot (#371) + escalation root-cause tail (#372)"
status: "Brief (input to the 2026-09-01 xyz-harness-quickwins marathon — not a tracked plan)"
created: 2026-09-01
updated: 2026-09-01
owner: Noel Saw
goal: >
  When a phase dies mid-turn, the record must carry WHAT the tree looked like and WHY the
  turn failed — not just an exit code.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/371
  - https://github.com/HiQS-Labs/XYZ-forge/issues/372
---

# p3 — incident records

## Status

| What was just completed | What's next |
|---|---|
| Phase brief authored. | Marathon phase execution. |

Read the capture docs first: `PROJECT/2-WORKING/GH-371-INTERRUPT-SNAPSHOT-UNCOMMITTED-TREE.md`
and `PROJECT/2-WORKING/GH-372-ESCALATION-ROOT-CAUSE-TAIL.md`.

## #371 — snapshot the uncommitted tree on interruption

Where `PHASE-INTERRUPTED.md` is written (`utils/py/marathon_drive.py` interrupted-phase
path), append a `git status --porcelain` snapshot of the main repo AND the turn's
worktree (when worktree isolation was on and the dirs differ). Observed 2026-09-01: a
killed turn left 6 modified tracked files + 3 untracked tests in the MAIN repo with the
worktree clean; the record showed only the exit code, and the next gate silently
collected the half-finished tests. The snapshot is the recovery map AND the input for a
follow-on "tree unexpectedly dirty" warning at the next phase's Step 0 (the warning is
optional here; the snapshot is not).

Test: `test/gh371-interrupt-snapshot.sh` — drive a phase to interruption against a
fixture repo with a dirty tree; assert the interrupted-phase record contains the
porcelain lines.

## #372 — root-cause tail in ESCALATION.md

On turn failure/escalation, embed the last ~40 lines of the failing turn's log in a
collapsed block inside ESCALATION.md. If the turn's log file was never created, write
that explicitly — a missing log is itself diagnostic (observed: codex's "workspace out
of credits" surfaced only as `relay-failed-before-gate`; the log was not locatable from
the record). The turn log path is already resolved per-turn (`rtl_default_log`) — reuse
it; do not invent a second log-location scheme.

Test: `test/gh372-escalation-log-tail.sh` — force a turn failure with a fixture log;
assert ESCALATION.md contains the tail; assert the no-log case says so.

## Constraints

- Leave a `GH-371` marker in marathon_drive.py and a `GH-372` marker in relay_drive.py
  at the change sites (preflight probes key on them).
- These files are shared with p1/p2 — rebase-aware; do not revert their changes.
- Gate: `bash validate.sh`. In-turn, run only the two new tests plus files you edit.
