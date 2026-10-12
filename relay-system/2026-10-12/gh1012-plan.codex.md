# RELAY · GH1012 stable promotion plan QA (conditional prerequisites)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-12.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1012-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **GH-1012-STABLE-PROMOTION.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-12

### Artifact — GH-1012-STABLE-PROMOTION.md
```
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
5. Freeze final base `B` and development candidate `D` after all pre-promotion evidence/QA
   publications and reconciliation. Refresh full-range assessment if either changed. Open a
   promotion PR from the approved development head into main. Record base/head, evidence,
   nonblocking findings and fix-forward strategy. -> Acceptance: base intentionally main,
   reviewed head matches published head, required PR checks current and review approved.
6. Demonstrate recovery in a disposable full clone before landing: synthesize the intended
   two-parent promotion merge, revert with mainline 1, compare restored full tree/modes to
   last-good main `B`, and retain successful recovery and a deliberately wrong-mainline red
   control with provenance. Then complete the authorized promotion through the PR using
   `--merge --match-head-commit D`, retain the development branch, recheck unchanged `B` and
   branch protections immediately before submission, and verify the resulting main SHA `M`. Then
   watch the exact resulting main SHA's hosted macOS boundary. -> Acceptance: full sequential
   boundary SUCCESS and `MACOS-BOUNDARY: green <SHA>`; required checks green, Ubuntu drift disclosed.
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
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.


## Review envelope

Plan QA only. Read the capture plan and current AGENTS/ROUTER/CI rules. The operator scope
decision remains pending, so held drafts stay prerequisites; this plan must not claim final
review, stable qualification, a capped-group review reset, new tests or held draft merge authority.
No test, fixture, gate or remote command may run in this review worktree. Read-only source
inspection and non-mutating queries are allowed. Answer these concrete questions:

1. Does the sequence preserve readiness/ledger/QA checks while keeping push gates in independent
   disposable full clones and fast-forwarding the valued primary?
2. Are provisional/tested/final-development/resulting-main/evidence-carrier SHAs distinguished,
   with stale-head invalidation and immutable stable designation?
3. Does ordinary ancestry-preserving promotion keep branch protections and development intact,
   with exact-head binding, fresh base checks and a witnessed recovery/red-control prerequisite?
4. Are final whole-range review and independent QA still mandatory and unclaimed?
5. Flag concrete plan gaps with citations. Do not demand a new driver, suite or gate.

Assess only this conditional operational plan, not the unread complete release range. End with
an explicit Approved or Changes Requested verdict and update STATUS truthfully. The independent
consult informed this plan but is not its approval or firsthand qualification.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
