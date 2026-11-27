# GH-1656 plan QA — non-ledger GitHub conflict: local-merge rung or a precise stop
STATUS: Open
NEXT: claude-a (Producer)

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


## Log

### Codex reviewer, round 1

**What this proposes.** When GitHub reports a conflict but Git can merge the pinned head cleanly, the `merge` strategy would land a merge commit through the existing pre-push hook. The plan adds a precise stop for dirty merges or incompatible strategies, changes the dry-run preview, and records the local rung in the batch issue.

**How the existing system works, per this document.** Phase 5 polls for GitHub's mergeability decision, prepares a disposable clone, and runs the ledger gate against the local merge. Dirty non-ledger conflicts stop at B1. A clean result proceeds through the remaining guards to the GitHub merge API, where GitHub can still refuse it.

**What it's not.** The frontmatter excludes branch updates that change the approved pin and local landings under squash or rebase policies. The preflight and implementation sections keep the existing ledger repair budget, pre-push hook, and test registry.

**Verdict:** Changes requested. Keep the single local-merge branch and common Phase 5 tail. Revise the pre-push and post-push contracts and make the red controls reach the intended seams.

#### Findings

1. **[Blocker] Verify the exact landing tree and base before publication.**

   **Observed input:** `merge_cleanup.py:1135–1141` checks out the pin and merges the integration ref into it. `merge_cleanup.py:2294–2304` gates that result, including the ledger worktree at `ledger_merge.py:687–715`. Plan lines 131–138 abort it and merge in the opposite direction before pushing. The plan checks only that the second merge succeeds. A local merge driver or an ours/theirs-sensitive resolution can yield a different clean tree. The usual non-fast-forward rejection also covers only incompatible base movement. If the integration ref moves to a commit already reachable through the pinned parent, the push is still a fast-forward even though its first parent is the old base.

   **Affected scope:** R1 and the exact-base claim. Capture the gated base and verify the tree of the proposed commit against the gated index, or run the existing ledger gate on the actual base-first simulation before committing it. Verify both parents and distinguish an already-contained pin or a failed command from a new clean merge. Reuse the exact-tip comparison at `merge_cleanup.py:2354–2363` and make the remaining push-time guarantee explicit. A preflight equality check alone leaves a race before Git negotiates the update. Preserve the no-force and hook requirements.

   **Falsifier:** Different clean trees cannot reach push. The landing has first parent equal to the gated base and second parent equal to the pin, and a moved base is refused even when the candidate contains the new tip via its second parent.

   **Clone probe:** `python3 test/gh534_phase_b_tests.py TestGh1656NonLedgerConflict.test_gated_tree_differs TestGh1656NonLedgerConflict.test_moved_base_is_ancestor_of_pin` after adding the named cases to the existing module. Use an asymmetric merge driver for the first case. For the second, advance the bare origin to an intermediate commit on the pinned branch just before the actual push and assert the published tip stays at that intermediate commit. [Unverified — needs clone run]

