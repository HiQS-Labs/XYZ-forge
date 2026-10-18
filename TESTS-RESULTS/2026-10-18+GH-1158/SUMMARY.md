# GH-1158 Verification & Red Control Summary

**Feature:** merge-cleanup: require a recorded direct-vs-group landing decision for queues of 3+ PRs (GH-1066 checkpoint)  
**Date:** 2026-10-18  
**Issue:** #1158  
**Candidate SHA:** `d81665f7` (production code & documentation)  
**Source SHA256:**
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`: `1341de26bb1108ef645fa66d82344b657db85f91b784f1beb0dcd3c92db088e7`
- `skills/2-daily/merge-cleanup/scripts/batch_record.py`: `478c5939d248e24eded15ab57133181c6009f3b0f6cdc4f43bc89de1679a0486`
- `skills/2-daily/merge-cleanup/SKILL.md`: `a1f981b3e6eb22748eacd5ab7e0190eba168203d679a263d7aadfc8e1cddcc00`
- `TESTS-RESULTS/2026-10-18+GH-1158/verify-landing-plan-checkpoint.py`: `0ce73bf972ab40f51b97010e18ff17c9f8265f77560ebe895c80bfca4375f7a8`

**Verification Script:** `TESTS-RESULTS/2026-10-18+GH-1158/verify-landing-plan-checkpoint.py`

## Acceptance Criteria Results

| # | Check / Criteria | Result | Evidence |
|---|---|:---:|---|
| 1 | Missing `--landing-plan` on 3+ PRs exits 5 before mutation (no `REBASE_HEAD` deletion, no `FETCH_HEAD` modification, recursive `rglob` batch search with seeded positive control, active innermost scan mock entry assertion `scan_mock.call_count == 0`, and no issue markers) | PASS | `test_01_missing_landing_plan_exits_5_and_zero_mutations` |
| 2 | Blank or whitespace-only `--landing-reason` is refused with exit 5 | PASS | `test_02_blank_or_whitespace_landing_reason_exits_5` |
| 3 | Happy path: valid direct plan proceeds without Exit 5, lands PRs, and exits 4 (QA pending) | PASS | `test_03_valid_direct_plan_executes_successfully` |
| 4 | `--landing-plan group` records decision, prints GH-1066 checklist, exits 0 without merging | PASS | `test_04_landing_plan_group_records_decision_and_exits_0` |
| 5 | `--landing-plan group` with GitHub issue error warns without false claim and exits 0 | PASS | `test_05_landing_plan_group_with_issue_error_degraded_state` |
| 6 | `--landing-plan direct` records decision and proceeds through Phase 5 merges (exits 4) | PASS | `test_06_landing_plan_direct_records_decision_and_merges` |
| 7 | Unchanged `--resume` reuses recorded landing plan for matching PR set | PASS | `test_07_resume_adopts_decision_when_prs_match` |
| 8 | Changed PR set on `--resume` invalidates recorded plan and exits 5 | PASS | `test_08_resume_refuses_when_pr_set_changes` |
| 9 | Small queues (1-2 PRs) remain completely unaffected without `--landing-plan` | PASS | `test_09_small_queues_unaffected` |
| 10 | Stale saves preserve `landing_plan`; `_landing_plan_touched` stripped on first persistence and merge | PASS | `test_10_stale_save_and_marker_stripping` |
| 11 | Phase 4 defers PRs opened after the pre-mutation checkpoint, binding execution to checkpointed queue (Codex F1 fix) | PASS | `test_11_queue_widening_between_checkpoints_is_deferred` |
| 12 | Deferred prerequisites transitively block their retained dependents (Codex F4 fix) | PASS | `test_12_deferred_prerequisites_block_retained_dependents` |

## Witnessed Red Controls (Codex F2 / F3)

1. **Active Scan Boundary Falsifier:** Mutated `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` to dispatch `scan_directories(...)` before refusal. Innermost mock immediately failed with `AssertionError: 1 != 0 : Zero-mutation violated: scan_directories was called on Exit 5`.
2. **Marker Dispatch Boundary Falsifier:** Mutated `merge_cleanup.py` to dispatch `post_issue_marker(primary_repo, 999, ...)` before refusal. Assertion immediately failed with `AssertionError: 1 != 0 : Zero-mutation violated: issue markers posted on Exit 5`.
3. **Checkpoint Bypass & Ref-Mutation Falsifier:** Mutated threshold from `>= 3` to `>= 99`. Execution proceeded into Phase 0, pruned orphaned `REBASE_HEAD`, and failed the refusal-text assertion.
- **Artifact:** Logged in `TESTS-RESULTS/2026-10-18+GH-1158/red-control-mutation.log`.
- **Restoration:** Restoring clean production code turned all checks green (`Ran 12 tests in 82.781s. OK`).

## Regression Suites Passing

- `test/gh436-merge-cleanup.py`: 188/188 OK (319s)
- `test/gh534_phase_c_tests.py`: 111/111 OK (291s, including `TestParityGuard` AST mutation test)
