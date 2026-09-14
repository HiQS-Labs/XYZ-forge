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

### Extension · System
relay-drive: round cap (1) reached but lane is converging (new commits or resolved items) — bounded extension granted to cap 2

---

## Round 2 — Producer (Claude)

### Dispositions to Round 1 Findings (R1–R7)

All 7 findings have been fully integrated into the canonical plan [`PROJECT/2-WORKING/GH-609-SDLC-AUTONOMOUS-GAPS-REMEDIATION.md`](../PROJECT/2-WORKING/GH-609-SDLC-AUTONOMOUS-GAPS-REMEDIATION.md):

| Finding | Severity | Disposition in Canonical Plan |
|---|---|---|
| **R1 (Safe Retry & Identity)** | **Block** | **Adopted in Full:** Added durable operation identity tuple `{operation_id, target_arn_or_url, request_fingerprint, idempotency_key}` recorded before dispatch. Defined the 4-state reconciliation evaluation (*Confirmed Success*, *Authoritative Non-Execution*, *Pending/In-Flight*, *Unknown/Stop*). Replay is forbidden on *Unknown/Expired* states without human escalation. For non-idempotent targets, natural identity or conditional preconditions (`If-Match`) are mandated. Stale-writer fence requires process liveness check (`kill -0`) or fencing tokens before acquiring write ownership. Reuses task evidence without generic journal bloat. |
| **R2 (Migration Invariants)** | **Block** | **Adopted in Full:** Added concurrent write synchronization during backfill, conflict/ordering strategy, and explicit data convergence verification gate prior to read cutover. Contraction is explicitly gated on: (1) retirement of legacy writers, (2) retirement of legacy readers, (3) retirement of delayed/asynchronous consumers, and (4) closure of the rollback window. Added lock/backfill rate budgets and stop/rollback tripwires. |
| **R3 (Preservation Split)** | **Fix** | **Adopted in Full:** Restored strict alignment with `workhorse` Rung 5: Costly operations require tested rollback/restoration procedures and disclosure of intervening lost writes; true One-way doors require explicit permanent-loss disclosure and fresh operation-specific confirmation (never demanding impossible rollback proofs). |
| **R4 (Containment Ownership)** | **Fix** | **Adopted in Full:** Assigned the 4-tier operational containment protocol to `skills/ci-debug/SKILL.md` (and cross-referenced in `workhorse`): (1) Provider-level revocation/rotation, (2) Blast radius log audit, (3) Sanitized evidence preservation, (4) Authorized history rewriting preserving worktree safety. |
| **R5 (Insertion Points & DRY)** | **Fix** | **Adopted in Full:** Mapped precise insertion points into existing skills: `start-task` Step 3/7 for resume reconciliation; `recon` Lanes B & D for reader/writer/consumer mapping; `ci-optimize` Principle 13 (bounded 100-run diagnostic stress loop + quarantined sink with owner, issue, UTC expiry, and fail-on-regression behavior; assertions still run) and Principle 14 (scoped performance/allocation budgets). |
| **R6 (Falsifiable Acceptance)** | **Fix** | **Adopted in Full:** Acceptance map in plan mandates `test/gh609-sdlc-agent-gaps.sh` with positive contract checks, empty-input size guards, and negative clause-removal mutation tests verifying that the test suite turns RED if any invariant is omitted. |
| **R7 (PDDA Metadata)** | **Fix** | **Adopted in Full:** Added `owner: agent-b`, `goal`, `updated`, and near-top status table (`What was just completed` / `What's next`) to the canonical working doc. |

---

### Request for Reviewer

With R1–R7 addressed in the canonical plan, is the plan approved to proceed to implementation across the 6 skill files and regression test suite?

**NEXT: Codex**


---

## Round 2 — Reviewer (Codex)

**Verdict: Changes requested — R1 and R2 remain partially unresolved; the revision otherwise makes substantial progress.**

Review basis: direct read of the complete revised canonical plan, the prior findings/dispositions, SWE review rubric, ROUTER, GUIDING-PRINCIPLES, PDDA requirements, and targeted existing skill clauses. This is a Markdown contract review; no structural graph completeness or runtime behavior is claimed. Graph project discovery returned a paginated inventory, but no project generation was established or relied upon. No project artifact, source, test, gate or git command was executed. Only this relay file was edited, in addition to the explicitly required token operations.

### Graded findings

All plan line references below name `PROJECT/2-WORKING/GH-609-SDLC-AUTONOMOUS-GAPS-REMEDIATION.md`.

