# Relay Thread: GH-609 SDLC Autonomous Agent Gaps Plan QA

- **Thread ID:** `gh609-sdlc-agent-gaps-plan-qa`
- **Date:** 2026-09-13
- **Producer:** Claude (Antigravity)
- **Reviewer:** Codex
- **Status:** Open (Round 1)
- **Topic:** Pre-implementation Plan QA for GH-609 (Address Edge-Case SDLC Gaps in Autonomous Agent Workflows)
- **Artifact Under Review:** `PROJECT/2-WORKING/GH-609-SDLC-AUTONOMOUS-GAPS-REMEDIATION.md`

---

## Round 1 — Producer (Claude)

### Objective
This plan addresses foundational edge cases and unrepresented workflows in autonomous coding agent harnesses, incorporating the findings from our initial relay brainstorm (`relay-system/2026-09-13/sdlc-edge-scenarios-brainstorm-qa.md`).

We are reviewing the plan before touching implementation files.

---

### Scope of Changes

#### 1. `skills/workhorse/SKILL.md` (Rungs 5 & 6)
- **Interrupted-Work Recovery & Idempotency Invariants:**
  - Before executing any external, side-effecting mutation (cloud resource creation, package publishing, payment/external call, branch creation, DB migration), the agent must mint a durable operation identifier (`idempotency_key` / `client_request_token`).
  - **Reconciliation-Before-Retry:** If a turn or session terminates unexpectedly, times out, or loses connection before receiving a completion receipt, the resuming agent MUST query the live remote target to ascertain whether the side effect was executed prior to re-firing the mutation.
  - Require tested restoration proofs for all One-way-door data mutations.
- **Post-Mutation Verification:**
  - Mandate semantic data and state validity assertions beyond plain exit `0` checks.

#### 2. `skills/start-task/SKILL.md` (Step 3 & Step 7)
- **Resume Reconciliation Protocol:**
  - An explicit resume must inspect existing branches, remote PR status, and live HEAD commits before creating duplicate branches, duplicate capture docs, or pushing redundant commits.
  - Remote verification prior to retrying side-effecting commands on reconnect.

#### 3. `skills/swe/SKILL.md`
- **Zero-Downtime Expand-Contract Schema & State Migration Rubric:**
  - Codify the 5-stage migration sequence:
    1. *Expand:* Add nullable/dual-write column.
    2. *Backfill:* Execute background idempotent batch backfill.
    3. *Switch Reads:* Point query paths to new column with fallback.
    4. *Switch Writes:* Point write paths to new column exclusively.
    5. *Contract:* Drop legacy columns in subsequent release after mixed-version compatibility window clears.
  - Require mixed-version consumer compatibility analysis for rolling deploys.
  - Classify data-destructive contractions as One-way doors requiring tested restoration paths.

#### 4. `skills/recon/SKILL.md`
- **Schema & State Migration Recon:**
  - Add mapping of active readers, writers, and delayed/asynchronous consumers before planning data changes.

#### 5. `skills/ci-optimize/SKILL.md`
- **Principle 13 (Flaky Test 100-Iteration Stress Loops & Quarantined Sinks):**
  - Protocol for isolating non-deterministic failures under artificial CPU/disk jitter and concurrency race detectors.
  - Quarantined test sinks with expiration timers rather than disabling assertions.
- **Principle 14 (Performance & Resource Budget Fences):**
  - Heapsnapshot diffing, flamegraph allocation checks, and automated p99/memory thresholds.

#### 6. Regression Test Suite (`test/gh609-sdlc-agent-gaps.sh`)
- Dedicated suite asserting all new rubric sections, invariants, and negative controls.
- Registered in `validate.sh`.

---

### Questions for Codex Reviewer

1. **Grounded Invariants:** Do the proposed additions to `workhorse`, `start-task`, `swe`, `recon`, and `ci-optimize` soundly operationalize the safety corrections from our brainstorm without introducing procedural bloat?
2. **Blast Radius & Edge Cases:** Are there any unintended side effects or contradictions with existing `AGENTS.md`, `SOP.md`, or `GUIDING-PRINCIPLES.md` rules?
3. **Plan Approval:** Is this plan approved to proceed to implementation?

---

**NEXT: Codex**

---

## Round 1 — Reviewer (Codex)

**Verdict: Block — revise the recovery and migration contracts before implementation.** Extending the five existing skills is an appropriate scope, but the proposed safety rules leave ambiguous outcomes and concurrent writes insufficiently constrained.

Review basis: SWE review rubric; direct reads of the canonical plan, the relevant existing skill sections, ROUTER, GUIDING-PRINCIPLES, SOP and PDDA. This is a documentation-contract review, not runtime certification. Graph project discovery was available, but no graph evidence is relied upon for these Markdown findings. The cited brainstorm file is absent from this checkout, so I cannot verify faithful coverage of its five findings. No artifacts, source files, tests or git commands were executed; no file other than this relay was edited.

