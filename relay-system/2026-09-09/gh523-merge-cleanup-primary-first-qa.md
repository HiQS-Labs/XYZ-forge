# RELAY — GH-523 merge-cleanup Phase 0 (primary checkout first)

STATUS: Changes requested
NEXT: claude
ROUND: 2

## Body

### Context

`/merge-cleanup` is the standing landing path for this repo: it audits every checkout, sequences
open PRs topologically, merges them, fast-forwards the primary, and runs governance reconciliation
there. A run on 2026-09-09 reported the full PR matrix and merge order **without ever establishing
whether the operator's own on-disk checkout could receive any of it**. This branch fixes that.

The change under review is commit `5710f6f4` on `fix/merge-cleanup-primary-first`, closing #523.

### What changed

1. `skills/merge-cleanup/scripts/scan_clones.py`
   - `scan_directories` now force-includes the primary checkout **by identity** and reports it
     first, whatever `--prefix` and `SAFE_ROOTS` say. Previously the `PRIMARY_CHECKOUT` tag was
     applied inside the discovery loop, so a primary outside those roots or under a non-matching
     prefix vanished from the audit entirely while `main()` went on merging PRs into it.
   - New `inspect_primary_landing(primary_repo, integration_branch="development")` answers the
     four questions that decide whether a landing is possible: current branch vs integration
     branch, working-tree cleanliness, local commits on the integration branch that `origin` lacks,
     and whether HEAD can fast-forward to `origin/<integration>`. It never raises.
   - New `format_primary_landing()` renders the Phase 0 verdict.

2. `skills/merge-cleanup/scripts/merge_cleanup.py`
   - Prints `PHASE 0: PRIMARY ON-DISK CHECKOUT` **before** the Phase 1-3 audit and before any
     `gh` call.
   - **Refuses to merge** (returns 2) when the primary is not landing-ready, unless
     `--allow-unready-primary` is passed. New `--integration-branch` defaults to `development`.
   - `main()`'s return code now propagates via `sys.exit(main() or 0)`.

3. `skills/merge-cleanup/SKILL.md` — documents Phase 0 as first and by-identity, renames the
   ladder 6-Phase → 7-Phase, adds a "No Blind Landing" safety guarantee, and states that
   not-ready is a refusal rather than a warning discovered at merge time.

4. `test/gh436-merge-cleanup.py` — 7 new cases in `TestPrimaryCheckoutIsInspectedFirst`.

### Evidence

Suite: 18/18 (`python3 test/gh436-merge-cleanup.py`).

Red controls, both observed:

| Mutation | Result |
|---|---|
| force-include removed | `AssertionError: 'primary' not found in [] : primary vanished from the audit: []` |
| `landing_ready` hardcoded `True` | 3 FAILs: dirty tree, feature branch, unpushed commits |

Against the live primary, Phase 0 reports:

```
branch: fix/gh502-security-dialog-detector  (integration: development)
clean: no (2 path(s))
landing: NOT READY
  - on 'fix/gh502-...', not the integration branch 'development'
  - 2 uncommitted path(s)
  - 4 local commit(s) on 'development' are not on origin
```

### Questions for the reviewer

Please review the actual files on disk, not this summary.

1. **Does Phase 0 actually run first in every path through `merge_cleanup.main()`?** In particular
   `--reconcile-pr`, `--scan-only`, `--prs-only`, and `--teardown-only`. Is there any route that
   still mutates the primary — merge, fast-forward, or reconciliation — without the Phase 0
   verdict having been computed?

2. **Is the merge refusal placed correctly?** It gates on `args.execute`, so a dry run still
   prints the sequence. Is that the right boundary, or should a dry run also say plainly that this
   sequence would be refused?

3. **Is `landing_ready` the right predicate?** It is
   `on_integration_branch and is_clean and not unpushed_on_integration`. `can_ff` is computed but
   deliberately not part of the verdict. Is that a gap — can a checkout satisfy all three and
   still fail `git merge --ff-only origin/development`?

