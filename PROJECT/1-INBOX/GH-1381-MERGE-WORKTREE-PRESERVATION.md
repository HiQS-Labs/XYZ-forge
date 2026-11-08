---
title: "GH-1381: keep merge separate from worktree cleanup"
status: proposed
created: 2026-11-08
updated: 2026-11-08
owner: operator
gh_issue: 1381
goal: Remove implicit branch/worktree cleanup from merge-only execution while preserving landing controls.
---

# GH-1381 — Merge worktree preservation

Tracking issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1381
Incident batch: https://github.com/HiQS-Labs/XYZ-forge/issues/1380

## Status

| What was just completed | What's next |
|---|---|
| Incident recorded; post-incident surviving-state inventory prepared with explicit unknowns | Parent trials pinned flywheel skill on the corrective implementation in a separate task; no duplicate implementation here |

## Problem and evidence

The current merge invocation and dry-run text include `--delete-branch`. Installed gh 2.101.0 removes another linked worktree checked out on the PR head while handling that flag. The branch/path/command match the missing #1377 worktree; runtime removal stdout is unavailable, so causation is a strong source-based inference. Phase 6 had not run. No complete ignored/untracked pre-incident baseline exists. No blanket no-data-loss claim is made.

Recovery inventory and actionable preservation limits: [RECOVERY-MANIFEST](../../TESTS-RESULTS/2026-11-08+GH-1381/RECOVERY-MANIFEST.md).

## Corrective scope

1. Trace and remove the implicit deletion flag from live merge execution and its dry-run text -> expect a merge-only invocation with unchanged strategy and exact-head guard.
2. Keep cleanup in the explicit existing inventory/safety workflow -> expect no branch/worktree deletion side effects from merging.
3. Verify with existing coverage or recorded manual controls -> expect a witnessed red control without touching real retained state; no new suite or gate.

This capture and inventory do not implement the correction, authorize cleanup/restoration/merge/installation, close broader factory qualification, or reset attempt history. Parent owns the separately authorized bounded implementation trial.
