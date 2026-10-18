# GH-1158 Verification & Red Control Summary

**Feature:** merge-cleanup: require a recorded direct-vs-group landing decision for queues of 3+ PRs (GH-1066 checkpoint)  
**Date:** 2026-10-18  
**Issue:** #1158  
**Verification Script:** `TESTS-RESULTS/2026-10-18+GH-1158/verify-landing-plan-checkpoint.py`

## Acceptance Criteria Results

| # | Check / Criteria | Result | Evidence |
|---|---|:---:|---|
| 1 | Missing `--landing-plan` on 3+ PRs exits 5 before mutation (no `REBASE_HEAD` deletion, no fetch, no issue) | PASS | `test_01_missing_landing_plan_exits_5_and_zero_mutations` |
| 2 | Blank or whitespace-only `--landing-reason` is refused with exit 5 | PASS | `test_02_blank_or_whitespace_landing_reason_exits_5` |
| 3 | Red control: Bypassing checkpoint demonstrates requirement is load-bearing | PASS | `test_03_red_control_bypassing_checkpoint` |
| 4 | `--landing-plan group` records decision, prints GH-1066 checklist, exits 0 without merging | PASS | `test_04_landing_plan_group_records_decision_and_exits_0` |
| 5 | `--landing-plan group` with GitHub issue error warns without false claim and exits 0 | PASS | `test_05_landing_plan_group_with_issue_error_degraded_state` |
| 6 | `--landing-plan direct` records decision and proceeds through Phase 5 merges (exits 4) | PASS | `test_06_landing_plan_direct_records_decision_and_merges` |
| 7 | Unchanged `--resume` reuses recorded landing plan for matching PR set | PASS | `test_07_resume_adopts_decision_when_prs_match` |
| 8 | Changed PR set on `--resume` invalidates recorded plan and exits 5 | PASS | `test_08_resume_refuses_when_pr_set_changes` |
| 9 | Small queues (1-2 PRs) remain completely unaffected without `--landing-plan` | PASS | `test_09_small_queues_unaffected` |
| 10 | Stale saves preserve `landing_plan`; `_landing_plan_touched` stripped on first persistence and merge | PASS | `test_10_stale_save_and_marker_stripping` |

## Regression Suites Passing

- `test/gh436-merge-cleanup.py`: 188/188 OK (319s)
- `test/gh534_phase_c_tests.py`: 111/111 OK (297s, including `TestParityGuard` AST mutation test)
