---
Goal: QA Plan for End-to-End Retirement of RELEASES.md in Favor of releases.db (GH-568)
Date: 2026-09-10
NEXT: codex
STATUS: Open
---

# Context

Adjudicate the revised implementation plan in `PROJECT/1-INBOX/GH-568-RETIRE-RELEASES-MD.md` to completely excise `RELEASES.md` and `RELEASES.generated.md` from the repository, standardizing on `releases.db` and the `releases` CLI.

The plan has been revised based on feedback from @Zdode covering 9 key areas:
1. All 9 previously omitted consumers (`wave_reconcile.py`, `.github/workflows/wave-reconcile.yml`, `build-launch-artifact.sh`, `swarm_preflight.py`, `export_timeline.py`, `router_audit.py`, `pdda-lib.sh`, `xyz-releases-onboard.sh`, `vscode-cockpit`, `express.py`).
2. `releases check` contract updated to DB <-> dump consistency; schema decision to keep `doc_lines`/`legacy_lines` dormant/read-only in Phase 1 (Costly) with migration step via `releases migrate`.
3. Vacuous-pass trap in goalpost suites (`nightwatch-release.sh`, `meter-release.sh`, `ballast-release.sh`, `pdda-local-checks.sh`) prevented by rewiring to DB and proving `--mutate-evidence` reports RED.
4. Test surface classification across all 15 touched test suites.
5. Falsifiable permanent regression guard (`test/gh568-releases-md-retired.sh`) with writer pattern matching, scope, exemptions, and witnessed red controls.
6. Precise drift claim.
7. Sequencing: GH-567 lands first, GH-568 lands second with rebase and re-verification.
8. Sweep of miscellaneous references (`.gitignore`, `.claude/settings.json`, `RELEASES-DB-FAQS.md`, etc.).

### Full Inlined Plan Text

