---
title: "GH-626: skills(workhorse, unstuck): close the autonomous re-entry loop — self-trigger on passive stalls and mandate orchestrator re-drive"
status: active
created: 2026-09-14
updated: 2026-09-14
owner: unassigned
goal: close the autonomous re-entry loop in workhorse and unstuck so batch orchestrators run to completion without operator intervention
gh_issue: 626
source: https://github.com/HiQS-Labs/XYZ-forge/issues/626
doc_type: enhancement
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/623
context_tags: [workhorse, unstuck, skills, autonomy, re-entry-loop, orchestrator]
non_goals:
  - Rewriting the core rungs of workhorse or unstuck
  - Changing git safety policies or worktree containment
  - Modifying how individual script commands work internally (tracked in #623)
effort: 2
complexity: 2
risk: 1
---

# GH-626 — skills(workhorse, unstuck): close the autonomous re-entry loop

## Status

| What was just completed | What's next |
|---|---|
| Issue #626 filed, task clone initialized, implementation plan approved | Update `skills/workhorse/SKILL.md` and `skills/unstuck/SKILL.md` |

## Quad Concepts
- Single-pass ladder stall → Mandate orchestrator re-drive loop (`drive → repair/park → --resume → loop`) in `workhorse`
- Dormant `/unstuck` on passive stalls → Add autonomous self-trigger tripwires (two-turn no-milestone, exit code inertia, passive narration, false completion)
- Micro-action limbo in Rung 5 → Require re-driving the primary execution engine before exiting Rung 5
- Silent scope degradation → Add anti-downgrade rail forbidding "Done" claims when batch deliverables were bypassed

## Background & Observed Friction

In session `ae137dca-3f97-4500-a69e-4f2275e9c2a5` (see GH-623), the operator had to intervene 4 times to re-drive what was intended to be an unattended `/merge-cleanup` landing run ("I kept having to drive it instead of it solving problems on its own").

While #623 addresses script-level bugs in `merge_cleanup.py` and `toposort_prs.py`, the behavioral breakdowns trace directly to gaps in `/workhorse` and `/unstuck`:
1. `/workhorse` was loaded at 03:33 UTC, but when execution hit a sub-task conflict (#596 `CHANGELOG.md` conflict), the model manually repaired the conflict file and then simply stopped, narrating "Waiting for the run to finish" without re-invoking the merge orchestrator.
2. `/unstuck` was available throughout the session but was never invoked—neither by the model nor automatically—despite the session stalling across multiple points (Phase 0 false completion in S1, classifier denial halt in S2, passive waiting in S5).

## Required Enhancements

### 1. `skills/workhorse/SKILL.md`
- **Orchestrator Re-Entry & Autonomous Drive Loop:**
  - In batch/orchestrator mode (`merge-cleanup`, `jog`, `marathon`), sub-item repair or park is an intermediate step, not the completion of the turn.
  - Mandate re-invoking the primary command with `--resume` immediately following the repair commit/park record.
  - Require looping autonomously until the queue is empty or all items are parked.
- **Anti-Downgrade Rail:**
  - Forbid reporting "Done" if an orchestrator sequence was requested but bypassed (e.g., Phase 0 refused landing and agent ran `--teardown-only`).
- **Tripwire to `/unstuck`:**
  - Interrupt looping without progress or repeated non-zero tool exits via `/unstuck`.

### 2. `skills/unstuck/SKILL.md`
- **Autonomous Self-Triggering Tripwires:**
  - Two-Turn No-Milestone Tripwire.
  - Tool Exit Code Inertia Tripwire.
  - Passive Narration Detection.
  - False Completion Detection.
- **Harden Rung 5 (Act, Verify, Re-Drive, Exit):**
  - Unblocking a batch runner requires re-driving the primary engine (`--resume`).
- **Bi-Directional Watchdog Handshake:**
  - Codify coordination between `workhorse` and `unstuck`.

## Verification & Acceptance
- Deploy skills via `skills/skills-army-hq/scripts/deploy.sh`.
- Verify tests in `test/test_deploy_skills.py` pass.
- Verify doc hygiene via `pdda.sh run`.
