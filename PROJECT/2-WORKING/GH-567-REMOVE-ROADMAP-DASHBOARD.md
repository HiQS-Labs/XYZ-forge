---
gh_issue: 567
source: https://github.com/HiQS-Labs/XYZ-forge/issues/567
title: "feat(ledger): end-to-end removal of ROADMAP-DASHBOARD.md and view-staleness machinery"
status: "In progress"
created: 2026-09-10
updated: 2026-09-10
owner: noelsaw
goal: "End-to-end removal of ROADMAP-DASHBOARD.md and view-staleness machinery across 11 scopes with permanent regression guard"
doc_type: enhancement
effort: 3
complexity: 3
risk: 2
supersedes: "PROJECT/1-INBOX/recon-roadmap-dashboard-removal.md (2026-09-07)"
sequence_before: 568
reversibility: Costly
---

# GH-567: End-to-End Removal of ROADMAP-DASHBOARD.md and View-Staleness Machinery

## Status

| What was just completed | What's next |
|---|---|
| Complete removal of `ROADMAP-DASHBOARD.md`, `utils/roadmap-dashboard.sh`, `githooks/dashboard-staleness-guard.sh`, update of `wave_reconcile`, `router_audit`, `jog`, `express`, `HQ`, `standup`, `ledger_merge`, and rehoming tests. Author permanent regression guard `test/gh567-roadmap-dashboard-retired.sh` with witnessed red controls (clean pass). | Full disposable clone validation gate pass, final Codex relay QA, push branch and open PR against `development`. |

## Problem Statement

`ROADMAP-DASHBOARD.md` is a committed, generated Markdown derivation of the `releases.db` roadmap ledger. Because it is committed into Git, it has been a persistent source of friction and over-engineering across the repository:
- Accounted for **19 out of 40 historical merge collisions** on `development` (sourced: `PROJECT/2-WORKING/recon-gh496-merge-churn-and-telemetry.md:32` and `PROJECT/2-WORKING/GH-496-SHARPEN-CICD.md:49`).
- Spurred a complex 195-line pre-push guard (`githooks/dashboard-staleness-guard.sh`) running git archive extraction and stderr inspections.
- Required automated post-merge reconciliation bot commits (`utils/py/wave_reconcile.py` / `.github/workflows/wave-reconcile.yml`) to keep it synced.
- Hard-coded in `utils/py/router_audit.py` as a mandatory contract in `ROUTER.md`.
- Requires multiple dedicated test suites (`test/roadmap-dashboard.sh`, `test/gh243-dashboard-staleness-guard.sh`).

The underlying truth is: **`releases.db` (via `releases.sql`) is already the sole source of truth**. GitHub does not render the database, and humans/agents who need to view the roadmap can do so on-demand via existing CLI tools (`releases roadmap list` or `releases roadmap render`). Committing this derived view creates continuous merge churn and brittle synchronization hooks.

The goal of this issue is an **end-to-end removal**—not merely gitignoring the file, but completely excising the committed view, all the secondary machinery built to protect it, and adding a permanent regression guard preventing it from returning.

## Supersession of 2026-09-07 Rejection

This issue explicitly supersedes the 2026-09-07 rejection recorded in `PROJECT/1-INBOX/recon-roadmap-dashboard-removal.md`:
1. **Router Hard Gate:** The prior rejection noted that `router_audit.py` mandated the dashboard. Under GH-567, rewriting the gate is explicitly in scope (Item 7) with an affirmative startup directive (`python3 utils/py/releases_app.py roadmap list`).
2. **Missing Alternatives:** AGENTS.md and GUIDING-PRINCIPLES.md previously named only the dashboard. They will now affirmatively direct readers to `releases roadmap list` / `releases.db`.
3. **Collision & Maintenance Weight:** The measured merge churn (19/40 conflicts), the 195-line pre-push guard, and post-merge CI bot noise decisively outweigh the passive Markdown mirror argument.
4. **Tooling Maturity:** HQ (`utils/hq/rollup.sh:35-69`) and other tools now consume `releases_app.py roadmap list --json` directly.

## Rollout, Phasing & Sequencing

- **One Atomic PR:** All file deletions, guard removals, reconciler updates, router-audit changes, and test updates must land in one atomic PR. Rollback is a single revert restoring all coupled paths together.
- **Pre-Merge Sweep:** Identify open branches touching `ROADMAP-DASHBOARD.md` or the ledger and require rebasing before merge to prevent delete/modify conflicts. Old clones will retain their local pre-push guard until updated.
- **Live In-Flight Coordination:** An in-flight marathon P1 lane is currently modifying `ROADMAP-DASHBOARD.md`, `releases.db`/`releases.sql`, and `utils/hq/` scripts. GH-567 must coordinate and land cleanly relative to this lane.
- **Sequencing with GH-568:** **GH-567 lands FIRST.** GH-568 (`RELEASES.md` retirement) lands second, rebasing on `development` and re-verifying shared lists in `releases-merge-resolve.sh:160`, `wave-reconcile.yml:76`, `jog_run.py:286`, and `express.py:699`.

