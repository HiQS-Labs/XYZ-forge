---
title: "Phase brief: GH-149 marathon-drive --require-clean self-trip (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-07-17
updated: 2026-07-17
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the
  gh149-require-clean-selftrip phase — not itself an active-doc capture; the canonical capture doc
  is GH-149-REQUIRE-CLEAN-SELFTRIP.md one level up.
roadmap_exempt: true
---

## Status

| What was just completed | What's next |
|---|---|
| Brief authored 2026-07-17. | Fire this phase via the marathon. |

## Phase: gh149-require-clean-selftrip — stop --require-clean from tripping on its own lock

Full context: [GH-149-REQUIRE-CLEAN-SELFTRIP.md](../GH-149-REQUIRE-CLEAN-SELFTRIP.md).
GitHub issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/149

### The bug

In `relay-automation/marathon-drive.sh`, the driver lock is placed at
`$ROOT/.relay-driver.lock` whenever `$ROOT/.git` is a **file** rather than a directory — exactly the
linked-worktree case (a `.git` file is a gitdir pointer). The `--require-clean` clean-check
(`git status --porcelain`, filtered only for `^phases/` and `^\.tick/`) then sees this lock as
untracked dirt inside the worktree and hard-stops, even though it's the driver's own bookkeeping
file.

### What to do

1. In `relay-automation/marathon-drive.sh`, when `$ROOT/.git` is a file (linked worktree), resolve
   the lock path via `git rev-parse --git-common-dir "$ROOT"` instead of placing it at
   `$ROOT/.relay-driver.lock` directly — this puts the lock in the real `.git/` dir, outside the
   worktree's own `git status --porcelain` view.
2. Add a regression test to `test/marathon-drive.sh` (a new, additive case) that runs
   `marathon-drive.sh --require-clean` from inside a linked worktree and asserts it no longer
   self-trips on its own lock.
3. Do not touch unrelated `marathon-drive.sh` logic — this is a narrow, single-purpose fix.

### Acceptance / done means

- `marathon-drive.sh --require-clean` succeeds from inside a linked worktree when nothing else is
  dirty (currently it fails on the lock alone).
- Full `bash test/marathon-drive.sh` green, including the new case.
- Leave a one-line status update in `GH-149-REQUIRE-CLEAN-SELFTRIP.md`'s Status table.
