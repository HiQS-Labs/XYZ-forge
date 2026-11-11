---
gh_issue: 1399
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1399
title: Attempt accounting at qualification entry
status: Active
created: 2026-11-10
updated: 2026-11-10
owner: Codex
goal: Refuse unaccounted task qualification through existing gate boundaries while preserving legitimate harness and administrative flows
---

## Status

| What was just completed | What's next |
|---|---|
| Implementation and discriminating manual controls committed; final QA exhausted3 rounds and lock-reader finding repaired | Operator-extended independent review, final qualification and ready PR remain pending |

## Request and scope

Issue1399 requests fail-closed qualification/pre-push accounting, automatic binding for standard harnesses and instructional start-task/workhorse flows, a supported manual repair entry, preserved consumed rounds, and unchanged non-task administrative routing. No merge or deployment is authorized by this start-task invocation.

## Acceptance

- [ ] Unaccounted mutation on a task branch is refused at push and direct local qualification boundaries.
- [ ] A valid canonical reservation or candidate-bound completed receipt permits the same qualification.
- [ ] Lane and merge-repair histories retain all consumed rounds; no migration/reset silently replenishes budgets.
- [ ] Reconciliation and docs-only integration-root updates retain existing ci-route behavior.
- [ ] Main and adjacent paths include archived/completed attempts, nested counted ownership and disposable full verification clones.
- [ ] Independent Codex plan and final QA Approved, applicable focused/final gates pass; ready PR targets development.

## Intake and rating rationale — 2026-11-10

Proposed75/60/50/35: priority follows the operator's next dependency after1400/1401; severity60 is observed accounting/audit drift with recoverable supervision cost, not evidence of data loss. Appeal50 is neutral: issue's initial60 is a proposal, with no explicit operator score identified. Cheapness35 reflects the traced producer/consumer and clone-transfer seams, broader than the issue's narrow-hook estimate40. No existing ledger rating/override found. Recent windows2026-10-27..11-10 versus10-13..10-26: one reported bypass class in1399 citing1386/1397;1387 is distinct history-retention behavior, not a second bypass incident. Coverage limited; trend unknown, not zero.

## Current recon

See `PROJECT/2-WORKING/recon-gh1399-attempt-entry-gate.md`. Base68367d6682737b5bcdb324c1bede6def53c197a2. Prior-art scan matched1403 only; its documentation explicitly delegates enforcement to1399 and does not solve this issue. No1399 clone, canonical task doc, roadmap row or open matching PR existed at pickup.

## Constraints and design questions

Existing lane fire files and merge-cleanup JSON reservations remain their respective accounting authorities. No parallel ledger, scheduler, runner, test suite or registry entry. The requested guard extends existing qualification boundaries; documented operator bypasses and unsafe-worktree refusal remain unchanged. A counter or truthy LANE_ATTEMPT_COUNTED alone is not a reservation. Bindings must cover both active work and legitimately completed/archived work, including separate full qualification clones. Merely requiring outcome=in_progress is incorrect.

A qualification guard can detect missing accounting, not infer logical repair episodes inside an authorized reservation. This limitation must remain explicit. Production implementation has not started; plan and authority/binding decision remain pending.

## Reversibility

Costly: a bad predicate could block every task publication or qualification. Rollback must revert the reader and its producer integrations together; retain all existing attempt bytes and historical receipts. No new source of truth or destructive migration.

## Preflight bet and proposed protocol

Outcome: every local task qualification has attributable accounting, without manual reconstruction. Smallest bet: one admission predicate in the existing gate-receipt module, referencing canonical lane/repair records. Rejected alternatives: checking a counter/flag is stale and unbound; guarding only JSON writing misses legacy and docs shortcuts; a new global lease ledger duplicates existing authorities. Authority is a read projection over existing writers, not a new accounting source. This is accidental-omission enforcement, not protection against an operator rewriting local state or documented Git bypasses.

