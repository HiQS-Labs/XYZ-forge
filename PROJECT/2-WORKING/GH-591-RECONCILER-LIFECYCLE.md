---
gh_issue: 591
source: https://github.com/HiQS-Labs/XYZ-forge/issues/591
title: Reconciler provenance lifecycle
status: In progress
created: 2026-09-13
updated: 2026-09-13
owner: Codex
goal: Every development PR reconciles automatically with durable full-suite evidence
doc_type: bugfix
umbrella: true
effort: 4
complexity: 4
risk: 3
phases: 4
---
# Reconciler provenance lifecycle

## Status

| What was just completed | What's next |
|---|---|
| Producer implementation and full local gate verified; recovery focused checks pass | Merge authorized; #599 landed, hosted qualification exposed runner assumptions; correct through #600 and observe acceptance |

## Table of contents
- [Phase 0 — diagnosis and decision](#phase-0--diagnosis-and-decision)
- [Phase 1 — producer](#phase-1--producer)
- [Phase 2 — recovery](#phase-2--recovery)
- [Phase 3 — live acceptance](#phase-3--live-acceptance)

## Phase 0 — diagnosis and decision

Budget: 1–2 hours. Debug-mantra governs execution. API, repository history, Python and npm are
available. Both exact invocations failed with exit 6. The throwaway pre-push Git proof confirmed
that hook-created files do not travel in the selected commit. See the committed
[Recon Map](../1-INBOX/recon-reconciler-provenance-lifecycle.md) and
[diagnostic evidence](../../TESTS-RESULTS/2026-09-13+GH-591/SUMMARY.md).

The recorded recommendation is full hosted qualification in the existing macOS reconciliation
workflow. The suite runs once per pending batch in an independent full clone, bound to the
integrated snapshot; a schema-specific receipt cannot fall back to legacy PR-number matching.
No new service, workflow, ledger or PR-class exemption. The local pre-push gate remains required.

### QA
- [x] Primitive failure and hook-file controls witnessed and retained.
- [x] Producers, consumers, bypasses and recovery gaps traced before implementation.
- [x] Findings and alternative costs recorded in the Recon Map.

## Phase 1 — producer

- [ ] #546: full sequential validation emits complete retained JSONL, exact tested/landing SHAs and passing receipts.
- [x] Failed/missing/incomplete telemetry, wrong identity, unmerged landing and mutation under test refuse receipts.
- [x] Receipts join rollback and the bot's narrow artifact allowlist; committed replay is idempotent.
- [x] Focused producer/consumer and workflow tests pass with retained red controls.
- [x] Full local pre-push gate and deterministic PDDA checks pass; independent review resolved.
- [ ] Producer PR opened against development; its own automatic run goes green after approved merge.

### QA
- [x] Exact negative command/output and passing commands are retained in the campaign and PR body.
- [x] No handwritten reconciliation receipt or bypass is used for this PR.

## Phase 2 — recovery

- [x] Separate #584 PR warns and continues on legacy unattributable closed rows; API failures remain errors.
- [x] Committed validated qualification receipts drive recovery of all merged development PRs since workflow activation, including no-issue PRs and open-issue references.
- [x] Mixed legacy + attributable fixture and lost-event/rejected-push fixtures demonstrate red then green.
- [x] No-op sweep writes nothing; actual failure rolls back; focused/full/PDDA gates pass.

### QA
- [x] Full workflow introduction history is the recovery boundary, not an arbitrary recent window or second ledger.
- [x] Invalid receipt identities/hashes cannot suppress recovery.

## Phase 3 — live acceptance

- [x] User approves concrete merges/outward follow-ups at the PR review boundary.
- [ ] Producer PR's own Wave reconciliation run is green without manual evidence.
- [ ] Recovery PR and next scheduled catch-up run are green.
- [ ] Three consecutive merged PRs reconcile automatically; run URLs recorded here and on #591.
- [ ] Existing express #592 / PR #597 and bounds #594 are linked from #591; any remaining ad-hoc direct-push gap is filed; #492/#534/#538 remain explicit adjacent work.

### QA
- [ ] Do not close the umbrella or call the class resolved before live acceptance is observed.
- [ ] Preserve task clones until origin contains every local artifact and no active work remains.

## Blast radius and rollback

Costly: every development PR's post-merge bot and its lifecycle/ledger outputs depend on this gate.
Shield: opt-in --qualify in the existing serialized workflow; legacy callers retain their behavior.
Tripwire: first hosted suite failure, missing/incorrect receipt or rejected push remains visible and
blocks closeout. Investigate through debug-mantra, with at most two fix/review cycles before replanning.
Rollback: revert the producer/workflow commit and preserve committed historical receipts; no DB schema
migration. Recovery uses fresh state after a push race, never rebases generated SQLite bytes.

## Lessons Learned (For Future Agents)

Ship a gate's producer, consumer and recovery path together. Git hook writes do not amend pushed
objects. A successful exit without complete telemetry is insufficient. The suite tests the integrated
snapshot containing a landing, not necessarily the historical merge commit. Public-repository runner
cost differs from the private-phase comments. A post-merge gate cannot protect the pre-merge boundary.

## Review and rollout findings

Producer PR: [#599](https://github.com/HiQS-Labs/XYZ-forge/pull/599). Both fixes pass the full normal
pre-push gate, with retained isolated-retry disclosures. Recovery includes canonical document lookup,
malformed telemetry diagnostics, exact process binding and isolated Git fixtures. The pending batch
read identified 18 closing issues across 24 merges; it did not execute downstream ledger/planner
writes. Existing express ownership is #592 / PR #597, with bounds #594. Ad-hoc direct pushes and the
observed full-gate environment/contention gaps have concrete issue drafts awaiting outward-action
approval. No umbrella closeout or clone teardown is authorized by local validation alone.

Agy sequential PR QA approved producer #599 and found the remaining loose filename match in the
pre-merge path while reviewing #600. The regression witnesses false ambiguity for active tasks and
a skipped canonical-document validation for completed tasks, in both GH-N- and N- naming forms.
The three-line correction aligns both lookups with the post-merge matcher and sorts completed
candidates. Focused evidence: 25 GH-421 tests and existing GH-496 pre-merge checks pass; retained
red/green logs and non-qualifying provenance are in the GH-584 campaign. Both Agy relay reviews are Approved with driver attestations. The normal full push gate for
correction 4cdb82a2 passed 374/374 in 896 seconds and published it to PR #600. The live relay
self-sufficiency suite failed in the pool and passed the built-in isolated retry without source
changes; the cause is unproven, and both outcomes are retained. This remains local push evidence,
not hosted qualification. See agy-qa-full-prepush.log and its diagnostic telemetry in that campaign.


### First hosted run — bounded correction cycle 1

PR #599 landed at `38507a23303bebab6184607b15e3099cc2dd88e3`. Automatic run
[34778194670](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/34778194670) failed after 50 minutes:
six suites failed and rollback prevented publication of a passing receipt. Five failures reproduce
in an independent clone with a fresh Python environment, absent agent clients, three reported CPU
cores and `GITHUB_ACTIONS=true`. The small correction adds the declared requests/PyYAML dependencies
to both existing full-suite workflow environments; fixtures supply their own client binaries,
exercise explicit three/eight-core cases, and select local Actions state themselves. No assertions
are skipped. The bridge suite passes locally through the exact bounded qualification launcher;
its hosted cause remains unproven. Its existing startup probes now capture a Python stack before
the unchanged deadline so another failure can identify the blocked operation.

This changes the landing dependency: #600 carries the runner corrections needed to qualify the
already-landed producer. Waiting for unchanged #599 to become green cannot restore the missing
dependencies. Land the reviewed correction only after the normal full gate; then observe the
automatic recovery run. Preserve the failed run as evidence; never count it as acceptance. The
three-consecutive-merge and scheduled-sweep criteria remain open.

Agy approved the bounded runner correction in a single relay turn, driver-attested at
`d442bf64` (reviewed source `b1983192` plus the review scaffold). The full gate remains the
pre-merge boundary. The bridge diagnostic probe passes 43/43 locally; that result does not
establish the hosted failure cause or replace automatic acceptance.

The normal full push gate for `b1983192` passed 374/374 in 1224 seconds, without bypass.
The registry concurrency fixture lost one of 16 rows in the pool and passed its built-in isolated
retry unchanged; the cause is unproven. Both results are retained. An earlier diagnostic attempt
was stopped because the driver's worker-count override invalidated the default-setting fixture;
controlled red/green proves that attribution, and no source change was made for it. This remains
local evidence; automatic qualification after the dependent merge is still pending.

## Merge evidence

- PR #597 merged 2026-09-15 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #598 merged 2026-09-15 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
