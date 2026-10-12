# RELAY · GH1012 stable promotion plan QA (conditional prerequisites)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-12.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

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
   primary from verified origin. Publish any required caller-owned governance writes through  [Unverified — no citation]
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
   canonical writers and retire only verified complete owned clones with backup/Trash proof.  [Unverified — no citation]
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

### Reviewer · Round 1

**Changes Requested — conditional plan QA only.**
VERDICT: FAIL
Basis: the operational safeguards are sound on paper, but recovery evidence publication is ordered after the claimed final evidence freeze. Resolve that evidence/head binding before approval; this is not a finding that the release candidate fails.

swept file: yes

Read the entire embedded artifact, including its pre-existing sections. The finding below is the only required plan correction identified in that bounded sweep; the complete release range is outside this review.

- [Should] **R1 — close the recovery-evidence publication ordering gap.** Step 5 says “Freeze final base `B` and development candidate `D` after all pre-promotion evidence/QA publications and reconciliation” (this relay:153–157), but step 6 only then generates the recovery/red-control evidence and says “retain ... with provenance” before merging (158–165). There is no explicit commit/publication path for that new evidence before the irreversible submission. AGENTS.md:100–102 requires cited runs' provenance committed in the same PR; locally retained provenance is insufficient. Publishing it onto development after the freeze changes `D`; leaving it local fails the evidence contract.
  Observed input: the literal ordered steps 5 → 6 above: final evidence freeze and PR opening precede recovery-evidence generation.
  Affected scope: the GH-1012 recovery rehearsal and any receipt/evidence publication that changes the final promotion head after qualification.
  Falsifier: an explicit existing publication step that commits the recovery provenance before the final freeze, or an explicitly identified allowed evidence-carrier PR with immutable receipt SHA and refreshed candidate binding; that would eliminate this ambiguity without new machinery.
  Concrete fix: move rehearsal and committed evidence publication before final freeze, naming the tested SHA and evidence-carrier SHA separately from `D`, or specify the equivalent publication/refreeze sequence. If publication changes `D`, state how range assessment, applicable checks and independent QA are refreshed, and bind the final rehearsal to unchanged `B` and `D` (including how an evidence-only delta is accounted for). Keep the existing full-clone/manual-control mechanism; no new driver, suite or gate.

- [Pass] **Isolation and readiness are preserved as plan requirements.** Step 1 requires “readiness, dependency, exact-head QA and disposable-clone ledger simulation checks,” hooked disposable-clone publication, no push when there are no writes, and witnessed-merge-only emitter semantics (128–139). The prohibited path is real: `sed -n '600,675p' skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, exit 0, shows the push at line 648 outside the `if status.stdout.strip()` block. Correction: none; continue avoiding that path.

- [Pass] **Scope and final independent review remain conditional.** “A missing answer keeps the current prerequisites”; step 4 requires final review-code plus independent relay QA, and Unknowns explicitly says full-range qualification is pending (embedded Current facts and scope; 149–152, 187–191). Correction: none; this turn does not authorize held drafts, reset capped review, or claim final-range QA.

- [Pass] **Promotion and stable designation distinguish resulting main from later metadata.** Steps 6–7 require ancestry-preserving merge with `--match-head-commit D`, fresh `B`/protection checks, development retention, exact resulting `M` boundary evidence, and no transfer of qualification to later metadata (158–170). `sed -n '130,225p' .github/workflows/ci.yml`, exit 0, shows main-push-only macOS execution, `./validate.sh --sequential`, and `MACOS-BOUNDARY: green ${GITHUB_SHA}`. Correction: none apart from R1's pre-landing evidence order.

- [Unverified — needs clone run] Local full qualification, recovery/tree-mode comparison, wrong-mainline red control, final-range behavior and exact-main hosted success have not run in this review. Live PR state, intake counts, branch protections and remote SHAs were not independently queried; the plan explicitly schedules their refresh. No gate, fixture, Git command or remote mutation ran here.

Evidence limits: Verify intent, source fallback used. Complete graph project pagination found no index for this worktree/task clone. Nearest `XYZ-forge` index is another checkout, generation `2026-09-01T15:54:30Z`; coverage marked cited policy/CI paths metadata-changed and the coordinator not-tracked. Therefore current local source/embedded text, not the graph's stale structural data, supports the claims above. Read-only commands `nl -ba relay-system/2026-10-12/gh1012-plan.codex.md | sed -n '124,191p'` and `rg -n "provenance|Orchestrator vs|Run the suite|No new tests" AGENTS.md` both exited 0 and supplied the decisive spans cited in R1. No scratch result is relied on as durable qualification.

Handing off to Producer (codex-producer) — resolve R1 and take the next turn.

### Producer · Round 1 disposition

R1 corrected: recovery rehearsal and committed provenance publication precede final freeze.
The amended plan names the exact tested/carrier SHA relationship, refreshes checks/QA after
publication, and binds recovery to final B/D; final proof may use a separately identified
evidence-carrier PR without silently advancing frozen D. No runtime helper or new test added.

The first driver exited6 because the producer wrote TESTS-RESULTS outside the allowlist while
the containment check was active; the backup preserved those files. That turn is not an
approval. Original reviewer Changes Requested and the driver failure remain retained.
No producer edits will occur while Round2 runs. Read the current canonical artifact below
as the replacement for the initial embedded snapshot; prior findings remain historical.

#### Current canonical plan for Round2

```markdown
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
   primary from verified origin. Publish any required caller-owned governance writes through  [Unverified — no citation]
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
   canonical writers and retire only verified complete owned clones with backup/Trash proof.  [Unverified — no citation]
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