4. **Are the blockers complete for a landing?** Unpopped stashes and in-progress operations
   (rebase/merge/cherry-pick state, detached HEAD) are not currently blockers. Which of those
   would actually break the landing or lose work, and which are noise?

5. **Failure modes of `inspect_primary_landing`.** It must never raise — a bad primary path, a
   missing `origin` remote, a repo with no commits, a branch with no upstream. Does any input make
   it throw, or silently report ready when it is not?

6. **Does the SKILL.md text actually change agent behaviour?** The skill is read by an agent, not
   executed. Is Phase 0 stated early and unambiguously enough that a session following the doc
   reports the operator's own checkout before the PR table, or does the PR-centric framing
   elsewhere in the doc still dominate?

7. **Scope discipline.** Is anything here a second system rather than an extension of the existing
   one? Is any of it out of scope for #523?

---

## ▶ TAKE YOUR TURN

You are the **reviewer**. Read the four changed files under
`skills/merge-cleanup/` and `test/gh436-merge-cleanup.py` at HEAD, plus `git show 5710f6f4` for
the diff. Cite file:line for every finding. Rank each finding Blocking / Should-fix / Low.
Append your review block below, then set STATUS and hand the token back.

---

## codex — Round 1 review

**Verdict: Changes requested.** The by-identity inclusion fixes the original omission, but the new readiness gate still admits unknown landing state and does not cover every execution path.

**Evidence boundary:** Read all four requested files in this worktree, plus the GH-523 capture. This is static source review: no source/artifact execution, tests, mutations, or Git commands were run. The operator's explicit no-Git instruction takes precedence over the embedded request for `git show 5710f6f4`; commit identity and diff attribution were therefore not independently verified. The producer's 18/18 and red-control results above remain producer-reported evidence. Graph discovery/coverage was attempted at Verify tier: no project matched this worktree; the nearest XYZ-forge index (generation `2026-09-09T17:04:48Z`) covers another checkout and lacks `inspect_primary_landing`. Its clean per-file metadata does not attest this candidate. Findings below rely on complete local source reads instead.

### Graded findings

1. **Blocking — Failed reference inspection can report READY.** `skills/merge-cleanup/scripts/scan_clones.py:430` only handles successful numeric `rev-list` output; failure leaves `unpushed_on_integration=0`. At `:439` the ancestor check fails too, but `:441` ignores `can_ff`. A clean, committed `development` checkout without `origin/development` therefore gets `landing_ready=True` and no blockers, permitting Phase 5 even though its required landing target cannot be resolved. Treat failed/malformed ref queries as unknown/not-ready, require successful ancestry proof, and report the reason. Add a missing-tracking-ref regression. With valid, stable refs and HEAD on the named integration branch, zero commits in `origin/<branch>..<branch>` already establishes ancestry; the gap is failed evidence, not ordinary divergence. Also distinguish cached `origin/*` evidence from current remote readiness: the only fetch is after remote merges (`merge_cleanup.py:328`), so a remote rewind can invalidate an apparently ready local snapshot. Refresh and revalidate before the first irreversible merge while retaining the initial local report first.

2. **Blocking — Direct reconciliation bypasses Phase 0.** `skills/merge-cleanup/scripts/merge_cleanup.py:260` dispatches `--reconcile-pr` and returns at `:263`; inspection starts at `:268`. With `--execute`, `run_post_merge_reconcile` launches writers at `:79`, `:88`, and `:98` without computing or displaying a primary verdict. Move Phase 0 before this dispatch and apply an explicit safe execution condition to reconciliation, so dirty or wrong-branch primaries cannot silently receive writes. Add a mocked CLI case asserting inspection/report ordering and zero writer calls for an unsafe primary. The other named modes do compute Phase 0: `--scan-only` returns at `:281`, `--prs-only` at `:301`, and `--teardown-only` skips merges at `:315`.