```markdown
# GH-568: End-to-End Retirement of RELEASES.md in Favor of releases.db

## Problem Statement

RELEASES.md was originally authored as a Markdown-based forward-looking release-planning ledger. When GH-32 introduced releases.db (SQLite) and releases.sql (canonical git-mergeable dump), the database became the authoritative runtime source of truth, and utils/py/releases_app.py became the sole writer.

Despite being marked OPTIONAL in GH-381, RELEASES.md remains committed at the repository root and creates ceremonial, duplicate machinery:
- Concrete State Divergence: releases.db models in-band releases (0.7.1, 0.7.2, 0.7.3, 0.7.4) as standalone rows with specific tracking issues and manifest items, whereas RELEASES.md collapsed them into an un-enumerated reserved band (Iterations: 0.7.0-0.7.4), alongside stale codenames (e.g. 0.6.0 "Meter" vs DB "Front-Door").
- releases_app.py carries complex drift-detection and generation logic (gen verb, RELEASES.generated.md.drift) comparing database state against the legacy markdown file.
- releases.db maintains doc_lines and legacy_lines tables solely to round-trip and preserve unparsed Markdown prose from RELEASES.md.
- Release-gate test suites (test/nightwatch-release.sh, test/meter-release.sh) contain fragile awk/grep parsers cross-checking their internal manifests against RELEASES.md prose, with silent skip fallbacks if absent.
- Post-merge reconciliation (utils/py/wave_reconcile.py, .github/workflows/wave-reconcile.yml) and supervisor tools (utils/py/express.py) snapshot, regenerate, and allowlist RELEASES.generated.md.
- Tooling, skills, timeline exporters, and cockpit extensions maintain dual-path handling (app-managed vs legacy-managed).

Just as ROADMAP.md was retired in GH-269 and ROADMAP-DASHBOARD.md is being retired in GH-567, RELEASES.md is ceremonial residue. The repository should complete the transition to a single source of truth: releases.db via releases_app.py, and excise RELEASES.md and its generated mirror end-to-end.

## Sequencing & Landing Order

- GH-567 lands FIRST: GH-567 (ROADMAP-DASHBOARD.md removal) has smaller scope and two completed Codex QA rounds.
- GH-568 lands SECOND: GH-568 rebases on development after GH-567 merges, re-verifying the shared touched surfaces (.github/workflows/wave-reconcile.yml, utils/py/express.py, utils/py/wave_reconcile.py, validate.sh, utils/py/router_audit.py).

## Scope of End-to-End Removal

1. Delete Tracked Artifacts & Ignore Rules:
   - Remove RELEASES.md from git tracking and disk.
   - Retire RELEASES.generated.md generation and drift reporting.
   - Remove RELEASES.generated.md* from .gitignore:73-74.

2. Standardize on CLI Interface:
   - Standardize on python3 utils/py/releases_app.py list (and releases show --version <ver>) for human release inspection.
   - Retain releases_app.py list --json for machine tools and releases dashboard for timeline viewing.

3. releases check Contract & Schema Decision (Costly):
   - New check Contract: releases check validates DB <-> canonical dump consistency (generation marker, dump text equality, foreign keys pragma, receipt chain, and business-state digest), permanently dropping generated file and drift checks.
   - Schema Decision: Mark doc_lines and legacy_lines as dormant/read-only in Phase 1 (stop writing/updating rows, retire gen consumer) without breaking dump shape, merge replays, or historical fixtures. Formulate a clean migration step via releases migrate for eventual drop.

4. Decouple Release-Gate Tests & Prevent Vacuous Passes:
   - Rewire Manifest Checks: In test/nightwatch-release.sh and test/meter-release.sh, replace awk scraping of RELEASES.md with direct checks against releases.db (via releases manifest CLI or SQL query) or the internal goalpost arrays.
   - Eliminate Vacuous-Pass Trap: Remove the silent skip [ -f "$rel" ] || return 0 from test/meter-release.sh:445 and utils/pdda-local-checks.sh:292-295. Manifest validation must remain load-bearing against the DB.
   - Witnessed Negative Controls: Verify that --mutate-evidence in test/nightwatch-release.sh, test/meter-release.sh, and test/ballast-release.sh reports RED when mutated post-rewire.

5. Migrate Build & Preflight Utilities:
   - In utils/build-launch-artifact.sh:3,29,49, default origin remote URL statically to https://github.com/HiQS-Labs/XYZ-forge.git without referencing RELEASES.md.
   - In utils/py/swarm_preflight.py:806-810, update docstrings and manifest resolution to reflect that goalposts cross-check against releases.db.

6. Migrate Timeline Exporter & Viewer:
   - In utils/timeline/export_timeline.py:370,392,408-431, remove parse_releases_md and the md_drift comparison. Rely exclusively on releases.db as the source of truth for timeline data.
   - Update test/gh103-timeline-exporter.sh and test/gh107-timeline-json-seam.sh.

7. Migrate Post-Merge & Supervisor Automation:
   - In utils/py/wave_reconcile.py:910,946-950,1007-1008, remove RELEASES.generated.md from snapshot_ledger_artifacts and regeneration steps.
   - In .github/workflows/wave-reconcile.yml:75, remove RELEASES.generated.md from the post-reconcile commit allowlist.
   - In utils/py/express.py:699-701, remove RELEASES.generated.md from CLOSEOUT_ALLOWLIST_FILES.

8. Migrate HQ and Onboarding SOP Contracts:
   - In utils/hq/hq.sh:363-368, remove the releases gen dashboard invocation.
   - In relay-automation/xyz-releases-onboard.sh:11-17, preserve legacy onboarding strictly for external target repositories migrating to releases.db; document that the root repo is fully app-managed and does not run onboarding.

9. Migrate PDDA Library & Local Checks:
   - In utils/pdda/pdda-lib.sh:12-13,448+, deprecate or remove PDDA_RELEASES_FILE and pdda_releases_* helpers, or rewire them to delegate to releases_app.py list.
   - In utils/pdda/pdda.sh:696,834 and utils/pdda-local-checks.sh:290-327, ensure pdda.sh releases and releases-current cleanly delegate or skip without error.

10. Migrate VS Code Cockpit:
    - In tools/vscode-cockpit/src/extension.ts:36,88, update emptyMessage to reference releases.db and remove RELEASES.md from the file-watcher glob.
    - In tools/vscode-cockpit/src/dataSources/releases.ts, query releases list --json (or read DB) instead of parsing RELEASES.md.

11. Update Test Suites Classification:
    - Rehomed / Updated: test/gh32-releases-app.sh, test/gh32-releases-artifacts.sh, test/gh284-p3-release-milestone.sh, test/gh284-p4-release-lanes.sh, test/releases-skill.sh.
    - Fixture-Only (Verified Safe): test/gh525-unshipped-version-tokens.sh, test/gh557-unknown-blocks-manifest.sh, test/gh197-vendor-tier-split.sh, test/gh57-releases-fuzz.sh, test/pdda-local-checks.sh.

12. Update Router Hard Gate & Documentation Contracts:
    - In utils/py/router_audit.py:626, remove RELEASES.md from the --fix role-split declaration template.
    - Update ROUTER.md:13,124-125,153,169, PROJECT/PDDA.md, AGENTS.md, ARCHITECTURE.md, RELEASES-DB-FAQS.md, HOW-TO-USE.md:48, relay-automation/README.md, utils/pdda/PDDA-INSTALL.md, skills/radar/SKILL.md:31,249, skills/relay-xyz/SKILL.md:181, and .claude/settings.json:10,13.

13. Falsifiable Permanent Regression Guard Test (test/gh568-releases-md-retired.sh):
    - Static Canary: Asserts [ ! -f "$root/RELEASES.md" ] and [ ! -f "$root/RELEASES.generated.md" ].
    - Static Writer Audit: Searches utils/, githooks/, relay-automation/, skills/, .github/workflows/ for production write, redirect, or regeneration commands targeting RELEASES.md or RELEASES.generated.md.
    - Exemptions: Explicitly exempts releases.sql data rows, LEADERBOARD.md, CHANGELOG.md, and historical archives.
    - Falsification & Red Controls: Test fixture verifies that restoring the root file AND injecting a simulated writer command each fail the guard independently. Asserts a non-empty candidate scan so an empty search root cannot pass.
    - Registered in validate.sh TESTS array.

## Acceptance Criteria

- [ ] RELEASES.md and RELEASES.generated.md are deleted from repo root and untracked; .gitignore is cleaned up.
- [ ] releases check verifies DB <-> canonical dump consistency without checking generated Markdown or drift files.
- [ ] doc_lines and legacy_lines schema usage is made dormant with no operational writes.
- [ ] test/nightwatch-release.sh and test/meter-release.sh manifest checks are rewired to releases.db and verified non-vacuous (--mutate-evidence reports RED when mutated).  [Unverified — no citation]
- [ ] utils/build-launch-artifact.sh, utils/py/swarm_preflight.py, and utils/timeline/export_timeline.py execute cleanly without RELEASES.md.
- [ ] utils/py/wave_reconcile.py, .github/workflows/wave-reconcile.yml, and utils/py/express.py remove all references to RELEASES.generated.md.
- [ ] tools/vscode-cockpit and skills/releases/SKILL.md route all release operations through releases_app.py.
- [ ] Dedicated regression guard test/gh568-releases-md-retired.sh with witnessed red controls is registered in validate.sh and passes.
- [ ] validate.sh passes 100% clean across all suites.
- [ ] Single atomic PR landed in sequence after GH-567.
```

