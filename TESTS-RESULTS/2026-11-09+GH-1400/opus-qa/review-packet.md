# Additional operator-requested QA — PR1403
Pinned reviewed head: 1d1c3fec5dc66ae5ba55715e1e7fb84d118dcc6a. The checkout contains this exact candidate plus the review scaffold only.
Reviewer requested: Claude Code CLI Opus, medium effort. Producer/adjudicator: parent Codex.
Operational envelope: instruction-only composition for a local operator directing existing XYZ workflows. No new runner, gate, daemon, automatic merge authority or readiness-label consumer. Full arc remains open for GH1399 enforcement and real qualification. Do not treat intentionally deferred work as implemented.
Read complete changed production file skills/2-daily/flywheel/SKILL.md, PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md, recon map, TESTS-RESULTS/2026-11-09+GH-1400/SUMMARY.md and provenance; inspect existing owner contracts skills/2-daily/merge-cleanup/SKILL.md, skills/1-hourly/handsfree/SKILL.md and relevant relay/native continuation semantics where needed. Read prior plan/final receipts as evidence, not substitute for review.
## Questions
1. Does this satisfy its bounded downstream scope, and truthfully distinguish delivered guidance from #1399/1401/trial dependencies?
2. Are batch pins, moved-head handling, merge authority, attempts, waits and recovery consistent with existing canonical owners and runnable capabilities?
3. Is the upstream readiness handoff an explicit selection/revalidation signal, without false automatic admission or review claims?
4. Are evidence and rating claims substantiated? Any concrete regression, omission or contradictory instruction in complete changed production file?
5. Is it surgical and DRY? Reject speculative machinery and new tests/gates (GH831); cite concrete file:line for findings. No enterprise threat model.
Read-only narrow source queries only; NO test suites/fixtures/pytest/validate in relay worktree. Any change-request must include Observed input, Affected scope, Falsifier. Output graded findings, swept file: yes/no, exact PASS/FAIL/PARKED verdict and basis into relay thread. Reviewer may modify relay thread only, not artifact; do not self-commit (harness owns commit). No push. Close Approved only when appropriate and finish tick handoff using existing protocol.
## Original issue requirements
## Executive Summary

Across recent factory and flywheel trials (#1254, #1298, #1356, #1358, #1386), our primary bottleneck has decisively shifted: **builder models can reliably write working code and passing tests, but orchestrating sessions spend massive time and token budgets babysitting handoffs, tracking accounting state, coordinating gate slots, and steering landing batches.**

This conceptual arc addresses the **supervision tax**—transforming the flywheel from an agent-assisted system requiring constant parent intervention into an economical, reliable pipeline that reuses existing mechanisms rather than introducing new daemons or complex frameworks.

---

## The Core Friction Points Observed

1. **Step-by-step landing nudging:** Even when PRs are fully verified and approved, parent agents frequently step through landing, reconciliation, and post-merge sweeps turn-by-turn.
2. **Interactive spinning on CI/gates:** Sessions idle-poll or execute repeated status checks while waiting on long-running test suites or review turns, consuming tokens and risking context compaction.
3. **Control and accounting overhead:** Discrepancies between execution and recorded attempt budgets (#1399) or review rounds require costly supervisory reconstruction.
4. **Upstream pipeline starvation:** As measured in #522, <5% of open issues are admissible for immediate pickup due to missing Preflight Contracts and roadmap registration, forcing ad-hoc manual planning during execution.

---

## Structured Proposal: 3 High-Leverage Solutions Reusing Existing Systems

### 1. Batch Landing via Unattended `merge-cleanup` Allowlists
* **The Insight:** Proven during the #1388 landing in #1386: when given an explicit allowlist (`--prs 1396,1397 --execute`), `merge-cleanup` successfully resolves topological ordering, landing, reconciliation, and post-merge sequence sweeps without turn-by-turn prompts.
* **Implementation:** The parent orchestrator provides an approved batch list once. `merge-cleanup` runs to completion autonomously, recording the sequence review in its maintained batch issue.

### 2. Event-Driven Continuation over Native Timers & GitHub Checks
* **The Insight:** Polling loops in chat sessions are expensive and fragile.
* **Implementation:** Use native asynchronous hooks (`watch_pull_request`, `schedule` one-shot timers) to sleep sessions until CI completes or an external blocker requires human decision. No token-burning poll loops.

### 3. Fail-Closed Boundaries Over Manual Bookkeeping (#1399)
* **The Insight:** Eliminate the need for supervisors to inspect logs and reconstruct whether agents stayed within attempt bounds.
* **Implementation:** Push and gate hooks fail closed if changes lack a registered attempt lease, shifting enforcement from manual supervisory vigilance to deterministic git hooks.

---

## Composition with Upstream Intake (The "Conveyor" Link)
This downstream composition engine pairs directly with an automated upstream intake pipeline (the **Conveyor**):
* **Conveyor (Upstream):** Takes raw issues -> conducts /recon research -> synthesizes capture docs & Preflight Contracts -> marks `status:ready-for-pickup`.
* **Flywheel/Jog (Execution):** Dispatches ready issues to builder/reviewer pairs with strict attempt budgets.
* **Merge-Cleanup (Landing):** Batches ready PRs and lands them in topological order with zero turn-by-turn nudging.

## Related Issues & Foundations
- #1254 (Outer loop primitive and declared supervision)
- #1298 (Factory flywheel arc)
- #1353 (Next-gen flywheel recommendations & loop instrumentation)
- #1356 (Flywheel Batch 2)
- #1358 (Outer loop qualification & bounds)
- #1386 (Merge inventory and supervision observations)
- #1399 (Attempt-accounting entry gate)