2. **[Blocker] Preserve PR eligibility and confirmation across the direct push.**

   **Observed input:** `merge_cleanup.py:2106–2111` checks OPEN and the selected base before the ledger gate and checks wait. The final refresh at `2382–2415` checks errors, draft/hold and head OID, but leaves OPEN/base checks to the GitHub merge endpoint. The proposed direct push targets the configured branch regardless of PR state or retargeting. That branch also ignores the late UNKNOWN case, and the current refresh at `587–592` does not fetch `mergeStateStatus` to cover the stated DIRTY input. After publication, plan lines 138–141 treat poll exhaustion as a success. The success tail records `merged` at `2419–2420` via `1937–1944`, then invokes reconcile at `2437–2442`. The local reconciler queries GitHub again (`merge_cleanup.py:1618`, `utils/py/wave_reconcile.py:384–422`) and routes an OPEN PR as unmerged (`2905–2916`, `2958–2986`). A stub that immediately returns MERGED hides this path.

   **Affected scope:** R1–R3 and the existing confirmation contract at `merge_cleanup.py:555–584`. Recheck OPEN, target, draft/hold, and the exact pin on the final live read before a direct push. Route the stated CONFLICTING/DIRTY signals explicitly and stop or poll if the final state is undecided. Keep the pushed OID as evidence of publication. Require confirmation of the pinned PR and reconcile against that landing before recording PR completion. On timeout, report the published or uncertain push separately, retain its OID and the rung, and name the resume/reconcile path so it neither pushes again nor processes a still-OPEN PR. The immutable SHA limits the head race to the approved content, but it cannot atomically prove the PR is still on that head or target at push time. Post-push drift can stop attribution, not reverse the push.

   **Falsifier:** A close or retarget with the same pin stops before push. Delayed confirmation enters the common tail once after MERGED. Confirmation timeout or MERGED on a different head never invokes reconcile or records completed success, and recovery retains the actual publication evidence.

   **Clone probe:** `python3 test/gh534_phase_b_tests.py TestGh1656NonLedgerConflict.test_final_pr_retargeted TestGh1656NonLedgerConflict.test_confirmation_lags_after_push TestGh1656NonLedgerConflict.test_confirmation_timeout_after_push` after adding the named cases. Drive a real bare-origin push and independently control the GitHub stub's final and post-push reads. In the timeout case assert the new origin OID is retained and no reconcile or next landing occurs. Keep the observed stale state available to the reconcile assertion. [Unverified — needs clone run]

3. **[Blocker] Make R1/R2/R4 assertions reachable in the existing fixture.**

   **Observed input:** Plan lines 113–119 require one PR, rc 0, an issue outcome row and a dirty-case rc 2. `merge_cleanup.py:3093–3098,3214–3228` creates no batch for one PR. With a real batch, `3168–3188` returns 4 while QA is pending. B1 handoff continues the queue at `2211–2219` and returns 3 for remaining handoffs at `2515–2528`. If the test sets `preserve_commit_history: true`, the policy capability check at `518–529` also requires `mergeCommitAllowed`, which the stub's `repo view` at `test/gh534_phase_b_tests.py:110–111` lacks. The fixture stubs hook wiring at `204–211`, so its ordinary success cannot establish that the hook blocked a bad push.

   **Affected scope:** Use `--strategy merge` or supply the capability in the policy fixture. Match the existing handoff exit 3 unless that behavior is deliberately changed. Use two PRs for the R4 issue assertion, inspect the rendered issue body captured by the stub at `112–124`, and expect the existing QA-pending exit when applicable. Keep the real bare-origin parent assertions. Use a rejecting hook in a focused case to prove the new push hits the hook and leaves origin unchanged. The normal hook check alone proves wiring, and `githooks/pre-push:83–87` honors an inherited bypass variable, so the new rung needs to refuse or strip that override.

   **Falsifier:** With only the fixture changes on base, the clean merge-policy and squash cases fail because their forced-conflict PR actually reaches the logged and rejecting `pr merge` call. The dirty case fails on the missing new diagnostic. The conflict preview fails on its old generic line. The stuck UNKNOWN case passes on base. On the candidate the published issue names the rung and the rejecting hook leaves the remote unchanged.

   **Clone probe:** `python3 test/gh534_phase_b_tests.py TestGh1656NonLedgerConflict` on base with the revised fixture and again on the candidate, then `bash test/gh436-merge-cleanup.sh` on the candidate, each from a disposable full clone. For the success stub, infer MERGED only from the actual origin ancestry and the commit introducing the current head, with separate delayed and withheld confirmation controls. [Unverified — needs clone run]

#### Recon and scope

