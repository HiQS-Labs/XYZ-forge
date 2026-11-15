---
gh_issue: 1400
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1400
title: Economical flywheel composition
status: In progress
created: 2026-11-09
updated: 2026-11-15
owner: Codex
goal: Reduce downstream supervision by composing existing owners without new machinery.
doc_type: project
effort: 2
complexity: 2
risk: 2
phases: 2
---

# GH-1400 — Economical flywheel composition

## Status

| What was just completed | What's next |
|---|---|
| PR #1403 instruction slice merged; fresh implementation recon identifies Jog recovery/alignment seam. | Independent plan QA for the separately authorized implementation slice below. |

## Quad Concepts

- Repeated landing nudges → one approved pinned batch owned by merge-cleanup.
- Idle polling → exact-result native continuation when supported.
- Accounting reconstruction → retain owner receipts and disclose the GH-1399 enforcement gap.
- Upstream ambiguity → preparation signal revalidated at actual pickup.

## Table of contents

- [Phase 1 — Recon and plan](#phase-1--recon-and-plan)
- [Phase 2 — Delivery and verification](#phase-2--delivery-and-verification)

## Phase 1 — Recon and plan

Observed problem: GH-1400 proposes reducing the supervision tax seen in GH-1386.
The existing runtime already pins batch selection, rejects stale heads, bounds repairs
and records landing outcomes. Flywheel currently links these owners but does not explain
how to hand off an entire approved batch or choose an event-driven continuation.

Recon: [map](recon-gh1400-supervision-composition.md). No graph tool is installed;
lanes A/B/C/D were read in this agent's context. Parent accepted this disjoint scope.

Outcome sought: fewer redundant supervisor turns while retaining actual approvals,
head identity, bounded recovery and honest remaining work.

Smallest viable bet: extend only `skills/2-daily/flywheel/SKILL.md` with a compact
composition contract and update its existing steps to use it. Reversibility: Easy;
revert the instruction patch. No persisted schema/runtime contract changes.

Alternative rejected: a new runner, scheduler or accounting guard duplicates existing
owners or takes GH-1399's scope. Existing links alone omit the concrete handoff,
wait identity and partial-result handling that this change supplies.

Blast: current radius is flywheel callers, merge-cleanup batch records, native wake
facilities and Jog pickup. Added radius is instruction-following sessions using the
new handoff. A mistaken claim of blanket merge approval or enforced accounting could
cause unauthorized landing or false confidence, so both are explicitly excluded.

### Requirements and boundaries

| Requirement | Delivery | Held dependency / limitation |
|---|---|---|
| Batch landing without stepwise nudges | One exact approved pinned allowlist; existing driver owns sequence/reconcile/outcomes | No merge is authorized by this task; changed heads need renewed eligibility/review. |
| Event-driven continuation | Prefer native PR watcher or delegate completion; bounded same-chat timers only where supported | No runtime-specific tools installed or scheduler armed. |
| Fail-closed accounting | Reuse existing durable owner records; expose missing accounting before work | GH-1399 remains OPEN; this change does not implement push/gate enforcement. |
| Upstream conveyor composition | Readiness is preparation signal; execution owner explicitly selects/revalidates | GH-1401 is independent; no new label consumer or automatic admission. |

### Rating rationale — 2026-11-09

PRS read-back: rated 75/60/50/80, no operator override. Priority reflects requested
factory throughput work; severity reflects repeated supervision cost rather than
proven data loss. Appeal stays neutral 50. Cheapness 80 reflects an instruction-only
change on existing owners, not the cost of the entire arc.
Recurrence windows: 2026-10-27..2026-11-09 versus 2026-10-13..2026-10-26.
GitHub title/body `flywheel` search returned 20 versus 1 updated issues; these are
search hits, NOT independent incidents or a velocity claim. Concrete recent examples
GH-1386 and GH-1399 report manual progression/accounting reconstruction; older coverage
is incomplete, so trend is unknown. Prior-art exact-seam search found only GH-1400,
no merged fix candidate; existing GH-1376 source supplies the base to extend.

### Ordered implementation and acceptance

1. Commit plan/map and obtain Codex plan QA → require Approved before implementation.
2. Record accepted-start through the exact owned PRS row; extend flywheel's existing flow → no new runner, runtime, tests or gates.
3. Read consumer entry and exercise main/adjacent instruction scenarios → approved two-PR batch delegates once; pending changed-head or missing-accounting paths stay held and never silently advance.
4. Classify final paths, run existing applicable gate and independent final Codex QA → retain provenance and Approved review; publish PR against development, leaving arc dependencies open.

Phase 1 QA: map findings integrated above; independent Codex plan review Approved in `relay-system/2026-11-09/gh1400-plan.codex.md` (driver exit 0).

## Phase 2 — Delivery and verification

Non-goals: implementing GH-1399, creating conveyor, modifying merge-cleanup/runtime,
landing real PRs, deployment, changing policy/caps, new suites or gate machinery.
Verification uses existing route and manual instruction checks with provenance under
`TESTS-RESULTS/2026-11-09+GH-1400/`. No speculative frameworks, fuzzers or synthetic runners.
No new decision gate is introduced; refusal scenarios check the instruction's meaning.
Dogfood/conformance follow-ups are bounded here as main/adjacent instruction reads;
the broader real-work qualification remains owned by GH-1386 and the full arc remains
open pending its dependencies. This is a small instruction extension, not a large refactor.

Phase 2 QA: textual main/adjacent instruction smoke PASS; docs gate at 37119562c returned 0 (659 inherited warnings), identity unchanged; final relay Approved and attested at `relay-system/2026-11-09/gh1400-final.codex.md`. No runtime/cost-saving qualification claimed.

## Lessons Learned (For Future Agents)

Edit verdict: flywheel instruction extension — no observed effect on real-world throughput (only textual smoke was run). NO_ENTRY: instruction review alone cannot establish a throughput gain.

## Integration repair

Remote development advanced to d526eef7 during publication. The first normal push
passed its docs hook (79s). A disposable-clone merge exposed only releases.db/sql
conflicts; the existing B1 classifier confirmed disjoint changes, and its writer
replayed the owned GH-1400 row with ratings and accepted-start. Resolver and PRS
checks passed, producing 7eb672f5; no source/skill bytes changed after final QA.
One integration repair, no cap reset or bypass. Retained record:
`TESTS-RESULTS/2026-11-09+GH-1400/integration-repair.json`.

## Published-PR readiness repair after extra Opus QA

Development advanced to 995af060 after the additional Opus review. B1's preview
refused to replay two Jog queue rows from the lower-generation integration side;
that refusal is retained, not overridden. Manual governed composition kept the full
integration ledger, replayed only the isolated GH-1400 row through the existing
`replay_ops` writer (add, rate, section/marker, accepted-start), then ran the existing
resolver/check. Generations 2511/2508 became 2513 without an arbitrary bump.
Every integration Jog row and pre-existing roadmap row stayed unchanged; owned
semantic fields and approved skill hash stayed unchanged. Routine leaderboard bytes
match integration. No source or helper changes, control bypass, new QA or new suite.

Repair accounting is explicitly retrospective: the first pre-publication integration
and this readiness repair consume 2/2 existing per-PR slots. The reminder arrived
after this repair command started; no advance reservation is claimed. No further
repair allowance remains. Retained refusal, invariants and accounting snapshot are
under `TESTS-RESULTS/2026-11-09+GH-1400/`.

## Merge evidence

- PR #1403 merged 2026-11-10 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).


## Implementation slice — 2026-11-15

This is newly authorized runtime work, separate from the completed PR #1403 instruction
slice above. Its historical scope and exhausted 2/2 publication repairs remain unchanged.
New limits: three repair rounds per blocker and three rounds each for plan/final review.

Capability: replace Spike 0's agent-issued resume and clone handoff with one bounded,
operator-invoked Jog wake that adopts an approved result and advances eligible pending work.
Critical path: eliminate reconstruction of existing execution receipts and safe branch alignment.
Evidence/budget: real CLI main/restart paths plus discriminating controls in the disposable
verification clone; no model dispatch, scheduler installation, LTVera changes or merges.

### Recon and solution fit

Base `7dd85cd3a55303818ce61cbcc5d89b246d4a6449`. Existing owner is
`utils/py/jog_run.py`, reached through `releases_app.py`'s `jog run` parser/handler.
`JogCheckpoint.begin` recovers an interrupted wake but calls cold projection without
publishing an approved receipt. `jog_resume` can publish it, but is a separate command.
`jog_run_main` switches a clean target to local development only with checkpoint mode;
it neither refreshes that branch nor preserves an ahead development before realignment.
`run_marathon_phase` already writes the execution record/result path before dispatch,
then consumes Marathon's result and publishes it. Marathon owns lane attempt caps; legacy
orphan recovery also parks at queue attempt_count >= 3. Supervised recovery does not reset
either history or remove that legacy threshold.

Verify graph: current project `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation
2026-11-15T07:36:58Z; jog_run_main/jog_resume direct both-direction traces and exact snippets;
coverage for jog_run, releases_app, harness and proc_group reports metadata_match/no recorded
gap (best effort). Trace contains heuristic false edges; exact task-clone source is authority.
Prior-art thin-supervisor search found #280 (implemented underlying Jog owner) and #1081
(exploratory shift proposal), plus #1474/#1477. Neither establishes this composition behavior.
No overlapping open PR matched. #1360 health monitoring and #1254 prototype are different owners.

Observed baseline: #1474 comment 6890286495 adopted #1098 without a rebuild, then ran #1099
while #1098 awaited landing, but required manual preservation/alignment. #1477 reviewed
artifact 55ed01192c3c58a9fc8716588515f3fd3e36917f supplies failure-model evidence, not production
code or acceptance authority. Its independent witness assumes isolated note loss; no correlated
rollback, power-loss, PID-reuse, live-worker recovery or context-continuity guarantee is imported.
Attribution: Agent Orchestrator's durable result adoption and explicit waiting-state concepts
in #1474 inform this composition; no AO source is copied.

Smallest viable bet: add opt-in `jog run --supervise-until <UTC epoch seconds>` to the existing
runner, requiring a positive `--max-tasks` and real Marathon executor. Existing manual run
behavior remains available. This is one wake, not a daemon or skill/plugin interpreter.
Reuse queue/state/checkpoint writers, preflight, receipt publication and proc_group cancellation.
Alternative: documenting resume + handoff leaves the demonstrated intervention unchanged.
A separate supervisor service would duplicate queue/attempt/receipt ownership and is rejected.

### Contract and boundaries

- Operator supplies an absolute deadline and finite task-selection limit. Deadline bounds new
  dispatch and preflight/worker subprocesses; the existing publication gate retains its own
  bounded clock. Cleanup/publication may finish after dispatch cutoff and are reported separately.
  A wake never allocates a retry, resets native attempts, or treats queue attempt_count as budget.
  An interrupted dispatched item without an exact valid result holds; retry-build remains explicit.
- Under the existing primary driver lock, reconcile orphaned executions before selecting pending
  work. Adopt only the latest execution's matching issue/execution result; approved receipts use
  existing publication validation before projection. Invalid, missing or mismatched evidence holds
  visibly without a builder. Malformed existing execution state must refuse, not become fresh state.
- Execution-clone alignment takes its existing driver lock. A live or stopped holder blocks; an
  initializing/unknown lock blocks. Preserve tracked dirty work by holding. Preserve every branch
  and untracked file. Fetch development; switch to development only when safe. If local development
  has unique commits, rename it to a deterministic preservation branch before recreating development
  from origin. Never reset, clean, stash, delete refs, or discard logs. Git's untracked-overwrite
  refusal stays a hold. Refuse dependent worktrees. A retained branch is reported to the operator.
- Keep target lock during alignment only; Marathon owns target execution lock. Primary exclusion
  serializes Jog wakes; target's live driver blocks recovery/alignment. No arbitrary stale-owner
  killing. Recovery requires the previous execution owner to be absent. Cold-lock simultaneous
  reclaim and malicious PID reuse are not newly certified by this slice.
- Count every selected item toward max-tasks, including a preflight hold. Continue only after an
  exact newly published approved receipt with PR identity (existing checkpoint continuation rule),
  or after receipt recovery has placed the prior item at awaiting landing. Failed/uncertain rows
  stay visibly held; no automatic retries. Preflight remains the execution-readiness authority.
- RAW requests still enter Conveyor/preparation, never `jog add` as raw prose. #1476 owns medium
  research/default policy. No new queue, ledger, schema, framework, scheduler, model route or spend.
  No persistent agent context, external-effect exactly-once, automatic landing, live qualification,
  whole-machine containment or arbitrary corrupted-state recovery claim.

Blast radius: opt-in Jog wake, shared execution-state validation and resume receipt checking;
existing run/retry readers must continue to accept valid historical state. Reversibility: Costly
because orchestration crosses state and process boundaries; rollback disables the opt-in mode
and reverts code while retaining native queue, receipts, history and preserved branches.

### Ordered build and verification

1. Record the owned PRS rating with its canonical writer on primary, preserve override and prior
   accepted-start; commit plan/recon. Independent Codex plan QA must approve before production edits.
2. Add the opt-in parser/validation and composed recovery/alignment path within Jog, reusing owners.
   Early real CLI smoke in the verification clone must adopt A and select B without duplicate build;
   adjacent rerun must leave A's attempts/receipt unchanged. Stop/replan if this requires a second ledger.
3. Add bounded preflight/worker invocation through proc_group, retain dispatch state on cancellation,
   and report held/stopped outcomes. Controls: expired deadline, stopped owner, missing/mismatched
   receipt, malformed state, tracked dirty target, branch preservation, current readiness refusal,
   native attempt exhaustion and repeat wake. Each must observe no unintended builder/queue effect.
4. Run existing focused Jog/Marathon coverage as applicable and manual provenance checks only.
   No new test suites, registry entries, fuzzers or production simulator dependency. Retain pre-change
   red controls showing resume/alignment intervention and all failed attempts. Aggregate an explicit
   nonempty required-check list; missing/duplicate/failed checks cannot yield PASS.
5. Final exact-revision Codex QA, classify all changed paths, run the required final gate once in
   the disposable full clone with before/after identity. Publish gated PR to development; leave #1400
   open unless whole-issue coverage is independently established. Parent owns CI monitoring/cleanup.

### Rating rationale — implementation

Primary writer read-back 75/60/50/45, retained override null: priority/severity reflect demonstrated
supervision/recovery cost, not proven irreversible loss; neutral appeal; lower cheapness reflects
runtime recovery and validation rather than the old instruction-only patch. Recurrence window
2026-11-02..15 versus 2026-10-19..11-01: #1474 is one concrete assisted run, #280 is older foundation,
#1477 is synthetic evidence, not another production incident. Trend unknown; no inflated count.

### Acceptance and current state

Plan QA Approved round 1/3 at 592f6c6457a3, driver exit0; receipt
`relay-system/2026-11-15/gh1400-implementation-plan.codex.md`. Nonblocking queue-threshold
nit accepted above. Primary accepted-start read-back: already active, original start preserved.
Implementation in progress; no runtime acceptance or qualified final gate claimed.
Required checks: real wake adoption/continuation; adjacent repeat; readiness red; result identity red;
missing-result hold; malformed state hold; stopped-owner exclusion; deadline/cancel; attempt retention;
safe branch/log preservation; explicit complete evidence aggregation. Gate/review remain separate.
