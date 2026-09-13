---
gh_issue: 605
source: https://github.com/HiQS-Labs/XYZ-forge/issues/605
title: Work-state projection correctness
status: In progress
created: 2026-09-13
updated: 2026-09-13
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
| Plan committed; Agy Approved with driver attestation; baseline validate passed 374/374 (one sequential retry) | BLOCKED: DeepSeek V4.1 Flash failed both allowed attempts; resolve reviewer route and authorize renewed QA before implementation/PR |

## Table of contents

- [Phase 1 — Ground truth and plan QA](#phase-1--ground-truth-and-plan-qa)
- [Phase 2 — Consistent events and honest diagnostics](#phase-2--consistent-events-and-honest-diagnostics)
- [Phase 3 — Verification and final QA](#phase-3--verification-and-final-qa)

## Scope and bet

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

Top-10 Ready and seven-day Done selection remain GH-402 follow-up requirements. Do not enable
the operator's automatic connector or change their board during this task. No deletions,
board-to-ledger writes, scheduler, new dependency, new schema, or unrelated CI/relay fixes.

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

## Phase 2 — Consistent events and honest diagnostics

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
