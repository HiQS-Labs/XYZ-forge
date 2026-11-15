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

| Phase | Description | Observable Gate | Status |
|---|---|---|---|
| Phase 1 | Foundation & Safety: allowlist, B1 marker coexistence, pre-write rollback snapshot | `python3 -m unittest test/gh534_phase_b_tests.py` passes; B1 accepts generated marker and rejects malicious HTML | ⏳ Ready |
| Phase 2 | Reconciler Engine & Dedicated Cutover Recovery (`wave_reconcile.py`) | `bash test/wave-reconcile.sh` passes; dry-run/off writes nothing; landing writes exact dated section with marker | ⏳ Ready |
| Phase 3 | Config Parser, Distributed Templates & Governance Updates | `bash test/pdda-run.sh` & `utils/pdda/pdda.sh run` pass; distributed templates updated | ⏳ Ready |
| Phase 4 | Verification (Manual Red Controls & Provenance) & Forge Dogfood Adoption | Manual red controls pass under `TESTS-RESULTS/2026-11-15+GH-1487/provenance.jsonl`; full `./validate.sh` passes | ⏳ Ready |

---

## 1. Goal & Context
Currently in `HiQS-Labs/XYZ-forge`, 4 of the 8 conflicting open PRs conflict on `CHANGELOG.md` (#1444, #1417, #1416, #1413).
Requiring every PR branch to append to `CHANGELOG.md` directly causes serial merge collisions. While `skills/2-daily/merge-cleanup/scripts/ledger_merge.py` implements the B1 `union_changelog` algorithm to attempt 3-way prefix-additive union, every conflict:
1. Forces a B1 branch repair, creating a new commit on the PR branch.
2. Invalidates CI checks and requires pushing a new remote head.
3. Requires re-pinning and re-running gates, invalidating the base of subsequent PRs in a batch sequence.

This task implements the solution specified in [GH-1487](https://github.com/HiQS-Labs/XYZ-forge/issues/1487), addressing all Codex Plan QA Round 1 and Round 2 findings:
1. **Universal Default is OFF (`CHANGELOG_WRITES=off`):** When unset or `off`, PR branches do not write `CHANGELOG.md`, the reconciler writes nothing, and `pdda.sh run` omits aggregate changelog warnings.
2. **Opt-in Landing Writer (`CHANGELOG_WRITES=landing`):** Authoritative single writer in `utils/py/wave_reconcile.py` synthesizes `CHANGELOG.md` from merged PR descriptions at landing time.
3. **Legacy Mode (`CHANGELOG_WRITES=branch`):** Preserves legacy branch-level changelog updates and aggregate checks for repositories that explicitly request it.

---

## 2. Recon & Code Seams

- **Landing PR Metadata Contract (`utils/py/wave_reconcile.py:390-420, 2510-2565`):**
  - In `wave_reconcile.py`, PR metadata is fetched via `gh pr view --json number,title,body,state,mergedAt,mergeCommit` (normalized to dictionary `pr_meta`).
  - Merged check strictly tests: `pr_meta.get("state") == "MERGED"` and non-empty `pr_meta.get("mergedAt")` and real PR identity (`number > 0`). Synthetic direct commits or unmerged PRs are never processed by the changelog writer.
- **Pre-write Snapshot & Rollback (`utils/py/wave_reconcile.py:1935`):**
  - `snapshot_ledger_artifacts(repo_root, dry_run, journal)` must snapshot `CHANGELOG.md` (or call `journal.track_created` if absent) **before** any write happens. If reconciliation errors out, `journal.rollback()` cleanly restores or deletes `CHANGELOG.md`.
- **Dedicated Changelog Cutover Boundary (`utils/py/wave_reconcile.py:1490`):**
  - `unreconciled_prs()` recovers lifecycle qualification receipts using `committed_qualifications()`.
  - The changelog writer does **not** modify this qualification activation boundary. Instead, changelog catch-up uses an independent forward boundary (`changelog_cutover_iso`), checking whether the PR's exact marker `<!-- pr:<number> merge:<sha> -->` is already present in `CHANGELOG.md`. Pre-cutover PRs or already-recorded PRs are skipped without altering qualification recovery.
- **B1 Marker Coexistence (`skills/2-daily/merge-cleanup/scripts/ledger_merge.py:469`):**
  - Currently line 469 rejects all `"<!--"` and `<` additions with `ValueError("fenced or HTML additions require manual changelog resolution")`.
  - Must explicitly permit the generated idempotency marker `<!-- pr:[0-9]+ merge:[0-9a-f]+ -->` at the expected position immediately following the entry heading, while strictly rejecting any other HTML tags or fenced code blocks.
- **Hosted Publication Allowlist & Retry Seam (`utils/py/hosted_lane_publish.py:50, 225-245`):**
  - Add `'CHANGELOG.md'` to `EXACT` allowlist so hosted lane runs cleanly publish changelog changes.
  - On raced pushes, `hosted_lane_publish.py` re-runs `wave_reconcile.py` via `recompute()` against the refreshed integration tip. Because the writer re-reads the updated `CHANGELOG.md` from the newly fetched base and checks exact markers, it prepends the new entry without duplicating or clobbering concurrent landings. If the bounded retries exhaust, publication halts without corrupting git state.
- **Branch-Writing Skills & Distributed Templates:**
  - `skills/2-daily/express/SKILL.md:29, 176` and `skills/4-occasional/install-improve-audit/SKILL.md:392`: Update instructions to make branch changelog edits conditional on `CHANGELOG_WRITES=branch`.
  - `utils/pdda/templates/ROUTER.target.md:40` and `utils/pdda/templates/ROUTER.releases.target.md:39`: Update distributed templates to document that PR branches do not edit `CHANGELOG.md` unless `CHANGELOG_WRITES=branch`.
- **Deterministic Check Gating (`utils/pdda/pdda.sh:1711`):**
  - Update `check_changelog()` in `pdda.sh`: check `.pdda-mode`. In `off` or `landing` mode, skip aggregate warnings during `cmd_run()`; retain standalone `pdda.sh changelog` command for manual audits.

---

## 3. Detailed Architectural Specifications

### A. Configuration Parsing & Precedence
- **File Format in `.pdda-mode`:**
  - Plain key-value lines: `CHANGELOG_WRITES=<value>` alongside existing enforcement mode and `ROADMAP_SOURCE=releases`.
  - Comments (`#`) and empty lines ignored. Duplicate lines: last non-empty value wins.
- **Precedence:**
  1. Environment variable `CHANGELOG_WRITES` (if set).
  2. Setting in `.pdda-mode` (if present).
  3. Built-in default: `off`.
- **Allowed values:** `off`, `landing`, `branch` (case-insensitive, trimmed).
- **Invalid value handling:** If value is unknown or malformed, log a warning to stderr and safely fall back to `off`.
- **Parsing:** Consistent parser implemented in Python (`wave_reconcile.py`) and Shell (`pdda.sh`).

### B. Input Sanitization & Formatting
- **Extraction:** Extract text under `## Changelog` (case-insensitive) up to the next Markdown H2 (`## `) or HTML comment.
- **Sanitization:**
  - Strip all HTML comments (`<!-- ... -->`) from author input to prevent marker forgery.
  - Strip conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`).
  - Strip or down-level internal H1/H2 headings (`# `, `## `) to bullet points or bold text to prevent breaking section hierarchy.
  - Strip leading/trailing whitespace.
  - Sanitize PR title for heading summary (strip newlines, backticks, control characters).
- **Fallback:** If section is absent or empty, use sanitized PR title with explicit flag: `changelog: fallback-title`.
- **Format:**
  ```markdown
  ## YYYY-MM-DD — <Sanitized Summary> (GH-N)

  <!-- pr:N merge:<sha> -->
  <Sanitized body>
  ```
  Heading date strictly uses `pr_meta['mergedAt']` converted to UTC (`YYYY-MM-DD`).
- **Placement:** Inserted immediately after the preamble (identified by first `## ` heading) and before existing history, retaining exact byte-for-byte history integrity.

### C. Idempotency & Transactional Safety
- **Idempotency check:** Search existing `CHANGELOG.md` for exact regex `(?m)^<!-- pr:<number> merge:[0-9a-f]+ -->`. If found, write nothing.
- **Transaction:** `snapshot_ledger_artifacts` captures `CHANGELOG.md` in `journal` before modification. Any unhandled exception during landing triggers journal rollback.
- **Dry Run:** When `--dry-run` is active, write nothing to disk.

---

## 4. Phased Implementation Plan

### Phase 1: Foundation & Safety Surfaces
1. Add `'CHANGELOG.md'` to `EXACT` in `utils/py/hosted_lane_publish.py`.
2. Update `skills/2-daily/merge-cleanup/scripts/ledger_merge.py:469`: permit the exact generated marker line `(?m)^<!-- pr:[0-9]+ merge:[0-9a-f]+ -->$` while strictly rejecting all other HTML/fenced blocks.
3. Update `wave_reconcile.py:snapshot_ledger_artifacts` to include `CHANGELOG.md` in pre-write snapshotting.
*Gate:* Run `python3 -m unittest test/gh534_phase_b_tests.py` and dedicated unit assertion proving B1 accepts generated marker and rejects malicious HTML.

### Phase 2: Reconciler Engine & Independent Recovery
1. Implement `read_changelog_writes_mode(repo_root)` in `wave_reconcile.py`.
2. Implement `extract_changelog_section(body, pr_title)` with sanitization, heading generation, and idempotency comment injection.
3. Implement `reconcile_changelog_entry(repo_root, pr_meta, merge_sha, dry_run, journal)`.
4. Integrate into `wave_reconcile.py` merged-PR landing loop with separate cutover boundary and marker presence check.
*Gate:* Run `bash test/wave-reconcile.sh` ensuring all existing reconcile behavior passes cleanly.

### Phase 3: Governance, Distributed Templates & Deterministic Checks
1. Update `skills/2-daily/express/SKILL.md` and `skills/4-occasional/install-improve-audit/SKILL.md` to make branch changelog edits conditional on `CHANGELOG_WRITES=branch`.
2. Update distributed templates `utils/pdda/templates/ROUTER.target.md` and `utils/pdda/templates/ROUTER.releases.target.md`.
3. Update `utils/pdda/pdda.sh:check_changelog` to skip aggregate checks when `CHANGELOG_WRITES` is `off` or `landing`.
4. Update `PROJECT/PDDA.md`, `ROUTER.md`, `AGENTS.md`, and `.github/pull_request_template.md`.
5. Update `utils/pdda/pdda-install.sh` and `utils/pdda/pdda-sync-manifest.conf`.
*Gate:* Run `bash test/pdda-run.sh` and `bash utils/pdda/pdda.sh run` in observe and full mode.

### Phase 4: Dogfood & Verification
1. Dogfood decision: Explicitly keep XYZ-forge on default `CHANGELOG_WRITES=off` (or opt into `CHANGELOG_WRITES=landing` if dogfood test is authorized), recording the configuration line in `.pdda-mode`.
2. Execute manual red controls under `TESTS-RESULTS/2026-11-15+GH-1487/`:
   - Red control 1: Verify default is `off` (no write on merge).
   - Red control 2: Verify invalid config falls back to `off`.
   - Red control 3: Verify `landing` writes sanitized entry with exact marker.
   - Red control 4: Verify idempotency (second run writes 0 bytes).
   - Red control 5: Verify B1 accepts generated marker and rejects malicious HTML.
   - Red control 6: Verify journal rollback restores original file on simulated error.
3. Run existing full repository checks: `./validate.sh` and `python3 utils/py/releases_app.py check`.
4. Retain test outputs and `provenance.jsonl`.
*Gate:* `./validate.sh` exits 0 with zero regressions.

---

## 5. Reversibility & Rollback Assessment
- **Reversibility:** High. All changes are strictly bounded behind the configuration setting `CHANGELOG_WRITES`.
- **Rollback Procedure:** Setting `CHANGELOG_WRITES=off` immediately halts all reconciler changelog writes across the repository without reverting code. Setting `CHANGELOG_WRITES=branch` restores the legacy per-branch writing model.
- **Data Shape Integrity:** The format generated in landing mode strictly adheres to the standard date-first heading format `## YYYY-MM-DD — <Summary> (GH-N)` compatible with `test_ci_test_policy.py` and legacy changelog readers.

---

## 6. Acceptance & Verification

- [ ] **Default is OFF:** In the absence of config or when `CHANGELOG_WRITES=off`, no changelog write occurs during landing, and `pdda.sh run` aggregate check skips warnings.
- [ ] **Landing Writer:** When `CHANGELOG_WRITES=landing`, a merged PR produces exactly one dated entry with `<!-- pr:N merge:<sha> -->`.
- [ ] **Idempotency:** Re-running reconciliation on an already-reconciled PR writes nothing.
- [ ] **Fallback:** A PR without `## Changelog` falls back to the PR title with `fallback-title`.
- [ ] **Sanitization:** HTML comments, forged markers, and H1/H2 headings in PR bodies are sanitized/stripped.
- [ ] **B1 Coexistence:** `ledger_merge.py:union_changelog` accepts the exact generated marker line without raising a `ValueError`, but still rejects other HTML additions.
- [ ] **Allowlist:** `hosted_lane_publish.py:EXACT` includes `CHANGELOG.md`.
- [ ] **Rollback:** `wave_reconcile` rollback journal snapshots `CHANGELOG.md` before write and restores original on failure.
- [ ] **Legacy Preservation:** When `CHANGELOG_WRITES=branch`, legacy behavior is fully retained.
- [ ] **Suites & Gates:** All existing test suites pass.