- **Clean / dirty / UNKNOWN.** On the seeded source, the clean simulation proceeds to the ledger gate, checks wait, pin check, and `execute_pr_merge` (`merge_cleanup.py:2294–2345,2382–2418`), whose call includes the match-head guard (`550–555`). The dirty non-ledger result hands off before any merge for that PR (`ledger_merge.py:565–582`, `merge_cleanup.py:2206–2219`). Persistent initial UNKNOWN stops at `1902–1916,2112–2128`, ahead of either dry-run preview or execute. A transition from UNKNOWN to CONFLICTING can still reach the generic preview at `2379–2381`. The new preview should respect the checks-pending preview at `2334–2335` and use the settled `info` available in dry-run mode.
- **Placement and history.** The proposed branch preserves the existing ledger and checks waits and can join the single fast-forward/reconcile/emit/write tail at `2419–2449` when confirmation succeeds. Guard the clean squash/rebase stop before `_protect_stacked_dependents`, which can edit dependent PR bases at `640–658`. The merge-only policy follows `merge_cleanup.py:508–515` and `.merge-cleanup.json:2`. The gated direct push of reconcile commits already exists at `merge_cleanup.py:1690–1702`. It establishes the transport precedent, while the PR landing adds the eligibility and confirmation obligations above.
- **Batch field.** Optional `rung` is sufficient. `batch_record.py:123–142` already persists arbitrary concrete touched fields, so set and touch it in `291–307` and render it in `375–381`. A later reconcile-only save will preserve it. The canonical `merged` status and existing merge rules stay intact.
- **Evidence limits.** Source-backed plan review only. The nearest graph is the canonical Forge clone indexed at 2026-11-26T04:31:47Z, with different source offsets. The trace request was denied by the tool, so the decision uses the seeded worktree's source lines. No runtime suites or fixtures ran and no reviewer phase gate was specified.

### Producer (claude-a), round 1 dispositions

1. **Accepted.** Step 2 now captures the gated tree and gated base before aborting, builds the
   base-first merge on the gated base, and refuses to push unless `HEAD^1 == gated base`,
   `HEAD^2 == pin`, `HEAD^{tree} == gated tree`. The push uses
   `--force-with-lease=refs/heads/<branch>:<gated base>`: an atomic compare-and-swap on the exact
   gated base, which covers the "moved to an ancestor of the pin" case; HEAD descends from the
   leased base, so a successful push is always a fast-forward. `test_moved_base_refused` added.
   The asymmetric-merge-driver test is **declined (ponytail)**: the tree-equality check is a
   three-line comparison; the moved-base and rejecting-hook tests already drive the real push.
2. **Accepted, one part declined.** Final live read now also requires OPEN and the selected base;
   routing is explicit on live `mergeable` (MERGEABLE → `gh pr merge`, CONFLICTING → rung/stop,
   else stop). Post-push confirmation timeout no longer enters the success tail: it records the
   pushed OID as `published (local-merge rung), GitHub has not confirmed`, names
   `--reconcile-pr N`, exits 2, no reconcile, no next PR. Lag and withheld controls added; the
   stub infers MERGED only from real origin ancestry. **Declined:** fetching `mergeStateStatus` —
   GitHub's `mergeable: CONFLICTING` is the signal the incident carried with DIRTY, and the routing
   keys on it; a second field adds a stub and refresh surface without a distinct input.
3. **Accepted.** `--strategy merge` in the fixture (no capability probe); two PRs for the batch
   issue assertion on the rendered body with the existing exit 4; dirty case keeps the existing
   handoff exit 3; a real rejecting pre-push hook in the landing clone plus `XYZ_SKIP_PREPUSH=1`
   in the caller env proves the rung hits the hook and strips the override. The squash stop now
   runs before `_protect_stacked_dependents`.

Plan revised in `PROJECT/2-WORKING/GH-1656-NON-LEDGER-CONFLICT.md` steps 1–3.

### Codex reviewer, round 2

**What this proposes.** Build a base-first merge of the approved pin and verify its parents and tree against the gated result. Publish it through the existing hook with an exact-base lease, then require GitHub confirmation before continuing to reconciliation.

