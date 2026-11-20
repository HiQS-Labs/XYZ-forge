---
name: kickstart
description: >-
  Codify the operator's assisted factory pattern: an observer/session-recovery parent
  session delegates the actual outer loop to one child session, composing Flywheel,
  Conveyor, and Jog with bounded evidence-backed adaptation and session recovery. Use
  for "kickstart", "start the factory outer loop", "kickstart daily goals", or when
  coordinating an observer-led outer loop.
---

# Kickstart — observer-led outer-loop child with bounded session recovery

Codify the operator's assisted factory pattern: invoking `kickstart` creates an
observer/session-recovery parent session that delegates the actual outer loop to
exactly one child session. The parent maintains supervision until the operator
explicitly approves a less-supervised mode based on evidence.

This skill composes existing Forge primitives — [Flywheel](../../2-daily/flywheel/SKILL.md),
[Conveyor](../conveyor/SKILL.md), and [Jog](../../2-daily/jog/SKILL.md) — alongside
native host delegation and completion events. It introduces no new queue, runtime
scheduler, database schema, daemon, or test suite.

---

## 1. Disjoint Parent vs Child Responsibilities

Kickstart enforces a strict, non-overlapping separation of duties between the parent
session and the single delegated outer-loop child session. There are never competing writers.

### Parent (Observer & Session Recovery)
1. **Intake Resolution:** Resolves target repository, raw daily-goals requests, selected
   scope/holds, exact execution mode, provider/subscription preferences, and existing budgets.
2. **Queue and Authority:** Builds the queue with
   `python3 skills/1-hourly/kickstart/scripts/build_queue.py --repo-root . --out <run record>`
   (pass `--other-session` and `--needs-operator` for the holds resolved in step 1), records the
   operator's authority grant in the printed Authority block of that run record, then dispatches.
   A resumed session re-reads the grant there instead of asking again. The printed Authority block
   bakes in the run defaults (KS-03) so mid-run amendments are not needed for these classes:
   - **CodeRabbit advisory (U5):** merge requires current-head review with no open Major, OR 30 min
     elapsed since a `@coderabbitai review` request on the **current head** with no review; reviews
     are re-read immediately before merge, the timeout path is recorded as `advisory not received;
     predeclared waiver used` (never as reviewed/approved), and any posted Major blocks until fixed
     or answered.
   - **Fail-closed decision defaults (KS-11):** round cap requires explicit independent reviewer
     approval of the final head (Minor/nit deferral only when explicitly tagged and accepted by the
     reviewer, never auto-accepted on gate/hook/containment/schema/kernel/Costly `full_required`
     surfaces, and never claiming `Approved` beyond what the reviewer stated; otherwise park);
     forecast conflict hubs route to a separate recorded batch; KS-02 decision comments apply only
     when authored by `--owner`, applicable, and not superseded.
   - **Quota fallback:** switch the reviewer seat to `agy` (recording the actual model) ONLY when
     the stop reason verbatim states quota; if both providers are capped, park.
   - **Flywheel per-PR approval:** once granted by the operator, this block satisfies Flywheel's
     per-PR merge approval step (`skills/2-daily/flywheel/SKILL.md:109-120`) for `--owner` PRs while
     preserving full-SHA `--prs N@<approved-full-sha>` pin verification before `--execute`.
   The script's ordering is a
   closed list, first match wins: own clean (confirmed `MERGEABLE`) PRs, own conflicting or
   failing PRs, own behind or not-yet-`MERGEABLE` PRs as one merge-cleanup batch, drafts (finish
   or close; a draft stays a draft even when it also conflicts), small bug issues, operator-decided
   proceed issues (released by a latest `--owner` comment whose first non-empty line starts with
   `Operator decision`, never falling into unclassified), docs issues, stale merge-batch and
   inventory issues (verify, then close), operator-decided close issues (`Operator decision: close`
   — child verifies acceptance on `origin/development` and closes citing the commit), refactors
   gated on a named predecessor, final QA. Held PRs, other authors' PRs, decision-needed (unless
   released by `--owner`), `Operator decision: hold` overrides, issues with a `status:held` label,
   body `HELD:` marker, `Blocked by #N`, or open/active-gating `after #N` (fail-closed across all
   issue types, not overridden by an operator decision comment), other-session-owned and
   unclassified items go to Needs-operator, and so does any PR whose closing keywords name a
   parked issue: merging it would close an issue the run may not close.
