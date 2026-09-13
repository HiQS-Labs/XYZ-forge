---
id: GH-609
title: 'feat(sdlc): address edge-case SDLC gaps in autonomous agent workflows'
status: active
created: 2026-09-13
labels: [enhancement, sdlc, architecture]
rated: 75/80/50/60
issue_url: https://github.com/HiQS-Labs/XYZ-forge/issues/609
---

# GH-609: Address Edge-Case SDLC Gaps in Autonomous Agent Workflows

## Context & Synthesis
Following an in-depth SDLC capability audit and a 5-finding Codex relay review ([relay thread](../../relay-system/2026-09-13/sdlc-edge-scenarios-brainstorm-qa.md)), this project addresses key unrepresented SDLC workflows and high-consequence failure modes in autonomous coding agent harnesses.

Rather than fragmenting into separate single-purpose tools, the remediation focuses on extending existing core skills (`workhorse`, `start-task`, `swe`, `recon`, `ci-optimize`) with zero code sprawl.

---

## The Gaps

### 1. Interrupted-Work Recovery & Lost-Acknowledgment Resilience (Critical)
- **Problem:** When an external side-effecting action (cloud deployment, package release, DB migration step, GitHub mutation) succeeds but the network transport drops before recording the receipt, agents naively retry from scratch upon resume, duplicating side effects or corrupting state.
- **Remediation:** Introduce pre-mutation idempotency tokens (`idempotency_key` / `client_request_token`), mandatory reconciliation against live remote state prior to retry, and lease expiry / stale-writer fences in `workhorse` and `start-task`.

### 2. Safe State, Database & Schema Evolution (Zero-Downtime Expand-Contract)
- **Problem:** AI agents default to atomic, single-step schema modifications (`ALTER TABLE`, renaming/dropping columns), causing table locks, downtime, or distributed service crashes during rollout.
- **Remediation:** Phased Expand-Contract protocols (Nullable/Dual-Write → Idempotent Backfill → Switch Read → Switch Write → Contract in subsequent release), mixed-version consumer compatibility windows, and verifiable data restoration proofs before destructive operations in `swe` and `recon`.

### 3. Operational Containment & Credential Leak Response
- **Problem:** When a secret/token is committed or printed in logs, agents attempt inline code redactions or destructive `git-filter-repo` runs that corrupt worktrees while leaving the active compromised credential active in third-party services.
- **Remediation:** Priority 1 provider-level revocation & rotation; Priority 2 blast-radius audit in access logs; Priority 3 sanitized incident evidence and worktree-safe history scrubbing.

### 4. Flake Quarantine & Performance Budget Fences
- **Problem:** Non-deterministic test flakes are silenced or skipped; performance/memory regressions pass functional tests unnoticed.
- **Remediation:** 100-iteration stress loops under artificial CPU/disk jitter and quarantined test sinks in `ci-optimize`; heapsnapshot and performance regression budgets.

---

## Implementation Plan

### 1. `skills/workhorse/SKILL.md`
- Add **Interrupted-Work Recovery & Idempotency Invariants** to Rung 5 (Preservation & Irreversibility Gate) and Rung 6 (Execution).
- Add tested restoration proofs for One-way-door state mutations.

### 2. `skills/start-task/SKILL.md`
- Update Step 3 (Provisioning) and Step 7 (Execution) with explicit **Resume Reconciliation**: verify remote PR/branch state before repeating side-effecting mutations.

### 3. `skills/swe/SKILL.md`
- Codify the **Zero-Downtime Expand-Contract Migration Rubric** and mixed-version compatibility invariants.

### 4. `skills/recon/SKILL.md`
- Add **Schema & State Migration Recon Checks** to map active readers, writers, and delayed consumers before planning data changes.

### 5. `skills/ci-optimize/SKILL.md`
- Add Principle 13: **Flaky Test 100-Iteration Stress Loops & Quarantined Sinks**.
- Add Principle 14: **Performance & Resource Budget Fences**.

### 6. Test Verification (`test/gh609-sdlc-agent-gaps.sh`)
- Dedicated regression test suite verifying contract integrity, required rubric headers, and negative falsification controls.
- Registered in `validate.sh`.

---

## Verification & Acceptance Criteria
- [ ] `test/gh609-sdlc-agent-gaps.sh` executes 100% green with positive and negative controls.
- [ ] Pre-implementation Plan QA approved by Codex via `relay-xyz`.
- [ ] Final Implementation QA approved by Codex via `relay-xyz`.
- [ ] Full pre-push test gate passes clean.
