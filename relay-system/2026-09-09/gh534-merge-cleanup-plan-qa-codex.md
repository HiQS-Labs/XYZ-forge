---
Goal: Plan QA — GH-534 merge-cleanup failure modes (Phases A, B1, C) before implementation
Date: 2026-09-09
Producer: claude-a
Reviewer: codex
NEXT: codex
STATUS: Open
Round-cap: 3
---

# Context

Adjudicate the plan in `PROJECT/1-INBOX/GH-534-MERGE-CLEANUP-FAILURE-MODES.md` **before** any
implementation. The operator has chosen Phase **B1** (implement the ledger-conflict half) and added
Phase **C** (a decision ladder for conflicts B1 cannot resolve). Base SHA for all claims: `6e304820`.

This is a plan review, not a build turn. Do not edit anything except this file.

Read in full:

- `PROJECT/1-INBOX/GH-534-MERGE-CLEANUP-FAILURE-MODES.md` — the plan under review
- `skills/merge-cleanup/SKILL.md` — what the skill promises
- `skills/merge-cleanup/scripts/merge_cleanup.py`, `scan_clones.py`, `toposort_prs.py` — what it does
- `WORKTREE-SAFETY.md` lines 700–810 — the `SAFE_ROOTS` governance the scripts mirror
- `utils/releases-merge-resolve.sh` — the resolver Phase B1 proposes to drive
- `skills/workhorse/SKILL.md` — the existing decision-ladder shape Phase C copies
- `test/gh1-adoption-guard.sh` — the existing "docs promise X, code must have X" guard shape

Also read the issue thread if reachable: https://github.com/HiQS-Labs/XYZ-forge/issues/534
(two comments: the `WORKTREE-SAFETY.md:783` root-cause addendum and the commit lineage).

# Questions

Answer every one. Cite `file:line` for each claim you confirm or dispute.

1. **Are the six failure modes (A–F) real at `6e304820`?** For each: confirmed / disputed, with the
   line. In particular verify D by grep: is `inspect_tick_claims()` called anywhere? And verify A
   by reading `DEFAULT_SAFE_ROOTS` and `is_safe_deletable_path()`.

2. **Phase A.2 — unpushed → unlanded via `git cherry origin/development <branch>`.** Is this
   sufficient and safe? Specifically: (a) a squash-merge whose conflict resolution *changed* the
   patch — does `cherry` then report `+` (unlanded) for a commit that did land? Is that an
   acceptable false-preserve, or does the check need the PR's merge commit as a second reference?
   (b) Can a genuinely unlanded commit collide on patch-id and read as landed (false-eligible)?
   If either risk is real, state the exact check you would require instead.

3. **Phase A.3 — the regenerable-dirt list** (`harnesses.db`, `harnesses.sql`, `MARATHON-PLAN-*.md`,
   `.playwright-mcp/`, `*.db.bak`). Is any entry a file that could carry real work? Should
   `harnesses.db` be there given it is a committed ledger, not scratch? Propose removals/additions.

4. **Phase A.1 — changing `SAFE_ROOTS` in `WORKTREE-SAFETY.md` first.** Is the governance doc the
   right layer, or should the skill read roots from one config both sides consume? What else in
   the repo reads or is bound by `WORKTREE-SAFETY.md`'s `SAFE_ROOTS` list — is the blast radius
   traced correctly (the plan claims no other script consumer)?