Write your verdict below and change the `STATUS` to Approved/Closed if it passes, or specify required changes.



## Log

### Codex plan QA — changes requested

**Verdict: Blocking.** The migration direction is sound, but the proposed scope is not yet
end-to-end. The omissions below would either leave a live `RELEASES.md` reader in production or
make registered regression suites fail after the artifact is deleted.

1. **`utils/release-lanes.sh` is an unplanned live reader — Blocking.** It derives
   `RELEASES_FILE` as `$ROOT/RELEASES.md` and parses `Release:`, `Codename:`, `Status:`, and
   `Milestone:` to resolve `--release` and implicit milestones (`utils/release-lanes.sh:20-123`).
   That is release-to-marathon input, not archival prose. Deleting the root file leaves both
   `--release` and implicit resolution broken. Add a concrete replacement contract using the
   releases CLI's machine-readable interface (including NULL/ambiguous/no-milestone outcomes),
   update `test/gh284-p4-release-lanes.sh`'s crafted Markdown fixture, and revise the now-stale
   `test/gh284-p3-release-milestone.sh` and `validate.sh` descriptions. A red control must prove
   a missing/ambiguous DB milestone refuses rather than silently returning an empty issue set.

2. **The touched-test and live-contract inventory is incomplete — Blocking.** Two registered
   suites directly create/assert the retiring projection: `test/gh267-express-skill.sh:129-169`
   and `test/gh424-roadmap-status-marker.sh:30-174`. They must be rebaselined to the new
   reconciliation/rollback contract, not left outside the stated 15-suite classification.
   Also add the active user-facing contracts omitted from the documentation sweep:
   `skills/releases/SKILL.md:3-45,246-249`, `tools/vscode-cockpit/README.md:12-14`, and
   `utils/timeline/README.md:16,48-52`. Classify `PAGES/roadmap.html:69-70` explicitly as either
   a maintained projection to update or a historical artifact to retain under a named exemption;
   the plan presently claims repository-wide retirement without making that choice.

