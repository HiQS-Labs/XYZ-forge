---
gh_issue: 605
source: https://github.com/HiQS-Labs/XYZ-forge/issues/605
title: Work-state projection correctness
status: In progress
created: 2026-09-13
updated: 2026-09-14
owner: Codex
goal: Make lifecycle events consistent and expose unknown projection readiness without guessing activity.
reversibility: Costly
doc_type: bugfix
effort: 3
complexity: 3
risk: 3
phases: 3
---

# Work-state projection correctness

## Status

| What was just completed | What's next |
|---|---|
| Corrections and independent QA complete; corrected candidate gate381/381; Rev.2 applied and independently verified with zero-change rerun | PR607 ready for code review and merge by operator; automatic synchronization remains disabled |

Final September14 closeout: corrected candidate dc218240 published normally after
round7 source approval and381/381 gate (789s, GH53 serial retry passed). Independent
Python79/79. Live apply64changes and one fresh six-status convergence pass complete;
all original cards retained, no duplicates, every intended status independently
verified. Board: Ready10, In progress6, In review15, Done89, Backlog3. Fresh preview
07:50:18Z returns0changes. Six existing In progress cards remain explicitly unverified,
not asserted active. Configuration is manual-only; no merge, scheduler or deployment.
Evidence: TESTS-RESULTS/gh605-implementation/FINAL.md and completion.json.
The following checkpoints are historical and do not override this final status.

September13 execution checkpoint: controlling plan QA Approved at8cfad6bb (driver exit0).
Final authorized continuation: source review6 Approved (driver0, reviewed96261ab2,
attestation94665101). All19files read toEOF; no remaining source findings. Seed counter
fixed in830455e8, parent79Pythonpass, removed-line redcontrol fails and restoration passes.
Development4ee561ed integrated with canonical ledger resolution, generation648.
GH615's minimal test-only line-wrap correction passed Sol authorship and independent
Astra outer review: GH615 8/8, GH616 7/7; incoming GH617 9/9 and GH365 16/16.
The earlier partial gate was interrupted before publication to integrate GH617;
the settled candidate's final normal gate is running. Then fresh board preview,
auditedapply, independentreadback and zero-change rerun. Historical pauses below are not
current blockers. No merge or automatic connector enablement is included.
Current disposition supersedes historical continuation paragraphs below: review5/a9a69567
closed the invalid-source, lease-ownership and queue-compaction findings but did not approve.
The same lane is exhausted at5/5; operator continuation requested for the mock seed-ID
correction and remaining source coverage. Parent reproduced the mock defect without live
network writes. The full gate onae7006c8 passed378/378 in879s and published normally. Preserve PR607 as draft and do not
apply the board or change local configuration before fresh approval plus a qualifying gate.
Latest continuation: operator explicitly authorized finishing corrections and verification.
Same relay extended to5 review rounds;426f5825 implements the four concrete remaining repairs.
Parent direct Python verification74/74 passes in a separate full clone. Fresh shell/full gates
and independent review4 are now required/running. Historical pauses/results below are retained,
not current blockers or fresh approval. No changes to the approved board policy or non-goals.
Implementation b9d784e9 incorporates the first independent code review's corrections.
The first-build full validate failed376/377; its registry defect now passes the focused
telemetry check. Historical41-test fixture failure and live GraphQL/WAL defects are corrected,
not relabeled as historical successes. Current54 Python tests and restored sweep pass in
separate full clones. Four deliberate regressions fail named assertions; all temporary edits
were restored and clone identity/cleanliness verified. Real read-only preview proposes55
changes matching independent GH/board analysis, preserving Ready10 and uncertain activity.
Reviewer round2 returned changes requested:4 Blockers and3 Shoulds. The saved next correction
brief was initially parked at the attempt cap. Operator authorized resuming; the same lane
was deliberately re-fired and22533bb4 addresses all seven findings with65Python tests passing
in a separate full clone. Development PR611/ec0823ab is included via57bcbcc5, ledger histories
combined by the canonical resolver (generation635, check clean). Final third review and fresh
full gate were started. Final review4b289868 returned FAIL/Escalated at3/3: actual jog
drop/skip/requeue/recovery event paths remain incomplete; evidence as_of must be fresh even
if created_at is refreshed; CLOSED issues need invalid/duplicate ledger preservation too.
Also correct PR-card representation in the stateful mock and finish declared source coverage.
These findings are accepted but unimplemented pending operator continuation beyond the cap.
Current65Python, six shell suites and restored red-control tests pass. Full normal gate passed
378/378 in854s; gh32 failed in parallel then passed sequential retry.22533bb4 is published,
clone identity intact, no bypass. This does not replace the missing final QA approval.
The normal full draft push gate passed377/377 in824s and published b9d784e9, independent
from missing QA approval. Clone identity stayed clean and unchanged; no bypass was used.
No live board writes, configuration changes, merge or deployment has occurred. PR607 remains
draft with implementation published. Evidence: TESTS-RESULTS/gh605-implementation/.