**How the existing system works, per this document.** Phase 5 settles GitHub's mergeability signal, simulates the merge in a disposable clone, and hands dirty non-ledger conflicts back to the operator. Clean simulations proceed through ledger and eligibility checks to the GitHub merge command, and a confirmed merge enters the batch recording and reconciliation tail.  [Unverified — no citation]

**What it's not.** The frontmatter limits local landing to the merge strategy and preserves the ledger repair budget and pre-push gate. Steps 2–3 treat a published commit awaiting GitHub confirmation as a separate outcome.

**Verdict:** Changes requested. The tree and parent comparisons plus the exact-base lease close the round-1 base race once the candidate commit exists. The clean setup, attribution and publication failure paths still need a complete contract.

1. **[Blocker] Handle a successful simulation with no merge to abort.**

   **Observed input:** `merge_cleanup.py:1135–1141` checks out the pin and merges the base into it. `ledger_merge.py:413–426` explicitly accepts that simulation without `MERGE_HEAD` when the pin already contains the base. `test/gh534_phase_b_tests.py:227–236` cuts the proposed success fixture's PR branch directly from development. With no intervening base advance before A, the simulation is already up to date. Plan step 2 (`GH-1656-NON-LEDGER-CONFLICT.md:148–154`) calls `git merge --abort` unconditionally before building the base-first merge.

   **Affected scope:** R1 and the primary success test. Check for an active merge and abort only when present. Require a successful abort when needed. Fail closed on failed tree/base capture, checkout or unexpected merge error. Keep the planned parent and tree comparisons, and give an already-contained pin or a clean tree mismatch a specific R2 stop reason. This keeps the same clone and ledger gate.

   **Falsifier:** The main success fixture leaves the gated base as an ancestor of A's pin, reaches the actual push, and records two parents and the gated tree. The divergent-but-clean path still aborts its real in-progress merge. An unexpected abort failure leaves origin unchanged.

   **Clone probe:** `python3 test/gh534_phase_b_tests.py TestGh1656NonLedgerConflict.test_clean_conflicting_lands_through_rung` with A first and cut from the current base. Assert that the original simulation has no `MERGE_HEAD` and verify both parents and the tree from bare origin. [Unverified — needs clone run]

2. **[Blocker] Bind confirmation and recovery to the commit the rung actually published.**

   **Observed input:** Plan steps 2–3 (`GH-1656-NON-LEDGER-CONFLICT.md:161–175`) accept MERGED at the pin and send every unconfirmed result, including MERGED at a different head, to `--reconcile-pr N`. The existing merge proof requires MERGED and a nonempty `mergeCommit.oid` (`merge_cleanup.py:559–584`). Recovery accepts any MERGED response with an OID, uses its current head and OID to reconcile, then rewrites the batch's merge OID (`2855–2884`). Independently, the Phase 5 finalizer overwrites any status other than `merged` on the current row at rc 2 (`1974–1996`). Putting a pending publication's OID in `merge_oid` also admits it to landed/QA accounting immediately (`batch_record.py:235–247,505–507,559–575`).

   **Affected scope:** R1/R4, the phase tail and the operator's recovery command. Require confirmation to match the pinned head, target and pushed commit OID. Carry the confirmed OID to hosted reconcile as `merged_head` when that mode is configured (`merge_cleanup.py:1595–1606,2437–2442`). Retain the unconfirmed publication separately from the confirmed merge OID and preserve its diagnostic through the finalizer. Before telling the operator to use `--reconcile-pr N --execute`, require them to verify the same published OID, pin and target once GitHub confirms, or validate those fields in the existing recovery command. A mismatched MERGED response needs an explicit stop and investigation. Keep the optional `rung` in the existing record and include it when rendering pending publication and confirmed success. This uses the existing tail and batch writer.

   **Falsifier:** Exact confirmation enters the tail once. Missing or different merge OID, a different head, or a different target leaves the published OID and rung visible, with no confirmed merge row, reconcile call or next push. Following the prescribed recovery with mismatched evidence cannot attribute or reconcile it as this rung's landing.

   **Clone probe:** `python3 test/gh534_phase_b_tests.py TestGh1656NonLedgerConflict.test_confirmation_lag_then_tail_once TestGh1656NonLedgerConflict.test_confirmation_withheld_stops_without_reconcile`. In the withheld scenario, drive the external read seam with missing and mismatched commit OIDs and a moved head, then exercise the recovery instruction against the mismatch. Inspect the final issue body and reconciliation calls after the actual bare-origin push. The stub can establish the consumer behavior; the plan's prior manual landing establishes that a direct push can land the commit, while live GitHub attribution remains unmeasured here. [Unverified — needs clone run]

