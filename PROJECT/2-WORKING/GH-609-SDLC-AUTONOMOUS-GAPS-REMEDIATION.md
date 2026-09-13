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
| Codex Round 2 Plan QA reviewed; R1.2, R2.2, R5.2, R6.2 fully integrated into canonical plan. | Finalize Round 3 Plan QA with Codex, implement skill enhancements, and execute verified test suite in disposable task clone. |

---

## Context & Synthesis
Following an in-depth SDLC capability audit and two rounds of Codex relay review ([relay thread](../../relay-system/2026-09-13/gh609-sdlc-agent-gaps-plan-qa.md)), this project addresses key unrepresented SDLC workflows and high-consequence failure modes in autonomous coding agent harnesses.

Rather than fragmenting into separate single-purpose tools, the remediation extends existing core skills (`workhorse`, `start-task`, `swe`, `recon`, `ci-optimize`, `ci-debug`) with zero code sprawl and strict governance compliance.

---

## Bounded Scope & Insertion Points

### 1. `skills/workhorse/SKILL.md` (Rung 5 & Rung 6)
- **Durable Operation Identity & Bounded Safe Retry (R1, R1.2, R3):**
  - Before dispatching any external side-effecting mutation (cloud resource creation, package publishing, payment/external API call, branch/PR creation, DB mutation), record a durable operation identity tuple: `{operation_id, target_arn_or_url, request_fingerprint, idempotency_key}`.
  - **Reconciliation-Before-Retry:** On resuming after an interruption, timeout, or dropped transport, reuse the recorded operation identity and unchanged request fingerprint, evaluating 4 distinct remote states:
    1. *Confirmed Success:* Extract existing receipt/output and continue without re-dispatch.
    2. *Authoritative Non-Execution:* Safe to re-dispatch with original idempotency key and unchanged request fingerprint.
    3. *Pending / In-Flight:* Wait or poll with bounded backoff up to a total reconciliation deadline / attempt cap (e.g. 5 attempts or 300s timeout); do not re-dispatch.
    4. *Unknown / Unavailable Lookup / Expired Deduplication Coverage / Deadline Exhausted:* **STOP and escalate to human decision**; automatic replay is strictly forbidden.
  - For targets lacking native idempotency, require natural unique constraints or conditional preconditions (e.g. `If-Match`, `version == N`), or stop when non-execution cannot be established.
  - **Stale-Writer Fence (R1.2):**
    - Local process liveness checks (`kill -0`, PID verification) are strictly scoped to operations whose complete write lifetime is demonstrably local (e.g., local repo locks or file mutations).
    - For remote mutations, an elapsed lease or local process exit does NOT guarantee that remote transactions have completed; a true remote stale-writer fence requires target-enforced monotonic fencing tokens / generation numbers that reject stale writers, or else must fall back to the Unknown/Pending stop rule.
  - **Preservation vs. Irreversibility Split (R3):**
    - *Costly Operations:* Require tested rollback/restoration procedures, explicitly disclosing any intervening writes that restoration would lose.
    - *One-Way Doors:* Require explicit permanent-loss disclosure and fresh, operation-specific operator confirmation; do not claim impossible rollback proofs.
  - **Semantic Post-Mutation Verification (Rung 6):** Verify data content, schema integrity, and semantic state invariants, not merely process exit code `0`.

### 2. `skills/start-task/SKILL.md` (Step 3 & Step 7)
- **Resume Reconciliation Protocol (R1, R5):**
  - Insertion point in Step 3/7: An explicit resume must inspect existing task clones, branch names, remote PR status (`gh pr list --head <branch>`), and live HEAD commit before creating duplicate branches, duplicate capture docs, or pushing redundant commits.
  - On network disconnection or timeout during PR creation or push, verify remote state and PR presence before repeating the command.

### 3. `skills/swe/SKILL.md`
- **Zero-Downtime Expand-Contract Schema & State Migration Rubric (R2, R2.2):**
  - Conditional on online/mixed-version changes with explicit lock/backfill rate budgets and stop/rollback tripwires.
  - Codify the 6-stage lifecycle:
    1. *Stage 1 (Expand):* Add nullable or dual-write column/field with explicit concurrent write synchronization.
    2. *Stage 2 (Backfill & Continuous Sync):* Execute background idempotent batch backfill; all updates during backfill and the entire mixed-version window MUST reach the new representation with an explicit conflict/ordering strategy.
    3. *Stage 3 (Convergence Gate):* Verify data reconciliation and parity across old and new representations before cutting over reads.
    4. *Stage 4 (Switch Reads):* Cut query paths to the new representation with graceful fallback.
    5. *Stage 5 (Dual-Write & Mixed-Version Support):* Continue bidirectional synchronization / updating both representations for every representation still read by active versions or needed by rollback throughout the entire mixed-version window.
    6. *Stage 6 (Contract & Retire):* Ending legacy updates and dropping legacy fields is gated on: (1) full retirement of legacy writers, (2) full retirement of legacy readers, (3) full retirement of delayed/asynchronous consumers, and (4) closure of the rollback window (or verified reverse synchronization if rollback occurs).

