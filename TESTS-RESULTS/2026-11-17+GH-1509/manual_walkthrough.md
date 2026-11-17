# Manual Instruction Walkthrough — GH-1509 Kickstart Skill

Date: 2026-11-17
Task: GH-1509 (Kickstart: observer-led outer-loop child with bounded session recovery)
Evaluator: Agy (gemini-3.8-flash)
Baseline Base Commit: 88df7852cca000b712944d76dd05909fc1ffecae
Scope: Source-only manual instruction walkthrough of main and adjacent recovery/hold paths.
Distinction: These are deterministic instruction contract checks establishing delivered instruction semantics; live unattended qualification remains a separate milestone.

---

## Scenario 1: Main Path — Happy-Path Delegation & Normal Completion

- **Input:** Operator invokes `kickstart` with daily-goals request.
- **Path Steps:**
  1. Parent resolves intake: verifies target repository (`XYZ-forge`), checks whether input is an existing issue or raw goal.
  2. If raw prose, obtains an issue via `idea` / repo intake SOP; if already an issue, passes directly to Conveyor for capture and Preflight Contract preparation.
  3. Parent records durable child owner pointer and dispatches exactly one child session via host delegation mechanism (`delegate_task` / platform delegate) with explicit scope and budgets.
  4. Parent adopts passive observer role awaiting native completion events or watches; does not poll running delegate.
  5. Child composes existing skills (Conveyor -> Flywheel -> Jog -> start-task -> relay-xyz), runs required gates, and opens ready PRs.
  6. Child emits native completion event. Parent observes completion, records deliverables and remaining budget, and reports outcome to operator.
- **Pre-declared expected result:** PASS. Exactly one child dispatched; zero competing writers; zero polling loops; clear handoff on normal completion.
- **Observed instruction contract:** Compliant (`skills/1-hourly/kickstart/SKILL.md` Sections 1, 2, 3, 4.1).
- **Verdict:** PASS.

---

## Scenario 2: Adjacent Path A — Unsupported Host Delegation Capability Stop

- **Input:** Operator invokes `kickstart` on a platform or runtime lacking child delegation or completion event mechanisms.
- **Path Steps:**
  1. Parent evaluates host capabilities (`orchestrator_capabilities` / host API).
  2. Discovery indicates `canRunChildTask: false` or unsupported completion watch.
  3. Parent records `status: held`, `reason: missing_host_delegation_capability`, `next_owner: operator`.
  4. Parent leaves a resumable handoff record preserving intake state and unconsumed budget, and halts.
  5. Parent does NOT pretend child execution succeeded, does NOT spawn a background daemon/cron, and does NOT execute unassisted directly.
- **Pre-declared expected result:** PASS. Safe halt on missing host capability; no silent fallback or unmanaged background services.
- **Observed instruction contract:** Compliant (`skills/1-hourly/kickstart/SKILL.md` Section 1.4, Section 3.3).
- **Verdict:** PASS.

---

## Scenario 3: Adjacent Path B — Task-Local Hold vs Selected Owner Continuation Semantics

- **Input:** Child executes outer loop via Jog wake; an individual task encounters a readiness refusal (e.g. exit 5 preflight failure or missing contract probe).
- **Path Steps:**
  1. Task fails preflight / readiness check.
  2. Child consults execution owner's exact semantics (Jog GH-1400 wake: readiness refusal halts the wake; only newly approved PR or validated exit 5 pre-advance-failed receipt allows continuing).
  3. Because readiness refusal is a wake-halting condition in Jog, the child does NOT continue to the next task; it halts the wake immediately.
  4. Child records concrete hold evidence: task ID, blocker reason, preflight exit code, and designated next owner.
  5. Child checkpoints state and hands off to parent.
  6. Parent observes the hold and surfaces it to the operator.
- **Pre-declared expected result:** PASS. Child strictly obeys execution owner continuation/halt semantics; does not bypass owner stop rules.
- **Observed instruction contract:** Compliant (`skills/1-hourly/kickstart/SKILL.md` Section 1 Child.3, Section 4.2).
- **Verdict:** PASS.

---

## Scenario 4: Adjacent Path C — Shared Unsafe Stop

- **Input:** Child detects a global repository safety violation (e.g. `relay-driver.lock` active by another PID, git-safety worktree collision, or unexpected ledger divergence).
- **Path Steps:**
  1. Child checks environment safety before dispatch; identifies active lock contention or unmanaged mutation.
  2. Child halts dispatch immediately.
  3. Child preserves local state and leaves a resumable checkpoint citing the lock file, ref SHAs, or divergent state.
  4. Child alerts parent with the concrete unsafe condition.
  5. Parent assesses boundary and engages operator without force-clearing locks or resetting state.
- **Pre-declared expected result:** PASS. Immediate dispatch halt on shared unsafe conditions; no forced overrides or silent state resets.
- **Observed instruction contract:** Compliant (`skills/1-hourly/kickstart/SKILL.md` Section 1 Child.4, Section 4.3).
- **Verdict:** PASS.

---

## Scenario 5: Adjacent Path D — Session Interruption & Stopped-Ownership Recovery

- **Input:** Parent session was disconnected or interrupted mid-run. New parent session reinvoked to recover the in-flight factory run.
- **Path Steps:**
  1. Returning parent re-reads existing records to identify concrete evidence: child session/thread ID, lock/PID state, execution root, last accepted milestone, receipt digest, remaining budgets.
  2. Stopped-ownership proof: parent inspects child session and all child-spawned builders/writers.
     - *Case 5.1 (Live, paused, or unknown):* Child or builder process is active, suspended, or unverified. Parent strictly REFUSES replacement/redispatch; marks run held for operator inspection.
     - *Case 5.2 (Proven stopped):* All processes and writers proven dead. Parent reconciles saved results (adopting unacknowledged completions without re-execution).
  3. Follows supported recovery ladder: `resume` first -> `retry-gate` if build approved but gate failed -> `retry-build` only if fresh attempt is genuinely required and budget remains.
  4. Never retries an unknown outcome; preserves original deadlines and attempt counters.
- **Pre-declared expected result:** PASS. Unknown/live/paused ownership halts replacement; proven stopped ownership recovers strictly via supported ladder within unconsumed budget.
- **Observed instruction contract:** Compliant (`skills/1-hourly/kickstart/SKILL.md` Section 1 Parent.5, Section 4.4).
- **Verdict:** PASS.

---

## Summary of Results

| Scenario | Path Name | Pre-declared Expected | Observed Verdict |
|---|---|---|---|
| 1 | Main Path: Happy-Path Delegation & Normal Completion | PASS | PASS |
| 2 | Adjacent A: Unsupported Host Delegation Stop | PASS | PASS |
| 3 | Adjacent B: Task-Local Hold vs Owner Semantics | PASS | PASS |
| 4 | Adjacent C: Shared Unsafe Stop | PASS | PASS |
| 5 | Adjacent D: Session Interruption & Stopped-Ownership Recovery | PASS | PASS |

All 5 manual instruction walkthrough scenarios verified consistent with the delivered instruction contract.