3. **The Phase-1 schema promise is internally underspecified — Blocking.** “Stop
   writing/updating `doc_lines`/`legacy_lines`” conflicts with retaining legacy external onboarding:
   `releases import` parses the legacy ledger (`utils/py/releases_app.py:1610-1629`) and
   `xyz-releases-onboard.sh` invokes that import. Specify command-by-command Phase-1 behavior:
   whether `import` remains supported for target repositories and may populate those historical
   tables, which root-repo commands may read them, what `releases migrate` changes, and the
   backward-compatible dump/replay contract. Pin each decision with an import/replay/migration
   test; otherwise “dormant/read-only” is not implementable or falsifiable.

4. **The planned negative controls need durable evidence destinations — Required.** For each
   rewritten goalpost and the new GH-568 guard, name the committed baseline/receipt path that
   records the witnessed RED control, then require the unmutated control to pass in the same
   execution. “`--mutate-evidence` reports RED” alone is a future promise and can regress into a
   vacuous check.

### Author response — Round 2 (Addressing Codex Plan QA Feedback)

All four blocking/required points from Codex plan QA have been fully addressed and incorporated into the canonical plan at `PROJECT/2-WORKING/GH-568-RETIRE-RELEASES-MD.md`:

1. **`utils/release-lanes.sh` Reader Replaced (Scope Section 4):**
   - `resolve_milestone()` in `utils/release-lanes.sh` is rewritten to query `releases.db` via `python3 utils/py/releases_app.py show` / `releases list --json` (or direct SQLite query against `milestone_title`), preserving the hierarchy: `--milestone` override > `--release NAME` match against version or codename > single in-progress release with a milestone.
   - Ambiguous, missing, or no-milestone conditions explicitly exit 3 with diagnostic refusals.
   - `test/gh284-p4-release-lanes.sh` is updated with a red control proving missing/ambiguous DB milestones refuse cleanly. Stale doc references in `test/gh284-p3-release-milestone.sh` and `validate.sh` are updated.

2. **Complete Touched-Test & Live-Contract Inventory (Scope Sections 8, 11, 12):**
   - `test/gh267-express-skill.sh:129-169` and `test/gh424-roadmap-status-marker.sh:30-174` are explicitly rebaselined to reflect the retired projection (`RELEASES.generated.md` removed from allowlists).
   - User-facing contracts added to documentation sweep: `skills/releases/SKILL.md:3-45,246-249`, `tools/vscode-cockpit/README.md:12-14`, `utils/timeline/README.md:16,48-52`.
   - `PAGES/roadmap.html:69-70` is explicitly classified as a historical issue-title entry and retained under a named exemption.

3. **Phase-1 Schema Behavior Specified Command-by-Command (Scope Section 3):**
   - External onboarding compatibility: `releases import` remains supported strictly for external target repositories onboarding from a legacy `RELEASES.md` via `xyz-releases-onboard.sh`; in that target repo context only, it may populate `doc_lines` and `legacy_lines`.
   - App-managed repo runtime commands (`add`, `update`, `ship`, `manifest`, `check`, `roadmap`): zero reads, zero writes, zero dependencies on `doc_lines` or `legacy_lines`.
   - `releases gen`: permanently retired in this repository.
   - Canonical dump/replay contract: preserves `doc_lines` and `legacy_lines` DDL in `releases.sql` to guarantee 100% backward-compatible git merge replays and historical fixture compatibility.
   - Eventual table dropping formulated as a future `releases migrate` step once all historical fixtures are migrated.

4. **Durable Evidence Destinations for Negative Controls (Scope Section 5 & Acceptance Criteria):**
   - Dedicated baseline evidence file: `test/baselines/GH-568-negative-control.md` will record witnessed RED controls for:
     - Mutated goalpost manifests in `test/nightwatch-release.sh`, `test/meter-release.sh`, and `test/ballast-release.sh`.
     - Static canary injection (restoring `RELEASES.md` at root).
     - Static writer injection (adding simulated `RELEASES.md` write/redirect in production scripts).
     - Empty candidate directory failure (preventing false clean on empty scans).
   - Both the red control execution and the unmutated green execution must be verified before PR submission.

Please review the revised plan in `PROJECT/2-WORKING/GH-568-RETIRE-RELEASES-MD.md` and provide your verdict.
 
<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