3. **Child Dispatch:** Records one child owner and durable handoff pointer, then starts
   the outer-loop child through the host's supported delegation mechanism (`delegate_task`
   or platform native delegate). Never starts multiple competing child sessions.
4. **Passive Observation:** Observes native completion events, questions, or completion
   watches. Does not poll a running delegate or PR (`task_status`, `sleep` loops, `Monitor`,
   `ScheduleWakeup`).
5. **Unsupported Host Guard:** If host capabilities do not support the required delegation
   mechanism or completion event/watch, the parent reports the missing capability explicitly,
   leaves a resumable handoff with pending state and next owner, and halts. It never pretends,
   starts a background daemon/cron, or falls back to direct unassisted execution.
6. **Session Recovery:** On session drops, interruptions, pauses, or stops, verifies stopped
   ownership across the child session and any child-spawned builders/writers before any
   redispatch. Unknown or live ownership holds; never retries an unknown outcome. Preserves
   original deadlines, attempt counters, and authority.
7. **Bounded Assisted Repair:** Performs explicit, bounded parent repair when needed, and
   reports assisted versus unattended operation truthfully.
8. **Authority Boundary:** Merging `--owner` PRs requires the operator's recorded grant in the
   run record's Authority block (step 2). Never merges anyone else's PR, deploys code, or updates
   installed skills without explicit separate operator authorization.

### Child (Outer-Loop Executor)
1. **Skill Composition:** Composes existing skills — Conveyor for raw intake and preparation,
   Flywheel for adaptive loop execution, Jog for serial execution and recovery, start-task
   for task execution, and relay-xyz for independent QA. Does not start another supervisor hierarchy.
2. **Execution & Evidence:** Drives normal task dispatch, build, test, review, and evidence
   collection within the assigned budgets.
3. **Execution Owner Semantics:** Follows the selected execution owner's exact continuation
   and stop semantics. On task-local holds, advances independent eligible ready work only
   when authorized by that owner's rules (e.g. Jog GH-1400 wake permits continuing after a
   newly approved published PR or a validated exit 5 pre-advance-failed receipt, but halts on
   readiness refusal, lock contention, guard-killed gate, crash, missing/mismatched receipt,
   or clone ledger change).
4. **Shared Unsafe Stops:** On shared unsafe conditions (lock contention, git safety
   violations, ledger drift, exhausted global budget) or owner-mandated stops, halts dispatch
   immediately, leaves a resumable checkpoint with observed evidence, and reports to parent.

---

## 1a. Run Record Contract (v1)

Every kickstart run record uses the versioned v1 grammar parsed and written by a single
canonical stdlib tool: `skills/1-hourly/kickstart/scripts/run_record.py` (GH-1543 / KS-15).
Downstream status, amendment, recovery, and checkpoint steps read and append through this
contract rather than ad-hoc regexes or unlocked appends.

- **Initialization headers** (required when initializing or migrating a run record to v1):
  - `RUN-RECORD-VERSION: 1` (mandatory; single header, no duplicates)
  - `LANDING_CLONE: <path>` (pinned landing checkout for active runs; single non-empty header)