## Table of contents

- [Phase 1 — Ground truth and plan QA](#phase-1--ground-truth-and-plan-qa)
- [Phase 2 — Consistent events and honest diagnostics](#phase-2--consistent-events-and-honest-diagnostics)
- [Phase 3 — Verification and final QA](#phase-3--verification-and-final-qa)

## Scope and bet

### Operator clarification — two required outcomes

This clarification supersedes the earlier restriction against live board application and
the deferral of selection/current-state behavior needed to satisfy this task. The earlier
Agy approval covers only the narrower plan; it does not approve the expanded scope below.

1. **Primary: durable repository fix.** Extend reusable, repeatable repo scripts and their
   tests so board state can be reconciled from evidence through the existing writers. A
   temporary population helper or manual card moves do not satisfy this outcome. Preserve
   dry-run, auditable decisions, safe retries and no-op rerun behavior. Rebalance/CLIO/prompt
   evidence must be checked for freshness and issue identity, then corroborated against GH;
   distinguish intent, started work, phase completion and whole-issue completion. Unknown
   evidence remains explicit rather than an invented transition.
2. **Required application: current Rev. 2 board.** Use the tested scripts to reconcile
   noelsaw1 project #4 (verified title: Q3 2026 - Planning Board - Rev. 2), snapshot before,
   inspect the proposed changes, apply, then independently read back the board and rerun
   the preview to verify convergence. Enforce the saved policy: top 10 eligible scored
   XYZ Forge items in Ready; verified inflight work in In progress; reviewable PRs in
   In review; recently completed work from the last 7 days in Done. No deletions; do not
   demote ambiguous items merely because activity is old. Report any unresolved mismatch.

Verified local configuration targets this project and HiQS-Labs/XYZ-forge, with the automatic
connector disabled and github_board_selection_policy marked pending/unconsumed. Preserve
those settings until the tested path can enforce them. Application is now authorized; this
does not independently authorize a recurring scheduler or merge. Live-write reversibility
is Costly: preserve before/after statuses and item identities for restoration through the
same writer. Required completion evidence is a reusable-script PR plus verified live-board
results, not just a diagnostics command or a code-only PR.

**Current checkpoint:** the September 13 revision below supersedes the earlier bounded
implementation list and deferrals. The operator explicitly requested execution using GLM's
new review and Qwen's recovered review. Qwen's route now completes (GH-608); its verdict
was changes requested, not approval. The unrelated harness patch remains outside this PR.
The revised plan receives a bounded Codex relay check before production edits; final QA
also uses the start-task Codex reviewer, with GLM/Qwen findings included as acceptance inputs.

### Earlier bounded increment — retained as recon input, not the full clarified scope

Follow-up to GH-549/GH-564 within GH-402. This PR fixes the confirmed deterministic
event/classification defects and makes projection readiness and evidence age inspectable.
The board remains a projection; recent prompts suggest investigation, not lifecycle authority.
The six September 13 audit findings are mapped below so limited scope cannot imply full resolution.

| Audit finding | This PR | Remaining work |
|---|---|---|
| Old schema and stale snapshots | Read-only work status diagnoses missing schema/events, connector state and evidence age | No auto-migration; external source freshness/adapters remain GH-402 |
| Live/backfill disagreement | Shared section-first classification; metadata writes cannot act as starts | No new state-machine subsystem |
| Bulk terminal sweep has no events | Per-row events in one existing receipt transaction | No alternate writer |
| PDDA checks closure, not recent activity | Document work status alongside PDDA; diagnose unknown/stale observation | No automatic demotion based on age |
| Review repair is one-way and issue-only | Document limitation explicitly | Current-state GH repair, reopening, standalone PR lifecycle remain GH-402 |
| Intent/activity/phase completion conflated | Report lifecycle separately from latest non-backfill start observation | No prompt classifier or automatic multi-source state inference |

The earlier increment deferred top-10 Ready and seven-day Done selection to GH-402 and
excluded live application. Those limits are superseded by the operator clarification above.
Retain these non-goals: deletions, board-to-ledger writes, scheduler, new dependency, new
schema absent demonstrated necessity, and unrelated CI/relay fixes.

Risk is **Costly** because perform_write is shared by all ledger writers. Shield: existing
connector disable/kill switch, unchanged opt-in activation, atomic transactions, no external
writes in tests. Tripwire: receipt-chain failure, incomplete rollback, duplicate sweep events,
or metadata-only update changing a board status. Rollback: revert this PR's code, disable the
connector, retain append-only history, and use reviewed reconciliation rather than rewriting it.

Rating read-back: `rated 80/65/50/65`, sum 260, no override. Priority reflects explicit operator
work; severity is misleading coordination state without observed data loss; appeal neutral 50;
cheapness 65 for bounded existing seams. Related GH-549 and GH-564 describe previous missing
producer gaps. Recent 14-day window 2026-08-30–09-13 versus preceding 2026-08-16–08-30:
this is one newly witnessed audit, not six independent incidents; recurrence trend unknown.

## Phase 1 — Ground truth and plan QA

**Goal:** Commit a grounded, independently reviewed plan before changing production code.

- [x] Inspect live board, local ledger schema, Rebalance/CLIO freshness, and GH activity.
- [x] Reproduce classifier contradictions using isolated pure-function execution.
- [x] Record the recon map below; graph index was stale and exact source was used.
- [ ] Agy review then DeepSeek 4.1 Flash review; adjudicate every finding, require successful driver exit and Approved before Phase 2.

### Recon map

Base: `38507a23303bebab6184607b15e3099cc2dd88e3`. Parent graph `XYZ-forge`, generation
2026-09-01: releases_app metadata changed, connector/board paths untracked by index. Source
fallback confirmed the relevant functions match live development. One read-only delegated
state/test lane plus primary entry/config/source cross-check; no completeness claim for GH-402.

| Seam | Source | Confirmed behavior |
|---|---|---|
| CLI update/move | utils/py/releases_app.py:3752 | mutate row, then perform_write roadmap-update |
| Event classifier | utils/py/releases_app.py:1445 | marker-only classification ignores section |
| Transaction writer | utils/py/releases_app.py:1562 | receipt then event before commit; dispatch after lock release |
| Terminal sweep | utils/py/releases_app.py:3859 | all GH reads first, row fence under lock, one bulk receipt, no events |
| Historical snapshot | utils/py/releases_app.py:4826 | Deferred skip, Completed first, then progress section/marker |
| Connector | utils/py/work_connectors/github_board.py:80 | maps event names, unmapped events acknowledged/skipped |
| Review producer | utils/py/releases_app.py:4960 | open non-draft linked issues only; cannot synthesize missing terminal events |
| PDDA diagnostics | utils/pdda/pdda.sh:662 | warns closure/section drift; not evidence of activity |
| Fixtures | test/gh549-work-events.sh; test/gh492-roadmap-state-sweep.sh | real CLI/migration/receipt, backfill and atomic sweep assertions |

State ownership: RELEASES writes only through perform_write/perform_migration; events append-only;
connector cursors local; board writer is board_sync. No new writer or persistent evidence store.
Failure paths: GH lookup or row-fence refusal before mutation; journal recovery on interrupted
write; connector failure never fails a committed ledger write. Event insertion currently lies
outside the mutate-only rollback handler: batch failure needs explicit rollback and journal cleanup.

Unknowns: external ingest freshness/coverage and activity-to-issue identity are not solved here;
GH-402 owns that adapter work. CLI work status cannot infer activity before recorded history.
The primary checkout's schema-7 DB is observed, not modified by this PR workflow.

### Phase 1 — QA gate

- [ ] Review inputs committed; both reviewers answer omission-diff against Scope and bet.
- [ ] All review findings disposed with evidence; no unavailable-model substitution.

### September 13 checkpoint — reviewer route blocked

Agy requested two clarifications, both resolved in 59ac7b2b, then Approved with driver
exit 0 and attestation in relay-system/2026-09-13/gh605-plan-agy.md. Its first invocation
omitted --reviewer and returned a non-approval handback; only the explicit-reviewer second
attempt qualifies. DeepSeek was configured as deepseek/deepseek-v4.1-flash via OpenRouter,
reasoning high. Attempt 1 returned driver exit 5: `STREAM_CLOSED: SSE stream ended without
[DONE]`; attempt 2 returned exit 7 after the 600-second idle/no-progress timeout. Both lacked
a VERDICT, and the harness released the claims. No approval and no model response are claimed.
The two-attempt cap is exhausted. Per start-task, stop before production edits; resolving the
reviewer route and renewed QA authority is the next action. No PR, push, deployment, connector
enablement, live board changes or primary DB migration occurred in this task.

Baseline evidence is retained in TESTS-RESULTS/gh605-plan-preflight/: full validate exit 0,
374/374 checks, identity unchanged. gh32-releases-app had four failed parallel assertions
and passed the gate's sequential retry; the original log is retained. This is baseline-only,
not evidence for an implementation that does not yet exist. Task branch fix/work-state-projection
and its fresh full clone are retained for resume; do not repeat intake or create another issue.

## September 13 expanded revision — controlling specification

### Review disposition and additional recon

GLM review: https://github.com/HiQS-Labs/XYZ-forge/issues/605#issuecomment-5656226533.
Recovered Qwen findings: https://github.com/HiQS-Labs/XYZ-forge/issues/608.
Both are advisory source-grounded reviews, neither is approval. Earlier historical checkboxes
and narrower exclusions above are retained as history, not the current implementation scope.

| Finding | Disposition |
|---|---|
| GLM B1 / Qwen selection and Done blockers | Add explicit policy planner, fresh GH reads, preview/apply/restore in existing board_sync; never replay raw events onto a policy-managed board |
| GLM B2 eligibility, ordering, freshness, demotion | Pin all four below; tests assert exact selected identities and preservation |
| GLM sidecars / lock capture | Refuse source WAL/journal ambiguity for read-only diagnostics; capture previous row only for roadmap-update |
| GLM registry / Deferred / two day knobs | Named classifier red control; preserve backfill Deferred skip and document incompleteness; 3-day activity and 7-day Done remain distinct |
| Qwen batch atomicity / metadata | One receipt and transaction for all sweep events; injected second-event failure proves rollback; metadata-after-review named test |
| Qwen snapshot / restoration | Explicit versioned local artifacts, preconditions, partial result journal and conditional status restoration; never claim remote atomicity |
| Qwen parameter duplication | Compare prior/current lifecycle only in update extractor; no prior-row queries for unrelated operations |
| Qwen receipt target / empty batch nits | Preserve bulk NULL target semantics and conservative whole-batch replay; clarify documentation, do not widen cursor semantics |

Additional recon at task HEAD 67bec216, graph Verify tier XYZ-forge generation
2026-09-01T15:54:30Z: releases_app metadata changed, board_sync/connector not indexed;
exact source fallback plus read-only board-contract lane. No relevant production changes
in this task since the baseline. Current radius is the shared ledger writer, work-event
consumers and configured GitHub project; no new authority or DB schema.

| Seam | Source before implementation | Consequence |
|---|---|---|
| Offline scan | board_sync.py:113–211 | Doc/branch presence and tick creation have no freshness; cannot independently prove started work |
| Snapshot | board_sync.py:387 | Issue-only, duplicate-collapsing dict; extend compatibly to PRs and detect ambiguous duplicate identities |
| Existing mutation | board_sync.py:524 | Validates column after add and doesn't advance supplied snapshot; preflight options and update snapshot after each successful operation |
| Resolver/config | device_config.py:76; work_connectors/__init__.py:49,110 | Reuse diagnostic resolver for dedicated saved policy; connector allowlist does not consume policy |
| Dispatch | work_connectors/__init__.py:233,414 | Nonzero child leaves entire cursor unchanged; no pending events means no dispatch, so policy repair must be explicit and snapshot-based |
| PR scan | releases_app.py:4960 | Limited200, non-draft/linked only; insufficient as current-state authority |
| Failure/undo | board_sync.py:476,503,557 | Reuse status writer and option resolution; never call deleting dedupe; status-only undo cannot remove added cards |

### Deterministic selection contract

Policy is the existing `github_board_selection_policy` block in device config, resolved
through `device_config` with strict types and explicit target identity. Consume
`project_owner`, `project_number`, `repos`, `ready_top_n=10`, `done_lookback_days=7`;
add explicit `activity_lookback_days=3` and column names Ready/In progress/In review/Done/Backlog.
Validate target matches configured connector if present; malformed policy refuses before GH.
No personal target defaults. Local automatic connector stays disabled; presence of a policy
for that board blocks raw-event connector writes with an actionable message, even if someone
enables it accidentally. Legacy non-policy configurations preserve their existing behavior.

- Identity is full GitHub repository + number + content kind, never a number alone. Ledger
  candidates require exact matching issue_url/gh_number and configured repo. Duplicates or
  mismatches are reported and preserved. Foreign/opaque board items are never mutated.
- Read all relevant current GH issues/PRs with bounded complete pagination, including closed
  board items; a failed/truncated lookup aborts preview/apply, not an empty successful result.
  Terminal issue state is CLOSED with known COMPLETED/NOT_PLANNED reason. Done age uses GH
  closed_at or PR merged_at, never ledger updated_at/backfill time. Unknown reason/date preserves.
- Completed issues/merged PRs within the inclusive UTC seven-day window go Done. Older verified
  terminal cards already on board go Backlog; absent old terminal items are not added. NOT_PLANNED
  and closed-unmerged PRs go Backlog only if already on board. No deletion or Deferred column needed.
- Every open PR card, including a draft, goes In review (operator: whatever is a PR). A linked
  OPEN issue goes In review for a non-draft open PR. Draft PR evidence can establish its linked
  issue In progress when PR updated_at is within three days. Use explicit GH closing references,
  repo-qualified; don't interpret an incidental mention as a closing link.
- An OPEN issue can also be In progress from a recent non-backfill in_flight/jog_running/leased
  recorded event with matching repo identity. GH OPEN corroborates nonterminal state; this is
  a recorded start, not proof an agent is currently running. Old 🚧/doc/branch presence alone is
  unverified; preserve its current card and exclude it from Ready rather than silently demote.
  Evaluate latest lifecycle-bearing evidence, not any historical start: a later parked/rated
  return-to-Queue, jog stop/failure/completion/deferral supersedes a prior start. Current Queue
  without progress marker contradicts an old start unless a newer independently witnessed
  active PR proves otherwise. New update-derived start payloads carry `source: roadmap-update`
  and `transition: true`; historical untagged in_flight events can be metadata-only artifacts
  and are never sufficient by themselves. Recent explicit jog events can qualify only while
  current jog/ledger state remains consistent. Unknown provenance remains unverified.
- External Rebalance/CLIO/prompt observations are optional normalized JSON evidence records:
  source, issue_url, observed_at (UTC), kind (intent/started/phase_completed/completed), reference.
  Validate identity and freshness; retain only reference/metadata in audit, never raw private text.
  They nominate candidates/explain agreement or conflict but cannot alone move a card, declare
  whole-issue completion, or substitute for GH corroboration. Missing/stale/unmapped source is
  unknown, never idle. Live operation collects these sources where available and reports gaps.
- Ready eligibility: GH OPEN, ledger nonterminal and not unverified-inflight, all four rating
  axes valid 1–100, no higher-precedence terminal/review/start decision. Sort by existing
  `rating_ovr` (if valid) else four-axis sum descending, then casefolded repo, number ascending,
  global_id final tie-breaker. No new scoring formula. Select at most10. Positively eligible
  excess Ready cards move Backlog; absent excess/unrated items are not bulk-added. Unknown
  Ready cards stay put and are reported as unresolved, so do not claim exact global10 falsely.
- Current GH OPEN prevents an old completed event from resurrecting Done. Reopened issue with
  contradictory terminal ledger state is preserved/reported pending ledger reconciliation,
  not automatically rewritten by a board projection. In review without an open qualifying PR
  can become Ready/Backlog only with positive eligible ledger evidence; otherwise preserve.

### Ordered implementation and verification (replaces earlier Phase 2 list)

1. Extend the shared section-first classifier and prior-state handling described in the older
   Phase 2.1 below. Metadata-only updates emit updated; Completed+🚧 is completed, Deferred+🚧
   deferred. Backfill retains Deferred skip. Only roadmap-update captures prior row under lock.
   -> Named tests for section-only progress, Completed+🚧, Queue no marker, metadata-after-review.
2. Extend perform_write with mutually exclusive single/batch explicit events. Cover generation,
   receipt, event insertion and COMMIT with precommit rollback; leave postcommit recovery intact.
   Sweep emits per-row completed/deferred payloads after its existing re-fence, all with one
   txn_id/time and one receipt. -> Two completed + one deferred, shared receipt, second event
   insert failure rolls back every row/event/receipt/generation and clears journal; rerun emits0.
3. Add read-only work status and a reusable read-only evidence loader in releases_app. Use
   mode=ro on an existing DB only; refuse WAL/hot-journal/live intent ambiguity before open,
   no migrations/config/cursor/network writes. Schema7 reports unready; schema8 reads rows,
   events/cursors. Inspect bytes/presence of DB and -wal/-shm/-journal, dump and config before/after.
   -> UTC malformed/future/backfill timestamps never become recent starts; stale-days default3
   is separate from policy done_lookback_days7. SQL reads only; missing inputs aren't fabricated.
4. Extend existing board_sync.py with policy preview/apply/restore subcommands and pure planner;
   reuse device_config, ledger evidence loader and current board writer. Extend snapshot/resolver
   compatibly for PR content and optional explicit repo; validate options before add; advance shared
   snapshot after each successful add/status. Keep all old command callers compatible. Add raw-event
   connector policy guard and accurate whole-batch failure documentation. No new dependency/module,
   scheduler, event schema or alternate GraphQL status writer. -> Exact deterministic selection
   fixtures including ties, foreign identity, duplicates, drafts, reopening, missing evidence,
   stale signals, two day windows, and policy-enabled connector refusal.
5. Preview defaults read-only remotely, writes a versioned JSON artifact only with explicit output
   path. Artifact contains as_of, policy, ledger generation/input digest, sanitized observations,
   board identities/statuses, decisions/reasons, proposed changes and warnings. Resolve fresh field
   options, not stored IDs as authority. Apply requires saved preview <=15minutes old, same policy,
   unchanged ledger input, and fresh GH+board re-plan using saved as_of equal to the reviewed
   decisions. Preflight every mutation first; unexpected drift refuses before first write. Acquire
   existing connector exclusion lock for the apply window so legacy dispatcher cannot race it.
   Write audit result before first mutation and after each success; stop on first failure, save
   partial state, return nonzero. Re-read before each change and refuse changed status/item identity.
   Add an optional audit callback to the existing writer: persist intent before EACH remote
   add/set/clear request and its response immediately afterward. Persist successful add's item ID
   before attempting status. On lost response or failed result persistence mark the operation
   indeterminate where possible, stop, and require fresh read-back before any retry/restore;
   never blindly repeat a mutation. A persisted intent without result is itself indeterminate
   after a crash. Policy mode disables blind mutation retry; legacy retry behavior is unchanged.
   -> Stale/tampered target, changed GH, missing option and concurrent card edit tests make zero
   unintended writes; failure at operation2 retains operation1 evidence and supports safe resume.
6. Restore takes result artifact and previews by default; explicit write conditionally restores
   original status through same writer only when current identity/status equals recorded after.
   Extend the same writer with clearProjectV2ItemFieldValue for an originally unset Status
   (not supported by the current string-only option setter). Added cards
   cannot be removed under no-delete: retain/report them, optionally move to Backlog only as an
   explicit restore decision. Never claim atomic remote rollback. -> Injected failure and concurrent
   edit tests prove restoration preserves unrelated/operator changes and reports residual cards.
   Also test add-success/status-failure, response loss, and journal failure before/after each
   request: the add ID or pending intent remains inspectable, no blind retry occurs, and
   originally-unset status restoration actually clears the field.
7. Register focused Python fixtures plus existing event/board/sweep suites, document commands and
   settings in RELEASES-DB-FAQS, and add CHANGELOG. Use debug-mantra for observed failures. Run all
   tests in separate disposable full clone with identity checks and committed provenance; red
   controls remove section precedence, batch events, freshness exclusion and top-N limit and must
   fail named nonempty-fixture assertions. Run full validate, qualifying gate as needed, PDDA and
   final Codex relay on committed implementation (three review rounds maximum).
   Selection fixtures explicitly include start->park, start->stop and pre-fix metadata-only
   in_flight; none may manufacture In progress.
8. After verified code, collect recent sources and current GH for the live Rev.2 target. Preserve
   device settings except explicitly documenting policy as implemented; keep automatic replay off.
   Generate preview, inspect all changes, apply it through tested CLI, retain before/result/after
   local artifacts (only sanitized summary committed), independently read back and run new preview.
   -> Zero intended writes on second run, top10 eligible identities and7day Done verified, unknowns
   listed. Partial failure stops without success claim; restore only safe statuses as above.
9. Update existing PR607 against development with exact implementation SHA, tests, reviews and live
   application evidence. Push through required gate from disposable clone; no merge. Retain task
   clone until origin completion verified. This is one scope, not a new PR for each finding.

### Acceptance, risk and rating update

Goal1 is complete only when steps1–7's reusable commands and gates pass; Goal2 only when step8's
fresh independent board read and no-op rerun pass (or clearly reported preserved unknowns).
Board mutation is Costly, not atomic: shield explicit saved-preview apply, kill switch and
disabled legacy replay; tripwire first mismatch/failure; undo conditional status restore with
new-card residuals. Shared writer remains Costly: no network under its lock, bounded local
prior-row query only for affected op, receipt-chain/fuzz regressions halt execution.
The source observations format is an interchange boundary, not a new canonical activity store.
Unavailable source exports remain a disclosed coverage gap, not grounds to invent observations.

Reassessed rating: `80/65/50/45` (240), no override: same urgency/consequence/neutral appeal;
expanded selection and safe live-application surface is materially less cheap than the earlier
bounded event fix. Persist/read back through roadmap rate before implementation. Recurrence
window/rationale above unchanged: known audit, unknown trend, no invented incident count.

## Phase 2 — Consistent events and honest diagnostics (historical detail)

**Goal:** The same lifecycle change produces the same state event, and unknown freshness is visible.

1. Extend the existing classifier so terminal sections win over markers. Live update uses it
   only when section/marker actually changes; metadata-only edits keep informational `updated`.
   Classification order is Deferred -> deferred; Completed -> completed; otherwise 🚧 marker
   OR In progress section -> in_flight; otherwise rated -> rated, unrated -> parked. Thus
   Queue without 🚧 maps to rated/parked; Queue with a stale 🚧 retains existing backfill
   precedence rather than inventing a new demotion rule. Match sections case-insensitively
   after stripping whitespace, preserving the existing prefix behavior.
   Capture the previous roadmap row inside perform_write after BEGIN IMMEDIATE and before
   mutate for roadmap-update. Add optional previous-state arguments to _record_work_event
   and _extract_roadmap_update; pass it only to the update extractor, leaving other extractor
   signatures unchanged. Compare section/marker before and after mutation there; never try
   to recover old state by rereading the overwritten row. Backfill keeps
   its existing Deferred skip. Live Deferred emits an informational `deferred` event, with no
   default column until the operator configures one. -> Expect section-only progress, Completed
   with either marker, no fake pr_merged, and no review-to-Ready regression on metadata edits.
2. Extend perform_write's existing explicit event seam with a batch argument for reconcile-state.
   Preserve the single-event caller and reject simultaneous single/batch arguments. All batch
   rows receive the same transaction ID and time, after the receipt, before commit. Expand the
   precommit rollback boundary to cover receipt/event writes; postcommit recovery stays intact.
   Sweep emits completed/deferred with source/section evidence, one receipt and existing row
   fences. -> Expect two completed rows plus one deferred row all-or-none; repeated sweep emits
   zero; event-insert failure restores rows, receipt count, events and clears precommit journal.
3. Add `work status [--json] [--stale-days N]` to the existing CLI (default 3 days, UTC).
   Open the existing DB read-only; do not run migration, dispatch, GH, or create a missing DB.
   Report schema readiness, enabled connector names, cursor/lag when available, and per-issue
   lifecycle plus latest recorded non-backfill in_flight/jog_running/jog_leased timestamp and
   age. Label absent observations unknown; stale observations unverified, not idle. Preserve
   lifecycle and distinguish completion/deferral from activity. Include informational latest
   event separately so replay/backfill timestamps cannot masquerade as recent activity.
   Missing DB/schema is an actionable diagnostic (JSON remains parseable, nonzero exit for
   unready schema); disabled connectors are visible, not an error; malformed/future timestamps
   are unknown. -> Expect byte-identical DB/dump/config after status on both schema7 and schema8.
4. Extend existing fixtures and RELEASES-DB-FAQS documentation; use a Python focused regression
   suite registered through validate.sh if clearer than increasing the large shell fixture.
   Document explicit repair sequence: check/recover, deliberate migrate, work status, review
   terminal sweep preview, apply, backfill preview/apply, connector reconcile only once configured.
   Warn historical replay is not complete current-state repair and stock connector cannot enforce
   the saved top-N/time-window limits. -> Expect actionable guidance without a second config.

### Phase 2 — QA gate

- [ ] Matrix of classifier cases and metadata-after-review checks passes.
- [ ] Event batch receipt linkage, rollback and idempotence checks pass.
- [ ] Schema7/8 status, malformed time and no-write cases pass.
- [ ] debug-mantra governs any debugging; no fixing unobserved failures by assumption.

## Phase 3 — Verification and final QA

**Goal:** A verified PR targeting development, not a claim of deployment.

- [ ] Run focused work-event/state-sweep/diagnostic tests in separate disposable full clone.
- [ ] Witness red controls: restore old marker-only classifier; omit sweep batch; treat backfill
  as activity; each must fail a named assertion against nonempty fixtures. Record in TESTS-RESULTS.
- [ ] Run full macOS validate and relevant PDDA gates against committed candidate; check clone
  identity before and after. Commit provenance.jsonl with command, SHA, platform and exit codes.
- [ ] Agy then DeepSeek 4.1 Flash final relay QA of final code, plan and receipts; no self-review
  substitution. Two ordered reviewers per stage; cap each reviewer at two attempts, stop on
  unresolved findings or harness failure rather than silently approving.
- [ ] Push with required gate from a disposable full clone, verify PR base/head/diff/checks.
- [ ] Retain task clone for merge handoff; no merge or deployment authorized here.

### Phase 3 — QA gate

- [ ] Required deterministic checks and both final reviewers pass on final implementation.
- [ ] All skipped/blocked checks disclosed; no private prompts, credentials or machine config in PR.
- [ ] Status table refreshed with actual PR link and remaining GH-402 work, not marked shipped.
