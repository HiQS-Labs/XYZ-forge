---
id: GH-609
title: 'feat(sdlc): address edge-case SDLC gaps in autonomous agent workflows'
status: active
owner: agent-b
created: 2026-09-13
updated: 2026-09-13
goal: 'Codify durable interrupted-operation recovery, zero-downtime expand-contract migrations, operational containment, and bounded flake/performance fences across core skills.'
labels: [enhancement, sdlc, architecture]
rated: 75/80/50/60
issue_url: https://github.com/HiQS-Labs/XYZ-forge/issues/609
---

# GH-609: Address Edge-Case SDLC Gaps in Autonomous Agent Workflows

## Status

| What was just completed | What's next |
|---|---|
| Initial intake registered, Codex Round 1 Plan QA reviewed (findings R1–R7 graded and addressed). | Finalize Round 2 Plan QA with Codex, implement skill enhancements, and execute verified test suite. |

---

## Context & Synthesis
Following an in-depth SDLC capability audit and a 7-finding Codex relay review ([relay thread](../../relay-system/2026-09-13/gh609-sdlc-agent-gaps-plan-qa.md)), this project addresses key unrepresented SDLC workflows and high-consequence failure modes in autonomous coding agent harnesses.

Rather than fragmenting into separate single-purpose tools, the remediation focuses on extending existing core skills (`workhorse`, `start-task`, `swe`, `recon`, `ci-optimize`) with zero code sprawl and strict governance compliance.

---

## Bounded Scope & Insertion Points

### 1. `skills/workhorse/SKILL.md` (Rung 5 & Rung 6)
- **Durable Operation Identity & Bounded Safe Retry (R1, R3):**
  - Before dispatching any external side-effecting mutation (cloud resource creation, package publishing, payment/external API call, branch/PR creation, DB mutation), record a durable operation identity: `{operation_id, target_arn_or_url, request_fingerprint, idempotency_key}`.
  - **Reconciliation-Before-Retry:** On resuming after an interruption, timeout, or dropped transport, the agent must evaluate 4 distinct remote states:
    1. *Confirmed Success:* Extract existing receipt/output and continue.
    2. *Authoritative Non-Execution:* Safe to re-dispatch with original idempotency key.
    3. *Pending / In-Flight:* Wait or poll with bounded backoff; do not re-dispatch.
    4. *Unknown / Unavailable Lookup / Expired Deduplication:* **STOP and escalate to human decision**; automatic retry is strictly forbidden.
  - For targets lacking native idempotency, require natural unique constraints or conditional preconditions (e.g. `If-Match`, `version == N`), or stop.
  - **Stale-Writer Fence:** An elapsed lease time alone does not authorize a second writer while the previous writer process could still be active; require holder PID termination verification (`kill -0`) or coordination fencing tokens before acquiring write ownership.
  - **Preservation vs. Irreversibility Split (R3):**
    - *Costly Operations:* Require tested rollback/restoration procedures, explicitly disclosing any intervening writes that restoration would lose.
    - *One-Way Doors:* Require explicit permanent-loss disclosure and fresh, operation-specific operator confirmation; do not claim impossible rollback proofs.
  - **Semantic Post-Mutation Verification (Rung 6):** Verify data content and integrity invariants, not merely process exit code `0`.

### 2. `skills/start-task/SKILL.md` (Step 3 & Step 7)
- **Resume Reconciliation Protocol (R1, R5):**
  - Clarify insertion point in Step 3/7: An explicit resume must inspect existing task clones, branch names, remote PR status (`gh pr list --head <branch>`), and live HEAD commit before creating duplicate branches, duplicate capture docs, or pushing redundant commits.
  - On network disconnection during PR creation or push, verify remote state before repeating the command.

