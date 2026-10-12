---
title: "GH-1012: regression verification and stable promotion"
status: Queued
created: 2026-10-12
updated: 2026-10-12
owner: Codex via workhorse
gh_issue: 1012
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1012
doc_type: plan
goal: >
  Complete the agreed integration scope, verify its promotion range with existing regression
  checks and final review-code, prepare a PR into main, and bind a stable designation to the
  exact-main hosted macOS boundary evidence.
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1030
  - https://github.com/HiQS-Labs/XYZ-forge/issues/947
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1022
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1031
---

# GH-1012 — regression verification and stable promotion

## Status

| What was just completed | What's next |
|---|---|
| Operator authorized workhorse execution. Fresh read confirms PR1017 merged; PR954 and PR1024 are drafts. A peer is refreshing PR1019 through a normal full push gate. Disposable task clone provisioned; no product code changed. | Verify the peer's PR1019 refresh/landing. Await the operator's scope decision for the two held drafts, then pin the release candidate; no final qualification or stable claim yet. |

## Current facts and scope

The issue is the live signal stream; historical batch receipts remain there. Current integration
base is `d09b8f9dedd436be3e5f883f68deff985719fe1b`; main is
`a076b1b117a68252dc3d9d1c4901b0c31fcb4db3`. At intake main is an ancestor of development;
there are 333 development-only commits and 2,041 changed paths. These counts are a baseline,
not the frozen candidate. The final review must cover the whole promotion range, not just this batch.

Current scope includes PR954, PR1019 and PR1024; PR930 remains held. No later PR is implicitly added.
PR1019 is also tracked by the active peer's merge record #1030; use its published result rather
than competing with its current repair. PR954 lacks a published Claude advisory route and an
explicitly authorized real advisory pilot. PR1024 remains FAIL/Escalated4/4 with Medium1031 and
unfinished W8–W11; no capped review reset, live dispatch or new test approval is inferred.
An operator scope decision is pending: keep both drafts as prerequisites or defer them from this
stable candidate. A missing answer keeps the current prerequisites.

## Existing procedure and evidence owners

This is an operational promotion plan with no runtime redesign. The repository's existing
merge-cleanup coordinator, RELEASES writer, hosted reconciliation, regression registry,
review-code and relay QA remain the owners. Recon for runtime implementation is deferred until
an actual defect demands a code change; review recon covers the pinned promotion range.

- `ROUTER.md` command rails require disposable full-clone gates and the full registry for promotion.
- `.github/workflows/ci.yml:151-152,196-214` runs the macOS boundary on a push to main,
  explicitly sequential, with a SHA-bound verdict. Skipped PR jobs do not qualify promotion.
- `ci-local.sh` supplies the full local qualifying record; it expressly does not replace hosted
  promotion evidence. Run only in a separate disposable full clone with identity brackets.
- `AGENTS.md` requires an independent peer/Codex QA receipt before promotion; self-review and
  passing tests alone cannot satisfy it.
- `PROJECT/3-COMPLETED/GH-822-PROMOTION.md` is historical precedent. Its branch-protection
  toggle/direct push is not this plan: use the requested ordinary promotion PR and retain protections.
- The current cleanup coordinator unconditionally pushes primary at
  `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:648`, even when nothing changed.
  Its possible full pre-push gate conflicts with valued-clone isolation. Do not run that path
  until safe publication containment is established; retain the existing #1012/PARKED incident.

## Ordered execution and acceptance

1. Complete ready in-scope landings using the existing peer handoff and merge-cleanup readiness,
   dependency, exact-head QA and disposable-clone ledger simulation checks. Use the ordinary
   GitHub PR merge with `--merge --match-head-commit <head>`; verify MERGED before proceeding.
   Wait for hosted reconciliation using the existing reconcile-only path, then fast-forward
   primary from verified origin. Publish any required caller-owned governance writes through
   a normal hooked push from a separate disposable full clone, never from primary; if there
   are no writes, there is no push. Preserve the coordinator attempt records and emitter
   semantics; emit only a merge this caller witnessed. Do not invoke its unconditional primary
   push path, substitute another primary, bypass hooks or add an alternate driver. Preserve original commit ancestry for PR1019's opt-in policy using merge strategy.
   Verify exact published head, independent QA, gates, merge commit and reconciliation receipts.
   Keep drafts held until their actual requirements pass or the operator explicitly defers them.
   -> Acceptance: all agreed prerequisites merged/reconciled, primary clean/equal origin.
2. Record provisional main base and reconciled development head, enumerate the complete range and map changed
   contracts/cross-PR seams. Obtain independent plan QA and the required workhorse consult on
   promotion/preservation before consequential execution. -> Acceptance: grounded scope and
   agreed stop/rollback conditions; refresh if either remote moves.