## Scope of End-to-End Removal

1. **Delete Tracked Artifact & Renderer:**
   - Remove `ROADMAP-DASHBOARD.md` from Git tracking and disk.
   - Delete `utils/roadmap-dashboard.sh`.
   - Do NOT simply leave it as a gitignored auto-generated root file; retire the requirement that it exists on disk.

2. **On-Demand Human Readability:**
   - Retain / streamline `python3 utils/py/releases_app.py roadmap list` (human/terminal default) and `roadmap render` (on-demand ephemeral export) so humans or agents can inspect the ledger instantly without needing a committed root Markdown artifact.
   - `releases_app.py roadmap list --json` remains the machine interface (already consumed by `utils/hq/rollup.sh:35-69`).

3. **Excise Pre-Push Staleness Guard:**
   - Delete `githooks/dashboard-staleness-guard.sh` entirely.
   - Remove its invocation from `githooks/pre-push` (`:88-99`).
   - Remove corresponding tests: `test/gh243-dashboard-staleness-guard.sh` and `test/roadmap-dashboard.sh`, and remove from `validate.sh`.

4. **Update Reconciler & Post-Merge Workflows:**
   - In `utils/py/wave_reconcile.py` (`:913-917, 949-1001`) and `.github/workflows/wave-reconcile.yml` (`:75-80`), remove `ROADMAP-DASHBOARD.md` from snapshotting, regeneration, staging, and workflow allowlists.
   - Update reconciler test suites: `test/wave-reconcile.sh`, `test/gh421-auto-wave-reconcile.sh`, `test/gh454-reconciler-defects.sh:40,105,145`, and `test/gh202-wave-reconcile-issue-state.sh:232-267,302`.
   - Update `test/gh424-roadmap-status-marker.sh:31` derived-views list.
   - Retain `test/gh534_phase_c_tests.py:318-334` (fixture usage asserting merge-cleanup does not resurrect deleted views). Classify `test/baselines/GH-424-negative-control.md:80` as exempt historical evidence.

5. **Update Merge Conflict Resolver:**
   - In `utils/releases-merge-resolve.sh` (`:160-204`), remove `ROADMAP-DASHBOARD.md` from `DERIVED` / `VIEWS` conflict handling and regeneration.
   - Update `test/gh57-live-merge-resolve.sh`.

6. **Migrate Jog & Express Runtimes:**
   - In `utils/py/jog_run.py` (`:244-260, 285-289, 608-615`), remove `jog_regenerate_dashboard` and remove `ROADMAP-DASHBOARD.md` from supervisor staging. Update `test/gh280-jog-marathon-adapter.sh`.
   - In `utils/py/express.py`, remove `ROADMAP-DASHBOARD.md` from `DRIVER_GENERATED` (`:74`), staging (`paths.add("ROADMAP-DASHBOARD.md")` at `:222`), and `CLOSEOUT_ALLOWLIST_FILES` (`:699`). Update `test/gh267-express-skill.sh`.

