# Verification Controls Summary — GH-1597

- **Tested Candidate Revision**: `6aa3b82b473ff5dc8e2a8e427817fc8ade44c938`
- **Baseline Replay Revision**: `ddf2e20b7`
- **Execution Date**: `2026-11-24 22:51:01Z`
- **Isolation Boundary**: Disposable full clone under `tempfile` (GH-564 compliant; zero test sprawl under `test/` per GH-831)
- **Clone Identity Verified (Pre & Post Suite)**:
  - `core.bare`: `false` == `false` (unchanged: True)
  - `user.email`: `test@example.com` == `test@example.com` (unchanged: True)
  - `remotes`: verified matching
  - Pre-run HEAD: `6aa3b82b473ff5dc8e2a8e427817fc8ade44c938`
  - Post-run HEAD: `6aa3b82b473ff5dc8e2a8e427817fc8ade44c938` (unchanged: True)
  - Pre/post status: clean (0 untracked, 0 dirty)
- **Result**: 10/10 controls PASSED

## Acceptance Criteria Results

| ID | Criterion | Result | Exit Status | Decisive Output / Note |
|---|---|:---:|:---:|---|
| **AC-0** | Red Control Replay (Pre-fix classifier fails AC-1) | PASS | 1 | Pre-fix inspect_open_handles extracted from `ddf2e20b7` executed against real lsof wrapper returned `verified: False, active: False` on overlay warning |
| **AC-1** | lsof unrelated warning tolerance on idle checkout | PASS | 0 | Candidate executed against real lsof wrapper returned `verified: True, active: False` |
| **AC-2** | Real holder enumeration (CWD & file) + pruning refusal | PASS | 0 | Real lsof detected both CWD holder PID 36066 & file holder PID 36067; `_remove_own_scratch` deleted idle scratch (`idle_deleted=True`) but refused removal on both held checkouts (`held_cwd_kept=True`, `held_file_kept=True`) |
| **AC-3** | Related warnings (equal, inside, ancestor, symlink) fail closed | PASS | 0 | All 4 related warning variants return `verified: False` with incomplete enumeration |
| **AC-4** | Standalone disclaimer & unclassified stderr fail closed | PASS | 0 | Standalone disclaimer and unrecognized stderr return `verified: False` |
| **AC-5** | gh version preflight before discovery (preview & execution) | PASS | 0 | Both modes exit 2 and emit `gh 2.18+` guidance before discovery failure; supported 2.18.0 exits 0 without warning |
| **AC-6** | git version preflight before forecast | PASS | 0 | Actual function entry sequence `["version_check", "build_forecast"]` observed; 2.37.9 warns before forecast; 2.38.0 clean |
| **AC-7** | _merge_tree tuple contract & diagnostic guidance | PASS | 0 | Preserves (rc, tree, paths, err); appends Git 2.38+ / ppa:git-core/ppa advice on legacy syntax |
| **AC-8** | Skills Army HQ Linux & intake init documentation | PASS | 0 | README.md and SKILL.md document POSIX/Linux support and `intake.py init` workflow |
| **AC-9** | Zero regressions in full clone (gh534 suite) | PASS | 0 | `test/gh534_phase_a_tests.py` ran 46 tests: OK (46/46 passed). Decisive: `---------------------------------------------------------------------- | Ran 46 tests in 25.417s | OK` |

Receipts captured in `provenance.jsonl`.