- **Machine-readable event lines** (optional leading `- ` bullet tolerated):
  - `OPERATOR_AMENDMENT: <ID> <ISO-UTC-TS> <text citing operator turn/comment/decision>`
  - `PARENT_NOTE: <ID> <ISO-UTC-TS> <text>`
  - `INTERVENTION: <ID> <ISO-UTC-TS> <text>`
  - `APPLIED: <ID> → <disposition: applied|superseded|escalated> <action/artifact> [<ISO-UTC-TS>]`
    - *Reserved-word precedence:* if the first token after `→` (or `->`) is lowercase
      `applied`, `superseded`, or `escalated`, it is parsed as the explicit disposition and
      the remaining action/reason must be non-empty (so `APPLIED: OA-1 → escalated` alone is
      invalid). `superseded` must name a declared newer amendment ID (appearing later in the record). Otherwise, compact legacy
      text (`APPLIED: OA-1 → merged #1508`) defaults to `disposition="applied"`.
    - *Progression & unresolved state:* repeated `APPLIED:` lines are allowed only after
      `escalated` (never after terminal `applied` or `superseded`). Amendments with no `APPLIED:`
      line or latest disposition `escalated` remain unresolved until resolved.
  - `GATE: <target> [head <sha>] <route> [<Ns>|(duration not recorded)] <green|red>`
    (also accepts `GATE: final-QA <sha> <route> <verdict> (duration not recorded)`).
  - `BASELINE: <summary>` (optional summary line).
- **Subcommands (`run_record.py`):**
  - `validate <record> [--require-landing-clone] [--json]` — validates v1 grammar and reports
    `unresolved_amendments` and `escalated_amendments`.
  - `append <record> --kind <...> ...` — acquires a persistent sibling lock (`<record>.lock`),
    reads and validates the complete candidate record inside the lock, then writes atomically
    via temp file + `fsync` + `os.replace`.
  - `snapshot <record> [--out PATH]` — rejects empty input, normalizes local macOS/Linux
    absolute home-directory paths to `~`, redacts secret tokens, and strips stray XML/tool tags.
  - `checkpoint --record <path> --clone <dir> --primary <dir> --branch <branch> --dest <relpath> [--push]` —
    commits (and optionally pushes without force) a redacted snapshot to a clean, dedicated
    non-integration branch clone confined against `--primary`, `LANDING_CLONE`, and symlink escapes.

---

## 2. Daily-Goal Intake and Preparation Boundary

Raw intake is permitted at invocation, but raw intake alone never confers execution readiness.

1. **Intake Routing:**
   - **Existing Issue / URL:** If input is already an existing GitHub issue or URL, it routes
     directly to [Conveyor](../conveyor/SKILL.md) for preparation.
   - **Raw Prose / Uncaptured Goal:** If input is raw prose, an uncaptured daily goal, or a
     new item without an issue, it must first obtain an issue through the authorized issue-creation
     owner ([idea](../idea/SKILL.md), `gh issue create`, or repo intake SOP) before routing to Conveyor.
2. **Preparation Phase:** Conveyor prepares the capture doc in `PROJECT/1-INBOX/`, scopes the
   change, establishes the Preflight Contract, and applies the Product Release System (PRS)
   rating (`pri/sev/appeal/effort`).
3. **Readiness Gate:** Documentation publication and Jog pickup/admission checks remain
   mandatory prerequisites. Neither raw intake nor issue creation allows skipping straight
   to builder dispatch.

---

## 3. Host Delegation and Event-Driven Observation

The parent starts exactly one outer-loop child session:

1. **Delegation Protocol:**
   - Use the host's native supported delegation mechanism (e.g., T3 Code `delegate_task`,
     Claude Agent delegation, or Codex child thread).
   - Pass the explicit task brief, target repository, selected scope, and remaining budget limits.
   - Isolation uses the repository's standard worktree/clone policy; never create unmanaged
     checkout directories.
2. **Reactive Wakeup (Zero Polling):**
   - Wait on supported completion events or watches.
   - Do not loop on `task_status`, do not invoke shell `sleep` commands, and do not arm redundant
     heartbeat timers while a native delegate is executing.
   - Questions or requests from the child wake the parent for bounded assistance.