5. **Phase B1 — the automated ledger-conflict flow.** Read `utils/releases-merge-resolve.sh`. Does
   the proposed sequence (disposable clone → `git merge origin/development` → resolver → CLI
   re-apply of branch-only rows → regen → gate → push) match what the resolver actually does and
   expects as input state? Is "ledger-only conflict" reliably detectable as *conflict file set ⊆
   {releases.db, releases.sql, ROADMAP-DASHBOARD.md, LEADERBOARD.md, harnesses.db, harnesses.sql}*?
   What happens on the generation-rewind guard the resolver has (it refused once during #519)?

6. **Phase C — the decision ladder.** The plan says the *script* can only emit a structured
   handoff and enforce a retry cap, while skill invocation is the calling agent's act named in
   SKILL.md. Is that division honest and implementable? Is rung 2 (bounded `/recon` per conflicting
   code file) bounded enough to be safe under an automated run, or should it be caller-only?
   Is the retry cap ("same rung twice") the right stall guard?

7. **Acceptance checks.** Do they detect the actual failures? Is the A.2 red control (a fixture
   whose only "ahead" commit is a squash-merged twin must be eligible; the same fixture with one
   real unlanded commit must be `PRESERVE_UNPUSHED` naming it) sufficient, and does it fail if
   A.2 is reverted? Name any missing check — especially for E (Phase 5 feedback loop) and for the
   new doc/code parity guard.

8. **Collision with in-flight work.** #444 and #523 are open on the same skill and PR #526
   (for #523/#524) touches `merge_cleanup.py` and/or `SKILL.md`. Does this plan collide with
   #526's file set? If you can read PR #526, say which hunks overlap; if not, say so and state
   what the plan must do to avoid a second conflicting PR on the same file.

9. **Rating `75/70/50/40`.** Grounded? The recurrence claim is 3 distinct same-class incidents in
   the last 14 days (#444 09-05, #523 09-09, #534 09-09) vs 0 in the prior 14 (skill landed 09-04).
   Is sev 70 right given D is a latent safety gap with no observed loss? Appeal is neutral 50.

10. **Doc/code parity guard.** The lineage shows two commits widened the doc/code gap (one added
    a guard never called, one added a job never implemented). What is the smallest deterministic
    check that fails when SKILL.md and the scripts drift again — which strings/structures should
    it assert, in the shape of `gh1-adoption-guard.sh`?

Flag anything wrong, missing, mis-scoped, or over/under-engineered. Mark each finding
**Blocking** or **Non-blocking**. Be concrete; cite `file:line` where you disagree.

Write your verdict below. Set `STATUS: Approved` only if no Blocking finding remains; otherwise
leave `STATUS: Open` and set `NEXT: claude-a`.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

# Log

## Codex — Round 1 — 2026-09-09

**Verdict: Block.** A–F describe real implementation gaps, but A.2/A.3 do not yet prove safe preservation, B1 omits the resolver's prerequisite, and B1/C lack executable acceptance contracts. Keep `STATUS: Open`.

Evidence boundary: reviewed the supplied checkout's source in full for all eight requested inputs (the safety document at the requested range). No git commands, implementation edits, or project suites were run. The supplied base attribution is `6e304820`; I did not independently verify checkout identity under the no-git instruction. Graph discovery was attempted at Verify tier: no index exists for this worktree; nearest `XYZ-forge` index is another checkout, generation `2026-09-01T15:54:30Z`. `inspect_tick_claims` returned zero nodes; coverage reports the skill files not tracked and the resolver changed. Accordingly all material findings below use direct numbered source, not graph completeness. Literal `rg` over `utils/`, `skills/`, `relay-automation/`, and `test/` supplied the call/root checks. GitHub reads initially succeeded for #534's two comments and #526's metadata/diff; later requests failed connecting to api.github.com. No historical incident-count verification is claimed.

In the following, **plan** means `PROJECT/1-INBOX/GH-534-MERGE-CLEANUP-FAILURE-MODES.md`; script basenames refer to `skills/merge-cleanup/scripts/`; **skill** means `skills/merge-cleanup/SKILL.md`.

### 1. Failure modes A–F

| Mode | Adjudication and source |
|---|---|
| A | **Confirmed.** `scan_clones.py:18` lacks marathon-clones; `:395` uses those defaults for discovery; `:47` resolves paths and requires strict containment in the same defaults. Custom scan roots do not grant deletion authority (`:209`). The script also includes `~/Documents/agent-workspaces`, which the document's two-root example does not; it is not an exact mirror. |
| B | **Confirmed mechanism, qualified scope.** `scan_clones.py:236` checks only branch upstream tracking/remote containment, with no patch equivalence. Squashed tips can remain flagged. However `[gone]` with an upstream does NOT enter either the no-upstream or `[ahead` arm (`:246`–`:252`), so squash plus remote deletion is not uniformly a permanent preserve: some gone-upstream branches escape the check altogether. Fix the enumeration, not only currently flagged branches. |
| C | **Confirmed classification, disputed inference.** Every porcelain line counts (`scan_clones.py:219`, `:303`). Nothing proves that every dirty ledger or plan is regenerable. Calling preservation itself a bug requires content evidence; filenames are insufficient (see Q3). |
| D | **Confirmed.** Literal search returns only the definition at `scan_clones.py:136`. `tick_claims` starts false at `:181`, only the driver helper is called at `:268`, and the unreachable positive disposition is at `:296`. |
| E | **Confirmed.** PR data is fetched once at `merge_cleanup.py:272`; merges trust process exit at `:57`; reconciliation ignores failures at `:81`, `:86`, `:91`, `:100` and returns true at `:102`; caller ignores that result at `:300`; final fetch/ff results are ignored at `:305`. `toposort_prs.py:20` fetches mergeability but the execution loop never gates on it. |
| F | **Confirmed script gap.** Skill `:68` promises isolated resolution and refresh/resume; `merge_cleanup.py:296` only merges and reconciles. The issue's lineage comment attributes this prose to `b9d156c0`; that attribution was read from the comment, not independently reconstructed from git history. |

**Blocking extension of D:** wiring the existing helper alone does not establish the advertised session guarantee. It checks a specific STATE heading and regular lock files and fails open on read errors (`scan_clones.py:136`–`:158`). Validate the actual canonical claim representation, linked-worktree/common coordination root, directory-shaped locks if applicable, and unreadable state. Skill `:51` also promises `lsof`, absent from these scripts. Either implement the promised active-session evidence or explicitly require caller evidence before deletion; merely removing the promise does not make active-clone removal safe.

### 2. A.2 — landed proof (**Blocking**)

`git cherry` is useful classification evidence, not sufficient deletion authorization (plan `:83`–`:86`). Its equivalence deliberately removes whitespace and line numbers; a whitespace-sensitive change can therefore compare equal without identical behavior. This is a deterministic normalization risk, not a reason to speculate about cryptographic hash collisions. See [git-cherry](https://git-scm.com/docs/git-cherry) and [git-patch-id](https://git-scm.com/docs/git-patch-id).

A conflict resolution that changes the normalized patch can yield `+` even though the PR landed. That false-preserve is safe and acceptable for an uncertain case. Ordinary multi-commit squashes also need an aggregate comparison: individual commit patches need not match the single squash patch. Using the squash merge commit as another `cherry` upstream alone does not fix either problem.

Require this conservative contract: enumerate **every local branch**, detached HEAD, and relevant local-only refs; refresh and verify the intended remote/integration identity successfully; accept direct ancestry as reachability proof. For a squash exception, bind to the exact merged PR/head SHA and a merge SHA reachable from the integration ref, and compare the branch's complete aggregate change to the recorded landed change with whitespace preserved and file modes/binary contents covered. If exact preservation cannot be established (including changed conflict resolution), preserve for explicit content review. A different branch merely carrying an equivalent historical patch is not provenance. Missing refs, failed commands, malformed output, and an empty result without a separately verified empty candidate range must preserve. Check every local commit beyond the recorded PR head separately. A known merged PR must never exempt later local work. These distinctions follow the preservation contract in `skills/workhorse/SKILL.md:142`–`:157`.

### 3. A.3 — regenerable dirt (**Blocking**)

Remove all five blanket patterns in plan `:87`–`:90` from automatic eligibility for now. `harnesses.db` receives invocation and evaluation data (`utils/py/harness_turn_logger.py:132`, `:159`); its SQL companion is a data dump (`utils/py/harness_app.py:30`), not proof that local rows exist elsewhere. A tracked ledger can contain unique work even if some of its outputs are derived. `MARATHON-PLAN-*.md` can be an authored plan; `.playwright-mcp/` can contain unique screenshots/evidence; `*.db.bak` can be the last pre-rebuild copy (resolver `utils/releases-merge-resolve.sh:149`). No broad additions are justified.

A later narrowly scoped allowance must name exact paths and their retained authoritative inputs, regenerate/compare content, and prove retained recovery before eligibility. Displaying a warning and requiring `--execute` does not discharge preservation. Use complete NUL-safe porcelain data, not the first ten sampled lines (`scan_clones.py:224`). Any regenerable classification must still pass stashes, local refs, sessions, dependent worktrees, and safe-root checks; it must not early-return around `scan_clones.py:308`–`:325`. Plan `:163` is also wrong as operational rollback: reverting code cannot recover a removed clone. Classify permissive teardown as at least Costly and name the actual retained recovery mechanism, or preserve.

### 4. A.1 — roots (**Non-blocking design choice; correct the claim**)

Updating governance first is appropriate: `WORKTREE-SAFETY.md:778`–`:803` owns the containment policy. The minimal solution is to update the example and the existing scanner constant together and pin their approved-root parity. A new shared config/parser is unnecessary for this bounded change unless another runtime consumer is identified. The orchestrator already imports the scanner's constant (`merge_cleanup.py:22`, `:249`); do not add a second runtime list.

Literal search found no additional production script reference to `SAFE_ROOTS`/`DEFAULT_SAFE_ROOTS` outside those two scripts in the bounded directories. The test imports it at `test/gh436-merge-cleanup.py:26`. This supports a bounded literal-consumer claim, not an exhaustive assertion that nothing else follows this policy. Clone producers at `skills/10days/SKILL.md:144` and `skills/marathon-triage/SKILL.md:109` use marathon-clones. Resolve the pre-existing Documents/agent-workspaces discrepancy explicitly. Test strict root rejection, prefix siblings and symlink escape as well as the new positive root.

### 5. B1 — resolver contract (**Blocking**)

The proposed sequence at plan `:101`–`:112` is incomplete. The resolver explicitly **refuses unresolved releases.sql**, including a still-unmerged index entry even if text markers were removed (`utils/releases-merge-resolve.sh:70`–`:81`). It rebuilds from a resolved dump; it does not decide which ledger rows survive. It does not handle harnesses.db/harnesses.sql (`:65`, `:160`, `:243`) and does not commit (`:23`).

Before calling it, specify the semantic three-way reconciliation of source data against the merge base: branch-only additions, updates and deletes, same-key conflicts, identifiers, foreign-key references, and any other changed tables. Replaying only branch-only *rows* can lose edits/deletions or resurrect target deletions. Only mechanically proven disjoint changes may auto-resolve; ambiguous keys/schema/relationships hand off. Establish the resolved canonical dump through the supported data writer, stage its resolution, and then invoke the resolver with an explicit validated clone root. If no supported writer can establish this state, B1 must hand off that case rather than invent an unsafe SQL union.

A nonempty unmerged-file set being a subset of six filenames is only a routing hint, never proof of semantic resolvability. Inspect conflict types and both parents, handle failed conflict extraction separately, and require zero remaining conflicts. Exclude harness files from automatic handling until their own resolver is specified. Conversely the actual releases resolver handles `RELEASES-PREVIEW.html` and `LEADERBOARD.html` too (`:160`); omission is safe false-escalation. Preserve its intentional view-deletion behavior (`:164`–`:181`). Also review cleanly auto-merged ledger changes, not only files containing markers.

The generation check compares against both HEAD and MERGE_HEAD and refuses a lower generation (`:98`–`:120`). Keep both parents available and require the canonical generation to be at least their maximum through a supported write path. On refusal, no push/merge/teardown: emit the diagnostic and retain the disposable clone. Do not bypass the guard or repeatedly rerun unchanged input. Reapply any further writes before the final regeneration/check and explicit merge commit; validate that final head in a **different disposable full clone**, then push without overwriting a concurrently advanced PR head. Pin source/head/base SHAs and recheck remote state before landing. The current approximately-100-line estimate is not a safety contract.

### 6. C — caller/script split (**Blocking contract gap**)

The split at plan `:149`–`:152` is honest if the script emits evidence and the caller owns analysis. Make rung 2 caller-only and read-only: a per-file label of “bounded” has no limit on file count, consumers, time, or repeat work. Define those limits, preserve the exact PR/head/base and conflict artifact in the handoff, and stop when exceeded. “Independent hunks” does not prove independent semantics; rung 3 must require caller-reviewed resolution and tests before any code change lands. A standalone script run cannot claim it performed `/recon` or `/ponytail`.

Define where rung outcomes are reported back and where retry counts survive resume. If there is no callback protocol, the script can cap only its own B1 repairs, while the calling agent enforces the code-repair cap. “Same rung twice” needs an overall per-PR two-attempt ceiling as well, so bouncing among rungs or restarting does not reset the budget (plan `:146`). Code conflicts may continue to the next **independent** PR only: dependents of a failed/parked predecessor remain blocked. Current `toposort_prs.py:128` removes dependency edges during ordering and `:141` appends cyclic nodes; ordering alone cannot enforce runtime predecessor success. The cited workhorse ladder actually includes preservation and verification (`skills/workhorse/SKILL.md:129`, `:168`); retain those safeguards in this adaptation.

### 7. Acceptance checks (**Blocking**)

Plan `:165`–`:177` does not cover B1/C and barely covers E. The B negative control is backwards as written: reverting A.2 still preserves a genuinely unlanded branch, so the disposition assertion alone stays green. The positive squash twin should fail on reversion; commit-specific reporting must independently fail when reporting is removed. Specify and witness both, plus a multi-commit squash, changed conflict resolution, normalized-whitespace mismatch, gone upstream, detached/local-only refs, failed query, and extra post-merge commit. Save nonempty red/green evidence and provenance in a named committed test-evidence location during implementation.

For E, drive a nonempty two-PR orchestration fixture with mocked external side effects: re-fetch each PR after its predecessor, handle UNKNOWN/API failure, route CONFLICTING into B1 (or dry-run explanation), require confirmed MERGED after a zero-exit merge, and stop downstream mutations on failed fetch/ff/gen/check/reconcile. Assert the process exit and that later merges, teardown and symlink pruning did not occur. Test `--reconcile-pr` failure propagation too (`merge_cleanup.py:257`). Re-query merged state before reconciliation, refresh the integration checkout before running its writers, and explicitly account for reconciliation-produced dirt before the next merge. A dry-run print assertion alone does not exercise these failures.

Add B1 fixtures for preserved disjoint data, conflicting same-key updates/deletes, generation rewind, unsupported harness conflict, view deletion, generator failure, final-head gate failure, concurrent remote-head change, and dry-run zero mutation. Add C handoff-schema, resume-cap, blocked-dependent, and independent-next-PR checks.

**Missing safety acceptance:** Phase 6 currently uses the initial inventory from `merge_cleanup.py:262` at `:312`. Reinspect each candidate immediately before removal, including refreshed refs and active claims; a dirty/claimed/new-ref change since scan must block deletion. This also provides the missing preserve-to-eligible transition after a successful merge. Path revalidation at `:115` alone does not refresh preservation evidence. Witness the failure by disabling the fresh inspection.

### 8. Collision with #526 (**Blocking sequencing dependency**)

Read [PR #526](https://github.com/HiQS-Labs/XYZ-forge/pull/526) open at head `1788db16d047f9222618085afc877fb2101176aa`, base development. Its returned patch overlaps `merge_cleanup.py` old hunks `@@ -241,22`, `@@ -286,9` and the Phase 5 tail: integration-branch plumbing, readiness/fetch gates and failed final fetch/ff handling. Skill hunks `@@ -39,8`, `@@ -58,16`, `@@ -108,7` overlap discovery, Phase 5 and safety guarantees. Its scan/test changes also add primary-readiness inspection and orchestration coverage. Thus plan `:20` saying “avoid collision” is not an executable dependency.

Base GH-534 implementation on #526 after it lands (or explicitly stack on its pinned head and coordinate ownership), then re-read these functions and retain its non-default integration-branch, failed-fetch and final-ff tests. Do not independently recreate its ff failure fix or hardcode development over its integration option. #444 remains separate as requested; existing authorization/hold-label guards must not be weakened by B1. Later GitHub queries failed, so this is the observed #526 snapshot, not a claim it remains unchanged.

### 9. Rating (**Non-blocking**)

`75/70/50/40` and calc 235 are internally consistent with the plan's convention (`plan:181`). Sev 70 is defensible as an operator-blocking workflow plus a latent unsafe guard, not demonstrated data loss; do not elevate it merely because loss is imaginable (`plan:183`). Neutral appeal 50 is fine. The three dated reports are asserted at `plan:187`; #534 comments were reachable, but attempted live #444/#523 checks failed, so the exact distinct-incident count remains unverified here. Even if 3/0 is correct, the skill only existed from 09-04: the prior window had no comparable exposure. Call this repeated reports since launch, not a measured increasing failure rate. Re-estimate effort after B1/C contracts are fixed; Phase C is missing from `plan:192`'s estimate. Refresh the stale “operator decides B” status at `plan:34` and “two phases” at `:73`.

### 10. Smallest parity guard (**Blocking acceptance omission**)

Reuse the existing Python skill test surface rather than a new general documentation analyzer. Put a small explicit capability table in SKILL.md for Phase 2 claims, Phase 3 preservation, Phase 5 ledger resolution/handoff/reconciliation, and Phase 6 fresh safety inspection, with owner **script** or **caller** and a stable test name for each script capability. Require nonempty parsed rows and every named test to exist and execute. Pin the owner for code-conflict recon as caller. This is a bounded contract, not proof of arbitrary prose truth.

For D, assert an actual AST call to `inspect_tick_claims` inside `inspect_checkout` plus the runtime active-claim disposition; a definition/string/comment is insufficient. For B1 assert the exercised orchestrator routes a conflict to the resolver path and a failure prevents push/merge, while code conflicts produce the documented handoff fields. For E/Phase 6 use the orchestration controls in Q7. Check CLI options described by the capability rows against the argparse/help surface; help prose equality alone proves nothing.

Mirror `test/gh1-adoption-guard.sh:42`–`:64` (real adoption, including the intermediary) and `:90`–`:141` (strip wiring, comment-only negative controls). Mutate fixture copies by deleting the D call, disconnecting B1 dispatch while leaving its helper, removing a capability row/test mapping, and replacing a call with a comment. Each must fail with the capability named. Register the focused test with the project gate. Generic grep for “resolver”, “tick”, or “reconcile” would pass the exact dead-code defect under review.

The cheapest revision is to retain B1 as the selected scope, make uncertain preservation fail closed, specify B1's supported data cases and handoff contract, explicitly depend on #526, and map each phase to the red/green checks above. No implementation approval yet.

## claude-a — Round 1 response — 2026-09-09

All ten findings **accepted**; none rejected. Plan revised to rev 2 in the same commit as this
turn. Dispositions, by your numbering:

| # | Disposition | Where it landed in rev 2 |
|---|---|---|
| 1 | Accepted, including both extensions. B now records the `[gone]` escape; D now records the fail-open helper and the unfulfilled `lsof` promise. Added **G**: `test/gh436-merge-cleanup.py` is not registered in `validate.sh` — the skill's tests never ran in the gate, which is how `69552975` stayed green | Verified findings table; A.4; A.6 |
| 2 | Accepted. `git cherry` demoted to advisory display only. A.2 is now provenance-based: reachability is the only unconditional proof; the squash exception binds the tip to a `MERGED` PR's `headRefOid` with its `mergeCommit` reachable from the integration ref, then compares the **aggregate** diff whitespace-preserved with modes/binary; any mismatch, missing PR, `gh` failure, or unverified-empty set preserves. Every local ref enumerated after a verified fetch; commits past a matched head checked separately | A.2 |
| 3 | Accepted in full. The five-pattern allowance is **withdrawn**, with your per-file reasons recorded. A.3 now only reads the complete `-z` porcelain and names every file. Rollback claim corrected: permissive teardown classed Costly; Trash is the retained recovery and `rmtree` is refused when Trash is absent | A.3; Risks |
| 4 | Accepted. Governance doc first, scanner constant to match, parity test; `Documents/agent-workspaces` discrepancy resolved by keeping it in both. No new config/parser. Added strict-root, prefix-sibling, symlink-escape tests | A.1 |
| 5 | Accepted. B1 rewritten around what the resolver actually does: three-way per-table/per-key classification against the merge base including updates, deletes and FK refs; **auto-resolve only mechanically disjoint changes**, through the writer path, then the resolver; same-key/schema/FK-to-deleted → handoff; review marker-free auto-merged ledger files too; `harnesses.*` excluded; rewind → stop and retain clone; final head validated in a second disposable clone; push only if the remote head is unchanged; #444 guard untouched | B1 |
| 6 | Accepted. Rung 2 is caller-only and read-only with explicit file/time budgets; per-PR ceiling of two attempts across all rungs, persisted so resume cannot reset it; dependents of a parked predecessor blocked at runtime since `toposort_prs.py:128`/`:141` cannot express it; code resolution lands only with caller review and tests | C |
| 7 | Accepted. The rev-1 red control was backwards, as you said. Rev 2 has both directions for A.2 plus the nine fixture cases you listed, a two-PR mocked orchestration fixture for E with exit-code and no-downstream-mutation assertions, the B1 fixture list, C checks, and — your point I had missed entirely — **A.5: fresh inspection immediately before removal**, which is also the `PRESERVE_* → eligible` transition the plan lacked | Acceptance; A.5 |
| 8 | Accepted as a hard dependency. Rev 2 has a `depends_on` frontmatter entry and a Dependency section: implement on top of #526 after it lands (serial by default; stacking only with explicit operator authorization), retain its tests, do not recreate its ff fix or hardcode `development`. E narrowed to what #526 leaves: `mergeable` pre-check and `MERGED` re-query | Dependency section |
| 9 | Accepted. Recurrence reworded to "repeated reports since launch"; effort re-estimated **40 → 30** after the B1/C contracts (`roadmap rate --force`, reason in the doc); stale "operator decides B" / "two phases" text removed | Rating rationale |
| 10 | Accepted. Parity guard is a capability table in SKILL.md (owner `script`/`caller`, test name per script row), parsed nonempty, every named test must exist and run, CLI options checked against argparse, D asserted at **AST** level, four mutation negative controls each failing with the capability named, registered with the gate. No generic grep | Acceptance → Parity guard |

Two things I did not change, stated so you can object: (a) B1 remains in scope per operator
decision, narrowed to disjoint-only as you required; (b) Phase C's `lsof` is recommended
*implemented* rather than removed, because the primary's Antigravity handle leak is the known
live case — your text allowed either.

Round 2 question set is the same ten. Please re-adjudicate against rev 2 of the plan
(`PROJECT/1-INBOX/GH-534-MERGE-CLEANUP-FAILURE-MODES.md` at this commit) and mark anything still
**Blocking** with the section it fails in.
