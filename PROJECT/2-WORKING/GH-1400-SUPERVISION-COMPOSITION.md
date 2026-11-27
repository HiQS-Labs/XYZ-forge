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
| PR #1403 instruction slice preserved; bounded Jog wake implemented with focused verification and review corrections. | Complete independent implementation QA and classified full gate, then publish a separate implementation PR. |

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

Implementation review correction (2026-11-15): supervised clone alignment also holds on a detached HEAD, preserving its unique commits in place. Explicit resume holds when the newest recorded gate retry lacks a valid matching result. Gate retry records its exact identity and result path before dispatch, so an interrupted retry remains visible without adding a new ledger.

## Follow-up — task-local failure continuation (2026-11-16)

Authorized after the dogfood round (#1400 comment 6909393598): fix the existing supervisor so a
provably task-local failure no longer halts independent ready work, and run the missing restart and
global-stop controls before any readiness claim. Same branch and PR #1491; the dogfood runtime pin
`1d9658c3c63c1b1a8780ad26e4962f808b3c7625` stays in history and its runtime clone is untouched.
Budget recorded 2026-11-16T17:32Z: setup+implementation at most 3 h (to 20:32Z); plan QA and final
QA at most 3 rounds each; at most 3 repair rounds per distinct blocker; synthetic controls 15 min
smoke, then 15 min of variations only if the smoke passes. No real builder dispatch, merge, deploy
or API fallback. Reviewer: Claude subscription through the existing relay harness.

### Observed problem

`jog_run_main` (supervised Marathon branch) projects the run's action and, for `failed`, prints
"stopping queue execution on task failure" and breaks. Wake 1 stopped at GH-1023 whose receipt was
`escalated` / `pre-advance-failed` / exit 5 / gate `red` with no PR; GH-1049 exec1 had the same
shape. `run_marathon_phase` returns `failed` in three different situations: (a) a valid,
identity-matched receipt whose outcome is not approved/parked (`projected-failed`); (b) no valid
receipt (`no-valid-result`, unknown outcome); (c) the clone's ledger artifacts changed
(`clone-ledger-changed`, shared clone contamination). Only part of (a) is task-local.

### Classification (fail closed)

A supervised wake continues past `failed` only when all hold, read back from durable state:
the ledger's newest execution is the one just dispatched (count = prior + 1) with status
`projected-failed` and recorded outcome `escalated`; its receipt reloads and validates, matches the
issue and execution id, names this execution target, has outcome `escalated`, reason
`pre-advance-failed`, exit code 5, gate result `red` and no preserved approval. The reason pins
the one escalation where the gate ran and found a defect (`marathon_drive.py` GH-390/GH-407);
`gate-killed` (resource guard, same exit 5 and gate red) is a shared-host condition and stops. Anything else, including a load error, stops as today. Not task-local
by construction: `lock-contention` (ownership), `interrupted`, `crashed`, `refused`,
`post-approve-failed`, `gate-killed`, any other escalation reason, an escalation whose gate did not
run red, no/corrupt/mismatched receipt,
clone ledger change, deadline expiry and any exception. Legacy relay drive failure and the
non-supervised checkpoint path keep breaking (scope is supervised real Marathon).

Why this is safe: the failed row is already `failed` with its reason and receipt path persisted by
the canonical writer before the decision, so it is never reselected or retried; `tasks_processed`
was counted at lease and the deadline check runs first each iteration, so neither budget resets.
The next dispatch still passes every shared check first: `_jog_align_target` takes the execution
clone's conservative lock (a live or SIGSTOPped owner exits 4; unknown owner holds), refuses
tracked dirt, detached HEAD and dependent worktrees; `_validate_execution_target` refuses ledger
changes. A task failure never skips those checks. Limit: a gate red caused by a shared environment
defect (wake 1's leaked reviewer variable) is indistinguishable from a task defect here; it can
cost later tasks one attempt each, bounded by `--max-tasks` and the deadline, never a retry.

Dependency: Jog has no dependency graph. A dependent task is held by preflight readiness
(refusal parks it without a builder and halts the wake, unchanged); earlier `parked`/`failed`
rows are never selected. Restart (requirement 3) and global stop (requirement 4) reuse existing
code (`JogCheckpoint.begin(recover=…)`, `_jog_supervise_recover`, `JogSupervisorLock`); this
follow-up adds no code there unless a control fails.

### Smallest change and non-goals

One helper in `utils/py/jog_run.py` implementing the classification above and one branch in the
supervised loop that continues with a message naming the retained failure. No new ledger,
status, flag, queue, daemon, retry, test suite or registry entry. No change to legacy drive,
recovery, checkpoint publication, preflight or Marathon. Docs: `skills/2-daily/jog/SKILL.md`
supervision paragraph and `CHANGELOG.md` entry updated in the same change.

### Controls (manual, `TESTS-RESULTS/2026-11-16+GH-1400/`, real `releases_app.py jog run` entrypoint)

Reuse PR #1491's retained `check.py` fixture (synthetic primary/remote/execution clone, controlled
preflight and worker, no provider) by exec as its other scripts do, adding a publication clone for
`--checkpoint-root` and a per-issue worker outcome. #1477's simulator is not reused: it exercises
the tick kernel through an adapter, not this entrypoint; its two scenarios are adapted here.
Every wake uses `--supervise-until` and `--checkpoint-root`. Each record carries the source HEAD.

1. `local-failure-continues`: A escalates `pre-advance-failed` gate red, worker leaves the lane
   committed and clean; same invocation dispatches B once; A `failed` with reason and receipt path,
   attempt 1; checkpoint published. `no-reentry-next-wake`: a second wake runs C, never A.
   `local-failure-dirty-holds`: A's lane left tracked dirt; alignment holds, B undispatched.
2. `budgets-held`: same run, `--max-tasks 2`, C pending: C undispatched, attempt 0.
   `dependent-not-dispatched`: order A(red), B pre-parked (held), C ready, D preflight-refused,
   `--max-tasks 4`: A and C dispatched once, B and D never; D parked and the wake halts there.
3. `restart-adopts-once`: worker writes an approved receipt and SIGKILLs the supervisor before
   publication/acknowledgement; restart adopts A without a builder (starts count unchanged), attempt
   retained, then B runs once. Variants `restart-missing` / `restart-corrupt` hold A (parked,
   "supervision held", one start) and B is dispatched once. The killed wake's worker must have
   exited before the restart.
4. `stop-owner`: after A's task-local failure a SIGSTOPped peer owns the execution clone lock; the
   wake stops (exit 4), B undispatched; after the owner is gone the next wake publishes A's failed
   row through journal recovery, then runs B once. `stop-checkpoint`: a contradicted journal
   (foreign primary commit) refuses before any dispatch. Mid-wake checkpoint contradiction is not
   checked between tasks (unchanged; `finish()` catches it afterwards). Fail-closed red, each with
   B undispatched: `gate-killed` (gate red, exit 5), `post-approve-failed`, `refused`,
   `interrupted`, `lock-contention`, `crashed`, escalation with gate not run, missing receipt,
   corrupt receipt, mismatched execution id and clone ledger change.
5. `baseline-red`: the unfixed `1d9658c3c` `jog_run.py` on control 1's fixture leaves B
   undispatched. Aggregation requires an explicit nonempty unique list; missing/failed rejects.

Each control also asserts no duplicate worker (per-issue start counts). The run records the
verify clone's HEAD, origin, `core.bare`, local identity and tracked status before and after and
refuses completion on drift or tracked edits; the baseline records its git blob id. Existing focused suite: the Jog–Marathon
integration suite run in a disposable full clone. Final gate selected by `utils/ci-route.sh`.

Unproven after this follow-up: production providers, real gate environment classification,
power loss, context continuity, external exactly-once, PID reuse and the clone state a real red
gate leaves (a tracked-dirty lane holds rather than dispatching).

### Rating

Existing row retained (75/60/50/45, no override); this is the same task's scoped repair, so no
re-score. Recurrence: one observed incident (wake 1); trend unknown.

### Follow-up current state

Plan QA PASS round 2/3 (Claude). Implementation `720b9c9a5`: helper `_jog_task_local_failure` and
one continuation branch in the supervised loop; jog skill and CHANGELOG updated. Controls complete
23/23 (smoke and repeat) at `7f946cd1d`, two failed fixture attempts retained, existing Jog–Marathon
integration 227/227; see `TESTS-RESULTS/2026-11-16+GH-1400/SUMMARY.md`. Final QA and the classified
gate follow on the final commit. #1400 stays open.


## Current outer-loop delivery alignment — 2026-11-16

Canonical Issue #1400 now records 35% milestone completion. The next 20 points are OL-14 (this integrated supervisor verified, reviewed, checked and landed), OL-09 (raw daily-goal preparation through Issue #1476), OL-10 (actual readiness admission through Issue #1476), and OL-12 (integrated task-local parking/independent continuation). Each earns five points only on its own evidence; this PR does not close the umbrella or all four milestones.

The operator authorized finishing review/checks and landing PR #1491. Combined candidate `dc3035c18` includes development `f346d8908`; existing runtime files were unchanged by that merge, but combined-head qualification remains required. Preserve prior review/attempt records. This documentation update changes no runtime acceptance. Verification, current-head independent review, publication and the normal merge-cleanup owner precede a landed claim.

OL-09 preparation may advance independently during an external OL-14 wait. It retains raw daily-goal intake, bounded medium research by default, justified deeper research, reused applicable evidence, explicit holds and opt-in risk deferral. OL-10 remains separate actual-admission evidence; no prose-only completion claim. Do not add a queue, readiness database or daemon. Issue #1399 attempt enforcement remains required before complete workflow qualification, not an expansion of this implementation slice.

Later qualification shares evidence across at most two planned bounded real runs and includes operator/global stop, preserved holds, useful outputs, intervention counts and restart/handoff. Recheck observed harness obstacles rather than assuming them fixed. Report synthetic, assisted, integrated and landed evidence distinctly. Skill deployment and unrelated merges remain outside this authorization.

## Merge evidence

- PR #1491 merged 2026-11-17 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #1514 merged 2026-11-19 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #1521 merged 2026-11-19 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #1495 merged 2026-11-20 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #1497 merged 2026-11-20 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- commit 5ae212b21380 landed 2026-11-16 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #1589 merged 2026-11-24 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #1621 merged 2026-11-26 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## GH-1633 — exhausted lane continues to the ready successor (OL-12, 2026-11-26)

Flywheel Day 2 (#1610) exercised a supervised wake with a ready successor behind each case, on the real
Jog → Preflight → Marathon path with the worker edge stubbed (GitHub responses, git transport and fixture gates are shimmed too). Task-local red gate, a human hold and a
shared stop already behaved as required; a row at its native lane-attempt cap halted the wake with the
successor never started. `_jog_lane_exhausted` in `utils/py/jog_run.py` now treats only a valid,
identity-matched cap receipt written after dispatch (parked, the drive itself exited 8, count at cap, gate not run, no PR,
same execution clone) as task-local; any other parked Marathon result still halts, except the already documented
published-approval continuation and the pre-lease human-hold park. Evidence and the red-then-green controls are under
`TESTS-RESULTS/2026-11-26+GH-1610-day2/`. OL-12 credit remains the operator's call after review of that
evidence and the live run recorded on #1610.

Operator decision recorded on #1610 (2026-11-26): an identity-matched, current `cap-stalled` receipt (reviewer
round cap, Marathon exit 4, gate not run, no PR) is also a qualifying task-local outcome; `_jog_review_cap_stalled`
implements it beside `_jog_task_local_failure`. Both new predicates share `_jog_receipt_is_current` (the drive's own
exit status and a receipt newer than the recorded dispatch instant) and Jog sets any receipt already at the result
path aside before dispatching. Shared stops (`cap-or-close-mismatch`, `no-progress`, refusals, crashes) still start
zero successors. Open finding at the review cap: a delayed receipt from an older concurrent Marathon process on the
same execution id could still be mistaken for the current one; two live drives in one clone are excluded by the
clone driver lock, so it was accepted open and is stated in the PR.

## Merge evidence

- PR #1647 merged 2026-11-27 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #1669 merged 2026-11-27 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
