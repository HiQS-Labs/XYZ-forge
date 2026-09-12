---
Goal: Final implementation QA — GH-568 End-to-End Retirement of RELEASES.md in Favor of releases.db
Date: 2026-09-12
Producer: claude-a
Reviewer: codex
NEXT: codex
STATUS: Open
Round-cap: 3
---

# Context

The plan in `PROJECT/2-WORKING/GH-568-RETIRE-RELEASES-MD.md` (which received `VERDICT: PASS` in Plan QA `relay-system/2026-09-10/gh568-retire-releases-md-plan-qa.md` at `e1e9a3c4`) is now fully implemented on branch `feat/gh568-retire-releases-md` across commits `ecc996bc`, `7cc8428d`, and `6e94bc97`.

The full validation suite (`./validate.sh --burst`) has run in a clean, separate disposable clone per `AGENTS.md` rules and is **100% GREEN (216/216 passed)**.
The frozen twin guard (`test/gh308-frozen-twin-guard.sh --check --staged`) passed clean with 0 frozen Bash twins modified and no new Bash.

This is a **review turn**: report findings, do not edit anything but this file.

### Implemented Surface Across All 14 Scopes:
1. **Scope 1 (File Removal & Gitignore):** `RELEASES.md` removed from repo root; `.gitignore` cleaned of `RELEASES.generated.md*`.
2. **Scope 2 (CLI & Check Contract):** Standardized on `python3 utils/py/releases_app.py list` and `releases show`. `releases gen` retired in `utils/py/releases_app.py:4844` (`refuse("retired", ...)`).
3. **Scope 3 (`releases check` Contract):** Validates DB <-> canonical dump consistency (generation marker, dump text equality, foreign keys pragma, receipt chain, business-state digest) without generated view or drift checks.
4. **Scope 4 (Release Seeding & Milestones):** `utils/release-lanes.sh` resolves milestones via SQLite from `releases.db` (`query_releases_db`).
5. **Scope 5 (Goalpost Manifest Checks & Silent Skips):** `test/nightwatch-release.sh`, `test/meter-release.sh`, `test/ballast-release.sh`, and `utils/pdda-local-checks.sh` rewired to query `releases.db`. Silent-pass fallbacks (`[ -f "$rel" ] || return 0`) eliminated.
6. **Scope 6 (Build & Preflight):** `utils/build-launch-artifact.sh` and `utils/py/swarm_preflight.py` docstrings/URLs updated to reference `releases.db`.
7. **Scope 7 (Timeline Exporter):** `utils/timeline/export_timeline.py` decoupled from `RELEASES.md` and drift comparisons; reads from `releases.db` and `releases.sql`.
8. **Scope 8 (Reconciliation & Supervisor Automation):**
   - `utils/py/wave_reconcile.py:1207`: removed `RELEASES.generated.md` from `snapshot_ledger_artifacts`.
   - `.github/workflows/wave-reconcile.yml:75`: removed `RELEASES.generated.md` from `exact` commit allowlist.
   - `utils/py/express.py`: removed `RELEASES.generated.md` from projections, reverts, and closeout allowlist.
   - `skills/merge-cleanup/scripts/merge_cleanup.py`: removed `releases_app.py gen` from `run_post_merge_reconcile`.
9. **Scope 9 (HQ & Onboarding):** `utils/hq/hq.sh` removed `releases gen` call; `relay-automation/xyz-releases-onboard.sh` updated.
10. **Scope 10 (PDDA Library & Local Checks):** `utils/pdda/pdda.sh:841-845` delegates `cmd_releases_current` to `releases_app.py list` when `releases.db` is present; `utils/pdda/pdda-lib.sh` updated.
11. **Scope 11 (VS Code Cockpit):** `tools/vscode-cockpit/src/extension.ts` and `dataSources/releases.ts` rewired to read `releases.db` with legacy fallback.
12. **Scope 12 (Test Suites Rehomed & Rebaselined):**
    - `test/fixtures/legacy-releases.md` created.
    - `test/gh32-releases-app.sh`: rehomed `REAL_LEDGER` to fixture; Section B asserts `releases gen` refusal (`rule=retired`); Section H exercises multi-stage crash recovery.
    - `test/gh32-releases-artifacts.sh`, `test/gh267-express-skill.sh`, `test/gh424-roadmap-status-marker.sh`, `test/gh284-p3-release-milestone.sh`, `test/gh284-p4-release-lanes.sh`, `test/gh107-timeline-json-seam.sh`, `test/gh57-releases-fuzz.sh`, `test/gh527-issue-url-repair.sh`, `test/gh436-merge-cleanup.sh` rebaselined and passing.
13. **Scope 13 (Router Hard Gate & Doc Contracts):** `utils/py/router_audit.py` removed `RELEASES.md` from `--fix` role-split template; `ROUTER.md`, `PROJECT/PDDA.md`, `ARCHITECTURE.md`, `RELEASES-DB-FAQS.md`, `HOW-TO-USE.md`, and skills updated.
14. **Scope 14 (Permanent Regression Guard & Negative Controls):**
    - Created `test/gh568-releases-md-retired.sh` (canary, production writer audit with empty-input guard, 5 witnessed red controls, `--mutate-evidence` mode).
    - Registered in `validate.sh` and `utils/ci-route.sh` (`releases` subsystem).
    - Witnessed transcripts recorded in `test/baselines/GH-568-negative-control.md`.

# Questions

Answer every question with `file:line` citations.

1. **Acceptance & Scope Completeness:** Walk each of the 14 scopes above. Are all planned removals and refactors fully satisfied in code? Are there any unaddressed remnants or dead paths?
2. **Static & Runtime Writer Audit:** Did any surviving active writers or write redirections to `RELEASES.md` or `RELEASES.generated.md` slip through in production code (`utils/`, `relay-automation/`, `skills/`, `.github/`)?
3. **Goalpost Manifest Checks & Fail-Closed Behavior:** Are silent-skip traps (`[ -f "$rel" ] || return 0`) genuinely eradicated in `test/nightwatch-release.sh`, `test/meter-release.sh`, `test/ballast-release.sh`, and `utils/pdda-local-checks.sh`? Do they fail closed when a release is missing or invalid?
4. **Falsifiable Regression Guard & Evidence:** Does `test/gh568-releases-md-retired.sh` provide robust, falsifiable coverage against reintroduction of `RELEASES.md` and active writers? Are the witnessed negative controls in `test/baselines/GH-568-negative-control.md` sufficient?
5. **Reversibility, Blast Radius, & Downstream Safety:** Does standardizing on `releases.db` and the CLI break any downstream or external workflows? Is the change cleanly reversible with atomic rollback?

Mark each question **Closed** or **Blocking** with cited lines.
Set `STATUS: Approved` only if none is Blocking; otherwise leave `STATUS: Open`, set `NEXT: claude-a`, and list every Blocking item as a numbered finding with the smallest fix you would accept.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