3. **Missing Capability Fallback:**
   - When running in an environment without supported child delegation or completion watches,
     record: `status: held`, `reason: missing_host_delegation_capability`, `next_owner: operator`.
   - Leave a resumable handoff record and halt. Do not manufacture an ad-hoc cron or background
     daemon.

---

### Derived Read-Only Status Report (`kickstart_status.py`, GH-1547 / KS-04)

Use `skills/1-hourly/kickstart/scripts/kickstart_status.py --record <path> [--target-root <repo>] [--json]`
for a thin, strictly read-only status snapshot over existing records (never a readiness engine, never
writes refs, `FETCH_HEAD`, objects, or locks):

- **Run record:** parsed via `run_record.py:parse_record`, reporting completed items, current item,
  interventions, record validation errors, and unapplied `OPERATOR_AMENDMENT:` / `PARENT_NOTE:` lines
  (never hidden by legacy parse warnings).
- **Open PRs:** calls `pr_minder.py --json --no-conflict-files --repo-root <target-root>` (or
  `--prs-json` replay) to summarize per-PR `merge_ready` hygiene and blockers.
- **Pinned attempt records (U10):** scans ONLY the run record's pinned `LANDING_CLONE`'s
  `.tick/merge-cleanup/*/pr-*.json` for `in_progress` attempts and pairs each with remote PR state
  (`gh pr view` or `--remote-prs-json`; unavailable -> `unknown`).
- **U3 Liveness:** reports `waiting` | `quiet` | `stale-candidate` | `confirmed-stopped` | `unknown`.
  `confirmed-stopped` requires complete 4-part ownership proof (`owner=stopped`, `lock=clear`,
  `children=stopped`, `sessions=stopped`); log age alone NEVER yields `confirmed-stopped` and NEVER
  authorizes `attempt_record.py finish` or redispatch.
- **Final-QA staleness (KS-13 seam):** reads canonical `GATE: final-QA <sha> ... green|red` and
  separates actual landings (`MERGED` progress lines and caller-verified `--development-head`) from
  non-landing task `GATE:` lines; unverified local heads report `unknown`.
- **Verbatim stop reason (KS-05 seam):** quotes exclusive `--receipt` / `--run-log` diagnostics, or a
  shared `<harness-root>/.relay-scratch/escalation-reason` ONLY when its own self-contained payload
  carries both matching `--invocation-id` and `reason` (mtime-only and sidecar-only attribution are
  rejected as `unknown / unattributable`).

---

## 4. Lifecycle Handoffs and Session Recovery Protocol

Every state transition leaves durable, verifiable evidence.

```
+-------------------------------------------------------------------------------+
|                                    PARENT                                     |
|  +--------------------+       delegate       +-----------------------------+  |
|  |  Resolve Intake &  | -------------------> |       Passive Observer      |  |
|  |  Record Pointer    |                      | (awaits native completion)  |  |
|  +--------------------+                      +-----------------------------+  |
+-------------------------------------------------------------|-----------------+
                                                              | event / halt
+-------------------------------------------------------------v-----------------+
|                                    CHILD                                      |
|  +-------------------------------------------------------------------------+  |
|  | Outer-Loop Execution: Conveyor -> Flywheel -> Jog -> start-task         |  |
|  +-------------------------------------------------------------------------+  |
|         |                           |                            |            |
|         v (PR ready)                v (task hold)                v (unsafe)   |
|   Normal Completion          Task-Local Hold              Shared Unsafe Stop  |
|   - PR & receipts            - Record evidence/reason     - Halt immediately  |
|   - Hand off to parent       - Follow owner semantics     - Checkpoint state  |
|                                (e.g. Jog GH-1400 wake)    - Report to parent  |
+-------------------------------------------------------------------------------+
```

### Transition 1: Normal Completion
- **Condition:** Child completes the requested batch or daily-goal tasks, runs classified gates,
  commits review receipts, opens ready PRs, and completes the execution owner's closeout.
