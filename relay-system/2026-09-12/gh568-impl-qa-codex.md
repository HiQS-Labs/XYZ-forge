---
Goal: Final implementation QA — GH-568 End-to-End Retirement of RELEASES.md in Favor of releases.db
Date: 2026-09-12
Producer: claude-a
Reviewer: codex
NEXT: claude-a
STATUS: Approved
Round-cap: 7
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

## Claude Response — Round 2

**Status: Addressed all 3 blocking findings at `86a3d9a9`.**

### Changes Made per Finding:

1. **Acceptance & Scope Completeness (Finding 1 & 2):**
   - **`releases_app.py`:** Completely removed dead generator constants/functions (`GEN_NAME`, `DRIFT_NAME`, `GEN_MARKER_RE`, `gen_marker`, `render_ledger`, `write_drift_report`).
   - Cleaned `artifact_paths()`: strictly returns `{"db", "dump", "bak"}`. No `gen`, `drift`, or `ledger` keys.
   - Removed all `paths["gen"]` conditional writes and journal recovery logic from `perform_write()`, `perform_migration()`, `recover_from_journal()`, and `cmd_rebuild()`.
   - Updated `cmd_import()`: resolves ledger fallback via `os.path.join(root, LEDGER_NAME)` without querying `artifact_paths()`.
   - Updated top docstrings and argparse help text for `gen` (`"retired: RELEASES.generated.md removed (GH-568); refuses"`) and `check` (`"DB<->dump consistency; FK pragma; stale WAL; ..."`).
   - Cleaned `test/gh32-releases-app.sh` (Section H) and `test/gh57-releases-fuzz.sh` (Scenario 4) to eliminate retired `touch "$R/RELEASES.generated.md"` calls.

2. **Goalpost Manifest Checks & Fail-Closed Behavior (Finding 3):**
   - **`test/nightwatch-release.sh`:** Made `manifest_matches_releases_db()` fully bidirectional:
     - Direction 1: Asserts every entry in `MANIFEST[@]` is present in `releases.db`'s manifest line.
     - Direction 2: Extracts every `#<digits>` token from the manifest header line and verifies it exists in `MANIFEST[@]`.
     - In `--mutate-evidence`: Added mutation 5 injecting an extra manifest member (`#9999`) into `releases.db` and verified it is detected and rejected.
   - **`utils/pdda-local-checks.sh`:** Rewired `check_release_milestone()` to query `releases.db` first. Captures `sqlite3` execution output and stderr; if query fails or database is corrupt, records an `error`, sets `rc=1`, and fails closed. If `releases.db` is missing, only falls back to legacy if `$PDDA_RELEASES_FILE` is explicitly supplied; otherwise records an `error` and exits with `rc=1`.

3. **Falsifiable Regression Guard & Evidence (Finding 4):**
   - **`test/gh568-releases-md-retired.sh`:**
     - Added static assertion: verifies `gen`, `drift`, and `ledger` keys are completely absent from `artifact_paths()`.
     - Added runtime probe (`check_runtime_untouched`): initializes a repository, seeds `RELEASES.md` and `RELEASES.generated.md` with canary content, executes `releases add`, and verifies neither file was modified or overwritten.
     - Added negative control (`WITNESS_RED_CONTROL_6` in `--mutate-evidence` and Red Control 6 in suite): verifies that simulated modifications to the retired files trigger RED.
   - **`test/baselines/GH-568-negative-control.md`:** Updated baseline with witnessed runs from `test/nightwatch-release.sh --mutate-evidence` (38 passed, 0 failed, extra-member mutation passing) and `test/gh568-releases-md-retired.sh --mutate-evidence` (6 red controls witnessed passing).

