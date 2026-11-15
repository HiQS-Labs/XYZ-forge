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

## Status

| Phase | Description | Status |
|---|---|---|
| Phase 1 | Foundation & Safety: allowlist, B1 marker coexistence, rollback snapshot | ⏳ Ready |
| Phase 2 | Reconciler Engine & Cutover Recovery (`wave_reconcile.py`) | ⏳ Ready |
| Phase 3 | Configuration parsing (`.pdda-mode`), branch-writer audit & governance docs | ⏳ Ready |
| Phase 4 | Verification (red controls, idempotent retry, publication) & Forge Dogfood | ⏳ Ready |

## 1. Goal & Context
Currently in `HiQS-Labs/XYZ-forge`, 4 of the 8 conflicting open PRs conflict on `CHANGELOG.md` (#1444, #1417, #1416, #1413).
Requiring every PR branch to append to `CHANGELOG.md` directly causes serial merge collisions. While `skills/2-daily/merge-cleanup/scripts/ledger_merge.py` implements the B1 `union_changelog` algorithm to attempt 3-way prefix-additive union, every conflict:
1. Forces a B1 branch repair, creating a new commit on the PR branch.
2. Invalidates CI checks and requires pushing a new remote head.
3. Requires re-pinning and re-running gates, invalidating the base of subsequent PRs in a batch sequence.

This task implements the solution specified in [GH-1487](https://github.com/HiQS-Labs/XYZ-forge/issues/1487), addressing all Codex Plan QA findings:
1. **Universal Default is OFF (`CHANGELOG_WRITES=off`):** When unset or `off`, PR branches do not write `CHANGELOG.md`, the reconciler writes nothing, and `pdda.sh run` omits aggregate changelog warnings.
2. **Opt-in Landing Writer (`CHANGELOG_WRITES=landing`):** Authoritative single writer in `utils/py/wave_reconcile.py` synthesizes `CHANGELOG.md` from merged PR descriptions at landing time.
3. **Legacy Mode (`CHANGELOG_WRITES=branch`):** Preserves legacy branch-level changelog updates and aggregate checks for repositories that explicitly request it.

---

## 2. Recon & Code Seams

- **Reconcile Writer & Snapshot (`utils/py/wave_reconcile.py:1935, 2546`):**
  - `snapshot_ledger_artifacts(repo_root, dry_run, journal)` must snapshot `CHANGELOG.md` (or track as created if absent) **before** any write happens, enabling transactional rollback on failure.
  - Writer executes only for merged PRs (`pr['merged_at'] is not None`). Direct commits or unmerged PRs are not synthesized into changelog entries.
- **Separate Cutover Boundary (`utils/py/wave_reconcile.py:1490`):**
  - Existing `unreconciled_prs()` derives lifecycle qualification work from `committed_qualifications()`.
  - The changelog writer must NOT hijack or move that activation boundary. Instead, changelog reconciliation uses an independent forward timestamp / commit cutover boundary (`changelog_cutover_boundary`), checking whether the PR's exact idempotency marker is already present in `CHANGELOG.md`.
- **B1 Marker Coexistence (`skills/2-daily/merge-cleanup/scripts/ledger_merge.py:469`):**
  - Currently line 469 rejects all `"<!--"` and `<` additions with `ValueError("fenced or HTML additions require manual changelog resolution")`.
  - Must explicitly permit the generated idempotency marker `<!-- pr:N merge:[0-9a-f]+ -->` at the expected heading position while continuing to reject all other HTML or fenced blocks.
- **Hosted Publication Allowlist (`utils/py/hosted_lane_publish.py:50`):**
  - Add `'CHANGELOG.md'` to `EXACT` allowlist so hosted lane runs cleanly publish changelog changes alongside qualification receipts.
  - Raced pushes recompute the reconcile write against the updated integration tip, preserving already-committed entries.
- **Branch-Writing Skills & Distributed Templates:**
  - `skills/2-daily/express/SKILL.md:29, 176` and `skills/4-occasional/install-improve-audit/SKILL.md:392` instruct branch authors to append to `CHANGELOG.md`. Update them to respect `CHANGELOG_WRITES` (skip on `off` and `landing`; execute only on `branch`).
- **Deterministic Check Gating (`utils/pdda/pdda.sh:1711`):**
  - Update `check_changelog()` in `pdda.sh`: check `.pdda-mode`. In `off` or `landing` mode, skip aggregate warnings during `cmd_run()`; retain standalone `pdda.sh changelog` command for manual audits.

---

## 3. Detailed Architectural Specifications

### A. Configuration Parsing & Precedence
- **Precedence:** `CHANGELOG_WRITES` environment variable takes precedence over `.pdda-mode` file.
- **Allowed values:** `off` (default), `landing`, `branch`.
- **Invalid value handling:** Warn to stderr, fall back safely to `off`.
- **Parsing:** Consistent parser implemented in Python (`wave_reconcile.py`) and Shell (`pdda.sh`).

### B. Input Sanitization & Formatting
- **Extraction:** Extract text under `## Changelog` (case-insensitive) up to the next Markdown H2 (`## `) or HTML comment.
- **Sanitization:**
  - Strip HTML comments to prevent marker forgery.
  - Strip conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`).
  - Strip or down-level internal H1/H2 headings.
  - Trim leading/trailing whitespace.
- **Fallback:** If section is absent or empty, use PR title with explicit flag: `changelog: fallback-title`.
- **Format:**
  ```markdown
  ## YYYY-MM-DD — <Summary> (GH-N)

  <!-- pr:N merge:<sha> -->
  <Sanitized body>
  ```
  Heading date strictly uses `pr['merged_at']` in UTC (`YYYY-MM-DD`).
- **Placement:** Inserted immediately after the preamble and before the first existing `## ` heading.

### C. Idempotency & Transactional Safety
- **Idempotency check:** `<!-- pr:N merge: -->` regex check against existing `CHANGELOG.md` text. If already present, write nothing.
- **Transaction:** `snapshot_ledger_artifacts` captures `CHANGELOG.md` in `journal` before modification. Any unhandled exception during landing triggers journal rollback.
- **Dry Run:** When `--dry-run` is active, write nothing to disk.

---

## 4. Phased Implementation Plan

### Phase 1: Foundation & Safety Surfaces
1. Add `'CHANGELOG.md'` to `EXACT` in `utils/py/hosted_lane_publish.py`.
2. Update `skills/2-daily/merge-cleanup/scripts/ledger_merge.py` line 469: permit `<!-- pr:N merge:[0-9a-f]+ -->` while strictly rejecting other HTML/fenced blocks.
3. Update `wave_reconcile.py:snapshot_ledger_artifacts` to include `CHANGELOG.md`.

### Phase 2: Reconciler Engine & Independent Recovery
1. Add `read_changelog_writes_mode()` in `wave_reconcile.py`.
2. Implement `extract_changelog_section(body, pr_title)` with sanitization and heading generation.
3. Implement `reconcile_changelog_entry(repo_root, pr, merge_sha, dry_run, journal)`.
4. Integrate into `wave_reconcile.py` merged-PR landing loop with separate cutover boundary and marker presence check.

### Phase 3: Governance, Skills & Deterministic Checks
1. Update `skills/2-daily/express/SKILL.md` and `skills/4-occasional/install-improve-audit/SKILL.md` to make branch changelog edits conditional on `CHANGELOG_WRITES=branch`.
2. Update `utils/pdda/pdda.sh:check_changelog` to skip aggregate checks when `CHANGELOG_WRITES` is `off` or `landing`.
3. Update `PROJECT/PDDA.md`, `ROUTER.md`, `AGENTS.md`, and `.github/pull_request_template.md`.
4. Update `utils/pdda/pdda-install.sh` and `utils/pdda/pdda-sync-manifest.conf`.

### Phase 4: Dogfood & Verification
1. Add manual test runner with red controls under `TESTS-RESULTS/2026-11-15+GH-1487/`:
   - Red control: Verify default is `off` (no write on merge).
   - Red control: Verify invalid config falls back to `off`.
   - Red control: Verify `landing` writes sanitized entry with marker.
   - Red control: Verify idempotency (second run writes 0 bytes).
   - Red control: Verify B1 accepts generated marker and rejects malicious HTML.
   - Red control: Verify journal rollback restores original file on simulated error.
2. Run existing suites: `pytest -m nodb tests/` and `utils/pdda/pdda.sh run`.
3. Retain test outputs and `provenance.jsonl`.

---

## 5. Acceptance & Verification

- [ ] **Default is OFF:** In the absence of config or when `CHANGELOG_WRITES=off`, no changelog write occurs during landing, and `pdda.sh run` aggregate check skips warnings.
- [ ] **Landing Writer:** When `CHANGELOG_WRITES=landing`, a merged PR produces exactly one dated entry with `<!-- pr:N merge:<sha> -->`.
- [ ] **Idempotency:** Re-running reconciliation on an already-reconciled PR writes nothing.
- [ ] **Fallback:** A PR without `## Changelog` falls back to the PR title with `fallback-title`.
- [ ] **Sanitization:** HTML comments, forged markers, and H1/H2 headings in PR bodies are sanitized/stripped.
- [ ] **B1 Coexistence:** `ledger_merge.py:union_changelog` accepts the exact generated marker without raising a `ValueError`, but still rejects other HTML additions.
- [ ] **Allowlist:** `hosted_lane_publish.py:EXACT` includes `CHANGELOG.md`.
- [ ] **Rollback:** `wave_reconcile` rollback journal snapshots `CHANGELOG.md` before write and restores original on failure.
- [ ] **Legacy Preservation:** When `CHANGELOG_WRITES=branch`, legacy behavior is fully retained.
- [ ] **Suites & Gates:** All existing test suites pass.