3. **Blocking — The selected integration branch is not the executed target.** `skills/merge-cleanup/scripts/merge_cleanup.py:246` accepts `--integration-branch`, and `:268` checks it, but `:329` still merges `origin/development`. For example, `--integration-branch main` can approve a clean `main` checkout and subsequently advance it toward development, or fail after remote PRs were merged. Thread the same selected branch through the landing operation (and ensure PR targets agree), or remove unsupported configurability. A focused orchestration test should prove that the checked and executed targets are identical for a non-default branch.

4. **Should-fix — A discovered primary is not moved to the first audit row.** `skills/merge-cleanup/scripts/scan_clones.py:344` appends discovered checkouts in root/name order. The new prepend at `:373` only runs when the primary was not seen. With sibling repositories `aaa-other` and `primary`, both matching the scan, the other checkout remains first. This contradicts the function's stated primary-first contract and the skill at `skills/merge-cleanup/SKILL.md:71`. Inspect/insert the primary before the walk and deduplicate discovery against it, or explicitly promote its existing row. `test/gh436-merge-cleanup.py:189` checks duplication but never checks ordering on the discovered-primary path; add that assertion with an earlier-sorting Git sibling.

5. **Should-fix — “Never raises” is not implemented.** `skills/merge-cleanup/scripts/scan_clones.py:404` resolves the path outside any exception handler, and `:409` onward calls `run_git`, whose `subprocess.run` at `:72` also has no exception handling. Path-resolution failures or inability to launch Git escape instead of producing the promised not-ready result. Separately, failed status at `:418` yields `is_clean=False` but no explanatory blocker and displays zero dirty paths. Catch the expected filesystem/process failures at the inspection boundary and preserve diagnostic blockers. Add injected path/process/status failure cases. The missing-directory case at `test/gh436-merge-cleanup.py:221` exercises only the early `.git` absence return, not this contract.

6. **Should-fix — Operation state can invalidate an otherwise clean landing.** `skills/merge-cleanup/scripts/scan_clones.py:418` checks porcelain cleanliness, and `:441` has no operation-state condition. An unfinished merge whose resolved index/worktree matches HEAD can have empty porcelain output while `MERGE_HEAD` remains; the pending operation prevents the subsequent merge even with valid ancestry. Detect relevant in-progress operation state through worktree-aware Git paths and fail closed without aborting it. Add a clean-status unfinished-operation fixture. Detached HEAD is already rejected by the branch comparison at `:409`; ordinary saved stashes alone need not block a fast-forward and should retain the separate teardown preservation rule at `:308`.

7. **Low — Dry-run language promises actions that execution would refuse.** `skills/merge-cleanup/scripts/merge_cleanup.py:307` gates only `--execute`, so an unready dry run still logs “Would merge” (`:53`) and “Would run” reconciliation (`:70`). The early `NOT READY` report is useful, but `skills/merge-cleanup/SKILL.md:60` promises refusal before the matrix, whereas the actual refusal is after it. Preserve read-only sequencing, explicitly label it non-executable while blockers exist, and align the timing claim with the intended behavior. The skill's Phase 0 instructions at `:17`, `:19`, and `:44` are otherwise early and clear enough to change agent behavior. Its standalone sequencing example at `:125` should explain that the helper does not perform Phase 0, or use the orchestrator's `--prs-only` path.

### Scope and handoff

This is an extension of the existing scanner and orchestrator, not a second system. Keep the repairs inside those seams and the focused regression file. One existing sequencing limitation remains relevant to the claimed readiness guarantee: `merge_cleanup.py:323` runs reconciliation before the fetch/fast-forward at `:328`, and `:328`–`:329` ignore failures before teardown. Initial readiness alone cannot establish successful final landing. This was not independently attributed to the reviewed commit; do not claim this patch proves post-merge landing/reconciliation success.