3. Run `ci-local.sh --base <main-base>` plus the existing relevant behavior checks in a fresh
   disposable macOS full clone. Inspect non-empty outputs and unchanged Git identity.
   Use existing mutation coverage or recorded manual red controls for material seams; no new
   suites, cases, registry entries or gate machinery. -> Acceptance: full green result and
   committed `TESTS-RESULTS/<date>+GH-1012/provenance.jsonl`, honest retry/unknown disclosures.
4. Perform final review-code and independent relay QA on the exact promotion range. Fix blockers
   through existing task/repair rails and rerun affected checks/QA after candidate changes.
   -> Acceptance: no unresolved promotion blockers, graded review posted to #1012 and rendered
   in chat, independent `relay-system/` receipt bound to the candidate.
5. Rehearse recovery before the final evidence freeze in a disposable full clone: synthesize
   the intended two-parent promotion merge from last-good main `B` and provisional candidate,
   revert with mainline 1, compare restored full tree/modes to `B`, and retain a deliberately
   wrong-mainline red control. Commit/publish the rehearsal's non-empty provenance through
   the existing evidence PR path before claiming it as proof. Record tested and carrier SHAs.
   -> Acceptance: rehearsal/negative control provenance is committed and inspectable before
   main submission. If evidence publication changes development, refresh the range/checks/QA
   and re-bind recovery to final `B`/`D`: account explicitly for an evidence-only delta by
   blob/mode inspection and isolated revert/tree comparison on final `D`; retain any final
   receipt on a separately identified evidence-carrier PR without advancing frozen `D`.
6. Freeze final `B` and development `D` after all pre-promotion evidence/QA landings/reconcile.
   Open the requested promotion PR into main with exact tested/carrier/base/head evidence.
   Recheck unchanged `B`, published `D` and protections immediately before submission; use
   `--merge --match-head-commit D` and retain development. Verify resulting main `M`, then
   watch its hosted macOS boundary. -> Acceptance: recovery proof is already durable, final
   range reviewed/qualified, required PR checks green and full sequential main boundary
   SUCCESS with `MACOS-BOUNDARY: green M`. A changed head/base invalidates submission.
7. Record `Stable qualified` in #1012 as the selected evidence-linked designation, bound to
   immutable `M`, the boundary run/job and independent QA receipts. Do not invent a release
   version/tag or transfer qualification to later metadata commits. Update #1012/PRS/PDDA through
   canonical writers and retire only verified complete owned clones with backup/Trash proof.
   -> Acceptance: outcome audit covers every required item; no stable claim on a red or stale SHA.

## Preservation and rollback

Intake edits are Easy, confined to this owned task branch. Remote development landings are
recoverable through explicit revert commits with reviewed/gated evidence. Main promotion is
Costly: existing main remains reachable, but consumers can pull the candidate. Revert/fix forward
through an ordinary reviewed PR; never reset/force-push main or weaken branch protection.
This Codex session owns the recovery decision: a red boundary prevents the stable designation
and triggers diagnosis/fix-forward or the rehearsed revert via a reviewed PR; an absent/queued
boundary stays unqualified until observed or its bounded wait expires. A red promotion boundary
prevents the stable designation and release publication. No release
version, tag or package publication is selected by this plan. Refresh exact-head evidence before
any merge; an active peer, changed PR head or unknown remote outcome prevents replay.

## Unknowns and blockers

- Operator decision for held PR954/PR1024 is pending; prerequisite defaults remain in force.
- PR1019's active refresh has not yet published; no concurrent branch write is permitted.
- Current main branch protections/required checks need fresh review before promotion.
- Full promotion-range recon, behavior probes, local qualification and final review are pending;
  historical 409/409 checks are not evidence for the current candidate.
- Stable representation is the evidence-linked `Stable qualified` designation on #1012 for
  exact `M`; GitHub labels, versions and releases are not substituted for qualification.

## PRS assessment

Rated 85/55/65/50, no override: operator-requested promotion is high priority; regression exposure
matters to adopters; a stable pin has clear value; full-range review and platform qualification
have material effort. The queued capture is not accepted-start or completion evidence.

## Workhorse consult disposition

Both Codex and Agy answered the 2026-10-12 operational preflight. Both identify the primary
unconditional push as blocking and recommend the existing disposable publication + ordinary
GitHub PR/hosted reconciliation path. Codex also flags evidence-ordering drift, atomic head
binding, untested recovery and undefined stable representation; the execution sequence above
now addresses those before main landing. Agy did not discuss those additional gaps; silence
is not disagreement or proof. Neither advisor approves held drafts or the final promotion range.
The harness stamped Codex's response `NO FIRSTHAND VERIFICATION CITED`; this is advisory
plan input, not runnable qualification. Original transcripts and prompt remain retained locally;
a condensed disposition is committed separately. No new gate, test or runtime helper is added.