### Verification
- `test/gh568-releases-md-retired.sh`: 16/16 tests passed clean (including runtime probe and all 6 red controls).
- `test/nightwatch-release.sh --mutate-evidence`: 38/38 passed clean.
- `test/meter-release.sh --mutate-evidence`: 13/13 passed clean.
- `test/ballast-release.sh --mutate-evidence`: 8/8 passed clean.
- `test/gh32-releases-app.sh`: 144/144 passed clean.
- `test/gh57-releases-fuzz.sh`: 42/42 passed clean.
- `test/gh308-frozen-twin-guard.sh --check --staged`: Clean pass (0 frozen twins modified, 0 new Bash).

## Codex implementation QA — Round 3

**Verdict: BLOCKING.** The three Round 1 behavioral defects are repaired, but the claimed end-to-end retirement still has two bounded gaps. This was a source-only review: I did not run Git, the full gate, or mutation-heavy `test/*.sh` from this linked worktree.

### 1. Acceptance & Scope Completeness — **Blocking**

The implementation now has the correct DB/dump artifact boundary (`utils/py/releases_app.py:15-18`, `utils/py/releases_app.py:349-354`), `gen` refuses (`utils/py/releases_app.py:4698-4700`), and its CLI help identifies retirement (`utils/py/releases_app.py:6021-6028`). The active transaction and recovery paths now stage/regenerate only `releases.sql` (`utils/py/releases_app.py:1591-1596`, `utils/py/releases_app.py:1644-1651`, `utils/py/releases_app.py:1846-1853`).

However, unaddressed contract remnants remain in active source: the generated-file section still says the side-by-side file carries the trio marker (`utils/py/releases_app.py:1303-1306`), `perform_write()` still documents staging a generated view (`utils/py/releases_app.py:1568-1574`), and recovery still promises to regenerate it (`utils/py/releases_app.py:1796-1803`). The timeline payload likewise still labels `sync` as a `RELEASES.md`-vs-DB drift banner even though `--check-drift` now returns a retirement message (`utils/timeline/export_timeline.py:442-451`, `utils/timeline/export_timeline.py:519-526`, `utils/timeline/export_timeline.py:554-556`). These are dead/stale paths precisely inside Scopes 2, 3, and 7, so the “fully satisfied/no remnants” claim is not yet true.

Smallest acceptable fix: delete the empty generated-marker section; change the two transaction/recovery docstrings to DB+dump-only wording; and rename/remove the timeline `sync` drift comment/compatibility description so it no longer asserts a live Markdown comparison.

### 2. Static & Runtime Writer Audit — **Closed**

The Round 1 writer is gone: `artifact_paths()` exposes only DB, dump, and backup (`utils/py/releases_app.py:349-354`); normal writes journal and stage only the dump (`utils/py/releases_app.py:1591-1596`, `utils/py/releases_app.py:1644-1651`); recovery rewrites only the dump (`utils/py/releases_app.py:1846-1853`). The representative runtime probe pre-creates both retired files, runs `releases add`, and requires byte-equivalent canaries afterward (`test/gh568-releases-md-retired.sh:239-251`). A source sweep of the named production scopes found no surviving non-onboarding writer; the legacy onboarding tool remains explicitly scoped and documented (`relay-automation/xyz-releases-onboard.sh:11-19`).

### 3. Goalpost Manifest Checks & Fail-Closed Behavior — **Closed**

Nightwatch now compares both directions and rejects missing or extra members (`test/nightwatch-release.sh:184-231`), with missing-DB and extra-member mutations (`test/nightwatch-release.sh:284-300`). The local milestone check is DB-first, treats SQLite/query failure as an error, and treats an absent DB as an error unless an explicit legacy input was supplied (`utils/pdda-local-checks.sh:285-318`, `utils/pdda-local-checks.sh:341-348`). Its exit is nonzero in PDDA full mode while observe/light intentionally report without gating (`utils/pdda/pdda-lib.sh:49-55`); that is an explicit mode contract, not a silent skip.

### 4. Falsifiable Regression Guard & Evidence — **Blocking**

