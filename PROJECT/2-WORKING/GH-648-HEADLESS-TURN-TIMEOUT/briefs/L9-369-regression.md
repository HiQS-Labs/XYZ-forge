---
title: "L9 brief — #369 regression baseline, verification only (Wave 2)"
status: "Brief (input to the GH-648 headless turn-timeout marathon — not a tracked plan)"
created: 2026-09-16
updated: 2026-09-16
owner: Noel Saw
goal: >
  Prove rtl_run_bounded still kills the whole process group at the cap; reopen #369 only on failure.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/648
---

# L9 — #369 regression baseline: verification only (Wave 2)

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-16) | Lane fires when the marathon chain reaches this phase |

Umbrella: #648 · Issue: #369 (CLOSED 2026-09-02 as the GH-478 shared process-group primitive) · Wave 2 · depends_on L8

## Goal
Prove the primitive still bounds #369's shape: a CLI that spawns children must have the WHOLE process group die at the cap. Build `test/gh648-l9-369-regression.sh`: a stub parent that forks a child (and a grandchild) sleeping past a short cap, run under `rtl_run_bounded`; assert every PID in the group is gone shortly after the cap fires.

If the group outlives the cap: STOP — reopen #369 with the suite receipt as evidence and escalate. Do NOT fix the primitive in this lane (it is GH-478's surface; a regression found here invalidates the umbrella's supervision assumption and goes back to the operator).

## Rules
Verification-only lane: your write-set is the suite + validate.sh registration. No production edits.

## Acceptance / Guard
The suite is the guard: whole-group termination at the cap, asserted per-PID, with a red path that would reopen #369.