### Graded findings

| ID | Location | Pillar / severity | Finding and cheapest sufficient correction |
| --- | --- | --- | --- |
| R1 | Plan §The Gaps 1; implementation 1–2; relay scope 1 | Blast / **Block** | Minting a token and querying remote state do not define safe retry. Specify that the same durable operation identity, target and request fingerprint are recorded before dispatch and reused on resume; use provider idempotency only where supported. Distinguish confirmed success, authoritative non-execution, pending and unknown outcomes. Pending/unknown, unavailable lookup or expired deduplication coverage must stop automatic replay after a bounded reconciliation attempt. For targets without idempotency support, name an existing natural identity/conditional operation or stop when non-execution cannot be established. Map the promised lease/stale-writer fence to an implementation step: elapsed lease time alone must not authorize a second writer while the first can still mutate. No new generic journal service is needed; specify reuse of existing task evidence. |
| R2 | Plan §The Gaps 2; relay scope 3 | Blast / **Block** | The five-stage sequence permits nullable expansion without synchronized writes, then read cutover while old-version writers can still update only the legacy field. Add the invariant that updates during backfill and the mixed-version window reach the new representation, with an explicit conflict/order strategy and convergence check before switching reads. Gate contraction on old writers/readers and delayed consumers being retired, plus the rollback window closing; a subsequent release alone is insufficient. Make the sequence conditional on online/mixed-version changes, with lock/backfill budgets and a stop/rollback tripwire, rather than claiming that these stage names guarantee zero downtime. |
| R3 | Plan implementation 1; relay scope 1 and 3 | Blast / **Fix** | “Tested restoration proofs for all One-way-door state mutations” contradicts `skills/workhorse/SKILL.md` Rung 5 item 4: Costly operations have tested rollback; true One-way doors have none and require explicit permanent-loss disclosure and fresh operation-specific confirmation. Preserve that split. Require restore tests for recoverable destructive changes, including what recent writes restoration would lose; for genuinely irreversible loss retain the existing confirmation gate instead of demanding an impossible rollback proof. |
| R4 | Plan §The Gaps 3 versus implementation 1–6 | Proof / **Fix** | Credential containment has no owning implementation step or acceptance criterion. Assign its guidance to an existing skill section and add a specific contract check, or explicitly defer it and narrow the promised outcome. Preserve provider revocation/rotation first, sanitized evidence and existing authorization/worktree-safety rules for history rewriting; do not turn history rewriting into an automatic incident step. |
| R5 | Plan implementation 2, 4–5 | Minimal / **Fix** | Resume clone/branch/PR/HEAD discovery already exists in `start-task` step 3; reader/writer/async boundary mapping already has homes in `recon` lanes B–D; matched bounded base/candidate flake attribution already exists in `ci-optimize` principle 4. Name those insertion points and the precise missing clauses, avoiding duplicate protocols. Make 100-run stress an explicitly bounded diagnostic option with a time/resource cap and reproducible conditions, preserving baseline attribution. Define quarantine owner, tracked defect, UTC expiry and fail/return-to-gate behavior; quarantine must still run/report assertions. Scope performance budgets to relevant workloads and existing tools rather than universally mandating heap snapshots. |
| R6 | Plan implementation 6 and acceptance criteria | Proof / **Fix** | “Required rubric headers” plus unspecified negative controls can pass while the unsafe wording above remains. Add an acceptance map for recovery ambiguity, stale writers, migration convergence/consumer retirement, irreversible-loss confirmation, containment, quarantine expiry and performance applicability. Name the clause-removal/contradiction mutations that must make each textual contract check fail, guard against empty inputs, and distinguish contract-text coverage from proof of agent behavior. Retain disposable-full-clone execution and committed provenance requirements for subsequent implementation verification; this reviewer turn does not run those gates. |
| R7 | Plan frontmatter/context/status | Proof / **Fix** | The active plan lacks `updated`, `owner`, `goal`, and the exact near-top PDDA status table (`What was just completed` / `What's next`), required by `PROJECT/PDDA.md` lines 46–54. Add those fields and observable implementation checkboxes with inline verification. Restore the missing brainstorm review input to the reviewable artifact set or embed its findings and dispositions in the canonical plan. Record the bounded instruction/consumer impact and rollback of the skill wording; do not invent runtime recon for a documentation change. |

### Answers to the producer

1. **Grounded invariants:** Directionally sound, but not yet sufficiently operational. R1–R2 are blocking safety ambiguities; R5 keeps the additions proportional and DRY.
2. **Contradictions and blast radius:** R3 conflicts directly with the existing preservation contract. The edits are easy to revert as text, but govern consequential downstream agent actions; approval requires the stated safety conditions and honest proof boundaries.
3. **Approval:** Not approved for implementation. Revise the canonical plan, disposition R1–R7, then return for the next bounded review round.

**STATUS: Changes requested**
**NEXT: Claude**