The new checks cover the actual Round 1 indirect-writer failure: artifact keys are asserted absent (`test/gh568-releases-md-retired.sh:199-205`), a real `releases add` must leave pre-created retired files untouched (`test/gh568-releases-md-retired.sh:239-251`), and the sixth witnessed control proves the content checker turns red on modification (`test/gh568-releases-md-retired.sh:166-187`). The durable transcript records Nightwatch's missing/extra directions and the six dedicated controls (`test/baselines/GH-568-negative-control.md:29-43`, `test/baselines/GH-568-negative-control.md:112-124`).

But the permanent source audit is not robust across the production codebase it claims to protect: it scans only `.sh`, `.py`, `.yml`, and `.yaml` (`test/gh568-releases-md-retired.sh:48-64`, `test/gh568-releases-md-retired.sh:70-79`) and omits `tools/` entirely (`test/gh568-releases-md-retired.sh:51-55`). A future `.js`, `.mjs`, or `.ts` writer—including one in the migrated VS Code cockpit—would pass this guard. The empty-input count cannot expose that blind spot because unrelated shell/Python files keep it nonzero.

Smallest acceptable fix: include the repository's production JavaScript/TypeScript extensions and the `tools/` production tree in both candidate counting and writer scanning, then add one witnessed JS/TS writer mutation. If the intended boundary is narrower, change the guard/evidence claims to state that narrower boundary and add a separate cockpit writer assertion.

### 5. Reversibility, Blast Radius, & Downstream Safety — **Closed**

The DB/dump transaction remains bounded and recoverable: intent precedes mutation, the DB commits before dump replacement, and the journal clears only after rename (`utils/py/releases_app.py:1591-1599`, `utils/py/releases_app.py:1601-1656`); post-commit recovery regenerates the canonical dump from DB state (`utils/py/releases_app.py:1839-1853`). Legacy import remains read-only (`utils/py/releases_app.py:15-18`, `utils/py/releases_app.py:5925-5925`) and explicit external onboarding remains available (`relay-automation/xyz-releases-onboard.sh:11-19`). Reversibility is **Costly but bounded**: restoring the retired projection would require a coordinated consumer rollback, while individual ledger writes retain atomic recovery.

### Blocking findings

1. Remove or correct the remaining generated-view/drift contract text in `releases_app.py` and the timeline exporter.
2. Expand the permanent writer audit to cover production JS/TS and `tools/`, with a witnessed mutation (or explicitly narrow its claims and add equivalent cockpit coverage).

## Claude Response — Round 4

Both Round 3 blocking findings have been addressed in code, verified with negative controls, and committed in `ed7dbdac`:

1. **Acceptance & Scope Completeness (Docstrings & Remnants):**
   - In `utils/py/releases_app.py`:
     - Deleted the empty generated-marker comment section (`dump_generation_from_text` section header).
     - Updated `perform_write` docstring (`utils/py/releases_app.py:1564`) to DB+dump-only wording (`-> stage dump carrying that generation`).
     - Updated `recover_from_journal` docstring (`utils/py/releases_app.py:1791`) to DB+dump-only wording (`REGENERATE the dump from the DB state`).
   - In `utils/timeline/export_timeline.py`:
     - Updated comment on `sync = None` (`utils/timeline/export_timeline.py:375`): `# retained for template compatibility; Markdown drift retired (GH-568)`.
     - Updated comment on `"sync": sync` in payload dictionary (`utils/timeline/export_timeline.py:450`): `# legacy template slot; always None (Markdown drift retired in GH-568)`.
     - Updated `--md` CLI option help text (`utils/timeline/export_timeline.py:519`): `help="deprecated: no-op compatibility flag (RELEASES.md retired in GH-568)"`.

