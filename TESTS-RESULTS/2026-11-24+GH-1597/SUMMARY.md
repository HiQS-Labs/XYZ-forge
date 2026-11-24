# Verification Controls Summary — GH-1597

- **Tested Candidate Revision**: `ad09619b613bec7567cee532c49bde4c31089773`
- **Baseline Replay Revision**: `ddf2e20b7`
- **Execution Date**: `2026-11-24 22:45:56Z`
- **Isolation Boundary**: Disposable full clone under `tempfile` (GH-564 compliant; zero test sprawl under `test/` per GH-831)
- **Clone Identity Verified**:
  - `core.bare`: `false`
  - Pre-run HEAD: `ad09619b613bec7567cee532c49bde4c31089773`
  - Post-run HEAD: `ad09619b613bec7567cee532c49bde4c31089773` (unchanged: True)
  - Pre/post status: clean (0 untracked, 0 dirty)
- **Result**: 10/10 controls PASSED

## Acceptance Criteria Results

| ID | Criterion | Result | Exit Status | Decisive Output / Note |
|---|---|:---:|:---:|---|
| **AC-0** | Red Control Replay (Pre-fix classifier fails AC-1) | PASS | 1 | Pre-fix inspect_open_handles extracted from `ddf2e20b7` returned `verified: False, active: False` on Docker overlay warning |
| **AC-1** | lsof unrelated warning tolerance on idle checkout | PASS | 0 | Candidate returned `verified: True, active: False` on Docker overlay warning outside repo |
| **AC-2** | Active root-CWD holder detection + real pruning refusal | PASS | 0 | `_remove_own_scratch` deleted idle scratch (`idle_deleted=True`) but refused held scratch (`held_kept=True`, reason names holder PID) |
| **AC-3** | Related warnings (equal, inside, ancestor, symlink) fail closed | PASS | 0 | All 4 related warning variants return `verified: False` with incomplete enumeration |
| **AC-4** | Standalone disclaimer & unclassified stderr fail closed | PASS | 0 | Standalone disclaimer and unrecognized stderr return `verified: False` |
| **AC-5** | gh version preflight before discovery (preview & execution) | PASS | 0 | Both modes exit 2 and emit `gh 2.18+` guidance before discovery failure; supported 2.18.0 exits 0 without warning |
| **AC-6** | git version preflight before forecast | PASS | 0 | CLI preview with 3 PRs under git 2.37.9 emits warning before forecast; git 2.38.0 passes without warning |
| **AC-7** | _merge_tree tuple contract & diagnostic guidance | PASS | 0 | Preserves (rc, tree, paths, err); appends Git 2.38+ / ppa:git-core/ppa advice on legacy syntax |
| **AC-8** | Skills Army HQ Linux & intake init documentation | PASS | 0 | README.md and SKILL.md document POSIX/Linux support and `intake.py init` workflow |
| **AC-9** | Zero regressions in full clone (gh534 suite) | PASS | 0 | `test/gh534_phase_a_tests.py` ran 46 tests: OK (46/46 passed). Decisive: `---------------------------------------------------------------------- | Ran 46 tests in 24.931s | OK` |

Receipts captured in `provenance.jsonl`.
