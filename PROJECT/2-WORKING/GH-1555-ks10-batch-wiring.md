---
issue: 1555
title: "kickstart(KS-10): wire merge-cleanup landing forecast, --landing-plan, canary_command, and 3+ PR batch defaults"
status: active
roadmap_id: rmi-01M7VQW02KMDKEVC6SAXN6TQRN
parent_arc: 1541
milestone: KS-10
owner: antigravity
goal: "Wire kickstart/SKILL.md to merge-cleanup's existing landing forecast, --landing-plan, canary_command, GH-1066 sequence review, U5 pin revalidation, and fail-closed 3+ PR batch defaults."
created: 2026-11-20
updated: 2026-11-20
---

# GH-1555 (KS-10) — Kickstart Wiring for Merge-Cleanup Batch Planning (3+ PRs)

## Status

| What was just completed | What's next |
|---|---|
| Created fresh clone, registered `rmi-01M7VQW02KMDKEVC6SAXN6TQRN`, completed grounded recon of `merge_cleanup.py:403-415,726-860,2286,2493-2645,2836-2855` and `ledger_merge.py:800-970`. | Complete Codex Plan QA, implement KS-10 wiring & fail-closed batch defaults in `skills/1-hourly/kickstart/SKILL.md`, execute paired red/green forecast controls + PDDA under `TESTS-RESULTS/2026-11-20+GH-1555/`, and pass Final QA. |

## Objective
Wire `skills/1-hourly/kickstart/SKILL.md` to merge-cleanup's existing batch-planning machinery (`--landing-plan`, `--landing-reason`, `qualification.canary_command`, `ledger_merge.py` landing forecast, and GH-1066 sequence review) with fail-closed defaults for 3+ PR batches (issue #1541 KS-10, U5/U9). No new batch-planning runner is invented.

## Grounded Recon
- `skills/2-daily/merge-cleanup/scripts/ledger_merge.py:800-970`: `_conflict_hubs()` and landing forecast compute `recommendation` (`"direct"`, `"group"`, or `None` when incomplete/withheld, e.g., clean-set fold did not run), `passes` (`direct in passes`), and `hubs`.
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:403-415,2286`: `qualification.canary_command` already exists in project merge policy and runs during qualification.
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2493-2645,2836-2855`: requires `--landing-plan direct|group --landing-reason "<justification>"` for queues of 3+ PRs under `--execute`, compares the chosen plan against the dry-run forecast (`forecast_comparison`), and enforces `--prs N@<approved-full-sha>` pin revalidation.
- `PROJECT/PDDA.md:462-465`: honor configured `CHANGELOG_WRITES` mode (no task-branch `CHANGELOG.md` edit under default `off`/`landing`).
- `utils/ci-route.sh`: classifies edits to `skills/1-hourly/kickstart/**`, `PROJECT/**`, `TESTS-RESULTS/**`, and `releases.db`/`releases.sql` as `route=docs`.

## Plan
1. **`skills/1-hourly/kickstart/SKILL.md`:**
   - Add **Batch Planning & 3+ PR Landing Defaults (KS-10, U5/U9)** subsection:
     - **Forecast Acquisition & U5 Pin Revalidation:** obtain the forecast from merge-cleanup's dry run with exact `--prs N@<approved-full-sha>,...`. A newly ready PR or changed head NEVER silently joins an already-forecast batch; re-run dry-run forecast and pin revalidation whenever the set or any head SHA changes.
     - **GH-1066 Sequence Review First:** complete the existing GH-1066 sequence review before the first merge, even when splitting a batch into smaller passes.
     - **Deterministic Forecast Dispatch Defaults:**
       - *Complete `direct` or `direct in passes` forecast:* execute each approved pass with `--landing-plan direct --landing-reason "<reason>"`, refreshing `--prs` full-SHA pins after any base or head change; honor configured `qualification.canary_command` and the existing post-batch sweep.
       - *`group` forecast (or conflict hubs):* execute a clean subset ONLY after a fresh, complete forecast proves that subset folds clean and all its hard dependencies are met; record the remaining conflict hubs as a held separate batch (KS-11b).
       - *Withheld / incomplete forecast (`recommendation: None`):* preserve the diagnostic verbatim and use the owner's bounded retry or hold path; NEVER infer a clean set or dispatch blindly.
2. **Paired Red/Green Checks (`TESTS-RESULTS/2026-11-20+GH-1555/`, no new test suite GH-831):**
   - **Control 1 (Withheld forecast -> HOLD, never dispatch — real `ledger_merge.py` + `merge_cleanup.py` CLI):**
     - Invoke real `ledger_merge.py` forecast logic on a fixture where clean-set fold did not succeed (producing `recommendation: None`, withheld diagnostic) AND invoke real `merge_cleanup.py --execute` on 3+ PRs without `--landing-plan` (refusal).
     - Verify KS-10 dispatch decision function + documented rule returns `HOLD` (preserving diagnostic, zero dispatch) on withheld forecast, routes `direct`/`direct in passes` -> `--landing-plan direct`, `group` -> subset only after fresh complete forecast + remainder held batch, and rejects newly added / changed-head PRs until re-forecast (U5).
   - Run `./utils/pdda/pdda.sh run` (0 errors), `utils/ci-route.sh`, and generate `provenance.jsonl`.

## Acceptance Criteria
- `skills/1-hourly/kickstart/SKILL.md` wires kickstart cleanly to merge-cleanup's existing forecast, `--landing-plan`, `canary_command`, GH-1066 sequence review, U5 pin revalidation, and fail-closed 3+ PR defaults.
- Paired red/green check (real `ledger_merge.py` withheld forecast -> HOLD, never dispatch), PDDA (0 errors), and `provenance.jsonl` retained under `TESTS-RESULTS/2026-11-20+GH-1555/`.
