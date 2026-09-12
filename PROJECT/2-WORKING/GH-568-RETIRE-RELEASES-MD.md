---
gh_issue: 568
source: https://github.com/HiQS-Labs/XYZ-forge/issues/568
title: "feat(ledger): end-to-end retirement of RELEASES.md in favor of releases.db"
status: "Active (2-WORKING)"
created: 2026-09-10
doc_type: enhancement
effort: 4
complexity: 4
risk: 3
reversibility: "Costly — schema and test wiring changes; one atomic PR with rollback path"
sequence_after: 567
---

# GH-568: End-to-End Retirement of RELEASES.md in Favor of releases.db

## Problem Statement

`RELEASES.md` was originally authored as a Markdown-based forward-looking release-planning ledger. When GH-32 introduced `releases.db` (SQLite) and `releases.sql` (canonical git-mergeable dump), the database became the authoritative runtime source of truth, and `utils/py/releases_app.py` became the sole writer.

Despite being marked OPTIONAL in GH-381, `RELEASES.md` remains committed at the repository root and creates ceremonial, duplicate machinery:
- **Concrete State Divergence:** `releases.db` models in-band releases (0.7.1, 0.7.2, 0.7.3, 0.7.4) as standalone rows with specific tracking issues and manifest items, whereas `RELEASES.md` collapsed them into an un-enumerated reserved band (`Iterations: 0.7.0-0.7.4`), alongside stale codenames (e.g. 0.6.0 "Meter" vs DB "Front-Door").
- `releases_app.py` carries complex drift-detection and generation logic (`gen` verb, `RELEASES.generated.md.drift`) comparing database state against the legacy markdown file.
- `releases.db` maintains `doc_lines` and `legacy_lines` tables solely to round-trip and preserve unparsed Markdown prose from `RELEASES.md`.
- Release-to-marathon tools (`utils/release-lanes.sh`) still parse `$ROOT/RELEASES.md` directly to resolve `--release` and implicit milestone join keys.
- Release-gate test suites (`test/nightwatch-release.sh`, `test/meter-release.sh`) contain fragile awk/grep parsers cross-checking their internal manifests against `RELEASES.md` prose, with silent skip fallbacks if absent.
- Post-merge reconciliation (`utils/py/wave_reconcile.py`, `.github/workflows/wave-reconcile.yml`) and supervisor tools (`utils/py/express.py`) snapshot, regenerate, and allowlist `RELEASES.generated.md`.
- Tooling, skills, timeline exporters, and cockpit extensions maintain dual-path handling (app-managed vs legacy-managed).

Just as `ROADMAP.md` was retired in GH-269 and `ROADMAP-DASHBOARD.md` is being retired in GH-567, `RELEASES.md` is ceremonial residue. The repository should complete the transition to a single source of truth: **`releases.db` via `releases_app.py`**, and excise `RELEASES.md` and its generated mirror end-to-end.

## Sequencing & Landing Order

- **GH-567 lands FIRST:** GH-567 (`ROADMAP-DASHBOARD.md` removal) has smaller scope and two completed Codex QA rounds.
- **GH-568 lands SECOND:** GH-568 rebases on `development` after GH-567 merges, re-verifying the shared touched surfaces (`.github/workflows/wave-reconcile.yml`, `utils/py/express.py`, `utils/py/wave_reconcile.py`, `validate.sh`, `utils/py/router_audit.py`).

## Scope of End-to-End Removal

1. **Delete Tracked Artifacts & Ignore Rules:**
   - Remove `RELEASES.md` from git tracking and disk.
   - Retire `RELEASES.generated.md` generation and drift reporting.
   - Remove `RELEASES.generated.md*` from `.gitignore:73-74`.

2. **Standardize on CLI Interface:**
   - Standardize on `python3 utils/py/releases_app.py list` (and `releases show --version <ver>`) for human release inspection.
   - Retain `releases_app.py list --json` for machine tools and `releases dashboard` for timeline viewing.

3. **`releases check` Contract & Phase-1 Schema Specification (Costly):**
   - **New `check` Contract:** `releases check` validates DB <-> canonical dump consistency (generation marker, dump text equality, foreign keys pragma, receipt chain, and business-state digest), permanently dropping generated file and drift checks.
   - **Command-by-Command Schema Behavior:**
     - `releases import`: Retained exclusively for external target repositories onboarding from a legacy `RELEASES.md` via `xyz-releases-onboard.sh`. In that target context only, it may populate `doc_lines` and `legacy_lines`.
     - In `XYZ-forge` (and all app-managed repos): runtime commands (`add`, `update`, `ship`, `manifest`, `check`, `roadmap`) never touch, read, or write `doc_lines` or `legacy_lines`.
     - `releases gen`: Retired in this repository.
     - Dump/replay contract: preserves `doc_lines` and `legacy_lines` table structures in `releases.sql` to maintain 100% backward-compatible git merge replays and historical fixture compatibility.
     - Formulate a clean migration step via `releases migrate` for eventual table dropping in a future maintenance arc.