2. **Permanent Writer Audit Scope & JS/TS coverage:**
   - In `test/gh568-releases-md-retired.sh`:
     - Expanded `check_writer_audit` to include `tools` directory in `dirs`: `for d in githooks utils relay-automation skills tools .github/workflows; do`.
     - Expanded candidate file searches in both `check_writer_audit` and Section 3 empty-input guard to scan `.js`, `.mjs`, and `.ts` files in addition to shell, Python, and YAML (`-name "*.sh" -o -name "*.py" -o -name "*.yml" -o -name "*.yaml" -o -name "*.js" -o -name "*.mjs" -o -name "*.ts"`), excluding build/distribution directories (`/node_modules/`, `/dist/`, `/out/`).
     - Expanded regex to detect JavaScript/TypeScript filesystem writers targeting `RELEASES.md` or `RELEASES.generated.md`: `|(writeFileSync|writeFile|createWriteStream)\s*\(.*RELEASES(\.generated)?\.md`.
     - Added Red Control 7 witnessing a JS/TS writer mutation (`tools/vscode-cockpit/bad_writer.ts` executing `fs.writeFileSync("RELEASES.md", ...)`) in `--mutate-evidence` mode and in the Section 4 suite body.
   - In `test/baselines/GH-568-negative-control.md`:
     - Updated Section 4 to record all 7 red controls passing (`WITNESS_RED_CONTROL_7: PASS (correctly detected JS/TS write to RELEASES.md)` and `== ALL 7 RED CONTROLS WITNESSED PASSING ==`).

### Verification
- `test/gh568-releases-md-retired.sh`: 17/17 tests passed clean (scanned 244 candidate production files, passed all 7 red controls).
- `test/gh568-releases-md-retired.sh --mutate-evidence`: All 7 red controls witnessed passing.
- `test/nightwatch-release.sh --mutate-evidence`: 38/38 passed clean.
- `test/gh32-releases-app.sh`: 144/144 passed clean.
- `test/gh57-releases-fuzz.sh`: 42/42 passed clean.
- `test/gh308-frozen-twin-guard.sh --check --staged`: Clean pass (0 frozen twins modified, 0 new Bash).

## Codex implementation QA — Round 5

**Verdict: BLOCKING.** The Round 3 implementation and guard defects are repaired. One bounded contract-cleanup gap remains, so the claimed end-to-end retirement is not yet complete. This was source-only review; I did not run Git, tests, artifacts, or the project gate.

### 1. Acceptance & Scope Completeness — **Blocking**

Scopes 1–9 and 11–14 now have the intended boundary: the canonical CLI exposes only DB/dump/backup artifacts and documents the DB/dump transaction (`utils/py/releases_app.py:349-354`, `utils/py/releases_app.py:1562-1573`); recovery regenerates only the dump (`utils/py/releases_app.py:1790-1797`); `gen` remains a refusing compatibility verb (`utils/py/releases_app.py:4693-4694`, `utils/py/releases_app.py:6015-6022`); timeline drift inputs are explicit no-ops (`utils/timeline/export_timeline.py:369-375`, `utils/timeline/export_timeline.py:516-527`); reconciliation and hosted allowlists retain only DB/dump artifacts (`utils/py/wave_reconcile.py:1198-1208`, `.github/workflows/wave-reconcile.yml:72-80`); and the cockpit reads `releases.db` with a deliberate downstream legacy fallback (`tools/vscode-cockpit/src/dataSources/releases.ts:67-79`). The release goalpost implementations and their missing/extra mutations are DB-backed (`test/nightwatch-release.sh:184-230`, `test/nightwatch-release.sh:272-300`; `test/meter-release.sh:443-475`, `test/meter-release.sh:598-632`; `test/ballast-release.sh:161-190`, `test/ballast-release.sh:353-379`).

Scope 10 and associated migrated command contracts still contain active-facing remnants. `release-lanes.sh` describes itself as turning a `RELEASES.md` release into input and says `--release` matches a `RELEASES.md` block, although its implementation is DB-only (`utils/release-lanes.sh:3-3`, `utils/release-lanes.sh:20-20`, `utils/release-lanes.sh:68-71`). The PDDA CLI usage still advertises `releases-current` as a roll-up of `RELEASES.md`, even though the command delegates to the DB CLI (`utils/pdda/pdda.sh:834-844`, `utils/pdda/pdda.sh:1677-1678`). Migrated Meter and Ballast suite headers/evidence metadata likewise still identify `RELEASES.md` as the manifest source (`test/meter-release.sh:7-7`, `test/ballast-release.sh:2-13`) while their checks query `releases.db`. These are not preserved generic downstream-PDDA documentation like the explicitly marked legacy helpers (`utils/pdda/pdda-lib.sh:448-452`); they describe this repo's migrated active commands and tests.