### 4. `skills/recon/SKILL.md` (Lanes B, C, and D)
- **Schema & State Migration Recon (R5.2):**
  - Insertion into Lane B (State/data lifecycle) and Lane C (Contracts/boundaries & async worker queues): Map all active readers, writers, background worker queues, and delayed consumers before planning data changes.
  - Insertion into Lane D (Build/failure/operations/rollback): Map operational tripwires, lock budgets, and reverse-sync rollback paths.

### 5. `skills/ci-optimize/SKILL.md`
- **Principle 13 (Flaky Test 100-Iteration Stress Loops & Quarantined Sinks) (R5, R5.2):**
  - Bounded diagnostic tool: 100-run stress loop under artificial CPU/disk jitter and concurrency race detectors (ThreadSanitizer/Go `-race`), with an explicit time/resource cap (e.g. 5-minute timeout).
  - Cross-references Principle 4 (matched base/candidate attribution) so stress testing does not become a competing single-sided attribution protocol.
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

## Acceptance Map & Falsification Matrix (R6.2)

| Invariant / Contract Area | Target Skill & Section | Positive Verification Control | Negative Falsification Mutation (Red Test) |
|---|---|---|---|
| **Durable Operation Identity & Safe Retry** | `skills/workhorse/SKILL.md` (Rung 5) | Asserts `{operation_id, target, request_fingerprint, idempotency_key}`, 4 remote states (*Confirmed Success*, *Authoritative Non-Execution*, *Pending*, *Unknown/Stop*), and deadline cap. | Deleting state 4 or idempotency reuse causes test failure. |
| **Stale-Writer Fence** | `skills/workhorse/SKILL.md` (Rung 5) | Asserts local PID scoping for local files, and remote generation/fencing tokens for remote mutations. | Allowing PID check alone to authorize remote replay causes test failure. |
| **Preservation Split** | `skills/workhorse/SKILL.md` (Rung 5) | Asserts tested rollback for Costly; explicit permanent loss disclosure & fresh operator confirmation for One-way doors. | Claiming rollback proof for irreversible one-way doors causes test failure. |
| **Expand-Contract Lifecycle & Rollback Safety** | `skills/swe/SKILL.md` | Asserts continuous sync during mixed-version window, convergence gate, and 4-part contraction gate (writers, readers, delayed consumers, rollback closure). | Permitting single-representation writes before reader retirement causes test failure. |
| **Recon Schema Mapping** | `skills/recon/SKILL.md` (Lanes B, C, D) | Asserts reader/writer/consumer mapping in Lanes B & C, and operational tripwires in Lane D. | Misassigning data mapping to Lane A causes test failure. |
| **Flake Stress & Quarantine Sink** | `skills/ci-optimize/SKILL.md` (Principles 13 & 14) | Asserts bounded 100-run stress loop aligned with Principle 4; Quarantine with owner, issue, UTC expiry, and active assertion execution. | Quarantine omitting UTC expiry or skipping assertion execution causes test failure. |
| **Operational Containment** | `skills/ci-debug/SKILL.md` | Asserts 4-tier ladder (Provider Revocation -> Log Audit -> Sanitized Evidence -> Authorized Scrubbing). | Inverting priority ladder (scrubbing before revocation) causes test failure. |

*Note on Evidence Boundary:* Text assertions prove contract presence in skill documents, not autonomous agent runtime behavior. Execution of mutation-heavy suites is strictly confined to disposable task clones; qualifying evidence is generated via `ci-local.sh` and committed `provenance.jsonl` (GH-430).

---

## Actionable Execution Steps

1. [ ] Update `skills/workhorse/SKILL.md` (Rung 5 & Rung 6) with durable operation identity, 4-state reconciliation-before-retry, stale-writer fencing, and refined preservation/loss splits.
2. [ ] Update `skills/start-task/SKILL.md` (Step 3 & Step 7) with resume reconciliation and dropped-transport verification.
3. [ ] Update `skills/swe/SKILL.md` with the Expand-Contract migration rubric and mixed-version compatibility invariants.
4. [ ] Update `skills/recon/SKILL.md` with reader/writer/consumer mapping in Lanes B & C, operational tripwires in Lane D.
5. [ ] Update `skills/ci-optimize/SKILL.md` with Principles 13 (Flake quarantine) and 14 (Performance fences).
6. [ ] Update `skills/ci-debug/SKILL.md` with the operational credential containment protocol.
7. [ ] Author `test/gh609-sdlc-agent-gaps.sh` implementing the complete Acceptance Map above (positive contract presence, negative clause-removal mutations, empty-input size guards).
8. [ ] Register `gh609-sdlc-agent-gaps.sh` in `validate.sh`.
9. [ ] Run `test/gh609-sdlc-agent-gaps.sh` and pre-push self-check gate (`./validate.sh`).
10. [ ] Execute final Codex Relay QA on completed diff.