### 3. `skills/swe/SKILL.md`
- **Zero-Downtime Expand-Contract Schema & State Migration Rubric (R2):**
  - Codify the online Expand-Contract sequence:
    1. *Expand:* Add nullable or dual-write column with explicit concurrent write synchronization.
    2. *Backfill & Sync:* Background idempotent batch backfill; updates during backfill must reach the new representation with an explicit conflict/ordering strategy.
    3. *Convergence Gate:* Verify data reconciliation across old and new representations before cutting over reads.
    4. *Switch Reads:* Cut query paths to the new representation with graceful fallback.
    5. *Switch Writes:* Route write traffic exclusively to the new representation.
    6. *Contract:* Drop legacy fields ONLY after all old writers/readers and delayed asynchronous consumers are retired AND the rollback window has closed.
  - Mandate mixed-version consumer compatibility analysis for rolling deploys and offline/delayed clients.
  - Require lock/backfill rate budgets and stop/rollback tripwires.

### 4. `skills/recon/SKILL.md` (Lanes B & D)
- **Schema & State Migration Recon (R5):**
  - Insertion into Lane B (State Invariants) and Lane D (Caller/Callee): Identify all active readers, writers, background worker queues, and delayed consumers of a data contract before authoring migration plans.

### 5. `skills/ci-optimize/SKILL.md`
- **Principle 13 (Flaky Test 100-Iteration Stress Loops & Quarantined Sinks) (R5):**
  - Bounded diagnostic tool: 100-run stress loop under artificial CPU/disk jitter and concurrency race detectors (ThreadSanitizer/Go `-race`), with time/resource budget cap.
  - Quarantine Sink: Must continue running and reporting assertions; requires designated owner, linked tracked issue, UTC expiry date, and strict fail/return-to-gate behavior. Never silently disable assertions.
- **Principle 14 (Performance & Resource Budget Fences) (R5):**
  - Apply performance/memory regression gates (heapsnapshot diffs, allocation profiling, p99 latency thresholds) scoped to representative workloads and performance-critical paths.

### 6. Operational Containment Protocol (R4)
- Documented in `skills/ci-debug/SKILL.md` and referenced in `skills/workhorse/SKILL.md`:
  - Priority 1: Provider-level credential revocation & rotation.
  - Priority 2: Blast radius audit in access/audit logs.
  - Priority 3: Sanitized incident evidence (no live secrets copied to prompts/tickets).
  - Priority 4: Explicitly authorized git history scrubbing (`git-filter-repo`) preserving worktree safety.

---

## Actionable Execution Steps

1. [ ] Update `skills/workhorse/SKILL.md` (Rung 5 & Rung 6) with durable operation identity, 4-state reconciliation-before-retry, stale-writer fencing, and refined preservation/loss splits.
2. [ ] Update `skills/start-task/SKILL.md` (Step 3 & Step 7) with resume reconciliation and dropped-transport verification.
3. [ ] Update `skills/swe/SKILL.md` with the Expand-Contract migration rubric and mixed-version compatibility invariants.
4. [ ] Update `skills/recon/SKILL.md` with reader/writer/consumer mapping in Lanes B & D.
5. [ ] Update `skills/ci-optimize/SKILL.md` with Principles 13 (Flake quarantine) and 14 (Performance fences).
6. [ ] Update `skills/ci-debug/SKILL.md` with the operational credential containment protocol.
7. [ ] Author `test/gh609-sdlc-agent-gaps.sh` with 15+ comprehensive test cases (positive contract presence, negative clause-removal mutations, empty-input guards).
8. [ ] Register `gh609-sdlc-agent-gaps.sh` in `validate.sh`.
9. [ ] Run full pre-push test gate and qualify 100% green.
10. [ ] Execute final Codex Relay QA on completed diff.

---

## Verification & Falsification Plan
- **Contract Assertions:** `test/gh609-sdlc-agent-gaps.sh` asserts the presence of every required contract clause across the 6 skill files.
- **Negative Falsification Controls:** Test suite injects deliberate clause deletions, contradictions, and empty inputs into temporary fixtures, asserting that the guard properly reports RED on missing or corrupted invariants.
- **Pre-Push Attestation:** Full sequential qualifying run via `validate.sh`.
