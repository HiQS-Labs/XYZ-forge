# Marathon Phase gh149-require-clean-selftrip
STATUS: Approved
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH149-REQUIRE-CLEAN-SELFTRIP-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

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

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/marathon-drive.sh,test/marathon-drive.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH149-REQUIRE-CLEAN-SELFTRIP-TURN --agent codex --paths "phases/gh208-154-149-198-issue-sweep--gh149-require-clean-selftrip/RELAY.md,relay-automation/marathon-drive.sh,test/marathon-drive.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH149-REQUIRE-CLEAN-SELFTRIP-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH149-REQUIRE-CLEAN-SELFTRIP-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh208-154-149-198-issue-sweep--gh149-require-clean-selftrip/RELAY.md and relay-automation/marathon-drive.sh,test/marathon-drive.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/marathon-drive.sh,test/marathon-drive.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH149-REQUIRE-CLEAN-SELFTRIP-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH149-REQUIRE-CLEAN-SELFTRIP-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh208-154-149-198-issue-sweep--gh149-require-clean-selftrip/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex

- Updated `relay-automation/marathon-drive.sh` so the driver lock stays at `$ROOT/.git/relay-driver.lock` for normal clones, resolves through `git -C "$ROOT" rev-parse --git-common-dir` when `$ROOT/.git` is a file (linked worktree), and keeps the existing `.relay-driver.lock` fallback for vendored/non-git roots.
- Added an additive linked-worktree regression to `test/marathon-drive.sh` that creates a real `git worktree`, runs `marathon-drive.sh --require-clean` from inside it, and asserts the run stays clean, does not report `.relay-driver.lock` as dirt, and still seeds the phase.
- Verification: `bash test/marathon-drive.sh` -> `105 pass, 0 fail`.

### Round 1 · Reviewer · agy

**Verdict:** Approved

The changes successfully resolve the issue. The lock path correctly resolves through the git common dir for linked worktrees, preventing `--require-clean` from self-tripping, and the new regression tests pass cleanly.
