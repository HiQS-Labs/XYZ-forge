# GH-839 Evidence — Standardized Clone Backup Layout & Integrity Verification

Adheres strictly to the moratorium on adding new CI/CD tests (GH-831). Verification was conducted via existing unmodified test suites (`test/gh534_phase_c_tests.py`, `test/gh589-skill-viewer.sh`) plus a committed, reproducible production falsifier test script (`python3 TESTS-RESULTS/2026-09-26+GH-839/verify_production.py`):

1. **`gh589-skill-viewer.log`**: `bash test/gh589-skill-viewer.sh` — 8/8 passed, 0 failed. Verifies skill frontmatter and directory viewer integrity for both `merge-cleanup` and `merge-cleanup-deep`.
2. **`gh534-parity-guard.log`**: `PYTHONPATH=. python3 test/gh534_phase_c_tests.py TestParityGuard` — 7/7 passed, 0 failed. Verifies that `--backup-first` CLI option and capability table remain in 100% parity between `merge_cleanup.py` and `skills/2-daily/merge-cleanup/SKILL.md`.
3. **`backup-clones-verification.log`**: `python3 TESTS-RESULTS/2026-09-26+GH-839/verify_production.py` — 33 asserts passed:
   - Proves Git refs and 100% source preservation (R3-1): `zf.read()` asserts byte-for-byte read equality for root `build/release.py`, `dist/source.py`, `target/config.py`, nested `src/env/config.py`, and loose `.git` refs (`node_modules/topic`, `venv/topic`, `build/topic`), while working-tree `node_modules/pkg/index.js` is excluded and `manifest.json` records `git_metadata_exempt=True`.
   - Proves zip integrity check and corrupt archive detection (R3-2): `test_zip_integrity()` detects CRC/header corrupted archive and fails closed.
   - Proves fail-closed refusal of linked worktrees with external Git storage under `--backup-first` (R3-3 / R2-2).
   - Proves atomic O_EXCL run directory allocation and duplicate basename disambiguation under concurrent/repeated runs (R3-4 / R2-4).
   - Proves production `merge_cleanup.main()` Phase 6 teardown gate (R3-5 / R2-3):
     - Negative Control 1: linked worktree refused, clone preserved, exits 2.
     - Negative Control 2: simulated corrupt archive refused, clone preserved, exits 2.
     - Red Control Witnessed: un-guarded `teardown_checkout()` proceeds and deletes candidate, proving the Phase 6 gate is load-bearing.
     - Positive Control: clean standalone clone backed up, verified, and torn down into Trash (exit 0).
     - Direct contract assertion: stale scan record refused by `teardown_checkout()`.