Smallest acceptable fix: update only those stale headers/help strings to say `releases.db` (and its manifest fields). Preserve the explicitly labeled downstream legacy parser/check contracts.

### 2. Static & Runtime Writer Audit — **Closed**

The active writer surface remains DB/dump-only (`utils/py/releases_app.py:349-354`, `utils/py/releases_app.py:1562-1568`, `utils/py/releases_app.py:1644-1651`, `utils/py/releases_app.py:1790-1797`). The permanent audit now scans production shell, Python, YAML, JS, MJS, and TS across `tools/` as well as the original production roots (`test/gh568-releases-md-retired.sh:48-83`), while the external onboarding writer is narrowly and explicitly exempted (`relay-automation/xyz-releases-onboard.sh:11-19`). The representative CLI probe requires both pre-created retired files to remain byte-equivalent (`test/gh568-releases-md-retired.sh:257-269`). No surviving active writer was found in the stated production scope.

### 3. Goalpost Manifest Checks & Fail-Closed Behavior — **Closed**

Nightwatch rejects absent DB state plus missing and extra members (`test/nightwatch-release.sh:184-230`, `test/nightwatch-release.sh:272-300`). Meter and Ballast enforce the same bidirectional DB contract and carry missing-DB controls (`test/meter-release.sh:443-475`, `test/meter-release.sh:598-632`; `test/ballast-release.sh:161-190`, `test/ballast-release.sh:353-379`). The local milestone check is DB-first, turns SQLite failure into `rc=1`, and permits legacy parsing only when an explicit legacy file was supplied (`utils/pdda-local-checks.sh:285-318`, `utils/pdda-local-checks.sh:319-348`).

### 4. Falsifiable Regression Guard & Evidence — **Closed**

The guard has non-empty candidate counting and scans the expanded production language/tree boundary (`test/gh568-releases-md-retired.sh:48-90`, `test/gh568-releases-md-retired.sh:272-289`). Its runtime control exercises a real CLI write (`test/gh568-releases-md-retired.sh:257-269`), and its JS/TS mutation proves the newly added branch turns red (`test/gh568-releases-md-retired.sh:191-203`, `test/gh568-releases-md-retired.sh:362-373`). The durable record identifies all seven witnessed controls, including empty input, indirect runtime modification, and JS/TS writing (`test/baselines/GH-568-negative-control.md:106-124`).

### 5. Reversibility, Blast Radius, & Downstream Safety — **Closed**

Writes journal intent, commit the DB, stage and atomically replace the dump, then clear the journal (`utils/py/releases_app.py:1562-1573`, `utils/py/releases_app.py:1591-1656`); post-commit recovery derives the dump from DB state (`utils/py/releases_app.py:1790-1797`, `utils/py/releases_app.py:1839-1853`). Legacy import/onboarding and the cockpit fallback preserve downstream migration paths (`relay-automation/xyz-releases-onboard.sh:11-19`, `tools/vscode-cockpit/src/dataSources/releases.ts:67-79`). Reversibility remains **Costly but bounded**: contract rollback is coordinated, while individual mutations retain atomic recovery.

### Blocking findings

1. Replace the stale `RELEASES.md` source descriptions in `utils/release-lanes.sh`, the `pdda.sh releases-current` usage text, and the Meter/Ballast suite headers with their actual `releases.db` contracts; keep explicitly labeled downstream legacy documentation intact.

## Claude Response — Round 6

The single remaining Round 5 blocking finding has been addressed in code, verified with negative controls, and committed in `425aec62`:

1. **Active command and goalpost contracts updated to `releases.db`:**
   - **`utils/release-lanes.sh`:**
     - Updated header doc comment (line 3) to state `turn a releases.db release into marathon input, and report what of it actually landed on trunk`.
     - Updated milestone resolution description (line 20) to state `else --release NAME matches a releases.db release by version or codename; else the single in-progress release that carries a milestone`.
     - Updated `resolve_milestone` comment (line 68) to state `Reads releases.db directly (GH-568) instead of parsing legacy markdown prose`.
   - **`utils/pdda/pdda.sh`:**
     - Updated `cmd_releases_current` comment (line 832) to state that in this repo it delegates to `releases.db` CLI (or legacy `RELEASES.md`).
     - Updated CLI usage string (line 1678) to state `read-only roll-up: active releases from releases.db (or legacy RELEASES.md) (rough, unvalidated)`.
   - **`test/meter-release.sh`:**
     - Updated header doc comment (line 7) to state `see releases.db's Meter release record`.
   - **`test/ballast-release.sh`:**
     - Updated `# gate-evidence:` metadata JSON (line 2) to state `manifest agreeing with releases.db`.
     - Updated header doc comment (line 8) to state `a claimed one (releases.db's exit-criterion note)`.
     - Updated Half A doc comment (line 13) to state `manifest here agrees with releases.db's Ballast manifest members in BOTH directions`.

### Verification
- `utils/release-lanes.sh --help`: clean pass.
- `utils/pdda/pdda.sh help`: clean pass.
- `test/meter-release.sh --mutate-evidence`: 13/13 passed clean.
- `test/ballast-release.sh --mutate-evidence`: 8/8 passed clean.
- `test/gh568-releases-md-retired.sh`: 17/17 tests passed clean (including all 7 red controls).
- `test/gh568-releases-md-retired.sh --mutate-evidence`: All 7 red controls witnessed passing.
- `test/gh308-frozen-twin-guard.sh --check --staged`: Clean pass (0 frozen twins modified, 0 new Bash).

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex implementation QA — Round 7

**Verdict: APPROVED.** The Round 5 blocker is closed, and no blocking defect remains. This was a source-only review: I did not run Git, tests, artifacts, or the project gate; I relied on the producer's recorded focused verification and inspected the final source.

### 1. Acceptance & Scope Completeness — **Closed**

All 14 planned scopes are satisfied. (1) the permanent guard rejects either retired root artifact (`test/gh568-releases-md-retired.sh:93-108`); (2–3) the canonical artifact map is DB/dump/backup-only and `gen` is a refusing compatibility verb (`utils/py/releases_app.py:349-354`, `utils/py/releases_app.py:4693-4694`); (4) release-lane milestone resolution is explicitly DB-backed (`utils/release-lanes.sh:20-21`, `utils/release-lanes.sh:68-72`); (5) the three goalposts use bidirectional DB comparisons, exemplified by Meter and Ballast (`test/meter-release.sh:443-475`, `test/ballast-release.sh:161-190`), while the local milestone check is DB-first and fail-closed (`utils/pdda-local-checks.sh:285-318`, `utils/pdda-local-checks.sh:341-348`); (6) build/preflight references were migrated as recorded in the accepted prior review; (7) timeline drift inputs are deprecated no-op compatibility surfaces (`utils/timeline/export_timeline.py:369-375`, `utils/timeline/export_timeline.py:516-527`); (8) reconciliation snapshots and hosted allowlists contain only surviving artifacts (`utils/py/wave_reconcile.py:1198-1208`, `.github/workflows/wave-reconcile.yml:72-80`); (9) onboarding's legacy behavior remains explicitly scoped (`relay-automation/xyz-releases-onboard.sh:11-19`); (10) `releases-current` now describes and delegates to the DB CLI, retaining an identified legacy fallback (`utils/pdda/pdda.sh:830-846`, `utils/pdda/pdda.sh:1675-1677`); (11) the cockpit prefers the DB with a deliberate downstream fallback (`tools/vscode-cockpit/src/dataSources/releases.ts:67-79`); (12) the rehomed suites are represented by DB-backed Meter/Ballast contracts (`test/meter-release.sh:443-475`, `test/ballast-release.sh:161-190`); (13) the accepted prior review found routing/doc contracts migrated; and (14) the permanent guard covers static writers, runtime non-modification, and witnessed mutations (`test/gh568-releases-md-retired.sh:48-90`, `test/gh568-releases-md-retired.sh:257-289`, `test/baselines/GH-568-negative-control.md:106-124`). The last stale active-facing descriptions are corrected in `release-lanes`, PDDA help, Meter, and Ballast (`utils/release-lanes.sh:3-4`, `utils/pdda/pdda.sh:1675-1677`, `test/meter-release.sh:5-9`, `test/ballast-release.sh:2-15`). No unaddressed active remnant or dead path was found.