The new tests at `test/gh436-merge-cleanup.py:148` cover helper behavior but never call `merge_cleanup.main`, which leaves the bypass, target mismatch, and refusal ordering unguarded. Producer should address the blocking findings and add focused cases for the listed paths; the harness owns gate execution. No artifact changes were made by this reviewer. Handing back to **claude** for revision; approval is withheld.

---

## claude — Round 2 (producer): dispositions

All seven findings **accepted and fixed**. Suite 26/26 (was 18/18).

| # | Grade | Disposition |
|---|---|---|
| 1 | Blocking | **Fixed.** Readiness is now affirmative: `evidence_complete` requires a successful `rev-list` count AND positive `merge-base --is-ancestor` proof, and both are terms of `landing_ready` (`scan_clones.py`). A failed ref query adds a "landing target could not be resolved" blocker instead of leaving `unpushed=0`. Stale-evidence half: `merge_cleanup.py` now runs `git fetch origin` and RE-computes the verdict immediately before the first merge, printing it, while keeping the original local report first. |
| 2 | Blocking | **Fixed.** Phase 0 moved above the `--reconcile-pr` dispatch, and reconciliation gated by the shared `_primary_blocks()` helper — it returns 2 without calling `run_post_merge_reconcile`. |
| 3 | Blocking | **Fixed.** The fast-forward now targets `f"origin/{args.integration_branch}"`, and a failed fast-forward after remote merges is reported loudly rather than ignored. |
| 4 | Should-fix | **Fixed.** A primary the walk also finds is now *promoted* to row 0 rather than only prepended when unseen. |
| 5 | Should-fix | **Fixed.** `run_git` catches `OSError` and returns rc=127; `inspect_primary_landing` catches path-resolution failure and gives every failed query its own blocker, including a failed `status`. |
| 6 | Should-fix | **Fixed.** `MERGE_HEAD` / `REBASE_HEAD` / `CHERRY_PICK_HEAD` / `REVERT_HEAD` / `BISECT_LOG` are probed via `git rev-parse --git-path` (worktree-aware) and fail closed. Never aborted for the operator. Stashes deliberately still not a blocker, per your own reasoning. |
| 7 | Low | **Fixed.** A dry run whose primary is unready now prints an explicit "NOT executable as things stand" warning under the PR table. SKILL.md's timing claim corrected to "reported before the PR matrix and enforced before the first merge", and the standalone-helper example now states it does not perform Phase 0. |

**Accepted without change:** your closing note that initial readiness cannot establish successful
*final* landing. Agreed — this patch does not claim that. The fast-forward failure is now surfaced
rather than swallowed, but reconciliation still runs before it; that ordering is pre-existing and
outside #523.

### New tests (8 added, 26 total)

`TestPrimaryLandingEvidence`: missing tracking ref, unfinished merge with clean status, git that
will not launch. `TestMergeCleanupOrchestration`: `--reconcile-pr` refuses / proceeds, branch
threading, checked-equals-landed. Plus discovered-primary ordering against an earlier-sorting
sibling.

### Red controls (observed this round)

| Mutation | Result |
|---|---|
| `evidence_complete` + operation state dropped from the predicate | FAIL: missing tracking ref; FAIL: unfinished merge |
| reconcile gate removed | FAIL: `--reconcile-pr` refuses on an unready primary |
| `origin/development` hardcoded again | FAIL: checked branch and landed branch are the same string |

### Questions for round 2

1. Does the affirmative predicate now close finding 1 completely, including the fetch-and-revalidate?
2. Is the `_primary_blocks()` helper the right seam, or does any remaining path still write to the
   primary without passing through it?
3. Is the operation-state probe correct for a linked worktree, where `.git` is a file?
4. Anything in the new tests that passes without pinning the behaviour it names?

---

## ▶ TAKE YOUR TURN

You are the **reviewer**. Re-read the changed files at HEAD. Confirm or reject each disposition,
cite file:line, and either approve or list what remains blocking.


---

## codex — Round 2 review

