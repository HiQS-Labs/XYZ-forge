# Evidence Summary — GH-1345 Cutover: Rows at Pickup

Date: 2026-11-07
Branch: `feat/XYZ-forge-gh1345-cutover-rows-at-pickup-2026-11-07`
Tasks: GH-1340 Tasks 2, 3, 4, 6, 11, 5, 12 (Issue #1345)

## 1. Scope & Acceptance Summary

- **Task 2 (Intake row decoupling):**
  - `hq park` (both `--create` and `--gh-issue` adoption), `/file-xyz-bug`, and `/idea` no longer insert rows into `releases.db` (`roadmap_items`) at filing.
  - `utils/pdda/pdda.sh check_roadmap_coverage` passes unstarted `1-INBOX` issue captures without a ledger row as `info`, while active `2-WORKING` captures without a row still fail with `error rc=1`.
  - Falsification verified: dummy doc placed in `2-WORKING` failed with `rc=1`.
- **Task 3 & 11 (Rated pickup writer & rating contract):**
  - Added CLI `releases roadmap pickup --issue-num N [--doc-path P] [--rated P/S/A/E] [--ovr O]`.
  - Enforces the 1–100 4-axis rating contract, rejecting placeholders (`50/50/50/50` without distinct rationale, or all <= 5).
  - Idempotent: repeated pickup preserves existing row, rating, and operator `ovr`. Grandfathered D-a rows are adopted without disruption.
  - Integrated into `express.py`, `jog_run.py`, `start-task`, `jog`, `start-marathon`, `10days`, `workhorse`.
- **Task 4 (Readiness & factory discovery for unstarted no-row issues):**
  - Extended `_unregistered_record` and `init_from_prs` in `utils/py/harness.py`.
  - Evaluates unstarted open issues by capture doc, Preflight Contract artifacts/writeset/zone, and PRS proposals. Fully specified issues enter factory candidate pool with `state = 'ready'` and `section = 'Queue / parked intake'`.
- **Task 6 (Duplicate prevention):**
  - Duplicate issues: `hq park --create` searches open issues before filing.
  - Duplicate captures: `hq park --gh-issue` reuses existing capture doc.
  - Duplicate rows: `UNIQUE(repo_id, gh_number)` enforced at pickup.
- **Task 12 (Structured body format & umbrella metrics):**
  - `hq park --create` and `/file-xyz-bug` render standard `/idea` sections (`## Observed`, `## Acceptance`, `## Preflight Contract`, `## PRS proposal`).
  - Added `umbrella` label handling to exclude tracking issues from atomic intake counts.
- **Task 5 (Backlog rollout instruction):**
  - Rollout instruction for #1298 batch documented: prepare issue text, capture doc, and contract only; create zero rows at intake.

## 2. Test Evidence

| Suite / Check | Command | Result | Notes |
|---|---|---|---|
| GH-238 HQ releases mode | `bash test/gh238-hq-releases-mode.sh` | PASS (100%) | Verifies no row written at filing; duplicate capture reused |
| HQ park intake writer | `bash test/hq-park.sh` | PASS (23/23) | Verifies preview, create, slugging, title override |
| HQ park synthesis | `bash test/hq-park-synthesis.sh` | PASS (35/35) | Verifies capture doc formatting and synthesis passthrough |
| Express skill | `bash test/gh267-express-skill.sh` | PASS (126/126) | Verifies express ledger pickup step with real rating |
| Harness registry | `bash test/gh174-harness-registry.sh` | PASS (8/8) | Verifies harness check and CLI execution |
| Releases DB check | `python3 utils/py/releases_app.py check` | clean (0 failures) | DB integrity, schema, and receipt chain consistent |
| PDDA roadmap coverage | `bash utils/pdda/pdda.sh roadmap-coverage` | clean (0 errors) | Unstarted inbox passes; active working requires row |
| PDDA full audit | `bash utils/pdda/pdda.sh run` | clean (0 errors) | All doc hygiene, changelog, and governance checks pass |
| Frozen twin guard | `bash test/gh308-frozen-twin-guard.sh --check --base origin/development` | PASS | Zero frozen bash twins edited; no new bash scripts |

No new test suites added per `AGENTS.md` GH-831.
