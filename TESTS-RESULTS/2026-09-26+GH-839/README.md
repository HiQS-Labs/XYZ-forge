# GH-839 Evidence — Standardized Clone Backup Layout & Integrity Verification

Adheres strictly to the moratorium on adding new CI/CD tests (GH-831). Verification was conducted via existing unmodified test suites (`test/gh534_phase_c_tests.py`, `test/gh589-skill-viewer.sh`) plus a committed, reproducible production falsifier test script (`python3 TESTS-RESULTS/2026-09-26+GH-839/verify_production.py`):

1. **`gh589-skill-viewer.log`**: `bash test/gh589-skill-viewer.sh` — 8/8 passed, 0 failed. Verifies skill frontmatter and directory viewer integrity for both `merge-cleanup` and `merge-cleanup-deep`.
2. **`gh534-parity-guard.log`**: `PYTHONPATH=. python3 test/gh534_phase_c_tests.py TestParityGuard` — 7/7 passed, 0 failed. Verifies that `--backup-first` CLI option and capability table remain in 100% parity between `merge_cleanup.py` and `skills/2-daily/merge-cleanup/SKILL.md`.
3. **`backup-clones-verification.log`**: `python3 TESTS-RESULTS/2026-09-26+GH-839/verify_production.py` — 38 asserts passed (executed in disposable full clone `/tmp/gh839-disposable-clone`):
   - Proves Git refs and 100% source preservation (R3-1): `zf.read()` asserts byte-for-byte read equality for root `build/release.py`, `dist/source.py`, `target/config.py`, nested `src/env/config.py`, and loose `.git` refs (`node_modules/topic`, `venv/topic`, `build/topic`), while working-tree `node_modules/pkg/index.js` is excluded and `manifest.json` records `git_metadata_exempt=True`.
   - Proves zip integrity check and corrupt archive detection (R3-2 / R5-1): `test_zip_integrity()` detects invalid header format and real on-disk payload CRC mismatch (computed strictly within payload data); direct `zf.read()` confirms underlying `BadZipFile: Bad CRC-32 for file 'test_crc.txt'`.
   - Proves fail-closed refusal of linked worktrees with external Git storage under `--backup-first` (R3-3 / R2-2).
   - Proves atomic O_EXCL run directory allocation and duplicate basename disambiguation under sequential/repeated runs (R3-4 / R2-4).
   - Proves production `merge_cleanup.main()` Phase 6 teardown gate (R3-5 / R2-3 / R5-1):
     - Negative Control 1: linked worktree refused, clone preserved, exits 2.
     - Negative Control 2: real on-disk CRC payload corruption caught by `test_zip_integrity()`; direct `zf.read()` confirms `BadZipFile: Bad CRC-32 for file 'corrupt_clone/README.md'`; clone preserved, exits 2.
     - Positive Control: clean standalone clone backed up, verified, and torn down into Trash (exit 0).
     - Direct contract assertion: stale scan record refused by `teardown_checkout()`.
4. **`backup-clones-red.log`**: Witnessed red control (executed in disposable full clone `/tmp/gh839-disposable-clone`):
   - Mutating `merge_cleanup.py` to bypass the `verified_paths` filter on `removable` causes production `merge_cleanup.main()` to remove the unverified candidate (`wt_clone`), causing `assert wt_clone.exists()` to fail with `AssertionError: Refused linked worktree must be preserved from teardown!` and exit code 1. Restoring `merge_cleanup.py` restores all assertions to green (exit code 0).