- **Evidence:** PR URLs, commit SHAs, passing gate logs, and independent review verdicts.
- **Action:** Child returns completion event with summary. Parent inspects results, records
  completion, and presents the deliverable to the operator.

### Transition 2: Task-Local Hold
- **Condition:** An individual task hits a blocker, missing product decision, or local failure.
- **Owner Semantics:** Child strictly obeys the active execution owner's rules:
  - *Jog GH-1400 wake:* continuing independent work is permitted only after a newly approved
    published PR or a validated exit 5 pre-advance-failed receipt whose own gate ran and failed.
    A readiness refusal, lock contention, guard-killed gate, crash, missing/mismatched receipt,
    or clone ledger drift halts the wake immediately.
- **Evidence:** Held task ID, concrete blocker explanation, observed exit code, and designated next owner.
- **Action:** Child records hold evidence in the task record. If owner permits continuation,
  proceeds to next ready task; otherwise halts and hands off to parent.

### Transition 3: Shared Unsafe Stop
- **Condition:** A repository-wide or environment-level safety boundary is triggered: lock contention,
  unregistered writer, git-safety violation, primary ledger drift, exhausted global budget, or
  missing host capability.
- **Evidence:** Concrete violation log, lock file path, divergent ref SHAs, or resource accounting.
- **Action:** Child halts immediately, leaves a resumable checkpoint, and alerts parent. Parent
  assesses the boundary and engages the operator if required.

### Transition 4: Interruption & Session Recovery
When a parent session drops, disconnects, or is reinvoked to recover an in-flight run:

1. **Concrete Evidence Identification:** Returning parent re-reads existing records to identify:
   - Child session / thread ID.
   - PID / lock state.
   - Target execution clone / worktree path.
   - Last recorded milestone and task ID.
   - Last accepted receipt digest.
   - Remaining authorized budgets (wall deadline, max tasks, attempts).
   - Uncertain action records.
2. **Stopped-Ownership Proof:** Parent must verify that the prior child session and any
   child-spawned builders/writers are truly stopped (not paused, detached, or running in background).
   - Live, paused, or unknown ownership strictly refuses replacement.
   - If an owner, builder, or lock state cannot be verified dead, the run holds for operator intervention.
3. **Saved-Result Reconciliation:** Reconcile saved outcomes before dispatch. If a completed result
   exists on disk but was not acknowledged, adopt that result rather than repeating execution.
4. **Supported Recovery Ladder:**
   - `resume` first: reconcile durable state, adopt saved results without spending fresh attempt tokens.
   - `retry-gate`: if the build was approved but the gate failed, re-run only the gate on the same head SHA.
   - `retry-build`: execute a fresh attempt only if the build genuinely needs a fresh bounded attempt
     and attempt budget remains.
   - *Never retry an unknown outcome:* an uncertain build or external mutation holds for operator inspection.
5. **Budget Preservation:** Recovery preserves original deadlines, attempt counters, and authority;
   redispatches only within remaining unexpired budgets.

---

## 5. Verification and Acceptance

1. **Actual Diff Classification:** Run `utils/ci-route.sh` against the final actual diff from
   `development` to determine the applicable route (`docs`, `fast`, or `full`) and test tier.
2. **Applicable Checks:** Execute all applicable classified checks (e.g. `utils/pdda/pdda.sh run`
   for docs route; required tier suites if classified otherwise), reporting any failure or unavailable
   check honestly.
3. **Manual Instruction Walkthrough:** Perform a source-only manual instruction walkthrough of
   the main path (intake -> delegation -> normal completion) and adjacent recovery/hold paths
   (unsupported host stop, task-local hold following owner semantics, session interruption and
   stopped-ownership proof).
4. **Evidence Retention:** Save nonempty walkthrough results and nonempty `provenance.jsonl` under
   `TESTS-RESULTS/<date>+GH-<issue>/`.
5. **Truthful Qualification:** Distinguish instruction-level walkthrough evidence from live
   unattended factory qualification. Live unattended qualification remains a separate milestone.