Task identity is independent of ci-route: task branches include the maintained feat/fix/chore/docs and harness marathon prefixes. A supplied managed-attempt context is always checked, even on an integration branch. Without managed context, maintained integration/admin roots retain normal routing; detached local task verification requires explicit context. Hosted Actions qualification is an explicit existing-CI case, using repository/commit identity, not a generic CI=true bypass. Push ref names must be retained and checked per pushed candidate, not only current HEAD.

Keep the current counter file and count semantics. Extend newly written lane fire entries with one-line JSON reservation metadata (unique id, target root, branch, starting revision, normalized remote identity, state), while counting and preserving pre-existing timestamp lines. Put the one shared append/update implementation beside existing archive handling in rtl.py; both drivers use it. Legacy lines continue consuming budget but are not fabricated into candidate-bound reservations. No automatic cap reset or retrospective uncounted binding.

Gate context references an absolute canonical record plus reservation identity/index; it is not proof on its own. For an in-progress record, require the same target repository/origin and a candidate matching the live target's committed HEAD, descended from its reserved start. For a completed/resolved record, require its recorded final candidate exactly. Missing/malformed/unreadable/mismatched context refuses with the supported booking command; the nested counted flag never substitutes for this check. Completion/failure updates newly structured entries through the same writer without changing consumed count; successful reset preserves exact bytes and archive provenance. Merge-cleanup keeps its locked JSON writer and existing resolved-commit qualification behavior.

Separate full gate clones receive an explicit reference to the originating record via the existing gate environment contract; validate the source/candidate binding, rather than copying a mutable counter or treating the verification clone as a fresh budget. A live lane may evolve through multiple checkpoints inside one already-booked episode; completed receipts cannot authorize later unrecorded revisions. This is deliberately not a claim that the system can infer logical episode boundaries from edits.

Manual start-task/workhorse booking should use subcommands on the existing gate_receipt CLI which delegate to the canonical lane writer, not a second writer or new executable. Skills book at accepted implementation start, retain the returned context through focused checks, QA and publication, and finish only after intended publication checkpoints. Existing harness producers establish/pass/finish context automatically; reviewer-only turns remain uncounted. Failed/resumed work preserves the existing cap/history and does not mint a new identity to obtain capacity.

## Ordered implementation and verification proposal

1. Reproduce current unaccounted task admission in a disposable full clone, plus integration/admin routing and receipt reuse. Retain commands/results/provenance; an assertion requiring refusal must be RED before the fix. No source edits before Approved plan QA.
2. Extend existing rtl lane reservation metadata/writer and the existing merge-repair record adapter; wire Relay/Marathon and nested ownership. Preserve line-count budgets, archive bytes and failure/cap behavior. -> manual controls distinguish missing, malformed, wrong-candidate and legitimate active/completed records.
3. Extend gate_receipt with the single admission predicate and delegated manual booking commands. Preserve context through gate_env. -> direct API/CLI negative controls reject arbitrary flags, stale/completed wrong SHA, and missing external record; same committed candidate in a disposable full clone passes.
4. Invoke that predicate before pre-push docs/receipt shortcuts and at direct validate/ci-local entry; cover legacy gate-record before its first green write and install fallback. Retain ref names and check every pushed task candidate. -> actual main/adjacent hook and qualification controls prove refusal and unaffected admin/deletion/hosted routing. Preserve unsafe-worktree and explicit-bypass contracts.
5. Update start-task/workhorse instructions and merge-cleanup qualification context at their existing producer/consumer seams, without deploying installed skills. -> exercise normal lane, nested lane, resolved B1, archived success/post-approve and standalone manual booking. Keep old evidence/history readable.
6. Run only existing focused suites for changed behavior, adjusting fixtures only where the new admission contract changes their setup. No new suites/registry entries or speculative security machinery. Record negative controls as manual receipts under TESTS-RESULTS/2026-11-10+GH-1399/.
7. Independent Codex final QA of committed scope, receipt and main/adjacent smoke evidence. Adjudicate within three rounds; select the final normal push gate from actual paths and run required full qualification once in a disposable full clone. -> independent Approved, identity unchanged, exact-head hosted smoke when published.
8. Publish one ready PR to development with issue mapping and limitations, issue closeout, and scoped published-checkout retirement. No merge or deployment. If binding/lifecycle cannot be made coherent within existing authorities, stop with concrete unresolved requirement rather than shipping a decorative or overbroad gate.

