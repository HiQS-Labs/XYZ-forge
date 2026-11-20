---
title: "Eliminate CHANGELOG.md merge conflicts via landing reconcile writer and dogfood adoption"
status: Active (2-WORKING)
created: 2026-11-15
updated: 2026-11-15
owner: Claude
branch: feat/XYZ-forge-gh1487-changelog-landing-2026-11-15
doc_type: project
gh_issue: 1487
global_id: rmi-01M7GCRVQW0G0Y45511ADW117H
prs_rating: 85/75/70/65 (calc: 295)
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1487
goal: Eliminate serial CHANGELOG.md merge conflicts by setting default writes to off and providing an authoritative opt-in post-landing reconciler writer.
---

# Architectural Plan: Eliminate CHANGELOG.md merge conflicts via landing reconcile writer and dogfood adoption

- **Issue**: [HiQS-Labs/XYZ-forge#1487](https://github.com/HiQS-Labs/XYZ-forge/issues/1487)
- **Status**: 🚧 In progress
- **Global ID**: `rmi-01M7GCRVQW0G0Y45511ADW117H`
- **PRS Rating**: 85/75/70/65 (calc: 295)

## Status

| What was just completed | What's next |
|---|---|
| Phase 0: Grounded recon, technical spike analysis, and multi-model consensus on GH-1487; Codex Plan QA Rounds 1-5 | Phase 1: Implement Foundation & Safety Surfaces (allowlist, B1 marker coexistence, pre-write snapshot) |

## Table of contents
- [Status](#status)
- [Phase Gates](#phase-gates)
- [1. Goal & Context](#1-goal--context)
- [2. Recon & Code Seams](#2-recon--code-seams)
- [3. Detailed Architectural Specifications](#3-detailed-architectural-specifications)
  - [A. Configuration Parsing, Precedence & Durable Adoption Boundary](#a-configuration-parsing-precedence--durable-adoption-boundary)
  - [B. Candidate Selection & Recovery Logic](#b-candidate-selection--recovery-logic)
  - [C. Input Sanitization, Formatting & Deterministic Ordering](#c-input-sanitization-formatting--deterministic-ordering)
  - [D. B1 Coexistence & Marker Exemption](#d-b1-coexistence--marker-exemption)
  - [E. Literal Identity Idempotency & Transactional Rollback Safety](#e-literal-identity-idempotency--transactional-rollback-safety)
  - [F. Publication & Race Retry Behavior](#f-publication--race-retry-behavior)
- [4. Phased Implementation Plan](#4-phased-implementation-plan)
  - [Phase 1: Foundation & Safety Surfaces](#phase-1-foundation--safety-surfaces)
  - [Phase 2: Reconciler Engine & Dedicated Cutover Recovery](#phase-2-reconciler-engine--dedicated-cutover-recovery)
  - [Phase 3: Governance, Distributed Templates & Deterministic Checks](#phase-3-governance-distributed-templates--deterministic-checks)
  - [Phase 4: Dogfood & Verification](#phase-4-dogfood--verification)
- [5. Reversibility & Rollback Assessment](#5-reversibility--rollback-assessment)
- [6. Acceptance & Verification](#6-acceptance--verification)

## Phase Gates

| Phase | Description | Observable Gate | Status |
|---|---|---|---|
| Phase 1 | Foundation & Safety: allowlist, B1 marker coexistence, pre-write rollback snapshot | `python3 -m unittest test/gh534_phase_b_tests.py` passes; B1 accepts generated marker and rejects malicious HTML / conflict markers | ⏳ Ready |
| Phase 2 | Reconciler Engine & Dedicated Cutover Recovery (`wave_reconcile.py`) | `bash test/wave-reconcile.sh` passes; dry-run/off writes nothing; landing writes exact dated section with marker; catch-up recovers missed PRs | ⏳ Ready |
| Phase 3 | Config Parser, Distributed Templates & Governance Updates | `bash test/pdda-run.sh` & `utils/pdda/pdda.sh run` pass; distributed templates updated | ⏳ Ready |
| Phase 4 | Verification (Manual Red Controls & Provenance) & Forge Dogfood Adoption | Manual red controls (including raced push and absent-file rollback) pass under `TESTS-RESULTS/2026-11-15+GH-1487/provenance.jsonl`; full `./validate.sh` passes | ⏳ Ready |

---

## 1. Goal & Context
Currently in `HiQS-Labs/XYZ-forge`, 4 of the 8 conflicting open PRs conflict on `CHANGELOG.md` (#1444, #1417, #1416, #1413).
Requiring every PR branch to append to `CHANGELOG.md` directly causes serial merge collisions. While `skills/2-daily/merge-cleanup/scripts/ledger_merge.py` implements the B1 `union_changelog` algorithm to attempt 3-way prefix-additive union, every conflict:
1. Forces a B1 branch repair, creating a new commit on the PR branch.
2. Invalidates CI checks and requires pushing a new remote head.
3. Requires re-pinning and re-running gates, invalidating the base of subsequent PRs in a batch sequence.

This task implements the architectural solution specified in [GH-1487](https://github.com/HiQS-Labs/XYZ-forge/issues/1487), addressing all Codex Plan QA findings:
1. **Universal Default is OFF (`CHANGELOG_WRITES=off`):** When unset or `off`, PR branches do not write `CHANGELOG.md`, the reconciler writes nothing, and `pdda.sh run` omits aggregate changelog warnings.
2. **Opt-in Landing Writer (`CHANGELOG_WRITES=landing`):** Authoritative single writer in `utils/py/wave_reconcile.py` synthesizes `CHANGELOG.md` from merged PR descriptions at landing time.
3. **Legacy Mode (`CHANGELOG_WRITES=branch`):** Preserves legacy branch-level changelog updates and aggregate checks for repositories that explicitly request it.

---

## 2. Recon & Code Seams

- **Landing PR Metadata Contract (`utils/py/wave_reconcile.py:390-420, 2510-2565`):**
  - In `wave_reconcile.py`, PR metadata is fetched via `gh pr view --json number,title,body,state,mergedAt,mergeCommit` (normalized to dictionary `pr_meta`).
  - Merged check strictly tests: `pr_meta.get("state") == "MERGED"`, non-empty `pr_meta.get("mergedAt")`, and real PR identity (`number > 0` with full 40-hex `merge_commit_sha`). Synthetic direct commits or unmerged PRs are never processed by the changelog writer.
- **Pre-write Snapshot & Rollback (`utils/py/wave_reconcile.py:1935-1955`):**
  - Reuses the existing `snapshot_ledger_artifacts(repo_root, dry_run, journal)` and `RollbackJournal` API:
    Add `"CHANGELOG.md"` to the existing loop over ledger files in `snapshot_ledger_artifacts`.
    If `CHANGELOG.md` exists, it calls `journal.snapshot(path)`. If absent, it calls `journal.track_created(path)`.
    Repeated calls are safely guarded by `if path in journal.backups or path in journal.created_files: continue`.
    If reconciliation errors out, `journal.rollback()` cleanly restores original bytes or removes newly created `CHANGELOG.md`.
- **Dedicated Changelog Cutover Boundary (`utils/py/wave_reconcile.py:1460-1490`):**
  - `unreconciled_prs()` recovers lifecycle qualification receipts using `committed_qualifications()`.
  - The changelog writer does **not** modify this qualification activation boundary. Instead, changelog catch-up uses an independent, durable boundary (`changelog_cutover_iso`), checking whether the PR's exact literal marker `<!-- pr:<number> merge:<sha40> -->` is already present at its expected position in `CHANGELOG.md`. Pre-cutover PRs or already-recorded PRs are skipped without altering qualification recovery.
- **B1 Marker Coexistence (`skills/2-daily/merge-cleanup/scripts/ledger_merge.py:469`):**
  - Currently line 469 rejects all `"<!--"` and `<` additions with `ValueError("fenced or HTML additions require manual changelog resolution")`.
  - Must explicitly permit the generated full-SHA marker line `<!-- pr:[1-9][0-9]* merge:[0-9a-f]{40} -->` at the expected position immediately following the entry heading, while strictly rejecting any other HTML tags, HTML comments, code fences, or conflict markers.
- **Hosted Publication Allowlist & Retry Seam (`utils/py/hosted_lane_publish.py:50, 180-275`):**
  - Add `'CHANGELOG.md'` to `EXACT` allowlist so hosted lane runs cleanly publish changelog changes.
  - On raced pushes, `hosted_lane_publish.py` checks receipts: without receipts, it exits 1 immediately; with receipts, it retries pushing receipts up to `RECEIPT_ATTEMPTS`, then re-runs `wave_reconcile.py` once via `recompute()` with `--only-receipted --skip-pull`. The writer prepends the new entry on the fresh integration base.
- **Branch-Writing Skills & Distributed Templates:**
  - `skills/2-daily/express/SKILL.md:29, 176` and `skills/4-occasional/install-improve-audit/SKILL.md:392`: Update instructions to make branch changelog edits conditional on `CHANGELOG_WRITES=branch`.
  - `utils/pdda/templates/ROUTER.target.md:40` and `utils/pdda/templates/ROUTER.releases.target.md:39`: Update distributed templates to document that PR branches do not edit `CHANGELOG.md` unless `CHANGELOG_WRITES=branch`.
- **Deterministic Check Gating (`utils/pdda/pdda.sh:1711`):**
  - Update `check_changelog()` in `pdda.sh`: check `.pdda-mode`. In `off` or `landing` mode, skip aggregate warnings during `cmd_run()`; retain standalone `pdda.sh changelog` command for manual audits.

---

## 3. Detailed Architectural Specifications

### A. Configuration Parsing, Precedence & Durable Adoption Boundary
- **File Format in `.pdda-mode`:**
  - Plain key-value lines: `CHANGELOG_WRITES=<value>` and optional `CHANGELOG_CUTOVER=<ISO-8601-timestamp>`.
  - Comments (`#`) and blank lines ignored. Duplicate lines: last non-empty value wins.
- **Precedence for `CHANGELOG_WRITES`:**
  1. Environment variable `CHANGELOG_WRITES` (if set).
  2. Setting in `.pdda-mode` (if present).
  3. Built-in default: `off`.
- **Allowed values:** `off`, `landing`, `branch` (case-insensitive, trimmed).
- **Invalid value handling:** If value is unknown or malformed, log a warning to stderr and safely fall back to `off`.
- **Durable Adoption Boundary (`changelog_cutover_iso`):**
  - **Purpose:** Decouples changelog catch-up from lifecycle qualification receipts so historical PRs merged before landing mode adoption are never backfilled, while ensuring raced or missed PRs from previous days are reliably recovered.
  - **Resolution hierarchy & fail-closed contract:**
    1. Environment variable precedence: If `CHANGELOG_CUTOVER` is set in the environment, parse its ISO-8601 timestamp.
    2. Configuration file: If `CHANGELOG_CUTOVER` is configured in `.pdda-mode`, parse its ISO-8601 timestamp.
    3. Git history discovery: If not explicitly configured, query git history for the *first* (oldest) commit that introduced `CHANGELOG_WRITES=landing` into `.pdda-mode`:
       `git log -S "CHANGELOG_WRITES=landing" --reverse --format=%cI -- .pdda-mode | head -n1`
       (Note: `--reverse` establishes oldest adoption; `--diff-filter=A` is omitted so edits modifying existing `.pdda-mode` are discovered).
    4. Fail-closed contract (No moving clocks, No workflow-era fallback):
       If no commit in history contains `CHANGELOG_WRITES=landing` AND no explicit `CHANGELOG_CUTOVER` is configured (e.g. uncommitted working tree edit or environment-only enablement), `wave_reconcile.py` **fails closed**:
       `die("CHANGELOG_WRITES=landing requires explicit CHANGELOG_CUTOVER=<ISO-8601> when adoption history cannot be established from git", code=6)`
       It strictly forbids falling back to workflow activation creation (which could be months in the past and backfill hundreds of historical PRs) and forbids falling back to a moving clock (which would drop yesterday's raced PRs).
  - **Timestamp Validation:**
    - Parse using `datetime.fromisoformat(ts.replace("Z", "+00:00"))`.
    - If the timestamp is timezone-naive, treat it as UTC (`replace(tzinfo=timezone.utc)`).
    - If the configured `CHANGELOG_CUTOVER` is invalid or cannot be parsed, fail closed (`die("Invalid CHANGELOG_CUTOVER timestamp; must be valid ISO-8601", code=6)`).
  - **Off-to-Landing Adoption:** When a repo switches from `off` to `landing`, the adoption boundary is the commit that added `CHANGELOG_WRITES=landing` (or explicit `CHANGELOG_CUTOVER`). All PRs merged on or after that boundary that lack an entry in `CHANGELOG.md` are recovered during `--catch-up`.
  - **Lifecycle Isolation:** The repository's lifecycle recovery activation rule (`unreconciled_prs()` using workflow creation history in `wave_reconcile.py:1460-1475`) is completely separate and untouched.

### B. Candidate Selection & Recovery Logic
- **Explicit CLI Landings (`--pr <N>` or `--manifest`):**
  - When `--pr <N>` is explicitly passed on the command line or via manifest, it is **always** evaluated as a changelog candidate, regardless of `changelog_cutover_iso`. If its exact literal marker `<!-- pr:N merge:<sha40> -->` is not present at its expected position in `CHANGELOG.md` and it is merged into development, its entry is generated.
- **Catch-up Selection (`--catch-up` in landing mode):**
  - `wave_reconcile.py` maintains separate selection paths for lifecycle qualifications vs changelog entries:
    - Lifecycle qualifications continue to use `committed_qualifications()` to determine `pending` PRs.
    - Changelog catch-up invokes `changelog_catchup_candidates(repo_root, repo_slug, cutover_iso)`. It queries closed development PRs since `cutover_iso`. Any merged PR whose exact literal marker `<!-- pr:N merge:<sha40> -->` is missing from its expected position in `CHANGELOG.md` is selected for changelog entry synthesis.
  - This guarantees that PRs that were already qualified during a period when `CHANGELOG_WRITES=off` (or during a temporary publication race) are recovered when `CHANGELOG_WRITES=landing` is enabled, without mutating lifecycle eligibility or re-running qualifications.

### C. Input Sanitization, Formatting & Deterministic Ordering
- **Extraction:**
  - Extract text under `## Changelog` (case-insensitive) in the PR body up to the next Markdown H2 (`## `) or EOF.
- **Sanitization:**
  - **PR Title Sanitization:** Strip all HTML tags (`<[^>]+>`), backticks, newlines, carriage returns, and conflict characters (`<`, `>`, `=`, `|`). Trim and collapse whitespace.
  - **Body Comment Stripping:** Strip all HTML comments (`<!--[\s\S]*?-->`) from author body to prevent marker forgery or corrupted HTML.
  - **Conflict Marker Elimination:** Strip any line matching `(?m)^[ 	]*(?:<{7}|={7}|>{7}|\|{7})(?: |$)` (including diff3 `|||||||` lines).
  - **Code Fence Neutralization for B1 Safety:** To satisfy B1's strict rejection of line-leading fences (`^[ 	]{0,3}(?:`{3,}|~{3,}|<)`), indent author code blocks by 4 spaces instead of triple backticks/tildes, or sanitize line-leading backticks/tildes.
  - **HTML Tag Elimination:** Strip all raw HTML tags (`<[^>]+>`) from author input to prevent unclosed elements and satisfy B1 safety.
  - **Heading Down-leveling:** Convert any internal `# ` or `## ` headings to bold bullets (`- **...**`) so Markdown hierarchy is preserved and B1 does not misinterpret them as separate release entries.
- **Fallback:** If `## Changelog` section is absent or whitespace-only, synthesize entry from sanitized PR title with explicit flag: `changelog: fallback-title`.
- **Exact Generated Output Structure:**
  ```markdown
  ## YYYY-MM-DD — <Sanitized Title Summary> (GH-N)

  <!-- pr:N merge:<sha40> -->
  <Sanitized body text or fallback>

  ```
  - Heading date strictly uses UTC `mergedAt` (`YYYY-MM-DD`).
  - Marker line is strictly `<!-- pr:<number> merge:<sha40> -->` where `<sha40>` is the full 40-hex merge commit SHA.
- **Deterministic Multi-Entry Ordering:**
  - When multiple PR entries are written in a single run (batch landing or catch-up), sort candidates descending by `mergedAt` timestamp as primary key, and descending by PR `number` as tie-breaker.
  - Prepend all new entries immediately after the preamble (identified by first `## ` heading) and before existing history, preserving exact byte-for-byte history integrity.

### D. B1 Coexistence & Marker Exemption
- **File:** `skills/2-daily/merge-cleanup/scripts/ledger_merge.py:469` (`union_changelog`).
- **Contract:**
  - B1's line 469 currently rejects any additions containing `"<!--"` or matching `(?m)^[ 	]{0,3}(?:`{3,}|~{3,}|<)`.
  - Update `union_changelog`:
    - Allow each section body to contain **only** the exact marker line: `re.fullmatch(r"<!-- pr:[1-9][0-9]* merge:[0-9a-f]{40} -->", first_body_line.strip())`.
    - Restrict the exemption to this exact position and format; any other HTML comments (`<!--`), arbitrary HTML tags (`<`), or code fences (```, ~~~) continue to be strictly rejected with `ValueError("fenced or HTML additions require manual changelog resolution")`.
    - Retain conflict marker check `(?m)^(?:<{7}|={7}|>{7}|\|{7})(?: |$)` rejecting any conflict markers in base, ours, or theirs.

### E. Literal Identity Idempotency & Transactional Rollback Safety
- **Literal Identity Check (Candidate Idempotency):**
  - Candidate identity tests for literal equality to `f"<!-- pr:{number} merge:{merge_sha} -->"` where `number` is the integer PR number and `merge_sha` is the candidate's exact 40-hex merge commit SHA.
  - Position check: The candidate is considered already recorded only if this exact marker string exists at the first non-blank body line of the section starting with `## YYYY-MM-DD — ... (GH-{number})`.
  - A generic regex matching any SHA anywhere in the file is NOT used for candidate deduplication, preventing stale, wrong-SHA, or misplaced markers from suppressing valid landings.
  - Direct reconciliation and catch-up candidate discovery use this exact literal match.
- **Pre-write Transaction Snapshot & Rollback:**
  - Reuses existing `snapshot_ledger_artifacts` in `wave_reconcile.py:1935`:
    - Add `"CHANGELOG.md"` to the snapshot loop file list.
    - If `CHANGELOG.md` exists: calls existing `journal.snapshot(path)`.
    - If `CHANGELOG.md` does not exist: calls existing `journal.track_created(path)`.
    - Guarded by existing `if path in journal.backups or path in journal.created_files: continue`.
  - On any unhandled exception or failure, existing `journal.rollback()` restores original bytes if modified, or completely removes `CHANGELOG.md` if newly created (absent-file rollback).
- **Dry Run:** When `--dry-run` is active, compute and log entries but write 0 bytes to disk.

### F. Publication & Race Retry Behavior
- **File:** `utils/py/hosted_lane_publish.py:50, 180-275`.
- **Allowlist:** Add `'CHANGELOG.md'` to `EXACT` allowlist so changes are committed and published.
- **Raced Push Handling:**
  - If a pushed commit is rejected by remote:
    - If no qualification receipts were generated in the commit: `hosted_lane_publish` exits 1 immediately without pushing or corrupting remote state. The discarded local commit is abandoned, and the next run will fetch fresh `origin/development` and recompute.
    - If qualification receipts exist: `hosted_lane_publish` resets to `origin/development`, extracts the receipts from the discarded commit, and pushes receipts up to `RECEIPT_ATTEMPTS` (3 attempts).
    - Upon successful receipt push, it executes `recompute(retry_argv(args.reconcile_args, prs, commits), reconcile_cmd)` ONCE with `--only-receipted --skip-pull`.
    - In `recompute`, `wave_reconcile.py` evaluates the receipted landings, reads the fresh `CHANGELOG.md` from the reset tip, sees that the exact literal markers are not yet in `CHANGELOG.md`, and prepends the entries.
    - `hosted_lane_publish` commits `CHANGELOG.md` and transitions, and pushes them. If that second push is rejected, it fails closed; receipts remain safely published on origin, and the subsequent catch-up run will complete the changelog entry cleanly.

---

## 4. Phased Implementation Plan

### Phase 1: Foundation & Safety Surfaces
1. Add `'CHANGELOG.md'` to `EXACT` in `utils/py/hosted_lane_publish.py`.
2. Update `skills/2-daily/merge-cleanup/scripts/ledger_merge.py:469`: permit the exact generated full-SHA marker line `(?m)^<!-- pr:[1-9][0-9]* merge:[0-9a-f]{40} -->$` while strictly rejecting all other HTML/fenced blocks and conflict markers.
3. Update `wave_reconcile.py:snapshot_ledger_artifacts` to include `"CHANGELOG.md"` in the existing snapshot loop.
*Gate:* Run `python3 -m unittest test/gh534_phase_b_tests.py` and dedicated unit assertions proving B1 accepts generated marker and rejects malicious HTML / conflict markers.

### Phase 2: Reconciler Engine & Dedicated Cutover Recovery
1. Implement `read_changelog_writes_mode(repo_root)` and `read_changelog_cutover(repo_root)` in `wave_reconcile.py` (with durable adoption boundary, timezone parsing, and fail-closed validation).
2. Implement `extract_changelog_section(body, pr_title)` with strict sanitization (HTML stripped, conflict markers stripped, headings down-leveled, code fences neutralized), heading generation, and literal full-SHA idempotency comment injection.
3. Implement `reconcile_changelog_entry(repo_root, pr_meta, merge_sha, dry_run, journal)`.
4. Implement dedicated `changelog_catchup_candidates(...)` decoupled from qualification receipts using literal identity check.
5. Integrate into `wave_reconcile.py` landing loop and `--catch-up` workflow with deterministic sorting (newest first).
*Gate:* Run `bash test/wave-reconcile.sh` ensuring all existing reconcile behavior passes cleanly.

### Phase 3: Governance, Distributed Templates & Deterministic Checks
1. Update `skills/2-daily/express/SKILL.md` and `skills/4-occasional/install-improve-audit/SKILL.md` to make branch changelog edits conditional on `CHANGELOG_WRITES=branch`.
2. Update distributed templates `utils/pdda/templates/ROUTER.target.md` and `utils/pdda/templates/ROUTER.releases.target.md`.
3. Update `utils/pdda/pdda.sh:check_changelog` to skip aggregate checks when `CHANGELOG_WRITES` is `off` or `landing`.
4. Update `PROJECT/PDDA.md`, `ROUTER.md`, `AGENTS.md`, and `.github/pull_request_template.md`.
5. Update `utils/pdda/pdda-install.sh` and `utils/pdda/pdda-sync-manifest.conf`.
*Gate:* Run `bash test/pdda-run.sh` and `bash utils/pdda/pdda.sh run` in observe and full mode.

### Phase 4: Dogfood & Verification
1. Dogfood configuration: Explicitly verify XYZ-forge default is `CHANGELOG_WRITES=off` (no branch writes, no reconciler writes).
2. Execute manual red controls under `TESTS-RESULTS/2026-11-15+GH-1487/`:
   - Red control 1: Verify default is `off` (no write on merge).
   - Red control 2: Verify invalid config falls back to `off`.
   - Red control 3: Verify `landing` writes sanitized entry with exact literal full-SHA marker.
   - Red control 4: Verify idempotency (second run writes 0 bytes).
   - Red control 5: Verify B1 accepts generated marker and rejects malicious HTML / conflict markers.
   - Red control 6: Verify journal rollback restores original file on simulated error.
   - Red control 7: Verify raced publication simulation (recompute retry with receipts; fail closed without receipts).
   - Red control 8: Verify absent-file rollback (simulated failure when `CHANGELOG.md` is initially absent removes created file).
   - Red control 9: Verify missing adoption history fail-closed check (running in `landing` mode with uncommitted config and no `CHANGELOG_CUTOVER` fails closed with code 6, proving workflow-era PRs are never silently backfilled).
3. Run existing full repository checks: `./validate.sh` and `python3 utils/py/releases_app.py check`.
4. Retain test outputs and `provenance.jsonl`.
*Gate:* `./validate.sh` exits 0 with zero regressions.

---

## 5. Reversibility & Rollback Assessment
- **Reversibility Scale:** Costly / Reversible via configuration toggle and git correction.
- **Rollback Procedure:**
  - Setting `CHANGELOG_WRITES=off` in `.pdda-mode` or environment immediately halts all reconciler changelog writes across the repository without reverting code.
  - Setting `CHANGELOG_WRITES=branch` restores the legacy per-branch writing model.
  - For already-published entries on `origin/development`: switching to `off` prevents future writes, but does not alter already-committed history. If an erroneous or malformed entry was published to `CHANGELOG.md`, recovery is performed via standard `git revert` or manual excision commit of the specific dated entry in `CHANGELOG.md`, preserving the preamble and prior history byte-for-byte.
- **Data Shape Integrity:** The format generated in landing mode strictly adheres to the standard date-first heading format `## YYYY-MM-DD — <Summary> (GH-N)` compatible with `test_ci_test_policy.py` and legacy changelog readers.

---

## 6. Acceptance & Verification

- [ ] **Default is OFF:** In the absence of config or when `CHANGELOG_WRITES=off`, no changelog write occurs during landing, and `pdda.sh run` aggregate check skips warnings.
- [ ] **Landing Writer:** When `CHANGELOG_WRITES=landing`, a merged PR produces exactly one dated entry with literal `<!-- pr:N merge:<sha40> -->`.
- [ ] **Idempotency:** Re-running reconciliation on an already-reconciled PR writes nothing.
- [ ] **Fallback:** A PR without `## Changelog` falls back to the PR title with `fallback-title`.
- [ ] **Sanitization:** HTML comments, forged markers, HTML tags, conflict markers, and H1/H2 headings in PR bodies are sanitized/stripped/down-leveled.
- [ ] **B1 Coexistence:** `ledger_merge.py:union_changelog` accepts the exact generated marker line without raising a `ValueError`, but still rejects other HTML additions and conflict markers.
- [ ] **Allowlist:** `hosted_lane_publish.py:EXACT` includes `CHANGELOG.md`.
- [ ] **Rollback:** `wave_reconcile` rollback journal snapshots `CHANGELOG.md` before write and restores original (or removes if newly created) on failure.
- [ ] **Legacy Preservation:** When `CHANGELOG_WRITES=branch`, legacy behavior is fully retained.
- [ ] **Suites & Gates:** All existing test suites pass.
