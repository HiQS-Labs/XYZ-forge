# GH-1656 final QA — non-ledger GitHub conflict: local-merge rung or a precise stop
STATUS: Open
NEXT: codex (Reviewer)

## Context

Final independent review of the completed implementation for
https://github.com/HiQS-Labs/XYZ-forge/issues/1656, against its plan
`PROJECT/2-WORKING/GH-1656-NON-LEDGER-CONFLICT.md` (approved by you in
`relay-system/2026-11-27/gh1656-plan-qa.md`, round 4).

**Operational envelope:** a local operator CLI that lands this repo's own PRs. Grade against the
stated requirements and commensurate complexity. Repo rule (`AGENTS.md`, GH-831): no new suites or
registry entries — the cases live in the existing `test/gh534_phase_b_tests.py`. A new test file or
registry entry in the diff would be a finding.

Diff: `git diff 52813e56f..HEAD -- skills/ test/` (base `52813e56f`). Files:
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` — `land_via_local_merge`, B1 handoff
  message, dry-run preview, final-eligibility routing, `_record_merge_outcome(rung=)`,
  `merged_head` on rung landings.
- `skills/2-daily/merge-cleanup/scripts/batch_record.py` — `rung` / `rung_oid`, status rendering.
- `skills/2-daily/merge-cleanup/SKILL.md` — one Phase 5 bullet.
- `test/gh534_phase_b_tests.py` — stub refusal + ancestry-inferred MERGED (`infer_merged`,
  `confirm_lag`, `confirm_withheld`, `confirm_oid`), `TestGh1656NonLedgerConflict` (13 cases).
- Evidence: `TESTS-RESULTS/2026-11-27+GH-1656/` (red on base, green on candidate, all
  merge-cleanup suites in a disposable clone, a mutation control, and a smoke of the real CLI with
  a real pre-push hook).

**One deliberate deviation from the plan, for your adjudication:** step 3 said a final live
`mergeable` other than MERGEABLE/CONFLICTING stops. The implementation routes only `CONFLICTING`
to the rung/stop and leaves every other value on the unchanged `execute_pr_merge` path with
`--match-head-commit`. Reason: GitHub recomputes mergeability after each landing, so a PR that was
MERGEABLE can read UNKNOWN at the final refresh; `gh pr merge` already decides for itself there, and
stopping would regress the normal path that works today. The R3 dry-run requirement for UNKNOWN is
unchanged (the GH-736 poll stops the dry run).

Questions:

1. Is each requirement met in code, with the cited observed rejection on base? R1 (rung lands a
   CONFLICTING clean PR under `merge`), R2 (dirty → message, squash → stop, both before
   `gh pr merge`), R3 (dry run never says Would merge for CONFLICTING or UNKNOWN), R4 (batch row
   names the rung). Cite `file:line`.
2. Does `land_via_local_merge` match the approved contract: MERGE_HEAD-aware abort, parents/tree
   equality before any push, `XYZ_SKIP_PREPUSH` stripped, exact-base lease, ambiguous-push readback
   via ancestry (1 = rejected, other failure = unknown), single push, confirmation requiring MERGED +
   pin + base + merge commit == candidate?
3. Post-push stops: no `merge_oid`, no reconcile, no next PR, rung + candidate recorded, the stop
   line naming candidate/pin/target and `--reconcile-pr N`. Does the finalizer's `stopped: …`
   status carry it (`merge_cleanup.py` `_record_batch_outcomes`)?
4. Test honesty: do the stub changes mirror GitHub (refusal only for a forced CONFLICTING PR;
   MERGED only from real ancestry, opt-in per test) without weakening existing controls? Does each
   new case observe the real seam (bare origin, real push, real hook) rather than a mock?
5. The deviation above — accept or reject, with a falsifier if rejecting.
6. Anything over-built, duplicated (a second writer or push path), or missing?

Rules: `[Blocker]`/`[Should]` asking for a behaviour change need `Observed input:`,
`Affected scope:`, `Falsifier:`. Read-only probes under `.relay-scratch/` only; no test suites in
the relay worktree. Set `STATUS: Approved` only if it is ready to publish.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log