| ID | Location | Pillar / severity | Finding and cheapest sufficient correction |
| --- | --- | --- | --- |
| R1.2 | Plan lines 35–42 | Blast / **Block** | PID termination is not a remote stale-writer fence: a request already accepted remotely can complete after its local client dies. A `kill -0` failure also needs error/identity interpretation rather than being treated as proof of termination. Replace the universal PID-or-token alternative with proof that the previous writer and its outstanding mutations cannot still commit, or a fence enforced by the mutation target that rejects stale generations. Scope local process checks to operations whose complete write lifetime is demonstrably local; otherwise preserve the unknown/pending stop rule. Explicitly reuse the recorded operation identity and unchanged request fingerprint on resume. “Bounded backoff” limits polling delay, not total polling: name a total reconciliation deadline/attempt cap and stop/escalate when exhausted. |
| R2.2 | Plan lines 56–63 | Blast / **Block** | Synchronization/convergence now protects read cutover, but step 5 still switches writes exclusively to the new representation before step 6 retires old readers and closes rollback. An old reader or a rollback to the old application can therefore see stale data while the legacy fields still exist. Require continued synchronization for every representation still used by supported readers/writers or rollback, throughout the mixed-version window. Gate ending legacy updates (not just dropping columns) on consumer retirement and rollback compatibility, or explicitly provide and verify reverse synchronization before rollback. This completes R2 without adding a new migration framework. |
| R6.2 | Plan lines 93–103 | Proof / **Fix** | `validate.sh` is incorrectly called a “Full sequential qualifying run”: ROUTER identifies it as parallel by default and a self-check even when sequential; `ci-local.sh` writes qualifying evidence. Name the intended self-check versus qualifying command accurately, require a separate disposable full clone for mutation-heavy suites, and require committed provenance for evidence cited in the eventual PR. Replace the arbitrary “15+” count with the requested compact invariant-to-positive/negative-control map, including the stale-writer and mixed-version counterexamples above. State that text checks prove contract presence, not autonomous-agent behavior. |
| R5.2 | Plan lines 65–74 | Recon / **Fix** | The claimed precise insertion point misidentifies recon Lane D as “Caller/Callee.” The current lane table (`skills/recon/SKILL.md:69–73`) assigns A to entry/call paths, B to state/data, C to contracts/boundaries including events/queues, and D to build/failure/operations. Extend B/C for reader/writer/delayed-consumer mapping and D only for operational tripwires. Cross-reference existing ci-optimize Principle 4's matched base/candidate attribution when adding Principle 13 so the new stress option does not become a competing single-sided attribution protocol. |

### Disposition and scope

- **R3 resolved:** Costly rollback and true irreversible-loss confirmation now match `workhorse` Rung 5.
- **R4 resolved at plan level:** Containment has an owner and preserves revocation-first, sanitized evidence and authorized history rewriting.
- **R5 substantially resolved:** Bounded stress, quarantine ownership/issue/UTC expiry/reporting and workload-scoped budgets are appropriate; the insertion-point/attribution correction above remains.
- **R6 partially resolved:** Empty-input guards and negative mutations are explicit; the acceptance map and correct evidence boundary remain outstanding.
- **R7 metadata resolved:** Required frontmatter and exact status table are present. The revised plan is reviewable on its own; this review does not certify coverage of the earlier unavailable brainstorm. The skill text is Easy to revert, while its downstream consumers perform consequential recovery/migration operations; this is why the two unsafe alternatives above still block approval.

The six-skill scope is appropriate. No additional subsystem, runtime implementation or broad recon is requested. Revise these bounded clauses and return for plan approval; implementation is not approved by this turn.

**STATUS: Changes requested**
**NEXT: Claude**

---

## Round 3 — Producer (Claude)

### Dispositions to Round 2 Findings (R1.2, R2.2, R5.2, R6.2)

All Round 2 findings have been directly incorporated into the canonical plan [`PROJECT/2-WORKING/GH-609-SDLC-AUTONOMOUS-GAPS-REMEDIATION.md`](../PROJECT/2-WORKING/GH-609-SDLC-AUTONOMOUS-GAPS-REMEDIATION.md):

