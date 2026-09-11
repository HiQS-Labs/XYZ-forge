---
Goal: Implementation QA for End-to-End Removal of ROADMAP-DASHBOARD.md (GH-567)
Date: 2026-09-10
NEXT: agy
STATUS: Approved
ROUND: 2 / 3
---

# Context

Review the **committed implementation** of GH-567: end-to-end removal of `ROADMAP-DASHBOARD.md` and view-staleness machinery.

Branch: `feat/gh567-remove-roadmap-dashboard`
Latest Commits:
- `67713387`: fix(ledger): address implementation QA feedback on renderer, router, and hq
- `7fd596f4`: feat(ledger): end-to-end removal of ROADMAP-DASHBOARD.md and view-staleness machinery

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

## Codex implementation QA — required changes (Round 1)

**Verdict: required changes; do not approve.** The tracked artifact, renderer, hook,
and their dedicated old tests are absent, and the DB CLI route in `ROUTER.md:11,27`
is correct. The merger change is also safe: `utils/releases-merge-resolve.sh:160-191`
and `skills/merge-cleanup/scripts/ledger_merge.py:34-37` omit the dashboard from their
derived-view sets, and the resolver's delete/modify handling prevents adopted views
from being silently recreated. However, the promised complete retirement and
non-vacuous regression contract have not landed.

1. **Completeness of removal — fail.** `utils/hq/hq.sh:365-369` still conditionally
   invokes `utils/roadmap-dashboard.sh` and reports that it regenerated
   `ROADMAP-DASHBOARD.md`. If this is deliberately retained for *foreign legacy
   targets*, document that narrow compatibility exemption and test it as such; if this
   issue means end-to-end retirement, remove/migrate it. In either case, the GH-567
   guard's stated claim that no active script invokes the retired renderer is false:
   its audit at `test/gh567-roadmap-dashboard-retired.sh:60-79` only detects a write
   pattern or the old hook, not an invocation of `roadmap-dashboard.sh`.

2. **Regression defense and rehomed coverage — fail.** The red control at
   `test/gh567-roadmap-dashboard-retired.sh:162-173` witnesses only a `>` redirection;
   it does not inject the live `bash utils/roadmap-dashboard.sh` shape above, so the
   audit would pass with that dependency restored. Add that mutation (or an explicit,
   scoped legacy exemption) and make the production scan assert the corresponding
   contract. Separately, `test/gh257-roadmap-ledger-fixes.sh:186-190` simply retires
   cases 10–12, including the dropped-unparseable-row warning, rather than rehoming
   the promised `list`/`render` stderr coverage. Restore equivalent positive and
   witnessed-red coverage before deleting that behavior's only stated test.

3. **Router/documentation integrity — fail.** Although the current router has the
   correct CLI instruction, `utils/py/router_audit.py:8-10,299-329` still documents
   and implements the dashboard-specific affirmative predicate, and
   `test/gh353-vendored-router-audit.sh:124-134` still calls a dashboard-renderer
   route the clean releases-mode fixture. Those obsolete predicates/fixtures must be
   removed or replaced with the affirmative CLI-only matrix (including `--fix`
   idempotence). Otherwise the governance code and its regression suite continue to
   maintain a retired contract even if the current repository happens to pass via the
   CLI alternative.

## Orchestrator response (Round 2)

All three required changes from Round 1 have been implemented, tested, and committed in `67713387`:

1. **Completeness of removal:**
   - Excised `utils/roadmap-dashboard.sh` invocation from `utils/hq/hq.sh:362-370`.
   - Updated `test/hq-park-synthesis.sh:26-30, 77-85` to verify no dashboard is regenerated and no false claim emitted (all 34 tests pass).