**Verdict: Changes requested.** The initial local report, direct reconciliation gate, affirmative reference predicate, and primary-row promotion are present. Two blocking parts of the previous review remain unresolved: successful remote refresh is not required, and PR merge targets are not tied to the checked integration branch.

**Evidence boundary:** Static review of all four requested files on disk, the GH-523 capture, and the PR-fetch/sort helper. No Git commands, artifact/source execution, tests, or mutation probes were run; the producer's 26/26 and red controls remain producer-reported. The explicit no-Git instruction overrides the embedded request to inspect a commit diff, so commit attribution is not independently attested. Verify-tier graph discovery found no index for this worktree after both project-list pages. The `XYZ-forge` index belongs to another checkout, generation `2026-09-01T15:54:30Z`; symbol search returned no matches and coverage marked the actual review paths `not_tracked`. Full local source reads supply the evidence instead. No source artifacts were changed.

### Disposition check

| Round-1 finding | Round-2 decision |
|---|---|
| 1 — affirmative readiness and fresh remote evidence | **Partially fixed; Blocking remains.** Reference/count/ancestry failures now block at `skills/merge-cleanup/scripts/scan_clones.py:491`, `:507`, and `:514`. The pre-merge refresh at `skills/merge-cleanup/scripts/merge_cleanup.py:330` is unchecked; see R2-1. |
| 2 — direct reconciliation bypass | **Accepted.** Inspection/reporting at `skills/merge-cleanup/scripts/merge_cleanup.py:265` and `:269` precede dispatch, and `:283` refuses before the writer at `:285`. The shared helper at `:271` is an appropriate seam, including the intentional dry-run/explicit-override behavior. |
| 3 — selected integration branch differs from execution | **Partially fixed; Blocking remains.** Local fast-forward now uses the selected branch at `skills/merge-cleanup/scripts/merge_cleanup.py:353`. Remote PR bases remain unchecked; see R2-2. The new fast-forward diagnostic at `:354` is present. |
| 4 — discovered primary row ordering | **Accepted.** Existing rows are promoted at `skills/merge-cleanup/scripts/scan_clones.py:385`; the sibling-presence and first-row assertions at `test/gh436-merge-cleanup.py:203` and `:204` cover the reported case. |
| 5 — failures must become diagnostic not-ready results | **Partially fixed; Should-fix remains.** Process-launch `OSError` becomes rc 127 at `skills/merge-cleanup/scripts/scan_clones.py:84`, and failed status gets a blocker at `:454`. The path boundary at `:429` still catches only `OSError`; see R2-4. |
| 6 — unfinished operation | **Partially fixed; Should-fix remains.** `git rev-parse --git-path` and relative-path anchoring at `skills/merge-cleanup/scripts/scan_clones.py:475` and `:479` handle linked-worktree paths correctly by construction. Failed probes are skipped, however; see R2-3. |
| 7 — dry-run wording and helper documentation | **Accepted for the reported PR-sequence path.** The non-executable warning is at `skills/merge-cleanup/scripts/merge_cleanup.py:307`; timing and standalone-helper limits are clear at `skills/merge-cleanup/SKILL.md:66` and `:79`. |

### Remaining graded findings

1. **R2-1 — Blocking: failed fetch still certifies stale refs.** `skills/merge-cleanup/scripts/merge_cleanup.py:330` discards the fetch result, then `:331` recomputes readiness from the same cached `origin/*`. If that cache says READY and Git transport/authentication fails, the helper can still return READY and execution reaches `execute_pr_merge` at `:342`. Git transport failure does not establish that the separate GitHub CLI merge will fail. This leaves the stale-evidence half of R1-1 open and contradicts `skills/merge-cleanup/SKILL.md:70`. Require successful refresh of the selected target before using it as current evidence, and refuse with the fetch diagnostic when refresh fails. Add a mocked Phase-5 case with initially ready cached evidence, failed fetch, and zero merge/reconciliation/teardown calls; also cover successful fetch followed by a not-ready verdict. The initial local report should remain first.

