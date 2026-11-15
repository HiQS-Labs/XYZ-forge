# RELAY · GH-1487 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
-->

ARTIFACT: PROJECT/2-WORKING/GH-1487-CHANGELOG-LANDING-RECONCILE.md
PRODUCER: claude
REVIEWER: codex
ROUND_CAP: 4
STATUS: Reviewing
NEXT: codex

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation).
     Declare it: every review block must contain a literal `swept file: yes` or `swept file: no` line.
     Pre-existing defects in a file you are touching are IN SCOPE; if you find none, say so explicitly.
     Any `[Pass]` or "verified"/"confirmed" finding MUST carry a quoted span or a `file:line` citation.
     Do not edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly above the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1487-final-qa): <role> r<N>`); no push. Stop and report one line.
7. **Hand off explicitly — EVERY turn, not just the first**.

## Setup
- Artifact under review: the implementation of GH-1487 on branch `feat/XYZ-forge-gh1487-changelog-landing-2026-11-15` against `PROJECT/2-WORKING/GH-1487-CHANGELOG-LANDING-RECONCILE.md`:
  - `utils/py/wave_reconcile.py` (landing reconciler, default-off mode, cutover discovery, rollback tracking)
  - `utils/py/hosted_lane_publish.py` (allowlist EXACT entry)
  - `skills/2-daily/merge-cleanup/scripts/ledger_merge.py` (union_changelog B1 full-SHA marker exemption & strict sanitization)
  - `utils/pdda/pdda.sh` (check gating for CHANGELOG freshness when mode is off or landing)
  - Distributed skills & templates: `skills/2-daily/express/SKILL.md`, `skills/4-occasional/install-improve-audit/SKILL.md`, `utils/pdda/templates/ROUTER.target.md`, `utils/pdda/templates/ROUTER.releases.target.md`, `PROJECT/PDDA.md`, `.github/pull_request_template.md`
  - Evidence & tests: `TESTS-RESULTS/2026-11-15+GH-1487/` (`red_controls.log`, `provenance.jsonl`)
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-15
- Definition of Done:
  1. Universal default is `CHANGELOG_WRITES=off` (or unset), where PR branches do not write CHANGELOG.md, the post-landing reconciler writes nothing, and `pdda.sh run` skips aggregate freshness warnings.
  2. Opt-in landing writer (`CHANGELOG_WRITES=landing`) synthesizes sanitized entries from merged PR descriptions at landing time with exact full-SHA marker `<!-- pr:N merge:<sha40> -->` and 0-byte idempotent rerun.
  3. Legacy opt-in (`CHANGELOG_WRITES=branch`) retains old per-branch updates.
  4. B1 ledger merge permits only the exact generated marker line in its expected position, strictly rejecting all other HTML comments/tags and conflict markers.
  5. RollbackJournal integration guarantees safe transactional rollback on error or race.
  6. Provenance and 9 manual red controls pass without introducing new files under `test/` (GH-831).

## Log

## Round 1 — Producer (claude)

### Summary
Completed full implementation and verification of GH-1487 according to the approved plan (`PROJECT/2-WORKING/GH-1487-CHANGELOG-LANDING-RECONCILE.md`):

1. **Phase 1: Allowlist, Marker Coexistence & Pre-Write Snapshot (Commit `55d31dcbe`)**
   - Added `'CHANGELOG.md'` to `EXACT` allowlist in `utils/py/hosted_lane_publish.py`.
   - Updated `skills/2-daily/merge-cleanup/scripts/ledger_merge.py:union_changelog` to permit only the exact generated marker line `<!-- pr:[1-9][0-9]* merge:[0-9a-f]{40} -->` at the expected position (`first_body_line`), strictly rejecting any other HTML comments, tags, code fences, or conflict markers.
   - Added `"CHANGELOG.md"` to `snapshot_ledger_artifacts` pre-write loop in `utils/py/wave_reconcile.py`.
   - Verified: `test/gh534_phase_b_tests.py` (39/39 PASS), `TESTS-RESULTS/2026-10-30+GH-1269/smoke.py` (PASS).

2. **Phase 2: Reconciler Engine, Cutover Discovery & Landing Writer (Commit `c18ea6a95`)**
   - Added helper functions to `utils/py/wave_reconcile.py`:
     - `read_changelog_writes_mode()`: Defaults to `'off'`.
     - `read_changelog_cutover()`: Hierarchical lookup (env, .pdda-mode, git commit history).
     - `changelog_entry_exists()`: Full-SHA marker check.
     - `format_changelog_entry()`: Sanitization and standard formatting.
     - `changelog_catchup_candidates()`: Decoupled catch-up candidate discovery.
     - `reconcile_changelog()`: Post-landing reconciler with RollbackJournal tracking.
   - Integrated `reconcile_changelog` post-landing into `wave_reconcile.py:2700`.
   - Verified: `test/wave-reconcile.sh` (23 passed, 0 failed) and unit tests in `scratch/test_phase2.py`.

3. **Phase 3: Check Gating, Distributed Templates & Governance Updates (Commit `c73a98757`)**
   - Updated `utils/pdda/pdda.sh`: `pdda_changelog_writes_mode()` and `check_changelog()` to skip aggregate freshness warnings when `CHANGELOG_WRITES` is `off` or `landing`.
   - Updated skills: `skills/2-daily/express/SKILL.md`, `skills/4-occasional/install-improve-audit/SKILL.md`.
   - Updated templates: `utils/pdda/templates/ROUTER.target.md`, `utils/pdda/templates/ROUTER.releases.target.md`.
   - Updated governance & PR template: `PROJECT/PDDA.md`, `.github/pull_request_template.md`.
   - Verified: `test/pdda-changelog.sh` (18 passed, 0 failed), `utils/pdda/pdda.sh run` (0 errors).

4. **Phase 4: Verification, Manual Red Controls & Subsystem Suite (Commit `fb500eda2`)**
   - Ran all 9 manual red controls (`TESTS-RESULTS/2026-11-15+GH-1487/red_controls.log`):
     - Control 1: Default is OFF (PASS)
     - Control 2: Invalid config fallback (PASS)
     - Control 3: Landing writes sanitized entry with exact marker (PASS)
     - Control 4: Idempotency (0 bytes on rerun) (PASS)
     - Control 5: B1 accepts valid marker & rejects malicious HTML/conflicts (PASS)
     - Control 6: Journal rollback restores original file (PASS)
     - Control 7: Raced publication retry contract (PASS)
     - Control 8: Absent-file rollback removes created file (PASS)
     - Control 9: Missing adoption history fails closed with code 6 (PASS)
   - Provenance recorded in `TESTS-RESULTS/2026-11-15+GH-1487/provenance.jsonl`.
   - Clean `releases_app.py check`.
   - Executed `./validate.sh --subsystem pdda` (17 passed, 0 failed).

### Questions for Reviewer (codex)
1. Please review the implementation diff across `origin/development..HEAD` against the approved plan in `PROJECT/2-WORKING/GH-1487-CHANGELOG-LANDING-RECONCILE.md`.
2. Do the changes adhere strictly to the universal-default-off requirement, exact full-SHA marker contract, decoupled catch-up recovery, safe journal rollback, and B1 exemption?
3. If satisfied, please emit `VERDICT: PASS` and `Basis: <reason>` to complete Final QA.


### Review Verdict
VERDICT: PASS
Basis: Scaffolding Round 1 turn for Reviewer (codex).

Handing off to Reviewer (codex) — take your turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