4. **Migrate Marathon Release Seeding (`utils/release-lanes.sh`):**
   - Rewrite `resolve_milestone()` in `utils/release-lanes.sh:20-123` to query `releases.db` via `python3 utils/py/releases_app.py show` / `releases list` or direct SQLite query instead of parsing `$ROOT/RELEASES.md`.
   - Preserve exact resolution hierarchy: `--milestone` override > `--release NAME` match against version or codename > single in-progress release with a milestone.
   - Ensure missing, ambiguous, or no-milestone conditions fail with exit code 3 and specific diagnostic messages.
   - Update `test/gh284-p4-release-lanes.sh` and include a red control proving missing/ambiguous DB milestones refuse cleanly.

5. **Decouple Release-Gate Tests & Prevent Vacuous Passes:**
   - **Rewire Manifest Checks:** In `test/nightwatch-release.sh` and `test/meter-release.sh`, replace awk scraping of `RELEASES.md` with direct checks against `releases.db` (via `releases manifest` CLI or SQL query) or the internal goalpost arrays.
   - **Eliminate Vacuous-Pass Trap:** Remove the silent skip `[ -f "$rel" ] || return 0` from `test/meter-release.sh:445` and `utils/pdda-local-checks.sh:292-295`. Manifest validation must remain load-bearing against the DB.
   - **Witnessed Negative Controls & Evidence Destination:** Verify that `--mutate-evidence` in `test/nightwatch-release.sh`, `test/meter-release.sh`, and `test/ballast-release.sh` reports RED when mutated post-rewire, recording durable test evidence in `test/baselines/GH-568-negative-control.md`.

6. **Migrate Build & Preflight Utilities:**
   - In `utils/build-launch-artifact.sh:3,29,49`, default origin remote URL statically to `https://github.com/HiQS-Labs/XYZ-forge.git` without referencing `RELEASES.md`.
   - In `utils/py/swarm_preflight.py:806-810`, update docstrings and manifest resolution to reflect that goalposts cross-check against `releases.db`.

7. **Migrate Timeline Exporter & Viewer:**
   - In `utils/timeline/export_timeline.py:370,392,408-431`, remove `parse_releases_md` and the `md_drift` comparison. Rely exclusively on `releases.db` as the source of truth for timeline data.
   - Update `test/gh103-timeline-exporter.sh` and `test/gh107-timeline-json-seam.sh`.
   - Update `utils/timeline/README.md:16,48-52`.

8. **Migrate Post-Merge & Supervisor Automation:**
   - In `utils/py/wave_reconcile.py:910,946-950,1007-1008`, remove `RELEASES.generated.md` from `snapshot_ledger_artifacts` and regeneration steps.
   - In `.github/workflows/wave-reconcile.yml:75`, remove `RELEASES.generated.md` from the post-reconcile commit allowlist.
   - In `utils/py/express.py:699-701`, remove `RELEASES.generated.md` from `CLOSEOUT_ALLOWLIST_FILES`.
   - Rebaseline `test/gh267-express-skill.sh:129-169` and `test/gh424-roadmap-status-marker.sh:30-174` to reflect the updated artifact list.

9. **Migrate HQ and Onboarding SOP Contracts:**
   - In `utils/hq/hq.sh:363-368`, remove the `releases gen` dashboard invocation.
   - In `relay-automation/xyz-releases-onboard.sh:11-17`, preserve legacy onboarding strictly for external target repositories migrating to `releases.db`; document that the root repo is fully app-managed and does not run onboarding.

10. **Migrate PDDA Library & Local Checks:**
    - In `utils/pdda/pdda-lib.sh:12-13,448+`, deprecate or remove `PDDA_RELEASES_FILE` and `pdda_releases_*` helpers, or rewire them to delegate to `releases_app.py list`.
    - In `utils/pdda/pdda.sh:696,834` and `utils/pdda-local-checks.sh:290-327`, ensure `pdda.sh releases` and `releases-current` cleanly delegate or skip without error.

11. **Migrate VS Code Cockpit:**
    - In `tools/vscode-cockpit/src/extension.ts:36,88`, update `emptyMessage` to reference `releases.db` and remove `RELEASES.md` from the file-watcher glob.
    - In `tools/vscode-cockpit/src/dataSources/releases.ts`, query `releases list --json` (or read DB) instead of parsing `RELEASES.md`.
    - In `tools/vscode-cockpit/README.md:12-14`, update documentation.