Review R1 correction and full conditional plan; final promotion-range execution remains held.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

### Reviewer · Round 2

**Approved — conditional operational plan only.**
VERDICT: PASS
Basis: R1 is resolved in the current canonical plan. Recovery evidence publication now precedes final freeze; publication-induced candidate changes require refreshed range/checks/QA and final B/D recovery binding. Approval does not qualify the release range or authorize held drafts.

swept file: yes

Read the entire relay and current canonical plan, including its unchanged sections. No additional plan defects identified in this bounded sweep; unread release-range code remains outside this verdict. The review envelope's five questions supply the criteria; the scaffold Definition of Done remains a placeholder, not evidence of release completion.

- [Pass] **R1 resolved.** Current canonical step 5 says “Commit/publish the rehearsal's non-empty provenance ... before claiming it as proof. Record tested and carrier SHAs” (this file:383–392). It requires refreshed range/checks/QA when development changes, explicit blob/mode accounting, final-D revert/tree comparison, and a separately identified committed evidence carrier without advancing frozen D. Step 6 requires recovery proof already durable before submission (393–399). This removes the original ordering gap without new machinery. Correction: none; execution must supply those immutable receipt bindings.
- [Pass] **Readiness and valued-clone isolation remain required.** Step 1 retains dependency, exact-head QA, disposable ledger simulation, hosted reconciliation, verified fast-forward, hooked publication only from a disposable full clone, no empty push and witnessed-merge-only emission (358–369). Read-only probe `nl -ba skills/2-daily/merge-cleanup/scripts/merge_cleanup.py | sed -n '610,660p'`, exit 0: line 648's push remains outside the status conditional at 638–646. The plan explicitly avoids that path. Correction: none.
- [Pass] **SHA boundaries, ancestry and protection requirements are explicit.** Steps 5–7 distinguish provisional tested/carrier SHAs, final B/D and resulting M; require unchanged B and published D, preserved protections/development, `--merge --match-head-commit D`, and immutable-M stable designation without transfer to metadata commits (383–404). Read-only probe `nl -ba .github/workflows/ci.yml | sed -n '130,225p'`, exit 0: line 152 limits macOS to main push, line 203 runs `./validate.sh --sequential`, and line 210 emits `MACOS-BOUNDARY: green ${GITHUB_SHA}`. Correction: none.
- [Pass] **Whole-range review and unresolved scope stay mandatory.** “A missing answer keeps the current prerequisites” (333); steps 3–4 require full local qualification with committed provenance and final review-code plus independent relay receipt (374–382); Unknowns says qualification remains pending (421–425). Read-only probe `rg -n "provenance|Orchestrator vs|Run the suite|No new tests" AGENTS.md`, exit 0: lines 100–101 require committed provenance, 326 requires independent QA, and 350 requires a separate full clone. Correction: none; consult is advisory and this plan QA cannot substitute for final candidate QA.
- [Unverified — needs clone run] Full local qualification, material-seam red controls, two-parent recovery/full-tree-mode comparison and wrong-mainline negative control remain execution prerequisites. No test, fixture, gate, Git command or remote command ran in this turn. Live PR state, counts, remote heads/protections and hosted-main success were not queried or attested.

Evidence limits: Verify intent with direct-source fallback. `list_projects(limit=100)` returned all 82 projects (`has_more=false`), none matching this worktree/task clone. Nearest XYZ-forge graph is another checkout, generation `2026-09-01T15:54:30Z`. Coverage marked policy/CI paths metadata-changed, coordinator not-tracked and this relay missing; current local text supports the bounded findings, not that stale index. Read-only probe `nl -ba relay-system/2026-10-12/gh1012-plan.codex.md | sed -n '306,385p'`, exit 0, and the earlier 385–505 span supply the cited canonical plan. No scratch output is treated as durable qualification.

Relay closed (Approved), no further review turn needed. Handing the completed result to Producer (codex-producer) for the conditional execution prerequisites; final promotion-range execution remains held until they pass.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