## Plan QA

Pending. The proposed protocol is not an implemented contract. Reviewer must challenge active/completed lifecycle, detached/verification clone identity, inherited environment, all successful qualification shortcuts, legacy counter compatibility, administrative exemptions and operational burden. Production admission remains unstarted until Approved review and accepted-start through the owned PRS row.

## Plan QA round1 disposition and archive protocol

Independent Codex requested one concrete correction: absolute live-record references stop resolving at archive/reset, and exact completed SHA alone cannot cover existing allowed post-approve transcript evolution. Accepted; no implementation yet.

Retain archive-before-post-approve ordering and its existing failure/reset semantics. Before successful reset, bind the existing protected relay attestation to the consumed reservation identity and the already-approved candidate. Return the archive path from lane_attempt_reset, and replace the propagated qualification reference with that actual archive path plus the matching attestation reference. Do not rewrite the archive afterward or maintain a shadow live budget. A failed rename does not advance context or report successful completion.

An archived-lane reference is admissible only when its immutable reservation entry and the protected attestation agree on reservation/target identity, the candidate matches the live target's committed HEAD for a separate gate clone, and the existing relay_attest.candidate_ok predicate accepts that candidate. Reuse that existing predicate unchanged: it permits only reviewed ancestry plus the already-defined transcript/phase-record paths, not arbitrary docs or source changes. A seeded-artifact/non-isolated review is not eligible through this path. This is a reference to existing approval/completion authority, not an additional budget store.

While post-approve is running, the original approved reservation remains the accounting proof for exactly that attested candidate set. Post-approve success uses existing record_phase_completion to pin its validated final candidate; failure keeps the archived accounting and approval intact, as today. Gate-only/closeout resume loads the same archived reservation reference from the existing protected attestation, verifies candidate_ok and phase identity, and does not fire/reset another attempt. New source changes fail that predicate and need a normally counted build. No new attempt is booked merely for closeout or transcript evolution.

Standalone manual reservations and completed B1 records use their exact recorded final commit once finished; only attested managed-lane archives receive the pre-existing transcript-only candidate rule. Standalone start-task keeps its reservation active through intended evidence/publication checkpoints, then finishes. Legacy timestamp-only history keeps consuming cap and is retained, but cannot be silently upgraded into a new binding. Controls must cover archive reference propagation, same-candidate publication, permitted transcript-only post-approve evolution, failed/resumed closeout, unrelated source refusal, unchanged archive hash and unchanged consumed count.

## Implementation admission

Plan QA Approved in round2 at ebeaae250a55a172f1b2ea5b926e430f18818039. Canonical accepted-start applied to exact issue-owned row rmi-01M74GKNF9DGEQBPX5R34FQBZN before implementation. Actual normal unaccounted task push reproduced the missing guard (expected refusal assertion RED); retained baseline/invalid-control diagnostics and independent review attestation are under TESTS-RESULTS/2026-11-10+GH-1399/baseline/. No implementation or fixed behavior is claimed yet.

## Implementation checkpoint

Initial shared writer, admission predicate and entry/harness integrations are implemented;
syntax and read-only admission controls pass (missing, counted-flag-only and wrong candidate
refuse; canonical active reservation passes). Actual fixed hook/qualification controls,
focused suites and final QA remain pending. The first writer bootstrap preceded the new CLI;
the current implementation episode was then booked once through that same shared API before
remaining integration and qualifying gates. The owned counter was moved byte-for-byte to the
maintained primary accounting area without changing id/count so later task retirement cannot
lose it. No primary tracked file was changed.

