---
title: "merge-cleanup: require a recorded direct-vs-group landing decision for queues of 3+ PRs (GH-1066 checkpoint)"
status: "Active (2-WORKING)"
created: 2026-10-18
updated: 2026-10-18
owner: Antigravity
gh_issue: 1158
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1158
doc_type: feature
complexity: 2
risk: 1
effort: 1
phases: 1
ratings_provisional: false
non_goals:
  - Automatic building of staging, fold, or aggregate branches
  - PR retargeting or modifying branch protections
  - Changing CI triggers or workflows (ci.yml, wave-reconcile.yml)
  - Replacing overall batch qualification policy (#1076) or merge queue (#571)
related:
  - GH-1066
  - GH-1064
  - GH-1140
  - GH-1076
  - GH-1122
  - GH-936
  - GH-939
  - GH-573
goal: "For queues of 3 or more PRs, make choosing direct versus grouped landing a deliberate, recorded decision in merge-cleanup before any mutation occurs."
---

# GH-1158 — merge-cleanup: require a recorded direct-vs-group landing decision for queues of 3+ PRs (GH-1066 checkpoint)

## Status

| What was just completed | What's next |
|---|---|
| Provisioned fresh task clone off `origin/development`, registered intake in RELEASES (rated 75/55/50/80), promoted doc to `2-WORKING`, sharpened GitHub issue #1158, and adjudicated Codex Plan QA R1 findings (R1, R2, R3). | Run Codex Plan QA Round 2 for approval, admit accepted-start in RELEASES, and implement Phase 1. |

## Preflight Solution-Fit Bet Check

- **Outcome sought:** In `merge-cleanup`, landing queues of 3 or more PRs must not proceed under `--execute` without an explicit, recorded decision between direct sequential landing and GH-1066 grouped candidate landing.
- **Smallest viable bet:** Add CLI options `--landing-plan {direct,group}` and `--landing-reason "<text>"` to `merge_cleanup.py`. When 3+ PRs are discovered for execution, validate the decision *before* any mutation occurs (before `prepare_primary_landing` prunes `REBASE_HEAD`, before checkout scan fetches, before `--marker` comments, and before `select_batch` writes). If missing or invalid, refuse execution with **Exit 5**. If `group`, record locally and in `merge-batch` issue, print GH-1066 guidance, and exit 0. If `direct`, record and proceed to Phase 5.
- **Alternatives rejected:**
  1. *Automatic heuristic grouping:* Inferring whether to group based on file overlap or conflict count was rejected because grouping involves trade-offs that require operator judgment.
  2. *Interactive prompt during execution:* Interactive prompts hang headless agents and automated runners; CLI flags ensure deterministic, scripted invocation.
  3. *Advisory-only reminder:* A reminder alone failed on 2026-10-18 when an agent skipped GH-1066 entirely; a hard gate is required.
- **Rollback / containment:** Completely isolated in `merge_cleanup.py` and `batch_record.py`. If reverted, merge-cleanup returns to executing all queues directly without the checkpoint. Reversibility: Easy.

## Problem

The GH-1066 merge-group policy (`skills/2-daily/merge-cleanup/SKILL.md:224-284`, PR #1068) asks the caller to consider a fold, staging PR or aggregate landing PR before landing 3 or more ready PRs. However, nothing currently enforces or prompts that consideration in code: `merge_cleanup.py --execute` proceeds to land a queue of any size sequentially one PR at a time without prompting. Whether the GH-1066 grouping policy is considered currently depends entirely on operator or agent memory.

On 2026-10-18, an agent executing a landing told the operator that staging or grouped PR landing support did not exist, having overlooked GH-1066 and historical fold precedents (#573, #936, #939, #1122). While that queue happened to be 2 PRs (below the threshold), the omission demonstrated that without a hard programmatic checkpoint, the GH-1066 policy will be routinely skipped by agents.

Even with GH-1127 removing per-merge hosted CI waits, landing queues of 3+ PRs still face compounding merge conflict repairs, soft-dependency collisions, repeated local reconciliation cycles, and qualification exposure that grouped candidate preparation cleanly mitigates.

## Detailed Specification

### 1. Pre-Execution Refusal & Zero-Mutation Invariant (Exit 5, Plan QA R1)
To ensure the strict zero-mutation invariant:
- In `merge_cleanup.py`, when `--execute` is passed (and not `--teardown-only`):
  - Perform read-only PR discovery (`fetch_open_prs_with_retry`) and toposort filtering before mutating state.
  - When the executable queue holds 3 or more PRs:
    - Check whether `--landing-plan` is specified with an acceptable choice (`direct` or `group`) and non-empty, non-whitespace `--landing-reason`.
    - If `--resume` is active, check if the matched unfinished batch record already holds an identical PR set with an existing `landing_plan`. If so, adopt that plan.
    - If no valid landing plan is present, print the decision input block and refuse execution with **Exit 5**:
      ```
      REFUSING to execute: 3 PRs ready to merge.
      GH-1066 merge-group policy requires a recorded landing decision for queues of 3+ PRs.
      Pass --landing-plan direct|group --landing-reason "<reason>" to proceed.
      ```
- **Zero-Mutation Guarantee (R1):** On Exit 5 refusal, the process halts immediately before calling `prepare_primary_landing` (preventing `update-ref -d REBASE_HEAD`), before checkout scans fetch remote refs (`refs/FETCH_HEAD`), before `--marker` comments are posted to GitHub, before `batch_record` creates a new issue or extends an existing one, and before any git commits or merges.

### 2. Decision Inputs in Phase 4 Display
During dry runs, `--prs-only`, and on Exit 5 refusal, print a concise `LANDING PLAN DECISION REQUIRED (GH-1066)` advisory block:
- Total executable PR count and sequence.
- Touched-file overlap pairs / soft collisions across the queue.
- Expected ledger/governance conflict sites (B1 repairs).
- Direct pointer to `skills/2-daily/merge-cleanup/SKILL.md` (GH-1066 guidance).
- Instructions on the required flags: `--landing-plan direct|group --landing-reason "<reason>"`.

### 3. Record in `batch_record` with Stale-Writer Safe Merge & Marker Stripping (Plan QA R2, R4)
- In `batch_record.py`, persist `landing_plan` in the batch record:
  ```json
  "landing_plan": {
    "decision": "direct" | "group",
    "reason": "<text>",
    "decided_at": "<ISO-8601>",
    "prs": [1062, 1089, 1097]
  }
  ```
- **Intentional-Update Merge Rule (R2, R4):** In `batch_record._merge_records(disk, mine)`:
  - Mutating `landing_plan` via `set_landing_plan()` marks `rec["_landing_plan_touched"] = True`.
  - In `_merge_records(disk, mine)`, if `disk` already has `landing_plan` and `mine` lacks `_landing_plan_touched`, preserve `disk["landing_plan"]`. A stale writer snapshot without the field cannot erase an existing recorded landing decision.
- **One-Shot Marker Consumption & Stripping Contract (R4):**
  - Add `_landing_plan_touched` to `_strip_marks(obj)` tuple: `("_touched", "_verdict_touched", "_sweep_touched", "_refreshed", "_landing_plan_touched")`.
  - In `save()`, ensure `_strip_marks` is applied on the initial save path (when no prior disk record exists) as well as within `_merge_records`, stripping the marker from both the persisted JSON and the caller dictionary.
  - This ensures reloaded snapshots never carry `_landing_plan_touched = True`, so an older reloaded snapshot saved after an intentional decision change cannot overwrite the new decision.
- In `batch_record.py` `script_block()`, render a dedicated section inside the script-owned markdown:
  ```markdown
  ## Landing decision (GH-1066)
  - Plan: `<decision>`
  - Reason: `<reason>`
  - Decided: `<timestamp>` for PRs #<n>, #<n>, #<n>
  ```
- **Resume Protocol:** When `--resume` is passed, if the batch record contains `landing_plan` and the PR set matches, reuse the decision without prompting. If new PRs joined that change the queue or no plan was recorded, enforce the checkpoint.

### 4. Issue Mirroring & Degraded-State Behavior (Plan QA R3)
- Local JSON record in primary coordinator directory (`.tick/` or equivalent) is the canonical source of truth and written under `RecordLock`.
- GitHub issue mirroring is attempted via `batch_record.create` / `batch_record.update`:
  - If GitHub issue creation/update fails (network error, rate limit, unreadable body), capture the error in `rec["issue_error"]` and log a warning: `merge-batch issue not created/updated: <error> — landing decision recorded locally at <path>`.
  - For `--landing-plan group`: write local record; if GitHub issue creation fails, log the warning (does not claim GitHub issue was posted), print the GH-1066 execution checklist (candidate freeze, adversarial review, single landing), and exit **Exit 0** cleanly without remote merges or checkout teardown. Building the combined branch remains caller-owned.
  - For `--landing-plan direct`: write local record; if GitHub issue creation fails, log the warning and proceed to Phase 5.

### 5. Direct Path Behavior (`--landing-plan direct`)
When `--landing-plan direct` is selected with non-empty `--landing-reason`:
- Record the decision and reason, then proceed through Phase 0, 1-3, 4, and 5 sequential execution.

### 6. Small Queues (<3 PRs)
Queues of 1 or 2 PRs are completely unaffected and run without requiring `--landing-plan`.

### 7. Documentation
Update `skills/2-daily/merge-cleanup/SKILL.md` GH-1066 section and CLI argument documentation.

## Phase 1 Implementation Plan

1. **CLI & Argument Parsing (`merge_cleanup.py`):**
   - Add `--landing-plan` (`choices=["direct", "group"]`, `default=None`).
   - Add `--landing-reason` (`type=str`, `default=""`).
   - Define exit code constant `EXIT_LANDING_PLAN_REQUIRED = 5`.
2. **Pre-Execution Checkpoint & Phase 4 Advisory (`merge_cleanup.py`):**
   - Perform read-only PR discovery upfront when `--execute` is set without `--teardown-only`.
   - Format and print the decision input block during dry run / prs-only / checkpoint check.
   - Refuse with Exit 5 before `prepare_primary_landing`, scan ref fetches, or `--marker` writes when `len(ordered_prs) >= 3` without a valid plan and reason.
   - Handle `--landing-plan group` by recording and exiting 0 with instructions.
3. **Batch Record Storage, Save Merge & Rendering (`batch_record.py`):**
   - Add `set_landing_plan(rec, decision, reason, prs)` marking `_landing_plan_touched = True`.
   - Add `_landing_plan_touched` to `_strip_marks` tuple in `batch_record.py:52`.
   - Update `_merge_records(disk, mine)` to preserve `disk["landing_plan"]` when `mine` lacks `_landing_plan_touched`.
   - Update `save()` to strip marks on first persistence so `_landing_plan_touched` is consumed immediately and never persisted to JSON or retained in caller state.
   - Render `## Landing decision (GH-1066)` in `script_block()`.
   - Update `extend()` / `find_unfinished()` handling for resume.
4. **Skill Documentation (`skills/2-daily/merge-cleanup/SKILL.md`):**
   - Document `--landing-plan`, `--landing-reason`, and Exit 5 in GH-1066 section and CLI reference.
5. **Verification & Red Controls:**
   - Adapt existing tests in `test/gh436-merge-cleanup.py` and `test/gh534_phase_a_tests.py` (Repo rail: No new tests, GH-831).
   - Author manual verification check with committed provenance under `TESTS-RESULTS/2026-10-18+GH-1158/`, including the stale-save-after-reload case.
   - Witness red controls for the checkpoint enforcement.

## Acceptance Criteria

- [ ] An `--execute` run on 3 or more PRs cannot merge anything without an explicit `--landing-plan direct|group` and non-empty `--landing-reason` (or a valid matching plan preserved on `--resume`).
- [ ] Omission of `--landing-plan` on 3+ PRs exits 5 before any git mutation (no `REBASE_HEAD` deletion, no `FETCH_HEAD` fetch writes), no issue markers, and no batch issue creation.
- [ ] Blank or whitespace-only `--landing-reason` is refused.
- [ ] `--landing-plan group` records the decision in the local batch record and batch issue (or warns on GitHub failure without false claim) and exits 0 with the GH-1066 checklist, without merging.
- [ ] `--landing-plan direct` records the decision and proceeds to Phase 5.
- [ ] Stale batch record saves under `RecordLock` preserve the recorded `landing_plan`.
- [ ] `_landing_plan_touched` is stripped and consumed on save (both first persistence and merge save); neither persisted JSON nor reloaded dict retain the marker; an older reloaded snapshot cannot overwrite a newer decision.
- [ ] The landing decision survives `--resume` on unchanged PR sets; changed PR sets require re-evaluation.
- [ ] Queues of 1 or 2 PRs remain completely unaffected.
- [ ] `skills/2-daily/merge-cleanup/SKILL.md` documents the flags, checkpoint, and Exit 5.