| Finding | Severity | Disposition in Canonical Plan |
|---|---|---|
| **R1.2 (Remote Fence & Bounded Retry)** | **Block** | **Adopted in Full:** (1) Local PID checks (`kill -0`) are strictly restricted to operations whose write lifetime is demonstrably local (e.g. local repo locks/files). For remote mutations, target-enforced monotonic fencing tokens / generation numbers that reject stale writers are required, or the agent must fall back to the Unknown/Pending stop rule. (2) Resume reuses the recorded operation identity tuple and unchanged request fingerprint. (3) Bounded reconciliation mandates an explicit total reconciliation deadline / attempt cap (e.g. max 5 attempts / 300s timeout) before stopping and escalating to human decision. |
| **R2.2 (Mixed-Version Sync & Rollback)** | **Block** | **Adopted in Full:** (1) Required continued bidirectional synchronization / updating both representations for every representation still read by active versions or needed by rollback throughout the entire mixed-version window. (2) Gated ending legacy updates (and dropping legacy fields) on: full retirement of legacy writers, full retirement of legacy readers, full retirement of delayed/asynchronous consumers, and closure of the rollback window (or verified reverse synchronization if rollback occurs). |
| **R5.2 (Recon Lanes & Attribution)** | **Fix** | **Adopted in Full:** (1) Corrected Recon lane mappings to current table: reader/writer/delayed-consumer mapping is assigned to Lane B (State/data lifecycle) and Lane C (Contracts/boundaries & async worker queues), while Lane D (Build/failure/operations/rollback) is reserved for operational tripwires and reverse-sync rollback paths. (2) Principle 13 (Flake stress) explicitly cross-references Principle 4 (matched base/candidate attribution) so it remains a diagnostic tool without competing with baseline attribution. |
| **R6.2 (Acceptance Map & Evidence Boundary)** | **Fix** | **Adopted in Full:** (1) Replaced arbitrary counts with a compact Invariant-to-Control Acceptance Map covering positive assertions and negative clause-removal falsification mutations (including stale-writer and mixed-version counterexamples). (2) Formally recorded the evidence boundary: text checks prove contract presence in skill documents, not autonomous agent runtime behavior. (3) Accurately specified `validate.sh` as self-check gate and `ci-local.sh` as qualifying evidence generator with committed `provenance.jsonl` (GH-430) inside disposable task clones. |

---

### Request for Reviewer

With R1.2, R2.2, R5.2, and R6.2 fully resolved in the canonical plan, is the plan now approved to proceed to implementation?

**NEXT: Codex**


---

## Round 3 — Reviewer (Codex)

**Verdict: Ship with conditions — approved to proceed to implementation; no blocking plan findings remain.**

Review basis: direct reads of the revised canonical plan, prior relay findings and dispositions, SWE rubric, ROUTER, GUIDING-PRINCIPLES, and the existing recon lane table and ci-optimize attribution/isolation clauses. This is a bounded Markdown contract review, not runtime certification or an exhaustive codebase review. No graph evidence is relied upon. No artifact/source execution, project tests, gates, or git commands were run. Only this relay file was edited, apart from the required coordination token operations. The file contains no embedded TAKE YOUR TURN block; the explicit operator instructions govern this turn.

### Disposition of Round 2 findings

| ID | Grade | Evidence and disposition |
| --- | --- | --- |
| R1.2 | Resolved | Scope §1 reuses operation identity and unchanged fingerprint, defines a total reconciliation deadline/attempt cap, restricts local liveness checks to demonstrably local write lifetimes, and requires target-enforced remote fencing or the pending/unknown stop rule. Remote completion after client death no longer authorizes replay. |
| R2.2 | Resolved | Scope §3 stages 2 and 5 require continuous synchronization throughout mixed-version support, including representations needed for rollback. Stage 6 gates ending legacy updates as well as dropping fields on reader/writer/delayed-consumer retirement and rollback closure or verified reverse synchronization. |  [Unverified — no citation]
| R5.2 | Resolved | Scope §4 correctly assigns data/consumer mapping to recon B/C and operational tripwires to D. Scope §5 explicitly preserves Principle 4 matched base/candidate attribution. |
| R6.2 | Substantially resolved; implementation condition below | The acceptance matrix now specifies positive and adversarial controls; the evidence note distinguishes text presence from agent behavior and identifies ci-local.sh plus committed provenance as qualifying evidence. Step 9 correctly calls validate.sh a self-check. Existing AGENTS and ci-optimize rules still require a separate disposable full clone, never a linked worktree, for mutation-heavy verification. |

### Graded implementation condition

| Location | Pillar / severity | Finding and cheapest sufficient correction |
| --- | --- | --- |
| Canonical plan §Acceptance Map; execution steps 1, 2, 5, 7 | Proof / **Fix before shipping** | The row labelled “Principles 13 & 14” checks only stress/quarantine; it does not check workload-scoped performance applicability. Resume reconciliation and semantic post-mutation verification also lack explicit controls. While implementing the existing suite, add compact positive checks and clause-removal negative controls for those three promised clauses. Require nonempty inputs and observed red mutations. This completes coverage of the already approved scope without adding another test framework or requiring another plan-only round. |

The six existing skill documents remain the right scope. Reversibility is **Easy** for the wording changes; their downstream recovery and migration decisions remain consequential, which the revised contracts now acknowledge. Implementation approval assumes the canonical plan supersedes the original Round 1 proposal. Final diff review must verify the wording and meaningful negative controls; this approval is not evidence of completed implementation, passing gates, or merge readiness.

**STATUS: Approved**
**NEXT: Claude**
