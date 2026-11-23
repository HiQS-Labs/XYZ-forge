# Recon Map — GH-1383 batch finalization repair
Commit: 85dbb6bdb5383213bae37944a3efc0f4a63da1af. Grep/read mode; no graph evidence used. Main lane plus independent read-only plan QA.

## Subject and change class
Repair existing merge-cleanup orchestration and isolation, with no new runtime authority, subsystem or persisted schema. Current module, batch_record and existing suite read; the original proposal and all five user-supplied defects were confirmed directly.

## Call paths and seams
- main -> land_prs -> _land_prs_loop (1290+) -> execute_pr_merge -> fetch/fast-forward -> run_post_merge_reconcile(892) -> emit_pr_merged -> commit_and_push_phase5_writes(975). Exact-head allowlist and AST ordering test gh549:627–640 remain binding.
- run_post_merge_reconcile skips issue-doc-sync when intermediate(949), but the loop's remaining_unattempted prediction(1657) includes not-yet-qualified successors; footer requires more than one actual merge(1688). One merge then deferred successors strands sync. Ordinary all-success batches duplicate sync.
- footer final sync(1692) warns on failure; add/commit/fetch(1695–1703) are unchecked. Existing commit_and_push_phase5_writes already checks all publication steps plus clean/remote equality.
- canary(1677) executes arbitrary policy command in primary without timeout. run_auto_sweep(2340) also permits primary execution and weakens the generated mktemp && chain into semicolon + rm trap.
- batch_record.finalize_sweep_inputs(494–542) emits guarded clone prefixes for local Small/per_batch; full promotion commands remain explicitly deferred. record_verdict owns clean/findings/deferred and QA debt; canary must not prematurely mark final QA clean.
- existing gh436 suite has orchestration mocks(392–466), sweep/verdict cases(812–884), checked publication(836–868) and canary-stop(902–925); no new suite/registry needed.
- _land_prs_loop finally deletes helper clones independently of Phase6; selected executing seam must preserve them under current no-cleanup instruction.

## State and downstream behavior
Each merge's verified OID enters the batch record before reconciliation; reconciled set determines whether persisted outcome is marked ok or still recoverable. Deferred sync debt must remain unfulfilled until successful final sync AND checked publication. Final failures return2; subsequent --reconcile-pr can recover with normal non-intermediate checks. No new DB state or retry-count reset.

## Contracts, rollback and radius
Existing primary-ready, strategy, pinned-head, bounded repair, hosted-check, emission order and committed-receipt contracts remain intact. Command execution moves into retained disposable full clones, not primary; no new runner executable or cleanup trap. Runtime/module tests plus SKILL/doc claims are the affected radius. Rollback is a reviewed revert before subsequent runs; no schema migration or one-way data operation introduced.

## Unknowns
Actual runtime gate and latest repaired composition are unverified until fresh disposable-clone tests/QA. App discovery remains unverified until per-app deployment checks. Foreign receipt/link conflicts remain boundaries, not permission to adopt/replace. Original source MacBook test claims are not reused as repair proof.
