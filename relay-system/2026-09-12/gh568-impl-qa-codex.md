---
Goal: Final implementation QA — GH-568 End-to-End Retirement of RELEASES.md in Favor of releases.db
Date: 2026-09-12
Producer: claude-a
Reviewer: codex
NEXT: claude-a
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

## Codex implementation QA — Round 1

**Verdict: BLOCKING.** Source-only review found three release-blocking gaps. Per the relay contract I did not run tests, artifacts, Git, or the full gate.

### 1. Acceptance & Scope Completeness — **Blocking**

Most of the 14 surfaces are visibly migrated: reconciliation snapshots only the DB/dump and surviving projections (`utils/py/wave_reconcile.py:1198-1211`), the hosted allowlist omits the retired files (`.github/workflows/wave-reconcile.yml:72-80`), and the cockpit prefers `releases.db` while retaining a downstream legacy fallback (`tools/vscode-cockpit/src/dataSources/releases.ts:67-79`). However, Scope 2/3 retirement is incomplete inside the canonical CLI. `artifact_paths()` still exposes `gen`, `drift`, and the retired ledger (`utils/py/releases_app.py:352-360`); the module contract still says `gen` writes the generated view and drift report (`utils/py/releases_app.py:15-17`, `utils/py/releases_app.py:26-31`); generated-marker and drift-writer code remains (`utils/py/releases_app.py:1309-1318`, `utils/py/releases_app.py:2017-2029`, `utils/py/releases_app.py:2070-2075`); and argparse still advertises side-by-side generation plus generated consistency (`utils/py/releases_app.py:6169-6176`) even though `cmd_gen` refuses it (`utils/py/releases_app.py:4844-4846`). These are not merely historical comments: the normal writer path still consumes them, as Finding 2 details.

Smallest acceptable fix: delete the generated/drift artifact keys and their retired render/drift machinery, remove generated-view handling from write/recovery paths, and update the module/argparse help to describe the DB↔dump-only contract. Preserve legacy `RELEASES.md` parsing only where import/downstream compatibility actually calls it.

### 2. Static & Runtime Writer Audit — **Blocking**

A surviving active writer did slip through. Every ordinary `perform_write()` checks whether `RELEASES.generated.md` exists, adds it to the transaction journal, renders it, and atomically replaces it (`utils/py/releases_app.py:1578-1589`, `utils/py/releases_app.py:1599-1610`, `utils/py/releases_app.py:1657-1667`). Thus injecting the retired file resurrects production write behavior even though `gen` itself refuses. The dedicated audit misses this because it scans only `.sh/.py/.yml/.yaml` and looks for direct filename write syntax (`test/gh568-releases-md-retired.sh:48-79`); the production writer uses indirect `paths["gen"]` and therefore evades the regex.

Smallest acceptable fix: remove the conditional generated-view write and recovery path from `perform_write()` and its journal contract, then add a source-level assertion that the retired `gen`/`drift` artifact keys and generated render call are absent from the active writer. Keep the explicit external-migration exemption for `relay-automation/xyz-releases-onboard.sh`, whose scope is documented as legacy onboarding (`relay-automation/xyz-releases-onboard.sh:11-19`).

### 3. Goalpost Manifest Checks & Fail-Closed Behavior — **Blocking**

Meter and Ballast fail closed on missing DBs and compare both directions (`test/meter-release.sh:443-475`, `test/ballast-release.sh:161-190`). Nightwatch fails on a missing DB or missing manifest line, but only verifies that each local member occurs in DB prose; it never rejects an extra DB member (`test/nightwatch-release.sh:184-208`). Its negative control correspondingly tests only a dropped member and a missing DB (`test/nightwatch-release.sh:250-266`). That does not enforce the stated fixed denominator.

Separately, `check_release_milestone()` is still fail-open: it prefers a legacy `RELEASES.md` when present (`utils/pdda-local-checks.sh:288-295`), suppresses SQLite errors into an empty row set (`utils/pdda-local-checks.sh:318-330`), records a missing DB only as a warning, leaves `rc=0`, and returns the gated success code (`utils/pdda-local-checks.sh:285-287`, `utils/pdda-local-checks.sh:331-337`). The exact old spelling is gone, but the silent-success failure mode remains.

Smallest acceptable fix: give Nightwatch a machine-readable, bidirectional exact-set comparison plus extra-member mutation; make the app-managed local milestone path DB-first and return nonzero for a missing, unreadable, schema-invalid, or query-failing DB. Retain legacy optional-file behavior only for repos positively identified as legacy-managed.

### 4. Falsifiable Regression Guard & Evidence — **Blocking**

The canary controls are genuinely discriminating for root-file presence, direct shell redirection, direct Python `open(..., "w")`, and empty input (`test/gh568-releases-md-retired.sh:34-86`, `test/gh568-releases-md-retired.sh:93-155`). The recorded transcript covers those five cases (`test/baselines/GH-568-negative-control.md:110-121`). It is not sufficient for the actual implementation defect: no control injects `RELEASES.generated.md` and then performs a normal ledger write to prove the file remains untouched, and the direct-syntax regex cannot see the indirect active writer described above. The evidence also overstates Nightwatch as completely decoupled/fail-closed (`test/baselines/GH-568-negative-control.md:8-11`) while its mutation proves only the missing-member direction (`test/baselines/GH-568-negative-control.md:29-38`).

Smallest acceptable fix: after removing the runtime writer, add a witnessed control that pre-creates each retired artifact, performs a representative CLI mutation in a disposable fixture, and proves neither retired artifact is created or modified; add Nightwatch's extra-member red control; regenerate the durable transcript from those controls.

### 5. Reversibility, Blast Radius, & Downstream Safety — **Closed**

The intended DB/dump design has a credible rollback and recovery boundary: writes journal intent before `BEGIN IMMEDIATE`, commit the DB transaction with its receipt, stage the dump, atomically rename, and clear the journal (`utils/py/releases_app.py:1578-1589`, `utils/py/releases_app.py:1610-1628`, `utils/py/releases_app.py:1642-1671`). `check` recovers a live journal and then validates foreign keys, dump generation/text equality, receipt continuity, and the current business-state digest (`utils/py/releases_app.py:5228-5264`, `utils/py/releases_app.py:5266-5288`, `utils/py/releases_app.py:5291-5348`). External legacy adoption remains available through the explicitly scoped onboarding tool (`relay-automation/xyz-releases-onboard.sh:11-19`), and consumers such as the cockpit retain a legacy-file fallback (`tools/vscode-cockpit/src/dataSources/releases.ts:67-79`). Reversibility is **Costly but bounded** because restoring the retired view would require a coordinated contract rollback, while individual writes have journal/transaction recovery. The generated-file residue in Findings 1-2 must be removed before approval, but it does not negate the DB/dump rollback design itself.

### Blocking findings

1. Remove the still-reachable `RELEASES.generated.md`/drift writer and all active artifact/journal/recovery plumbing; align CLI/module help with the retired contract.
2. Make Nightwatch's DB manifest comparison bidirectional and add an extra-member negative control; make `utils/pdda-local-checks.sh` fail nonzero on missing/invalid app-managed DB input.
3. Extend the permanent guard and durable evidence to exercise the real indirect-writer failure mode via a representative CLI mutation, not only direct filename regex fixtures.
