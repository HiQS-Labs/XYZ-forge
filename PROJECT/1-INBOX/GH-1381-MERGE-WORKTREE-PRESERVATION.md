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
| Independent plan QA approved; minimal fix and controlled red/green complete | Focused verification, final QA, bounded gated publication |

## Problem and evidence

The baseline merge invocation and dry-run text include `--delete-branch`. Installed gh 2.101.0 removes another linked worktree checked out on the PR head while handling that flag. The branch/path/command match the missing #1377 worktree; runtime removal stdout is unavailable, so causation is a strong source-based inference. Phase 6 had not run. No complete ignored/untracked pre-incident baseline exists. No blanket no-data-loss claim is made.

Recovery inventory and actionable preservation limits: [PR1382 recovery manifest](https://github.com/HiQS-Labs/XYZ-forge/blob/bf17c636655f1cc23c321b5cec946996ad215b4d/TESTS-RESULTS/2026-11-08%2BGH-1381/RECOVERY-MANIFEST.md).

## Corrective scope

1. Trace and remove the implicit deletion flag from live merge execution and its dry-run text -> expect a merge-only invocation with unchanged strategy and exact-head guard.
2. Keep cleanup in the explicit existing inventory/safety workflow -> expect no branch/worktree deletion side effects from merging.
3. Verify with existing coverage or recorded manual controls -> expect a witnessed red control without touching real retained state; no new suite or gate.

The original incident capture and inventory did not implement the correction. The separately authorized bounded implementation trial is recorded below; it does not authorize cleanup/restoration/merge/installation, close broader factory qualification, or reset attempt history.

## Implementation trial — pinned flywheel

Capture reused from PR1382 at bf17c636655f1cc23c321b5cec946996ad215b4d; recovery inventory remains there. Missing-worktree completeness is UNKNOWN, independent of fix proof.

Mode 1B, not unattended qualification. Objective: reviewed, verified GH1381 fix PR; no merge, installation, restoration, deletion or Phase B. Baseline 1c2bd89eb: live helper conditionally requests deletion; outer preview always requests it. Intended gain: carry observed failure through repair, review and gated publication without repeated parent rescue. Critical path: independent review and bounded push gate.

Rubric 2: capture the actual helper command at the subprocess boundary in a controlled fixture; baseline must fail the no-delete assertion, fixed command must pass while linked-worktree sentinel remains. No destructive red control. Existing gh436 suite verifies adjacent merge/stack paths. No new suite or gate.

Rubric 3: smallest sufficient experiment removes command side effect and obsolete suppression state, not teardown. Easy rollback by reverting this change; blast radius is merge command construction, preview and stacked-retarget wording. Strategy, pin, checks, reconciliation and attempt caps remain unchanged. A passing result supports this repair workflow, not formal factory readiness.

Budget: 2026-11-08 21:46:19–22:46:19Z, at most two builder attempts, three routine repair rounds per blocker, one full host gate capped 1800s and before cutoff. Subscription Codex/Agy only; usage unknown. Implementation started 21:47Z; builder attempt 1. T3 supplied isolation overrides fresh-clone provisioning; all checkouts retained by explicit operator instruction. Native independent QA authorized in place of harness review transport; no duplicate runner/queue.

Rating 95/90/50/90: urgent observed worktree disappearance, ignored/untracked recovery unknown; neutral appeal; localized fix. Incident #1380 is the single sourced incident; broader recurrence trend unknown.

1. Independently review minimal removal plan and gh 2.101.0 defaults -> approval required before code.
2. Remove flag and obsolete suppression plumbing, adapt existing assertions -> actual command and both previews agree.
3. Record controlled red/green and existing focused suite in disposable full clone -> sentinel retained and merge controls pass.
4. Independent final QA, then coordinated bounded normal push gate -> ready PR against development if green; preserve partial otherwise.

No new consult boundary observed: this is attended, explicitly scoped implementation, not unattended machinery repair continuation.

## Trial observations

21:48Z plan QA Approved (native independent Codex); admission via canonical roadmap update. One implementation attempt removed obsolete deletion state without changing teardown. 21:49Z controlled invocation red/green passed all strategies; actual gh behavior assessed against exact-version source, no remote merge performed. Parent reserved full-gate slot at 21:50:33Z; latest full-gate entry 22:16:19Z.

Routine repair 1: first focused invocation accidentally used baseline files because copy commands ran in the gate working directory. Preserve that baseline result separately; rerun focused verification after copying the changed files from the task checkout. This is agent-assisted work, not unattended qualification. No caps or gates bypassed.

Flywheel routing: step 1 reused incident capture; steps 2–3 selected start-task/current Codex builder with supplied isolation; step 4 native independent plan/final QA by explicit override; step 5 active continuation without scheduler; step 6 publication only under no-merge boundary; step 7 deployment not authorized. No runner/queue introduced.

CLI trace: execute_pr_merge has no public delete_branch parameter; the local boolean and suppression set were internal only. The single production caller is _land_prs_loop; direct test callers retain the unchanged signature. Both dry-run strings now omit deletion. Explicit scoped Phase 6 teardown is unchanged. gh capture_output=True plus explicit --strategy prevents interactive deletion prompting. No other merge-cleanup documented invocation requests the flag.

Environment repair: system python lacks requests; existing ~/.cache/xyz-forge-test-venv toolchain imports requests/yaml/pytest. Use that supported PATH for verification/publication; no new installation or access.
