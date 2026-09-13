---
title: End of Week skill — build plan
status: In progress
created: 2026-09-13
updated: 2026-09-13
owner: Codex
goal: Update Project Kanban and begin governance automation script recalibration.
gh_issue: https://github.com/HiQS-Labs/XYZ-forge/issues/606
branch: feat/end-of-week
effort: 2
complexity: 3
risk: 3
phases: 2
reversibility: Easy — instructions-only artifact; future writes retain before/after evidence.
---

# End of Week skill

## Status

| What was just completed | What's next |
|---|---|
| Requirements resolved; current-source recon mapped existing readers and writers. | Independent plan QA, then author and verify the skill. |

## Table of contents

- [Phase 1: Contract and plan QA](#phase-1-contract-and-plan-qa)
- [Phase 2: Skill and verification](#phase-2-skill-and-verification)

## Problem and requirements

A weekly governance review must connect activity evidence to corrected canonical
metadata and a verified kanban projection, while turning automation gaps into actionable
follow-up. Existing CLI entry points have different semantics, fail-soft outcomes and
machine configuration; a plausible generic sync recipe can write the wrong state.
See [the Recon Map](recon-end-of-week.md) for measured seams and limitations.

The six tasks, in order, are: check reconciliation on GitHub's configured default branch;
reconcile if needed; compare RebalanceOS HiQS/local git/origin git with PDDA, RELEASES
SQLite (operator calls it PRS), and XYZ metadata; file an umbrella issue; correct metadata;
update/read back kanban. Goals: update Project Kanban and begin script recalibration.
Default window is seven days ending at a recorded UTC start time. Current-state blockers
remain visible even when their origin predates the window.

Invocation authorizes ordinary additive issue creation, verified metadata correction and
configured board updates. Up to ten ranked evidenced gaps carry diagnosis, prognosis,
recommendation, confidence, relevant script seam and verification proposal. Fewer than ten
is valid; never invent gaps. Prefix Critical for substantiated corruption/data-stability
threats and High priority for blockers, with severity rationale and matching existing labels
when available. Script changes stop at recommendations. Same-window retries reuse the
weekly issue; a new reporting window can open a new umbrella linked to prior unresolved work.

The contract recital appears at startup, after compaction and once at initial completion.
The first completion is an audit checkpoint: check all six tasks/two goals against evidence,
resume only missing in-scope work, and finish with partial/blocked outcomes if needed. Do not
restart the whole workflow, refile the issue, or repeat the completion recital indefinitely.
Keep the canonical issue/run pointer and verified progress in handoff context.

Mid/high-capability models are the audience, including the operator's examples Astra,
Sol High, Fable/Opus and Gemini Pro 3.1. No hardcoded model IDs, provider flags, model
installation, compatibility claims or dependency on a particular agent runtime.

## Design choice and blast radius

Chosen: one `skills/end-of-week/SKILL.md`, optionally one focused reference only if needed,
and a skills-index entry. Existing readers/writers carry all execution. Alternatives:
(a) a new orchestration CLI duplicates writers and exceeds the request;
(b) report-only mode misses the board-update goal;
(c) unconditional reconciliation/backfill risks stale evidence and unsupported branches;
(d) raw board mutations bypass the canonical writer. Strongest counterargument: installed
versions vary. Resolve runtime capability and explicitly report unsupported operations.

Easy authoring rollback: revert only this task's committed docs. Future invocation spans
shared metadata/board state and is low-medium operational risk: record stable IDs, prior
values, intended changes, resulting values and corrective writer actions. Re-read before
writes to detect concurrent changes; preserve operator overrides and unrelated cards.
Do not auto-merge PRs, promote releases without proof, change repository default branches,
force a reconciler, clear kill switches, install schemas, or edit governance scripts.
No public personal paths/config/HiQS private text. Read Rebalance evidence without writes.

Two root values are explicit: target consumer repository and installed harness. Discover
origin identity/default branch through GitHub, not current checkout or origin/HEAD alone.
Resolve board settings through the existing config reader (including a user-supplied
XYZ_DEVICE_CONFIG_PATH); don't assume repo .xyz and user .xyz are equivalent. Verify target
repo against effective connector repos[0], which is the current writer's identity boundary.
No new end-of-week config schema. Missing settings prompt only for the missing value.

## Phase 1: Contract and plan QA

**Goal:** A grounded, independently reviewed instruction contract.

1. Register issue/ledger and recon, rate the task through RELEASES, and commit the plan inputs
   → expect exact source seams, preserved public portability and read-back of registration.
2. Run a Codex plan relay using relay-xyz, with reviewer writes limited to its relay file
   → expect Approved, or record the blocker and stop before implementing. Maximum three rounds.

### Phase 1 — QA checklist

- [x] User decisions and six-task/two-goal contract captured.
- [x] Current source distinguishes HiQS ranked actions from search, issue kanban from release cards,
      work-start sync from lifecycle replay, and consumer root from harness root.
- [ ] Ratings read back and independent plan QA Approved.

## Phase 2: Skill and verification

**Goal:** A portable skill with a complete evidence-to-board loop.

3. Author the skill against the approved contract and add its normal skills-index entry
   → expect only instructions/doc integration; no new runtime, global install or weekly sweep.
4. Walk the acceptance scenarios below with explicit expected decisions; run relevant doc hygiene,
   skill validation and path/privacy checks → expect all six tasks, two goals and capability/refusal
   branches covered. Preserve evidence and limitations; no live mutation for a documentation test.
5. Run final Codex relay on committed artifact and evidence; resolve findings within three rounds;
   publish the reviewed PR to development through the required gate → expect final head/base verified,
   no routine generated views committed, no claim of merge or live board success.

### Acceptance and falsification

| Scenario | Required behavior | Red control / evidence destination |
|---|---|---|
| User's default branch is main; installed reconciler accepts development only | Report unsupported-target gap; inspect/correct only through supported writers on intended branch | Reject a recipe that substitutes development or skips branch guard; QA transcript |
| Vendored harness plus external/repo-local device settings | Use consumer root and effective config; no personal paths/board IDs; validate repo match | Wrong root or another repo in repos[0] must stop board writes; QA transcript |
| HiQS cache missing/stale/empty or no connector | Continue independent sources, report missing coverage; never infer no work | Empty source cannot produce a fully verified result; QA transcript |
| Ready/open PR vs merged PR vs completed metadata | Preserve distinct lifecycle evidence and use configured status_map | touch/reconcile work-start recipe must not move completed cards back; QA transcript |
| Writer exits zero but logs FAILED or cursor stalls | Report failed/partial board outcome and read back actual cards | A zero-only success assertion is rejected; QA transcript |
| Seven-day review, source results paginated/truncated | Record exact bounds, retrieval completeness and ongoing old blockers | Missing page / top-k cannot support exhaustive no-gap claim; QA transcript |
| No material gaps | Report zero with coverage evidence; weekly umbrella is truthful status record | Padding list to ten fails; QA transcript |
| Same-window resume and first completion | Reuse issue, keep progress; one completion audit; no endless re-run | Duplicate issue or repeated full sweep fails; QA transcript |
| Corruption/blocker finding | Critical/High priority title justified by evidence; script remediation recommended only | Unsupported severity or script edit fails; QA transcript |
| Authoring privacy / no live actions | No operator paths/config/raw private source content; no live weekly writes for tests | Forbidden literal inserted into temporary candidate must fail privacy check; committed validation summary |

New deterministic validation will include a witnessed negative control; prose scenarios
are reviewed decisions, not claims that a live agent run was tested. Store sanitized
validation and provenance under `TESTS-RESULTS/2026-09-13+GH-606/`. Mutation-heavy gates
run only in a separate disposable full clone with before/after identity comparison.
Debug-mantra governs diagnosis if a check fails: reproduce, trace, disprove, reconcile evidence.

### Phase 2 — QA checklist

- [ ] Skill and index entry created; no runtime or machine settings added.
- [ ] Acceptance decisions reviewed; deterministic doc/privacy checks passed with red control.
- [ ] Final independent QA Approved; PR ready and verified against final head.

## Ratings and limits

Proposed RELEASES rating: 70/40/50/70 (priority/severity/neutral appeal/cheapness).
Useful governance workflow with medium cross-system reasoning; this authoring task is not
itself a demonstrated corruption incident. Recurrence trend unknown: no incidence-rate
claim, and existing board/reconciler issues are context rather than new incidents.
Live board config was unresolved in this session; the skill must report that at invocation,
not ship the author's identity as a default. HiQS was traced read-only, not refreshed.
