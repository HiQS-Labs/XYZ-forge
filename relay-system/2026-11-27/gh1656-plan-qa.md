# GH-1656 plan QA — non-ledger GitHub conflict: local-merge rung or a precise stop
STATUS: Open
NEXT: codex (Reviewer)

## Context

Independent plan review, before any production code, of
`PROJECT/2-WORKING/GH-1656-NON-LEDGER-CONFLICT.md` (issue https://github.com/HiQS-Labs/XYZ-forge/issues/1656).

**Operational envelope:** a local operator CLI (`merge_cleanup.py`) that lands this repo's own PRs.
Machinery and tests must stay commensurate with one branch in an existing landing loop. Repo rule
(`AGENTS.md`, GH-831): no new test suites or registry entries — focused cases go into the existing
`test/gh534_phase_b_tests.py`, collected by the registered `test/gh436-merge-cleanup.sh`. No new
tool. Never bypass the pre-push gate. Grade against the stated requirements, not speculative layers.

### Step 1 — paraphrase first (GH-1414)

Read ONLY the plan doc first. Before opening any source file, write 2–5 sentences each under:
- **What this proposes**
- **How the existing system works, per this document**
- **What it's not** (only where a consequential expectation could be mistaken; ground exclusions in
  the plan's own sections, label inference)

### Step 2 — source-backed assessment

Then read the requirements and source:
- Issue text is transcribed in the plan's Problem section. Required behavior (from the operator):
  when GitHub reports CONFLICTING/DIRTY and the conflict is not ledger-only, either (a) attempt a
  local merge of the exact pinned head onto origin/development and, if clean, continue under the
  same pre-push gate and exact-head discipline (merge commit, push, reconcile, recorded in the batch
  issue as the rung used), or (b) stop BEFORE `gh pr merge` with "non-ledger conflict; local merge
  clean/dirty: <files>". Prefer (a) when clean, (b) when dirty. The dry run must wait on or report
  mergeable UNKNOWN instead of printing "Would merge".
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`: `_land_prs_loop` (≈2013–2470),
  `_await_mergeable` (≈1902), `prepare_landing_clone` (≈1100), `push_resolved_head` (≈1172),
  `execute_pr_merge` (≈533), `commit_and_push_phase5_writes` (≈1657), `_record_merge_outcome` (≈1937).
- `skills/2-daily/merge-cleanup/scripts/batch_record.py`: `set_outcome`, `_merge_outcome`, `script_block`.
- `test/gh534_phase_b_tests.py`: `GH_STUB`, `LedgerFixture`, `TestPhase5EndToEnd`.
- `.merge-cleanup.json` (Forge policy: `preserve_commit_history: true`).

Questions:

1. Are the plan's recon claims grounded? In particular: (i) a clean local merge with GitHub
   CONFLICTING falls through to `execute_pr_merge` today; (ii) the dirty non-ledger case already
   stops at the B1 handoff before any merge; (iii) UNKNOWN already stops the dry run. Cite lines.
2. What prevents an unchanged, unfixed candidate from being reported as delivered? Name, per
   requirement R1–R4, the observed rejection the planned tests produce on base (the stub refusing
   `pr merge` for a forced-CONFLICTING PR is the key one) — and whether the stub changes make the
   fixture lie in a way that hides a real defect (Test-Honesty: real seam vs mocked away).
3. Rung (a) placement: wired after final eligibility, the pin check and stacked-dependent
   protection, keyed on the *live* refresh's `mergeable`. Is anything (a guard, the checks wait,
   the ledger gate, batch outcome, the post-merge fast-forward/reconcile) skipped or double-run?
   Is the merge commit built on the same base the ledger gate ran against? Is a moved base refused
   (non-fast-forward push) rather than raced?
4. Exact-head discipline: does the plan keep GH-1226 (only the pinned head lands) on the
   direct-push path where `--match-head-commit` is not available? Is the TOCTOU between the final
   refresh and the push acceptable for a local CLI, given `gh pr merge --match-head-commit` is
   replaced by merging the pinned SHA itself?
5. Is gating `local merge` to strategy `merge` correct (squash/rebase → stop (b))? Is a direct push
   to `development` an existing accepted path (cite `commit_and_push_phase5_writes`)?
6. Is the batch-record change (an optional `rung` field, status stays `merged`) the smallest way
   to "record it in the batch issue as the rung used"? Does it break `_merge_outcome` merging?
7. Over/under-engineering: anything to cut (ponytail) or any requirement missed?

Rules: `[Blocker]`/`[Should]` requesting a behaviour change need `Observed input:`,
`Affected scope:`, `Falsifier:`. You may run read-only probes under `.relay-scratch/` only; do not
run test suites here. Write your verdict below; set `STATUS: Approved` only if the plan is ready to
implement, otherwise hand back with findings.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log
