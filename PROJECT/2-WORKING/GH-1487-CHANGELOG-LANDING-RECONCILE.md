---
gh_issue: 1487
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1487
title: "Architectural Plan: Eliminate CHANGELOG.md merge conflicts via landing reconcile writer and dogfood adoption"
status: Active
created: 2026-11-15
updated: 2026-11-15
owner: Claude
doc_type: feature
complexity: 2
risk: 2
effort: 2
phases: 4
non_goals:
  - removing CHANGELOG.md from git
  - changing releases.db / releases.sql writes (#1458)
  - weekly integration branches
  - retroactive history rewriting of existing duplicate or legacy entries
goal: >
  Eliminate CHANGELOG.md serial merge conflicts across PR branches by establishing
  CHANGELOG_WRITES=off as the universal default, implementing an opt-in post-landing
  reconcile writer (CHANGELOG_WRITES=landing) in wave_reconcile.py, and dogfooding it cleanly.
---

# Plan: Eliminate CHANGELOG.md merge conflicts via landing reconcile writer and dogfood adoption (GH-1487)

- **Issue**: [HiQS-Labs/XYZ-forge#1487](https://github.com/HiQS-Labs/XYZ-forge/issues/1487)
- **Status**: 🚧 In progress
- **Global ID**: `rmi-01M7GCRVQW0G0Y45511ADW117H`
- **PRS Rating**: 85/75/70/65 (calc: 295)

## 1. Goal & Context
Currently in `HiQS-Labs/XYZ-forge`, 4 of the 8 conflicting open PRs conflict on `CHANGELOG.md` (#1444, #1417, #1416, #1413).
Requiring every PR branch to append to `CHANGELOG.md` directly causes serial merge collisions. While `skills/2-daily/merge-cleanup/scripts/ledger_merge.py` implements the B1 `union_changelog` algorithm to attempt 3-way prefix-additive union, every conflict:
1. Forces a B1 branch repair, creating a new commit on the PR branch.
2. Invalidates CI checks and requires pushing a new remote head.
3. Requires re-pinning and re-running gates, invalidating the base of subsequent PRs in a batch sequence.

This task implements the solution specified in [GH-1487](https://github.com/HiQS-Labs/XYZ-forge/issues/1487):
1. **Default is OFF:** Set `CHANGELOG_WRITES=off` (or unset) as the universal default across all repositories. Neither PR branches nor the reconciler write `CHANGELOG.md`. Zero changelog merge conflicts occur.
2. **Opt-in Landing Writer:** Implement `CHANGELOG_WRITES=landing` in `utils/py/wave_reconcile.py` (the single authoritative writer for landing mutations). It extracts the `## Changelog` section from the merged PR body, sanitizes it, and prepends a date-first entry (`## YYYY-MM-DD — <Summary> (GH-N)`) with an idempotency marker `<!-- pr:N merge:<sha> -->`.
3. **Safety & Publication Foundations:**
   - Update `utils/py/hosted_lane_publish.py:50, 80` allowlist so hosted lane runs cleanly publish changelog changes when enabled.
   - Update `skills/2-daily/merge-cleanup/scripts/ledger_merge.py:469` so the HTML idempotency comment is recognized as valid and does not trigger B1 handoff.
   - Add `CHANGELOG.md` to `wave_reconcile.py:2726` rollback journal snapshot.
   - Define an explicit cutover timestamp/commit boundary in `wave_reconcile.py:1467` to prevent replaying historical PRs or skipping un-reconciled ones during catch-up.
4. **Governance & Checks:**
   - Make `pdda-check-changelog` in `utils/pdda/pdda.sh` mode-aware: skipped in aggregate `pdda.sh run` when `CHANGELOG_WRITES` is `off` or `landing`; retains standalone `pdda.sh changelog` command for manual maintainer audits.
   - Update `ROUTER.md`, `AGENTS.md`, and `PROJECT/PDDA.md` to establish the default-off and landing opt-in semantics.
   - Update `.github/pull_request_template.md` with guidance on the optional `## Changelog` section.

## 2. Planned Changes & Code Seams

- **`utils/py/wave_reconcile.py`**:
  - Add `read_changelog_writes_mode(repo_root)` reading `.pdda-mode` (default: `off`).
  - Implement changelog extraction from PR body (`## Changelog` section up to next H2 or comment block).
  - Prepend dated entry with `<!-- pr:N merge:<sha> -->` marker if `CHANGELOG_WRITES == 'landing'`.
  - Add `CHANGELOG.md` to transactional rollback journal.
  - Set cutover boundary in catch-up recovery.
- **`utils/py/hosted_lane_publish.py`**:
  - Add `"CHANGELOG.md"` to declared artifact allowlists at lines 50 and 80.
- **`skills/2-daily/merge-cleanup/scripts/ledger_merge.py`**:
  - Permit `<!-- pr:N merge:<sha> -->` comment markers in `union_changelog` without triggering line 469 `ValueError`.
- **`utils/pdda/pdda.sh`**:
  - In `check_changelog()`, inspect `CHANGELOG_WRITES` from `.pdda-mode`: if `off` or `landing`, emit info or return 0 during aggregate `cmd_run()`, while keeping standalone `pdda.sh changelog` operational.
- **`PROJECT/PDDA.md`, `ROUTER.md`, `AGENTS.md`, `.github/pull_request_template.md`**:
  - Document `CHANGELOG_WRITES` configuration (`off|landing|branch`), default-off behavior, and PR template guidance.

## 3. Acceptance & Verification
- [ ] When `CHANGELOG_WRITES=off` (or unset), neither PR branches nor `wave_reconcile.py` write `CHANGELOG.md`.
- [ ] When `CHANGELOG_WRITES=landing`, a merged PR with `## Changelog` produces exactly one dated entry in `CHANGELOG.md` with the `pr:N` marker.
- [ ] Re-running `wave_reconcile.py` on an already reconciled PR writes nothing (idempotent).
- [ ] In `landing` mode, a PR without `## Changelog` falls back to the PR title and logs `fallback-title`.
- [ ] `ledger_merge.py:union_changelog` handles entries containing the HTML idempotency marker without raising a `ValueError`.
- [ ] `hosted_lane_publish.py` allowlist includes `CHANGELOG.md`.
- [ ] `wave_reconcile.py` rollback journal restores `CHANGELOG.md` if reconciliation fails midway.
- [ ] All existing test suites pass (`pytest tests/`, `utils/pdda/pdda.sh run`, and releases check clean).
