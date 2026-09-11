---
Goal: Implementation QA for End-to-End Removal of ROADMAP-DASHBOARD.md (GH-567)
Date: 2026-09-10
NEXT: Codex
STATUS: In review
ROUND: 1 / 3
---

# Context

Review the **committed implementation** of GH-567: end-to-end removal of `ROADMAP-DASHBOARD.md` and view-staleness machinery.

Branch: `feat/gh567-remove-roadmap-dashboard`

Read in full:
- `PROJECT/2-WORKING/GH-567-REMOVE-ROADMAP-DASHBOARD.md` — canonical task document and implementation plan addressing all 7 feedback items from plan QA.
- `relay-system/2026-09-10/gh567-remove-roadmap-dashboard-plan-qa.md` — prior plan QA review rounds.

Summary of Implementation across 11 scopes:
1. Deleted `ROADMAP-DASHBOARD.md` and `utils/roadmap-dashboard.sh`.
2. Deleted `githooks/dashboard-staleness-guard.sh`, removed its invocation from `githooks/pre-push`, and deleted `test/gh243-dashboard-staleness-guard.sh` and `test/roadmap-dashboard.sh`.
3. Updated `utils/py/wave_reconcile.py` (removed dashboard regeneration, snapshot, and rollback boundaries) and `.github/workflows/wave-reconcile.yml`.
4. Updated `utils/releases-merge-resolve.sh` (removed dashboard from derived views and conflict resolution) and `test/gh57-live-merge-resolve.sh`.
5. Updated `utils/py/jog_run.py` (removed dashboard references, staging, and generation) and `utils/py/express.py`.
6. Updated `utils/py/router_audit.py` (affirmative CLI startup directive `releases roadmap list`), `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `ARCHITECTURE.md`, and `ARCHITECTURE/ledger-diagram.json` + `html`.
7. Updated `utils/ci-route.sh` and `test/ci-route.sh` suite counts (14->13 HQ, 22->21 releases).
8. Updated `utils/hq/hq-lib.sh`, `utils/hq/hq.sh`, `skills/standup/collect.sh`, `skills/merge-cleanup/scripts/ledger_merge.py`, and operator docs.
9. Rehomed test coverage in `test/gh269-roadmap-retired.sh`, `test/gh491-roadmap-section-validation.sh`, `test/gh257-roadmap-ledger-fixes.sh`, `test/hq-park-synthesis.sh`, and `test/gh232-wave-reconcile-multiphase.sh`.
10. Authored `test/gh567-roadmap-dashboard-retired.sh`: permanent regression guard with static canaries, active tool execution checks, writer audits, empty-input protection, and witnessed red controls.
11. Updated downstream test harnesses (`test/gh358-wave-reconcile-vendored-paths.sh`, `test/gh421-auto-wave-reconcile.sh`, `test/gh429-wave-reconcile-vendored-observe.sh`, `test/gh534_phase_c_tests.py`, `test/gh267-express-skill.sh`).

Gate status:
- Full `./validate.sh` suite executed in a clean disposable full clone: **100% green pass** (zero test suite failures across 200+ test suites).
- All PDDA doc checks (`pdda.sh run`) passed with 0 errors.
- Test tiers and CPU governance (`test/gh35-test-tiers.sh`) passed: 71 pass, 0 fail.
- Frozen Bash twin guard (`test/gh308-frozen-twin-guard.sh`) passed: clean.

## Questions

Answer each with a verdict and cite `file:line` where you disagree.

1. **Completeness of Removal:** Are there any active production scripts, hooks, or CI workflows where `ROADMAP-DASHBOARD.md` or its former rendering scripts still linger as a dependency or side-effect?
2. **Rehomed Coverage & Regression Defense:** Does `test/gh567-roadmap-dashboard-retired.sh` and the rehomed assertions in `gh491`/`gh269`/`gh257` adequately guard against regressions while satisfying the falsifiability / red-control contract?
3. **Merge & Conflict Resolution Safety:** Does removing `ROADMAP-DASHBOARD.md` from `LEDGER_VIEWS` in `utils/releases-merge-resolve.sh` and `skills/merge-cleanup/scripts/ledger_merge.py` safely avoid resurrecting the file or triggering spurious merge conflict refusals?
4. **Router and Documentation Integrity:** Does `ROUTER.md`, `AGENTS.md`, and `router_audit.py` provide clear, affirmative direction to `releases roadmap list` without dead links or broken governance checks?

Write your verdict below and change `STATUS` to Approved/Closed if it passes, or specify required changes.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