Standard gate entry points consume the admitted context before suites, remove it from their
unrelated fixture children, and explicitly restore it only to their own receipt writer.
Gate-env still passes the proof into the qualifying process. This prevents the parent record
from contaminating fixture controls. Source instruction changes stay in this repository PR;
no managed skill payload, app link or installation was changed.

Administrative branch identity is explicitly main/development/master, rather than treating every unrecognized name as administrative. Other branch names and task destinations require accounting even when pushed with local ref HEAD. The tier classifier remains unchanged. Completed manual receipts resolve their original id from preserved archives even after a new budget reuses the live filename; completed exact-revision proof does not require a retired source checkout.


## Implementation refinements

Historical quality receipt reads remain read-only facts; fresh qualification and pre-push admission run before receipt reuse. Managed review binds its protected attestation path and reviewed candidate into the same canonical reservation row before immutable archival. Counted nested builders cannot reuse reviewed reservations; gate-only recovery uses that attested proof. Exact completed phase candidates may qualify after later phases advance the live HEAD, through the existing protected phase-completion predicate. No additional budget ledger or gate runner is introduced.

Upstream integration used the canonical ledger resolver; accepted-start and ratings were replayed on reminted issue row rmi-01M74P46VSM66QZET13SBH36SS. Earlier row identity is retained above as history.


Final QA round1 identified a real nested merge-repair approval writer mismatch. Fixed by retaining parent ownership for inherited manual/merge contexts; red/green driver controls retained under implementation/final-controls. Final QA round2 pending. Administrative normal push passed74s; separate-clone completed proof accepted. No new test suite or registry added.


## Resumable stop — final QA cap exhausted

Plan QA Approved in round2. Final QA rounds1–3 ran; no Approved final receipt. Round1's inherited merge-repair approval defect was fixed and red/green verified. Round2 closed it but left whole-file coverage incomplete. Round3 found a pre-existing canonical directory-lock reader mismatch in the touched scan_clones file and escalated at the binding three-round cap. Root fixed that existing reader in6f081242c: read directory/pid, preserve legacy file and conservative malformed-lock handling. Manual old-reader RED/fixed live, stale, missing-pid and legacy controls pass; real checkout inspection returns ACTIVE_LOCKED for a known live directory lock. Receipts are committed under TESTS-RESULTS/2026-11-10+GH-1399/lock-reader. This last repair has not received independent QA.

Remaining: complete the outstanding full-file review and independently review the lock-reader repair under an operator-extended review budget; then final qualifying gate, normal push, ready PR against development, hosted checks, and published-checkout retirement. No PR, push to canonical remote, merge, deployment, or full qualification is claimed. Task and helper clones are preserved because intended commits/evidence remain local-only. Three final QA rounds are consumed; do not reset the count or scaffold a replacement relay. Continue GH1399-FINAL-20261110 and the existing final transcript if authorized. The completed old todo watchdog remains canceled; no new watchdog was armed.

Sanity assessment: the directory-lock mismatch is a real producer/reader contract defect in the touched cleanup code. Active clone preservation is relevant to authorized retirement, so the two-line reader fix is necessary and proportionate; no new guard framework or suite. Review coverage is an explicit skill requirement, not a newly observed runtime defect.

Edit verdicts: accounting entry integration helped (unaccounted push refused and booked route admitted); archived binding helped (immutable same/transcript candidate accepted, unrelated changes refused); inherited parent approval fix helped (old driver control fails, fixed succeeds without changing parent count); lock reader helped (old reader misses the directory, fixed checkout preservation sees it); qualification fixture adjustments are confounded with dependency changes and are not independent proof of admission. NO_ENTRY for LESSONS-LEARNED: these task-specific repairs do not establish a distinct general lesson beyond the existing producer/consumer and meaningful-red-control guidance.
