# Verification Controls Summary — GH-1597

- **Tested Revision**: `ddf2e20b70e0cc9f644d562904c9a416d42c9cea`
- **Execution Date**: `2026-11-24 22:38:46Z`
- **Isolation Boundary**: Disposable full clone under `tempfile` (GH-564 compliant; no test files under `test/` per GH-831)
- **Result**: 10/10 controls PASSED

## Acceptance Criteria Results

| ID | Criterion | Result | Exit Status | Decisive Output / Note |
|---|---|:---:|:---:|---|
| **AC-0** | Red Control Replay (Pre-fix classifier fails AC-1) | PASS | 1 | Pre-fix inspect_open_handles treated Docker overlay warning as fatal enumeration failure |
| **AC-1** | lsof unrelated warning tolerance on idle checkout | PASS | 0 | `verified: True, active: False` on Docker overlay warning outside repo |
| **AC-2** | Active root-CWD holder detection + pruning refusal | PASS | 0 | `verified: True, active: True` with holder PID; scratch pruning refused removal |
| **AC-3** | Related warnings (equal, inside, ancestor, symlink) fail closed | PASS | 0 | All 4 related warning variants return `verified: False` with incomplete enumeration |
| **AC-4** | Standalone disclaimer & unclassified stderr fail closed | PASS | 0 | Standalone disclaimer and unrecognized stderr return `verified: False` |
| **AC-5** | gh version preflight before discovery (preview & execution) | PASS | 0 | Both modes emit `gh 2.18+` guidance before discovery exits; 2.18.0 passes without warning |
| **AC-6** | git version preflight before forecast | PASS | 0 | 2.34.1/2.37.9 warn `git 2.38+`; 2.38.0 passes cleanly |
| **AC-7** | _merge_tree tuple contract & diagnostic guidance | PASS | 0 | Preserves (rc, tree, paths, err); appends Git 2.38+ / ppa:git-core/ppa advice on legacy syntax |
| **AC-8** | Skills Army HQ Linux & intake init documentation | PASS | 0 | README.md and SKILL.md document POSIX/Linux support and `intake.py init` workflow |
| **AC-9** | Zero regressions in full clone (gh534 suite) | PASS | 0 | `test/gh534_phase_a_tests.py` ran 46 tests: OK (46/46 passed) |

Receipts captured in `provenance.jsonl`.
