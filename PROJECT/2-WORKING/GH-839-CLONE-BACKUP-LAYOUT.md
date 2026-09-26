---
title: "GH-839: feat(skills): standardize clone backup layout and integrity verification for merge-cleanup-deep and merge-cleanup"
status: Active (2-WORKING)
gh_issue: 839
source: https://github.com/HiQS-Labs/XYZ-forge/issues/839
doc_type: enhancement
created: 2026-09-26
updated: 2026-09-26
owner: Antigravity
complexity: 2
risk: 1
effort: 2
goal: >
  Standardize clone backup layout and integrity verification in merge-cleanup-deep
  and merge-cleanup to expedite aggressive clone deletion without data loss risk.
---

# GH-839 — feat(skills): standardize clone backup layout and integrity verification for merge-cleanup-deep and merge-cleanup

## Status

| What was just completed | What's next |
|---|---|
| Implemented `backup_clones.py` utility and `--backup-first` CLI option in `merge_cleanup.py`. Updated `skills/3-weekly/merge-cleanup-deep/SKILL.md` and `skills/2-daily/merge-cleanup/SKILL.md`. Verified with `TestParityGuard` (7/7 pass), `gh589-skill-viewer.sh` (8/8 pass), and production falsifiers in disposable full clone testing R3-1 through R3-5 (34 asserts passing green, witnessed red control) in `TESTS-RESULTS/2026-09-26+GH-839/`. | Codex final QA relay Round 5, commit diff, push branch, and open ready PR against `development`. |

## Context & Problem Statement

To expedite deletion of full clone folders so operators do not have to worry about aggressive teardown, `/merge-cleanup-deep` and `/merge-cleanup` require an automated, standardized backup system.

Previous work (GH-728) introduced an ad-hoc inline bash backup snippet in `skills/3-weekly/merge-cleanup-deep/SKILL.md` (`cd ... && zip ...`), which dumped flat zip files into `~/Documents/Backups/<repo>-clones-<date>/` without structured subdirectories, integrity validation, or cache exclusions, and `/merge-cleanup` lacked a `--backup-first` option for direct safe teardown.

## Requirements

1. **Standardized Directory Structure**:
   Archives are placed in the top-level GitHub folder under `<top_level>/_backups/<repo-name>/<YYYY-MM-DD_HHMMSS>/`:
   - `zips/`: Individual `<clone>.zip` archives.
   - `metadata/`: `MANIFEST.tsv`, `manifest.json`, and per-clone summaries (`<clone>.git-summary.txt` containing branch, HEAD, commit log, unpushed commits, and porcelain status).
   - `reports/`: Deep-scan agent triage reports and teardown logs.
   - `SUMMARY.md`: Human-readable markdown manifest index.
2. **Dedicated Python Engine**:
   - `skills/2-daily/merge-cleanup/scripts/backup_clones.py` providing deterministic, reusable backup functionality.
3. **Integrity Gate Before Teardown**:
   - `testzip()` CRC/compression check and SHA256 verification before a clone is approved for teardown.
4. **Cache Pruning**:
   - Excludes heavy disposable package and cache directories (`node_modules/`, `.venv/`, `venv/`, `__pycache__/`, `.pytest_cache/`, `.mypy_cache/`, `.ruff_cache/`, `.parcel-cache/`, `.cache/`, `.DS_Store`) while preserving `.git/` and all working tree source code (including build/, dist/, and target/ directories).
5. **Aggressive Teardown Integration**:
   - Add `--backup-first` flag to `merge_cleanup.py`.
6. **No New Tests in CI/CD**:
   - Strictly honor the moratorium on adding new CI/CD tests.
