---
title: merge-cleanup merge sequence optimization (canary gating, coalesced reconciliation, default automated QA sweep)
status: Active
created: 2026-11-08
updated: 2026-11-08
owner: noel
gh_issue: 1383
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1383
doc_type: feature
complexity: 2
risk: 2
effort: 2
phases: 2
ratings_provisional: false
non_goals:
  - Bypassing or disabling git safety checks (Phases 0-4, 6 remain strict and fail-closed).
  - Removing `--prs` exact-head SHA allowlist pinning (GH-1226).
  - Silently skipping post-merge regression sweeps when no qualification policy is configured.
related:
  - GH-944 (merge-batch issue tracking)
  - GH-1064 (batch sweep exit 4 contract)
  - GH-1066 (landing groups and CI-heavy planning)
  - GH-1127 (no hosted run per merge; local reconcile default)
  - GH-1159 (qualification policy in .merge-cleanup.json)
  - GH-1226 (--prs allowlist pinning)
fix_probes:
  - python3 skills/2-daily/merge-cleanup/scripts/merge_cleanup.py --primary . --scan-only
  - pytest test/gh436-merge-cleanup.py
goal: >
  Optimize multi-PR merge cleanup sequences by introducing intermediate canary
  gating between merges, coalescing redundant post-merge governance syncs/pushes,
  and baking in an automated post-merge QA regression sweep by default at batch
  conclusion, eliminating manual Exit 4 stalls.
---

# GH-1383 — merge-cleanup: Optimize merge sequence with intermediate canaries & default automated QA sweep

## Status

| What was just completed | What's next |
|---|---|
| Step 1-3 intake completed: GitHub issue #1383 created, roadmap row rmi-01M6YJHCF8FA1XNSHKYX6J1KC8 parked and promoted to `In progress`, task branch `feat/XYZ-forge-gh1383-merge-cleanup-optimization-2026-11-08` provisioned. Grounded recon completed. Phase 1 & 2 implementation completed: intermediate reconcile `[skip ci]` tag & deferred `pdda issue-doc-sync`, automated post-merge QA sweep execution by default with `--no-auto-sweep` opt-out. All 211 tests in `test/gh436-merge-cleanup.py`, 125 tests in `test/gh549-work-events.sh`, and 111 tests in `test/gh534_phase_c_tests.py` passing green. PDDA run clean. | Step 4 pre-push validation gate (`validate.sh`), push task branch, open PR, link PR, and closeout. |

## Context & Problem Statement
During multi-PR merge batches (such as the 9-PR sequence in LTVera thread `90a3846f-ed6a-4104-b71e-73ef197e3182` and XYZ Forge batches #1374, #1375, #1380), `merge-cleanup` currently executes a full cycle of local reconciliation (`run_local_wave_reconcile`), RELEASES DB check (`releases_app check`), PDDA sync (`pdda.sh issue-doc-sync`), and commits/pushes to `origin/development` after **every single merged PR**.

This creates substantial overhead:
1. **Excessive remote push churn:** In repositories running full-isolation database suites or heavy suites (e.g., LTVera running `pytest-db-full` on every `development` push), each intermediate push to `development` triggers hosted CI workflows, saturating runners.
2. **Repeated governance overhead:** Re-running repository-wide GitHub queries, roadmap syncs, and issue doc syncs after each individual PR in a batch adds multiple minutes of serialized delay per PR.
3. **Manual halt for batch QA sweep (Exit 4):** When 2+ PRs land, `merge_cleanup.py` exits 4 (`STATUS: landed, QA pending`), requiring an external operator or agent to separately invoke the sweep command, generate a verdict file, and run `--record-sweep <file>` by hand.

## Implementation Architecture

### Phase 1: Baked-in Post-Merge Sequence QA Regression Sweep (On by Default)
- In `merge_cleanup.py`, when `batch_record.qa_pending(batch)` is true at the conclusion of Phase 5:
  - Inspect `batch["sweep_inputs"]["command"]`.
  - If a local sweep command is configured (e.g. `mode == "per_batch"` or local small canary suite):
    - Automatically execute the command in an isolated throwaway clone (`T=$(mktemp -d)`).
    - If returncode == 0: format a `clean` verdict (`verdict: clean\nAuto-executed post-merge sweep passed.`), call `record_verdict(batch, text)`, update the GitHub `merge-batch` issue via `batch_record.update()`, clean up the temp clone, and exit 0.
    - If returncode != 0: format a `findings` verdict (`verdict: findings\n- [ ] Post-merge sweep failed: ...`), call `record_verdict(batch, text)`, update the issue, and exit 4 (or 1) with failure details.
  - If `--no-auto-sweep` / `--defer-sweep` is passed, or if the sweep command is an external hosted workflow dispatch (e.g. `gh workflow run wave-reconcile.yml --ref development`), maintain the existing deferral behavior (exit 4).

### Phase 2: Intermediate Canary Gating & Coalesced Reconciliation
- Allow `qualification.canary_command` or lightweight checks during batch merges.
- When executing a multi-PR batch with N PRs:
  - Run lightweight local canaries between intermediate merges to verify tree integrity.
  - Defer heavy syncs and intermediate git pushes to the batch conclusion when running in batch mode, avoiding N remote push events to `origin/development`.

## Verification Plan
1. Run `pytest test/gh436-merge-cleanup.py` and verify all existing tests pass.
2. Add new test cases in `test/gh436-merge-cleanup.py` covering:
   - Auto-execution of sweep command on clean run resulting in exit 0 and recorded `clean` verdict.
   - Sweep command failure resulting in recorded `findings` verdict and exit code.
   - `--no-auto-sweep` flag preserving exit 4 deferral.
   - Hosted dispatch commands remaining deferred without local execution.
3. Validate repository hygiene with `utils/pdda/pdda.sh run` and `./validate.sh`.