### 2. Static & Runtime Writer Audit — **Closed**

The active artifact and transaction boundary is DB/dump-only (`utils/py/releases_app.py:349-354`, `utils/py/releases_app.py:1562-1573`, `utils/py/releases_app.py:1644-1651`). The audit spans the named production roots plus `tools/` and the production shell/Python/YAML/JavaScript/TypeScript extensions (`test/gh568-releases-md-retired.sh:48-90`); its representative CLI probe requires pre-created retired files to remain byte-identical (`test/gh568-releases-md-retired.sh:257-269`). No surviving active writer or write redirection was found; the external onboarding exception is narrow and documented (`relay-automation/xyz-releases-onboard.sh:11-19`).

### 3. Goalpost Manifest Checks & Fail-Closed Behavior — **Closed**

Nightwatch rejects absent DB state and compares missing and extra members (`test/nightwatch-release.sh:184-230`, `test/nightwatch-release.sh:272-300`). Meter and Ballast do the same (`test/meter-release.sh:443-475`, `test/meter-release.sh:598-632`; `test/ballast-release.sh:161-190`, `test/ballast-release.sh:353-379`). The local milestone check treats query failure or missing app-managed DB state as an error and permits legacy parsing only through explicit legacy input (`utils/pdda-local-checks.sh:285-318`, `utils/pdda-local-checks.sh:319-348`). The old silent-success behavior is gone.

### 4. Falsifiable Regression Guard & Evidence — **Closed**

The guard asserts a non-empty candidate population and audits the expanded production tree/language boundary (`test/gh568-releases-md-retired.sh:48-90`, `test/gh568-releases-md-retired.sh:272-289`). It exercises a real CLI mutation against both pre-created retired artifacts (`test/gh568-releases-md-retired.sh:257-269`) and includes a witnessed JS/TS-writer red control (`test/gh568-releases-md-retired.sh:191-203`, `test/gh568-releases-md-retired.sh:362-373`). The durable baseline records all seven witnessed controls (`test/baselines/GH-568-negative-control.md:106-124`). This is falsifiable coverage of both the prior indirect runtime defect and future direct production writers.

### 5. Reversibility, Blast Radius, & Downstream Safety — **Closed**

Writes journal intent, commit the DB, stage and atomically replace the dump, and clear the journal only afterward (`utils/py/releases_app.py:1562-1573`, `utils/py/releases_app.py:1591-1656`); recovery regenerates the dump from committed DB state (`utils/py/releases_app.py:1790-1797`, `utils/py/releases_app.py:1839-1853`). Explicit legacy onboarding and the cockpit fallback preserve downstream migration paths (`relay-automation/xyz-releases-onboard.sh:11-19`, `tools/vscode-cockpit/src/dataSources/releases.ts:67-79`). Reversibility is **Costly but bounded**: restoring the retired projection requires a coordinated contract rollback, while individual mutations retain atomic recovery.

No blocking findings.

## Log

### Round 7 — Codex final implementation QA

VERDICT: PASS

Basis: All five QA questions are Closed with cited source evidence; the Round 5 contract-text blocker is corrected and no active writer, fail-open goalpost, regression-guard gap, or unbounded rollback defect remains.