3. **[Blocker] Distinguish a rejected push from an unknown publication result.**

   **Observed input:** Plan lines 155–163 run a bounded network push and poll after success. Its Risks section at 210–212 assumes push failure means nothing landed. `merge_cleanup.py:226–234` converts a timeout to rc 124, so the same nonzero shape can represent a lost acknowledgement after a remote ref update. The existing GitHub path looks up actual remote state on error for this reason (`555–571`). The revised local path provides recovery evidence only after a reported successful push.

   **Affected scope:** R1/R4 and safe retries. Capture the candidate OID before invoking the push. After a timeout or ambiguous transport failure, read the destination to distinguish candidate present, proven rejection and unknown. If the candidate is present, use the same confirmation path. If evidence is unavailable, report the candidate OID, target and rung and stop for verification. The exact-base lease continues to prevent overwriting a moved integration ref; it cannot tell the caller whether the previous command published.

   **Falsifier:** A push that really updates bare origin and then returns rc 124 never reports an unpublished failure or attempts a second push. A lease rejection keeps the new origin tip. An unavailable remote read retains the candidate OID and stops without reconcile or a next landing.

   **Clone probe:** `python3 test/gh534_phase_b_tests.py TestGh1656NonLedgerConflict.test_push_acknowledgement_lost TestGh1656NonLedgerConflict.test_moved_base_refused` after adding the first case to the existing fixture or recording an equivalent manual case. Wrap the one push call to run the real push first, then return the timeout shape, and check the published ref from bare origin. In the lease case advance origin to an intermediate commit on the pinned parent so a plain fast-forward push would otherwise succeed. [Unverified — needs clone run]

**Remaining assessment.** The seeded clean/dirty/UNKNOWN paths and merge-only policy are grounded as recorded in round 1. The final live refresh is the right branch point (`merge_cleanup.py:2382–2418`), with stop-only decisions before stack retargeting. A branch update during the push cannot add unpinned content to the candidate. Exact post-push attribution is still required. Keying on CONFLICTING is adequate for the observed input paired with DIRTY. The fixture's forced-CONFLICTING refusal is an honest base red for R1 and the squash arm of R2. The dirty diagnostic is R2's red, the conflict preview is R3's red and stuck UNKNOWN is an existing green control. The rendered batch row is R4's assertion. Keep the ancestry-derived MERGED response scoped to direct-push cases so existing false-success controls retain their meaning. Make the rejecting hook reject only when the explicit skip override was removed so the advertised bypass check can fail. Qualify the clean conflict preview if required checks are pending (`2334–2335`), and reference acceptance cases by name because plan lines 201–203 still point to the old test numbers.

**Evidence limits.** Static Verify-tier review against the seeded source. Coverage checked on the nearest indexed Forge clone, generation 2026-11-26T04:31:47Z. Its bounded symbol search returned no matches, and the revised plan was absent there, so the cited evidence comes from direct source and plan reads in this worktree. No runtime probes, suites or reviewer phase gate ran.

VERDICT: FAIL
Basis: The plan needs to handle the clean no-op simulation, preserve exact publication identity through confirmation and recovery, and retain evidence after an ambiguous push.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
