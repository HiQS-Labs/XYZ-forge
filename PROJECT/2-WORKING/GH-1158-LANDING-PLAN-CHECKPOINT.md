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
| Provisioned fresh task clone off `origin/development`, registered intake in RELEASES (rated 75/55/50/80), promoted doc to `2-WORKING`, and sharpened GitHub issue #1158. | Complete pre-implementation plan QA with Codex via relay-xyz, obtain approval, and admit accepted-start in RELEASES. |

## Preflight Solution-Fit Bet Check

- **Outcome sought:** In `merge-cleanup`, landing queues of 3 or more PRs must not proceed under `--execute` without an explicit, recorded decision between direct sequential landing and GH-1066 grouped candidate landing.
- **Smallest viable bet:** Add CLI options `--landing-plan {direct,group}` and `--landing-reason "<text>"` to `merge_cleanup.py`. If 3+ PRs are queued for execution and no landing plan is provided (and none recorded in the resumed batch), refuse to execute with **Exit 5** before any remote or local mutation. If `group` is passed, record it and exit 0 with GH-1066 guidance. If `direct` is passed, record it and proceed to Phase 5.
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

### 1. Programmatic Checkpoint & Distinct Exit Code (Exit 5)
In `merge_cleanup.py`:
- When Phase 4 topological sort yields 3 or more executable PRs and `--execute` is enabled (and not `--teardown-only`):
  - Check whether `--landing-plan` is specified with an acceptable choice (`direct` or `group`) and non-empty `--landing-reason`.
  - On `--resume`, check if the matched unfinished batch record already holds an identical PR set with an existing `landing_plan`. If so, adopt that plan.
  - If no valid landing plan is present, print the decision input block and refuse execution with **Exit 5**:
    ```
    REFUSING to execute: 3 PRs ready to merge.
    GH-1066 merge-group policy requires a recorded landing decision for queues of 3+ PRs.
    Pass --landing-plan direct|group --landing-reason "<reason>" to proceed.
    ```
- **Zero-Mutation Invariant:** On Exit 5 refusal, make NO git commits, NO remote merges, NO worktree removals, and create NO GitHub issues.

### 2. Decision Inputs in Phase 4 Display
During dry runs, `--prs-only`, and on Exit 5 refusal, print a concise `LANDING PLAN DECISION REQUIRED (GH-1066)` advisory block:
- Total executable PR count and sequence.
- Touched-file overlap pairs / soft collisions across the queue.
- Expected ledger/governance conflict sites (B1 repairs).
- Direct pointer to `skills/2-daily/merge-cleanup/SKILL.md` (GH-1066 guidance).
- Instructions on the required flags: `--landing-plan direct|group --landing-reason "<reason>"`.

### 3. Record in `batch_record` and GitHub `merge-batch` Issue
- In `batch_record.py`, persist `landing_plan` in the batch record:
  ```json
  "landing_plan": {
    "decision": "direct" | "group",
    "reason": "<text>",
    "decided_at": "<ISO-8601>",
    "prs": [1062, 1089, 1097]
  }
  ```
- In `batch_record.py` `script_block()`, render a dedicated section:
  ```markdown
  ## Landing decision (GH-1066)
  - Plan: `<decision>`
  - Reason: `<reason>`
  - Decided: `<timestamp>` for PRs #<n>, #<n>, #<n>
  ```
- **Resume Protocol:** When `--resume` is passed, if the batch record contains `landing_plan` and the PR set matches, reuse the decision without prompting. If new PRs joined that change the queue or no plan was recorded, enforce the checkpoint.

### 4. Group Path Behavior (`--landing-plan group`)
When `--landing-plan group` is selected:
- Record the decision and reason in the local batch record and post the `merge-batch` issue.
- Print the GH-1066 execution checklist (candidate freeze, adversarial review, single landing).
- Exit cleanly (**Exit 0**) without executing remote merges or checkout teardown. Building the combined branch remains caller-owned.

### 5. Direct Path Behavior (`--landing-plan direct`)
When `--landing-plan direct` is selected with `--landing-reason`:
- Record the decision and reason, then proceed directly to Phase 5 sequential execution.

### 6. Small Queues (<3 PRs)
Queues of 1 or 2 PRs are completely unaffected and run without requiring `--landing-plan`.

### 7. Documentation
Update `skills/2-daily/merge-cleanup/SKILL.md` GH-1066 section and CLI argument documentation.

## Phase 1 Implementation Plan

1. **CLI & Argument Parsing (`merge_cleanup.py`):**
   - Add `--landing-plan` (`choices=["direct", "group"]`, `default=None`).
   - Add `--landing-reason` (`type=str`, `default=""`).
   - Define exit code constant `EXIT_LANDING_PLAN_REQUIRED = 5`.
2. **Phase 4 Advisory & Checkpoint (`merge_cleanup.py`):**
   - Format and print the decision input block during dry run / prs-only / checkpoint check.
   - Refuse with exit code 5 when `len(ordered_prs) >= 3` without a valid plan and reason.
   - Handle `--landing-plan group` by recording and exiting 0 with instructions.
3. **Batch Record Storage & Rendering (`batch_record.py`):**
   - Add `set_landing_plan(rec, decision, reason, prs)` and serialize to JSON.
   - Render `## Landing decision (GH-1066)` in `script_block()`.
   - Update `extend()` / `find_unfinished()` handling for resume.
4. **Skill Documentation (`skills/2-daily/merge-cleanup/SKILL.md`):**
   - Document `--landing-plan`, `--landing-reason`, and Exit 5 in GH-1066 section and CLI reference.
5. **Verification & Red Controls:**
   - Adapt existing tests in `test/gh436-merge-cleanup.py` and `test/gh534_phase_a_tests.py` (Repo rail: No new tests, GH-831).
   - Author manual verification check with committed provenance under `TESTS-RESULTS/2026-10-18+GH-1158/`.
   - Witness red controls for the checkpoint enforcement.

## Acceptance Criteria

- [ ] An `--execute` run on 3 or more PRs cannot merge anything without an explicit `--landing-plan direct|group` and `--landing-reason`.
- [ ] Omission of `--landing-plan` on 3+ PRs exits 5 before any git mutation or issue creation.
- [ ] `--landing-plan group` records the decision in the batch issue and exits 0 with the GH-1066 checklist, without merging.
- [ ] `--landing-plan direct` records the decision and proceeds to Phase 5.
- [ ] The landing decision survives `--resume` on unchanged PR sets.
- [ ] Queues of 1 or 2 PRs remain completely unaffected.
- [ ] `skills/2-daily/merge-cleanup/SKILL.md` documents the flags, checkpoint, and Exit 5.
