# GH-839 Evidence — Standardized Clone Backup Layout & Integrity Verification

Adheres strictly to the moratorium on adding new CI/CD tests (GH-831). Verification was conducted via existing unmodified test suites (`test/gh534_phase_c_tests.py`, `test/gh589-skill-viewer.sh`) plus a committed, reproducible production falsifier test script (`python3 TESTS-RESULTS/2026-09-26+GH-839/verify_production.py`):

1. **`gh589-skill-viewer.log`**: `bash test/gh589-skill-viewer.sh` — 8/8 passed, 0 failed. Verifies skill frontmatter and directory viewer integrity for both `merge-cleanup` and `merge-cleanup-deep`.
2. **`gh534-parity-guard.log`**: `PYTHONPATH=. python3 test/gh534_phase_c_tests.py TestParityGuard` — 7/7 passed, 0 failed. Verifies that `--backup-first` CLI option and capability table remain in 100% parity between `merge_cleanup.py` and `skills/2-daily/merge-cleanup/SKILL.md`.
3. **`backup-clones-verification.log`**: `python3 TESTS-RESULTS/2026-09-26+GH-839/verify_production.py` — 16 asserts passed:
   - Proves Git refs preservation: `.git/refs/heads/node_modules/topic`, `.git/refs/heads/venv/topic`, and `.git/refs/heads/build/topic` are byte-for-byte preserved in `.git`, while working-tree `node_modules/pkg/index.js` is excluded and `src/env/config.py` is retained (R2-1).
   - Proves fail-closed refusal of linked worktrees with external Git storage under `--backup-first` (R2-2).
   - Proves atomic O_EXCL run directory allocation and duplicate basename disambiguation under concurrent/repeated runs (R2-4).
   - Proves production `merge_cleanup.main()` Phase 6 teardown gate: refused/corrupt candidates are withheld from teardown and exit with code 2, while clean standalone candidates are verified, backed up, and torn down with exit code 0 (R2-3).
   - Proves direct `teardown_checkout` contract safety (stale inspection records refused).