7. **Update Router Hard Gate & Documentation Contracts:**
   - In `utils/py/router_audit.py` (`:397-407, 454-463`), preserve releases-mode detection and `ROADMAP.md` legacy freeze, while removing the dashboard requirement.
   - Rework `--fix` (`:576-663`) to emit affirmative startup directive to `python3 utils/py/releases_app.py roadmap list`.
   - Update `test/gh353-vendored-router-audit.sh` matrix (valid CLI route passes, wrong route fails, `--fix` repairs idempotently).
   - Update `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `ARCHITECTURE.md` (`:18, 385-441, 464`), and hand-maintained `ARCHITECTURE/ledger-diagram.json` (node `:88`, description `:192`) and `ARCHITECTURE/ledger-diagram.html`.
   - Classify `PAGES/roadmap.html:64` as historical generated content, exempt from active removal.

8. **CI Route & Test Registry Migration:**
   - In `utils/ci-route.sh` (`:25-26, 38`), remove `roadmap-dashboard.sh` from HQ and releases focused suite registries and path mapping.
   - In `test/ci-route.sh` (`:158-161`), update the registry assertions.

9. **Migrate HQ, Standup, and Merge-Cleanup Runtime Surfaces:**
   - In `utils/hq/hq-lib.sh`, remove the `LOCAL_DASHBOARD_STALE` check in releases mode (at symbol `LOCAL_DASHBOARD_STALE`). Update `test/gh239-hq-status-releases-mode.sh`.
   - In `utils/hq/hq.sh` (`:360-374`), clarify / preserve legacy target handling or migrate cleanly.
   - In `skills/standup/collect.sh` (`:545`) and `test/gh77-standup-triage.sh` (`:428-430`), migrate the triage close command to DB/CLI-only.
   - In `skills/merge-cleanup/scripts/ledger_merge.py` (`:34-37`) and `skills/merge-cleanup/SKILL.md` (`:119`), remove `ROADMAP-DASHBOARD.md` from `LEDGER_VIEWS` and conflict resolution.
   - Update operator-facing docs: `skills/express/SKILL.md:83-86`, `skills/vendor-stack/SKILL.md:111-114`, `utils/README.md:136`, `utils/py/site_build.py:7-9`, and `run-tests.sh:8-10`.

10. **Rehome Existing Renderer Test Coverage:**
    - In `test/gh269-roadmap-retired.sh` (`:25-30`), rewrite the renderer check to assert the CLI-only releases-mode route.
    - In `test/gh491-roadmap-section-validation.sh` (`:20, 123-183`), rehome section-vocabulary and red-control coverage to `releases_app.py roadmap render`.
    - In `test/gh257-roadmap-ledger-fixes.sh` (`:189-245`, Cases 10+), rehome dropped-row warning visibility (`roadmap-dashboard: warning: dropped N unparseable row(s)...`) to `releases_app.py roadmap list`/`render` stderr.
    - In `test/gh232-wave-reconcile-multiphase.sh` (`:75-84`), update downstream stubs.

11. **Falsifiable Permanent Regression Guard Test (`test/gh567-roadmap-dashboard-retired.sh`):**
    - Modeled after `test/gh269-roadmap-retired.sh`.
    - Static canary: asserts `[ ! -f "$root/ROADMAP-DASHBOARD.md" ]`. If any tool resurrects the file at repo root, the suite fails.
    - Static writer audit: searches `utils/`, `githooks/`, `relay-automation/`, `skills/*/scripts/`, `skills/standup/`, and `.github/workflows/` for production write, redirect, or regeneration commands targeting `ROADMAP-DASHBOARD.md`.
    - Pre-wired benign exemptions: `releases.sql` data rows (GH-75/GH-474/GH-567 issue titles), `utils/leaderboard.sh:11` comment, historical/evidence directories (`docs/`, `PROJECT/`, `relay-system/`, `PARKED/`, `evidence/`, `TESTS-RESULTS/`).
    - **Falsification & Red-Control Contract:** Test fixture verifies that restoring a root dashboard AND injecting a simulated production writer each cause the guard to report RED. Asserts non-empty candidate scan so an empty search root cannot pass.
    - Registered in `validate.sh` `TESTS` array.

## Lessons Learned (For Future Agents)

1. **Derived Views in Git Cause Compounding Friction:** Committing generated Markdown artifacts (`ROADMAP-DASHBOARD.md`) as derived views of a transactional database (`releases.db`) inevitably creates merge collisions, complex staleness hooks, and sync race conditions. Providing on-demand CLI queries (`releases roadmap list`, `roadmap render`) is cleaner, faster, and eliminates collision surfaces completely.
2. **Remove the Whole Surface Atomically:** When retiring a root artifact, every secondary subsystem built around it (pre-push hooks, reconciler passes, router-audit gates, merge resolver derived-views lists, tool adapters) must be updated simultaneously, guarded by a permanent regression test with falsifiable red controls (`test/gh567-roadmap-dashboard-retired.sh`).

## Acceptance Criteria

- [x] `ROADMAP-DASHBOARD.md` is removed from git tracking and deleted, and `utils/roadmap-dashboard.sh` is retired.
- [x] `githooks/dashboard-staleness-guard.sh` is deleted and unregistered from `githooks/pre-push`.
- [x] `utils/py/jog_run.py`, `utils/py/express.py`, and `skills/standup/collect.sh` no longer reference or stage `ROADMAP-DASHBOARD.md`.
- [x] `utils/releases-merge-resolve.sh` and `skills/merge-cleanup/scripts/ledger_merge.py` remove `ROADMAP-DASHBOARD.md` from derived views.
- [x] `utils/ci-route.sh` and `test/ci-route.sh` update test routing registries.
- [x] `utils/py/wave_reconcile.py`, `.github/workflows/wave-reconcile.yml`, and tests (`test/wave-reconcile.sh`, `test/gh421-auto-wave-reconcile.sh`, `test/gh454-reconciler-defects.sh`, `test/gh202-wave-reconcile-issue-state.sh`) succeed without generating or committing `ROADMAP-DASHBOARD.md`.
- [x] `utils/py/router_audit.py` passes without requiring `ROADMAP-DASHBOARD.md`, and `--fix` emits `releases roadmap list` directive.
- [x] Hand-maintained `ARCHITECTURE/ledger-diagram.json` and `ARCHITECTURE/ledger-diagram.html` are updated.
- [x] Rehomed test coverage in `test/gh269-roadmap-retired.sh`, `test/gh491-roadmap-section-validation.sh`, and `test/gh257-roadmap-ledger-fixes.sh` passes cleanly.
- [x] Dedicated regression guard `test/gh567-roadmap-dashboard-retired.sh` with witnessed red controls is registered in `validate.sh`.
- [x] `validate.sh` passes 100% clean across all suites.
- [x] `python3 utils/py/releases_app.py roadmap list` serves as the primary query interface.
- [ ] Single atomic PR landed in sequence before GH-568.

## Merge evidence

- PR #576 merged 2026-09-11 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