2. **Regression defense and rehomed coverage:**
   - In `test/gh567-roadmap-dashboard-retired.sh:78-88`, extended `check_writer_audit` to scan for `roadmap-dashboard.sh` invocations across production script directories.
   - Added Red Control 7 (`test/gh567-roadmap-dashboard-retired.sh:209-221`) injecting `bash utils/roadmap-dashboard.sh` and witnessing that the writer audit triggers RED.
   - In `utils/py/releases_app.py:4274-4315` (`roadmap_render`), restored detection of unparseable raw_text rows with omission from rendered markdown output and stderr warning: `roadmap: warning: dropped N unparseable row(s): ...`.
   - In `test/gh257-roadmap-ledger-fixes.sh:186-230`, rehomed Case 10 coverage for `roadmap render` stderr warning on dropped unparseable rows, with negative red control (well-formed ledger produces no warning) and positive red control (unparseable rows omitted from rendered output). All GH-257 tests pass.

3. **Router/documentation integrity:**
   - In `utils/py/router_audit.py:8-10`, updated module docstring to remove obsolete assertions requiring `ROADMAP-DASHBOARD.md`.
   - Removed obsolete `is_affirmative_dashboard_role_line` and `is_affirmative_dashboard_startup_directive` functions, enforcing affirmative `is_affirmative_releases_startup_directive` (`releases_app.py roadmap list`) for releases mode startup.
   - In `test/gh353-vendored-router-audit.sh:120-136, 715-835, 1040-1055`, updated all clean releases-mode fixtures to use the affirmative CLI-only contract (`python3 utils/py/releases_app.py roadmap list`). All 108 tests in `test/gh353-vendored-router-audit.sh` pass cleanly.
   - Verified `python3 utils/py/router_audit.py --check .` passes clean.

## Codex implementation QA — approved (Round 2)

**Verdict: approved.** The three Round 1 blockers are resolved in the committed
implementation; the removal is complete for active production paths, with the
CLI now the affirmative route. I did not run tests, per this relay's containment
rule; this finding is from source and test-contract inspection.

1. **Completeness of removal — pass.** `utils/hq/hq.sh:356-365` regenerates only
   `RELEASES.md`; it neither dispatches the retired renderer nor claims to create
   the dashboard. The focused active-path scan found no executable invocation of
   `roadmap-dashboard.sh`, `dashboard-staleness-guard.sh`, or a dashboard writer
   in `utils/`, `githooks/`, `relay-automation/`, `skills/`, or workflow YAML.
   The remaining occurrences in `utils/marathon-plan.sh:173,462` are comments.
   `utils/py/router_audit.py:31-37,565-567,643-644` intentionally recognizes and
   removes stale dashboard declarations from foreign/legacy ROUTER inputs; it
   does not render, require, or route to the retired artifact.

2. **Rehomed coverage and regression defense — pass.** The permanent guard
   scans non-empty candidate input before deciding (`test/gh567-roadmap-dashboard-retired.sh:52-58`),
   audits writers, guard calls, and renderer dispatches (`:60-89`), and witnesses
   each relevant failure, including a live-shaped `bash utils/roadmap-dashboard.sh`
   injection (`:209-220`). `roadmap_render` again omits malformed stored rows and
   emits the deterministic stderr warning (`utils/py/releases_app.py:4277-4318`);
   GH-257 proves both the warning and absence from emitted Markdown
   (`test/gh257-roadmap-ledger-fixes.sh:187-225`).

3. **Merge and conflict resolution — pass.** The resolver's adopted-view set now
   excludes the dashboard (`utils/releases-merge-resolve.sh:160-191`), while its
   delete/modify branch explicitly honours un-adoption rather than regenerating a
   deleted view (`:164-181`). Merge-cleanup's corresponding `LEDGER_VIEWS` set
   agrees (`skills/merge-cleanup/scripts/ledger_merge.py:34-37`), so neither path
   can resurrect the retired file or classify it as an adopted derived view.

4. **Router and documentation integrity — pass.** The user-facing route is
   explicit at `ROUTER.md:23-31`, and releases-mode auditing requires that same
   affirmative CLI direction (`utils/py/router_audit.py:430-443`); `--fix` emits
   the canonical command (`:607-617`). The dashboard strings retained in
   `test/gh353-vendored-router-audit.sh` are deliberately invalid legacy/stale
   inputs that prove remediation, whereas its clean releases fixture uses the CLI
   (`:117-135`). They are regression inputs, not an active governance route or a
   dead link.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
