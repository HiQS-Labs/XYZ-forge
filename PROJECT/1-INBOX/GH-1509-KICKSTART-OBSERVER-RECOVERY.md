---
gh_issue: 1509
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1509
title: "GH-1509: Kickstart: observer-led outer-loop child with bounded session recovery"
status: "Proposed (1-INBOX — plan QA pending)"
created: 2026-11-17
doc_type: feedback
owner: Agy
goal: Codify the operator's assisted factory pattern where invoking kickstart creates an observer/session-recovery parent delegating one outer-loop child.
effort: 1
complexity: 2
risk: 2
phases: 1
---

# GH-1509: Kickstart — observer-led outer-loop child with bounded session recovery

Canonical discussion: [Issue #1509](https://github.com/HiQS-Labs/XYZ-forge/issues/1509).
Related: Umbrella [#1400](https://github.com/HiQS-Labs/XYZ-forge/issues/1400) (OL-17 start/resume, OL-20 handoff), research [#1474](https://github.com/HiQS-Labs/XYZ-forge/issues/1474), raw preparation [#1476](https://github.com/HiQS-Labs/XYZ-forge/issues/1476), PR [#1491](https://github.com/HiQS-Labs/XYZ-forge/pull/1491) Jog supervisor.

## Status

| What was just completed | What's next |
|---|---|
| Provisioned task worktree and drafted 1-INBOX capture and plan | Independent Codex plan QA relay |

## The Preflight Bet Check (Solution-Fit)

- **Outcome sought:** Codify the operator's current assisted factory pattern: invoking `kickstart` starts an observer/session-recovery parent session that delegates the actual outer loop to exactly one child session, preserving parent supervision until the operator explicitly approves a less-supervised mode based on evidence.
- **Smallest viable bet:** Add a thin Forge-owned `kickstart` skill (`skills/1-hourly/kickstart/SKILL.md`) and register it in `ARCHITECTURE.md` (Skills Index). Reuses Flywheel, Conveyor, Jog, native delegation/completion events, and existing records. No deployed-copy changes in this task.
- **Alternatives rejected:**
  1. *Embedding into `flywheel`:* Flywheel owns adaptive loop execution within a single session / runner loop. Adding parent observer / child delegation / session recovery to flywheel would conflate the outer coordinator with the executing engine and add multi-role complexity to flywheel.
  2. *New daemon / background scheduler / supervisor service:* Prohibited by GUIDING-PRINCIPLES.md and AGENTS.md (no new queue, schema, daemon, or runtime service).
  3. *Direct unassisted child execution without parent supervision:* The operator pattern explicitly requires parent observer / session recovery with bounded assisted intervention; unattended qualification remains separate.
- **Rollback / containment:** Source-only markdown skill instruction addition. Revert via git revert if needed. No database schema changes, no new queue, no runtime services, no deployed-copy changes.

## Observed problem and scope

Currently, the operator's assisted factory pattern runs an outer-loop session where an observer/session-recovery parent coordinates work, while delegating the execution of the outer loop to a single child session. Without a codified skill:
- Role boundaries between the observer/recovery parent and the executing child are ad hoc, risking competing writers or duplicate execution.
- Daily-goal intake is sometimes confused with execution readiness; raw intake must route to preparation owners before execution admission.
- Interrupted or dropped sessions lack an explicit, bounded recovery protocol that checks process/lock liveness, avoids retrying unknown outcomes, and preserves remaining budgets.
- Task-local holds are sometimes escalated globally instead of allowing independent ready work to continue.

## Disjoint Parent vs Child Responsibilities

1. **Parent (Observer & Session Recovery):**
   - Resolves the target repo, raw daily-goals issue, selected scope/holds, exact mode, provider/subscription preferences, and existing budgets.
   - Records one child owner and durable handoff pointer.
   - Starts the outer-loop child through the host's supported delegation mechanism (`delegate_task` or platform native delegate). Never competing writers!
   - Observes native completion events, questions, or completion watches (no polling, no sleep loops).
   - If the host environment does NOT support the required delegation mechanism or completion event/watch: reports the missing capability explicitly, leaves a resumable handoff with pending state and next owner, and halts. Does NOT pretend, start a daemon/cron, or fall back to direct unassisted execution.
   - Handles session recovery on interruptions, pauses, or stops: verifies stopped ownership (including child-spawned builders and writers) before any redispatch; unknown state holds; never retries an unknown outcome; preserves original deadlines, attempt counters, and authority.
   - Performs explicit, bounded parent repair; reports assisted vs unattended truthfully.
   - Never merges, deploys, or updates installed skills without explicit separate operator authorization.

2. **Child (Outer-Loop Executor):**
   - Composes existing skills: Conveyor (raw intake & preparation), Flywheel (adaptive loop), Jog (serial execution & recovery), start-task (task execution), relay-xyz (independent QA).
   - Performs normal dispatch and evidence collection.
   - Follows the selected execution owner's exact continuation and stop semantics: on task-local holds, advances independent eligible ready work only when authorized by that owner's semantics (e.g. Jog GH-1400 wake permits continuing after a newly approved published PR or a validated exit 5 pre-advance-failed receipt, but halts on readiness refusal, lock contention, guard-killed gate, crash, missing/mismatched receipt, or clone ledger change).
   - On shared unsafe conditions (lock contention, git safety violation, ledger drift, exhausted global budget) or owner-mandated stops: halts dispatch immediately, leaves a resumable checkpoint, and reports to parent.
   - Never starts another competing child supervisor hierarchy.

## Daily-Goal Intake and Preparation Boundary

- Raw intake is permitted: daily-goal intake accepts raw requests, issue URLs, or backlog items.
- Routing to preparation owners:
  - If the input is already an existing GitHub issue (or issue URL), it routes directly to Conveyor (GH-1476) for preparation.
  - If the input is raw prose / uncaptured goal / new item with no issue, it first obtains an issue via the existing authorized issue-creation owner (e.g. `idea` / `gh issue create` / repository intake SOP) before entering Conveyor.
  - Conveyor prepares the capture doc, Preflight Contract, and PRS rating.
- No execution readiness claim from raw intake or issue creation alone: Conveyor preparation, documentation publication, and Jog pickup/admission checks must occur before execution admission.

## Lifecycle Handoffs and Recovery Protocol

1. **Normal Completion:** Child finishes batch/tasks, commits receipts, opens ready PRs, and returns completion event with summary. Parent inspects results, records completion, presents outcome to operator.
2. **Task-Local Hold:** One task encounters a blocker/question/decision hold. Child follows the selected execution owner's exact semantics: if permitted, records hold with concrete evidence (task ID, blocker reason, next owner) and continues to next independent ready item; if the owner halts on that condition (e.g. readiness refusal in Jog), halts the wake. Parent observes hold and next owner.
3. **Shared Unsafe Stop:** Global condition (lock held by unknown owner, dirty/divergent state, exhausted budget, missing capability). Child halts immediately, leaves resumable checkpoint with observed evidence. Parent assesses condition and coordinates resolution.
4. **Interruption / Session Recovery:** Session drops or process pauses.
   - **Concrete Evidence Fields:** Returning parent re-reads existing records to identify: child session/thread ID, PID/lock state, target execution root, last recorded milestone, last accepted receipt digest, remaining authorized budgets (deadline, max tasks, attempts), and uncertain action records.
   - **Stopped-Ownership Proof:** Parent verifies that child processes and any child-spawned builders/writers are truly stopped (not paused, detached, or running in background). A live, paused, or unknown process holds; never replace while an owner or builder is active or unknown.
   - **Supported Recovery Order:** Adhere strictly to the Jog/Flywheel recovery ladder:
     1. `resume` first (reconcile durable state, adopt saved results without token spend).
     2. `retry-gate` if build was approved but gate failed (same head SHA, no builder turn).
     3. `retry-build` ONLY if build genuinely needs a fresh bounded attempt and remaining attempt budget permits.
     4. Never retry an unknown outcome; unknown state holds for operator decision.
   - Preserves original deadlines, attempt counters, and authority; redispatches only within remaining budget.

## Acceptance Criteria (from Issue #1509)

- [ ] Invocation plainly creates parent observer/recovery + one outer-loop child with disjoint responsibilities and no competing writer.
- [ ] Daily-goal intake routes to existing preparation owners; no readiness claim from raw intake alone.
- [ ] Normal completion, task-local hold, shared unsafe stop, and parent/child interruption handoffs are specified with concrete evidence and next owner.
- [ ] Unknown, live, or paused ownership refuses replacement; replacement permitted only after proven stopped ownership and reconciliation within original limits, preserving uncertain results.
- [ ] No extra queue/schema/runtime service, new test suite or silent installed-skill update.
- [ ] Independent plan/final QA, classified checks and recorded main/adjacent instruction walkthrough establish the delivered instruction contract; live unattended qualification remains separate.

## Ordered Implementation and Verification

1. Review this capture plan via independent Codex relay QA (`relay-system/2026-11-17/gh1509-plan-qa.md`).
2. Adjudicate findings; obtain Approved verdict within the 3-round cap.
3. Implement `skills/1-hourly/kickstart/SKILL.md` specifying:
   - Frontmatter (`name: kickstart`, description).
   - Parent vs Child disjoint responsibilities and non-overlapping ownership.
   - Daily-goal intake routing (issue-first via `idea`/repo SOP for raw prose, then Conveyor) without premature readiness claims.
   - Host delegation and native completion/question observation without polling; explicit stop on missing host capability.
   - Session recovery rules (stopped-ownership proof including builders/writers, preserve remaining budget/deadline, unknown state holds, supported recovery ladder `resume` → `retry-gate` → `retry-build`, never retry-build unknown outcome).
   - Concrete handoff states: normal completion, task-local hold following owner semantics, shared unsafe stop, interruption recovery.
   - Preserving original budgets, receipts, and uncertain outcomes; reporting assisted vs unattended truthfully.
4. Register the new skill in `ARCHITECTURE.md` under the Skills Index.
5. Classify the final actual diff against integration base `development` via `utils/ci-route.sh` to determine applicable route (docs, fast, or full) and test tier.
6. Conduct a source-only manual instruction walkthrough of main (happy-path delegation & normal completion) and adjacent paths (task-local hold, shared unsafe stop, session interruption/recovery), recording nonempty results and nonempty `provenance.jsonl` under `TESTS-RESULTS/2026-11-17+GH-1509/`. Distinguish instruction walkthrough from live unattended qualification.
7. Run all applicable classified checks (e.g. `utils/pdda/pdda.sh run` for docs route; required tier suites if classified otherwise), reporting any failure or unavailable check honestly.
8. Conduct independent final Codex relay QA (`relay-system/2026-11-17/gh1509-final-qa.md`).
9. Open ready pull request against `development` and close out issue #1509.

## Task Rating Rationale

2026-11-17: rated 75/60/50/85, calc 270, ovr null.
- Priority: 75 — reflects composition bottleneck for outer-loop assisted factory.
- Severity: 60 — workflow stalls and misclassification without data corruption.
- Appeal: 50 — neutral under G5.
- Effort: 85 — high cheapness/ease: instruction-only skill composing existing Flywheel, Conveyor, Jog, and native host delegation.
- Recurrence window: trend unknown. Stored rating in `releases.db` via canonical CLI `releases_app.py roadmap pickup`.

## Lessons Learned (For Future Agents)

Pending implementation evidence; NO_ENTRY at planning time.