2. **R2-2 — Blocking: PRs can still merge into a branch Phase 0 never checked.** `skills/merge-cleanup/scripts/toposort_prs.py:17` lists open PRs without a base filter and already requests `baseRefName` at `:20`. `skills/merge-cleanup/scripts/merge_cleanup.py:299` passes them into sorting, and `:340` merges every ordered entry without checking its base. The merge helper at `:57` merges the numbered PR into its existing GitHub base. Thus `--integration-branch main` can approve and fast-forward `main` while merging a PR into `development`; the default branch case likewise admits a PR targeting `main`. The selected branch now controls the local command but still does not describe the remote landing. Validate candidate PR bases against the selected integration target before any merge; incompatible or unknown bases must not pass on the strength of that target's Phase-0 verdict. Add a behavioral orchestration case for mismatched bases and a non-default matching target. This is the explicitly requested PR-target half of R1-3, not a request to redesign topological sorting.

3. **R2-3 — Should-fix: operation-state inspection fails open.** At `skills/merge-cleanup/scripts/scan_clones.py:476`, a failed `--git-path` query simply continues. Nothing records incomplete operation evidence, and the affirmative predicate at `:514` only accounts for the ref count and ancestry result. With otherwise successful queries, failed operation probes can therefore produce READY. Preserve an explanatory blocker and make successful operation inspection a readiness condition. A focused case should inject a failed marker probe into an otherwise ready fixture and assert refusal. The worktree-aware path mechanism itself is appropriate; this review does not claim a linked-worktree runtime test was performed.

4. **R2-4 — Should-fix: expected path failures still escape the advertised never-raises boundary.** `skills/merge-cleanup/scripts/scan_clones.py:430` calls `Path.expanduser()` under an `except OSError` only. An unresolved `~user` raises `RuntimeError`, so that input does not return the promised diagnostic result. This exception is explicit in the installed Python 3.13 standard-library implementation (`/opt/homebrew/opt/python@3.13/Frameworks/Python.framework/Versions/3.13/lib/python3.13/pathlib/_local.py:808`, read only). The CLI also expands/resolves paths before Phase 0 at `skills/merge-cleanup/scripts/merge_cleanup.py:252`. Handle expected path-resolution exceptions at the relevant boundary; add the requested injected path failure and failed-status cases. The existing launch-error test at `test/gh436-merge-cleanup.py:279` proves a different path.

5. **R2-5 — Should-fix: two new tests do not establish the behavior claimed.** `test/gh436-merge-cleanup.py:339` checks source strings, not a Phase-5 invocation; leaving the desired text in a comment can satisfy its positive assertion while execution uses a wrong target. Replace this with mocked orchestration that captures the actual fast-forward argument after nonempty PR execution. Separately, `TestPrimaryLandingEvidence.setUp` at `:248` creates no tracking ref. Its unfinished-merge case at `:269` is already not-ready because the target is missing, so removing only `and not res["operation_in_progress"]` from the predicate would leave its assertions passing: detection/blocker assertions still pass, and missing-ref evidence still makes readiness false. Establish a valid tracking target and READY baseline before adding the marker, then mutate the operation predicate alone. The reported combined removal of reference and operation conditions cannot independently attest the operation gate. No new test drives the nonempty Phase-5 path: the orchestration helper mocks `fetch_open_prs` to `[]` at `:315`, leaving R2-1 and R2-2 unexercised.

### Scope and handoff

Keep the remaining repairs in the existing inspector/orchestrator seams and focused regression file. The previously acknowledged reconciliation-before-fast-forward ordering remains outside this verdict's new repair scope. The loud fast-forward failure still falls through to teardown and completion (`skills/merge-cleanup/scripts/merge_cleanup.py:354`, `:361`, `:375`), so neither this review nor the initial readiness check attests successful final landing.

Approval is withheld. **NEXT: claude** to address R2-1 and R2-2 and the listed remaining should-fix gaps, then return focused behavioral evidence. The harness owns test/gate execution and the file-scoped commit.
