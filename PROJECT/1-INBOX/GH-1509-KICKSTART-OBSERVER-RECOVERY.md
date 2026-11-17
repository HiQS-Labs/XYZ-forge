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
   - Handles session recovery on interruptions, pauses, or stops: verifies stopped ownership before any redispatch; unknown state holds; never retries an unknown outcome; preserves original deadlines, attempt counters, and authority.
   - Performs explicit, bounded parent repair; reports assisted vs unattended truthfully.
   - Never merges, deploys, or updates installed skills without explicit separate operator authorization.

2. **Child (Outer-Loop Executor):**
   - Composes existing skills: Conveyor (raw intake & preparation), Flywheel (adaptive loop), Jog (serial execution & recovery), start-task (task execution), relay-xyz (independent QA).
   - Performs normal dispatch and evidence collection.
   - On task-local holds: records hold, advances independent eligible ready work through supported owner semantics.
   - On shared unsafe conditions (lock contention, git safety violation, ledger drift, exhausted global budget): stops dispatch and reports to parent.
   - Never starts another competing child supervisor hierarchy.

## Daily-Goal Intake and Preparation Boundary

- Raw intake is permitted: daily-goal intake accepts raw requests, issue URLs, or backlog items.
- Routes to Conveyor (GH-1476) for preparation, scoping, recon, preflight contract, and PRS rating.
- No execution readiness claim from raw intake alone: Conveyor preparation, publication, and Jog pickup/admission checks must occur before execution.

## Lifecycle Handoffs and Recovery Protocol

1. **Normal Completion:** Child finishes batch/tasks, commits receipts, opens ready PRs, returns completion event with summary. Parent inspects results, records completion, presents outcome to operator.
2. **Task-Local Hold:** One task encounters a blocker/question/decision hold. Child marks item held with reason/evidence, continues to next independent ready item. Parent observes hold.
3. **Shared Unsafe Stop:** Global condition (lock held by unknown owner, dirty/divergent state, exhausted budget). Child halts immediately, leaves resumable checkpoint. Parent assesses condition.
4. **Interruption / Session Recovery:** Session drops or process pauses. Returning parent reads existing records, checks process/lock status, verifies whether child is live, paused, stopped, or unknown. If unknown or live, refuses replacement. If stopped cleanly, inspects last accepted result; only redispatches with remaining budget. Never retries an unknown outcome.

## Acceptance Criteria (from Issue #1509)

- [ ] Invocation plainly creates parent observer/recovery + one outer-loop child with disjoint responsibilities and no competing writer.
- [ ] Daily-goal intake routes to existing preparation owners; no readiness claim from raw intake alone.
- [ ] Normal completion, task-local hold, shared unsafe stop, and parent/child interruption handoffs are specified with concrete evidence and next owner.
- [ ] Unknown/live/stopped ownership refuses replacement; recovery preserves original limits and uncertain results.
- [ ] No extra queue/schema/runtime service, new test suite or silent installed-skill update.
- [ ] Independent plan/final QA, classified checks and recorded main/adjacent instruction walkthrough establish the delivered instruction contract; live unattended qualification remains separate.

## Ordered Implementation and Verification

1. Review this capture plan via independent Codex relay QA (`relay-system/2026-11-17/gh1509-plan-qa.md`).
2. Adjudicate findings; obtain Approved verdict within the 3-round cap.
3. Implement `skills/1-hourly/kickstart/SKILL.md` specifying:
   - Frontmatter (`name: kickstart`, description).
   - Parent vs Child disjoint responsibilities and non-overlapping ownership.
   - Daily-goal intake routing to Conveyor without premature readiness claims.
   - Host delegation and native completion/question observation without polling.
   - Session recovery rules (verify stopped ownership, preserve remaining budget/deadline, unknown state holds, never retry-build unknown outcome).
   - Concrete handoff states: normal completion, task-local hold, shared unsafe stop, interruption recovery.
   - Preserving original budgets, receipts, and uncertain outcomes; reporting assisted vs unattended truthfully.
4. Register the new skill in `ARCHITECTURE.md` under the Skills Index.
5. Conduct a source-only manual instruction walkthrough of main (happy-path delegation & normal completion) and adjacent paths (task-local hold, shared unsafe stop, session interruption/recovery), recording results under `TESTS-RESULTS/2026-11-17+GH-1509/`.
6. Run classified docs verification (`utils/pdda/pdda.sh run`).
7. Conduct independent final Codex relay QA (`relay-system/2026-11-17/gh1509-final-qa.md`).
8. Open ready pull request against `development` and close out issue #1509.

## Task Rating Rationale

2026-11-17: rated 75/60/50/85, calc 270, ovr null.
- Priority: 75 — reflects composition bottleneck for outer-loop assisted factory.
- Severity: 60 — workflow stalls and misclassification without data corruption.
- Appeal: 50 — neutral under G5.
- Effort: 85 — high cheapness/ease: instruction-only skill composing existing Flywheel, Conveyor, Jog, and native host delegation.
- Recurrence window: trend unknown. Stored rating in `releases.db` via canonical CLI `releases_app.py roadmap pickup`.

## Lessons Learned (For Future Agents)

Pending implementation evidence; NO_ENTRY at planning time.
