# GH-839 Evidence — Standardized Clone Backup Layout & Integrity Verification

Adheres strictly to the moratorium on adding new CI/CD tests (GH-831). Verification was conducted via existing unmodified test suites (`test/gh436-merge-cleanup.py`, `test/gh534_phase_c_tests.py`, `test/gh589-skill-viewer.sh`) plus a recorded manual verification check:

1. **`gh589-skill-viewer.log`**: `bash test/gh589-skill-viewer.sh` — 8/8 passed, 0 failed. Verifies skill frontmatter and directory viewer integrity for both `merge-cleanup` and `merge-cleanup-deep`.
2. **`gh534-parity-guard.log`**: `PYTHONPATH=. python3 test/gh534_phase_c_tests.py TestParityGuard` — 7/7 passed, 0 failed. Verifies that `--backup-first` CLI option and capability table remain in 100% parity between `merge_cleanup.py` and `skills/2-daily/merge-cleanup/SKILL.md`.
3. **`backup-clones-verification.log`**: Manual verification check:
   - Proves standardized directory structure under `<root>/_backups/<repo>/<timestamp>/` with `zips/`, `metadata/`, `reports/`, and `SUMMARY.md`.
   - Proves cache exclusion: heavy disposable directories (`node_modules/`, `.venv/`) are excluded from archive zips, while tracked files, untracked code, and `.git/` are retained.
   - Proves `testzip()` CRC/compression check and SHA256 generation in `MANIFEST.tsv`.
   - Proves `merge_cleanup.py --backup-first` CLI integration.