12. **Update Test Suites Classification:**
    - **Rehomed / Updated:**
      - `test/release-lanes.sh` & `test/gh284-p4-release-lanes.sh`: rewired to `releases.db` with red controls.
      - `test/gh32-releases-app.sh` & `test/gh32-releases-artifacts.sh`: rehome tests to verify DB-only writes, dump consistency, and absence of generated/drift files.
      - `test/gh267-express-skill.sh` & `test/gh424-roadmap-status-marker.sh`: rebaselined without `RELEASES.generated.md`.
      - `test/gh284-p3-release-milestone.sh`: update to test against DB or test fixtures.
      - `test/releases-skill.sh`: update assertions to verify that `/releases` routes to `releases.db`.
      - `test/gh103-timeline-exporter.sh` & `test/gh107-timeline-json-seam.sh`: remove drift assertions.
    - **Fixture-Only (Verified Safe):**
      - `test/gh525-unshipped-version-tokens.sh`, `test/gh557-unknown-blocks-manifest.sh`, `test/gh197-vendor-tier-split.sh`, `test/gh57-releases-fuzz.sh`, `test/pdda-local-checks.sh` generate temporary fixtures and do not touch root `RELEASES.md`.

13. **Update Router Hard Gate & Documentation Contracts:**
    - In `utils/py/router_audit.py:626`, remove `RELEASES.md` from the `--fix` role-split declaration template.
    - Update `ROUTER.md:13,124-125,153,169` to document `releases.db` / `releases_app.py` as the sole releases entry point.
    - Classify `PAGES/roadmap.html:69-70` as historical issue-title entries exempt from active file retirement.
    - Update `PROJECT/PDDA.md`, `AGENTS.md`, `ARCHITECTURE.md`, `RELEASES-DB-FAQS.md`, `HOW-TO-USE.md:48`, `relay-automation/README.md`, `utils/pdda/PDDA-INSTALL.md`, `skills/radar/SKILL.md:31,249`, `skills/releases/SKILL.md:3-45,246-249`, `skills/relay-xyz/SKILL.md:181`, and `.claude/settings.json:10,13`.

14. **Falsifiable Permanent Regression Guard Test (`test/gh568-releases-md-retired.sh`):**
    - **Static Canary:** Asserts `[ ! -f "$root/RELEASES.md" ]` and `[ ! -f "$root/RELEASES.generated.md" ]`.
    - **Static Writer Audit:** Searches `utils/`, `githooks/`, `relay-automation/`, `skills/`, `.github/workflows/` for production write, redirect, or regeneration commands targeting `RELEASES.md` or `RELEASES.generated.md`.
    - **Exemptions:** Explicitly exempts `releases.sql` data rows, `LEADERBOARD.md`, `CHANGELOG.md`, and historical archives.
    - **Falsification & Red Controls:** Test fixture verifies that restoring the root file AND injecting a simulated writer command each fail the guard independently. Asserts a non-empty candidate scan so an empty search root cannot pass. Recorded evidence committed to `test/baselines/GH-568-negative-control.md`.
    - Registered in `validate.sh` `TESTS` array.

## Acceptance Criteria

- [ ] `RELEASES.md` and `RELEASES.generated.md` are deleted from repo root and untracked; `.gitignore` is cleaned up.
- [ ] `releases check` verifies DB <-> canonical dump consistency without checking generated Markdown or drift files.
- [ ] `doc_lines` and `legacy_lines` schema usage is made dormant with no operational writes in this repo.
- [ ] `utils/release-lanes.sh` resolves milestones from `releases.db` and passes `test/gh284-p4-release-lanes.sh`.
- [ ] `test/nightwatch-release.sh` and `test/meter-release.sh` manifest checks are rewired to `releases.db` and verified non-vacuous (`--mutate-evidence` reports RED when mutated).
- [ ] Durable negative control evidence committed to `test/baselines/GH-568-negative-control.md`.
- [ ] `utils/build-launch-artifact.sh`, `utils/py/swarm_preflight.py`, and `utils/timeline/export_timeline.py` execute cleanly without `RELEASES.md`.
- [ ] `utils/py/wave_reconcile.py`, `.github/workflows/wave-reconcile.yml`, and `utils/py/express.py` remove all references to `RELEASES.generated.md`.
- [ ] `tools/vscode-cockpit` and `skills/releases/SKILL.md` route all release operations through `releases_app.py`.
- [ ] Dedicated regression guard `test/gh568-releases-md-retired.sh` with witnessed red controls is registered in `validate.sh` and passes.
- [ ] `validate.sh` passes 100% clean across all suites.
- [ ] Single atomic PR landed in sequence after GH-567.
