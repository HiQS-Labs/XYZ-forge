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
| Ownership transferred from MBP; five remaining controls witnessed red on476400948 and green on takeover repair. Reviewed1384 branch preservation integrated. Fresh independent static QA found no additional blocker. | Existing focused334/334 and normalfullprepushGREEN540s at58671b8d0. Publish receipt tail, land1385first without cleanup, deploy merged skill, then measure real multi-PR sequence under1386. Prior failures/caps retained. |

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
    - If returncode == 0: format a `clean` verdict (`verdict: clean\nAuto-executed post-merge sweep passed.`), call `record_verdict(batch, text)`, update the GitHub `merge-batch` issue via `batch_record.update()`, retain the independent temp clone, and exit 0.
    - If returncode != 0: format a `findings` verdict (`verdict: findings\n- [ ] Post-merge sweep failed: ...`), call `record_verdict(batch, text)`, update the issue, and exit 4 (or 1) with failure details.
  - If `--no-auto-sweep` is passed, or if the sweep command is an external hosted workflow dispatch (e.g. `gh workflow run wave-reconcile.yml --ref development`), maintain the existing deferral behavior (exit 4).

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


## Grounded finalization repair — 2026-11-08

Recon: [current seams](../../TESTS-RESULTS/2026-11-08+GH-1383/recon.md). Independent read-only plan review confirmed all five supplied failures; prior source claims do not qualify this repair. Reversibility: Costly operational orchestration (remote merge/publication), reversible code change; preserve exact-head gates, receipts, attempts and all retained clones. No new persisted state or authority.

1. Integrate exact reviewed GH-1381 runtime preservation changes from PR1384 into this PR before PR1385 lands -> live invocation and both previews omit --delete-branch; old obsolete conditional state removed. PR1385 still lands first, with provenance of the additive reviewed fix; PR1384 later carries its remaining evidence/intake changes.
2. Share isolated, bounded command execution inside the existing module between canary and automatic sweep -> create retained full clone, run there, fail closed on allocation/clone/command failure; never rewrite && into unchecked semicolons, add deletion traps, or run mutation-heavy commands in primary. Strip only the exact known batch-generated clone prefix before reusing the shared isolation path to avoid double clones. Hosted promotion remains deferred.
3. Track actual deferred issue/doc sync debt -> pending future PRs determine intermediate behavior; successful final non-intermediate sync and checked publication clear debt. If later PRs defer, footer settles any debt even after one actual merge. Footer sync failure hard-stops; reuse checked commit/push/fetch/durability helper. Hard abort retains unreconciled debt for existing recovery, never reports complete. No duplicate final sync.
4. Update only existing gh436 coverage for changed behavior -> witness pre-fix red controls for allocation failure/no cleanup, primary isolation, command failure/timeout, one landing plus successor deferral, no duplicate sync, and all final publication failures; then verify focused suites in a separate disposable full clone and obtain fresh final independent QA. No new suite/gate machinery.
5. Publish through normal full gate after host-slot confirmation, then land PR1385 through pinned reviewed PR1384 safe source with caller no-cleanup restrictions independently checked -> exact-head merge, original sequence and governance checks preserved; no unmerged code globally installed.

Budget: existing review cap3 rounds/blocker, repair cap2/PR; batch window ends2026-11-09T02:42:44Z, no new scheduler. Future deployment uses only SkillsArmyHQ scripts against the explicit existing Pulse collection and merged canonical primary, never a second mirror or ad hoc link edits. All applied warnings/refusals are reported without adoption/drift overrides.

## Merge evidence

- PR #1385 merged 2026-11-09 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
