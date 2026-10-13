---
gh_issue: 1043
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1043
title: "feat(recon, review-code): Step N+1 bounded downstream verification in default and exhaustive simulation in deep mode"
status: "Proposed (1-INBOX — active)"
created: 2026-10-12
doc_type: feature
effort: 2
complexity: 2
risk: 1
phases: 2
---

# GH-1043: Step N+1 Downstream Verification for Recon and Review-Code

## Context & Motivation
In complex systems, LLM agents performing code reconnaissance (`/recon`) or pull request reviews (`/review-code`) routinely suffer from a critical blind spot: **stopping at the point of mutation**.

Recent production case study (LTVera-Pandas #591 review, Oct 12, 2026):
1. **The Poller Trap (State & Data):** Recon observed that receiving an asynchronous job ID from an external email provider immediately set `status = SENT`. Recon recommended transitioning to `SENDING` without checking if a polling worker existed. In reality, no background job polled for `Campaign.status`, so changing to `SENDING` would have orphaned every campaign in `SENDING` forever.
2. **The Lease Recovery Trap (Failure & Operations):** Recon observed that if an entity ID was missing, the commit silently proceeded. Recon recommended raising an exception and holding the claim. Tracing the enclosing distributed lease manager revealed that holding the claim caused Celery to retry 15 minutes later under `RECOVER`, find the same incomplete state, raise again, and trigger an infinite stuck-campaign retry storm (#672).
3. **The Parameter Generator Trap (Contracts & Boundaries):** Recon observed an empty `events` parameter in a nightly spacing planner and recommended passing stored items into it. Tracing the callee revealed that `merchant_events()` converts every item into a *new candidate slot*, which would duplicate every stored entity rather than constraining spacing.
4. **The Unbuilt Route Trap (Catalog Data):** Spot-checking documentation summaries missed that 28 of 33 articles in a help catalog instructed merchants to navigate to routes that do not exist.

## Architectural Decision: Tiered Step N+1

Rather than hiding Step N+1 in an opt-in `--deep` mode (which leaves default recons vulnerable to the same traps) or forcing heavy multi-hop simulation on every small task (which causes token bloat), we adopt a **tiered discipline**:

### 1. Default Recon & Review-Code: Bounded Step N+1 ("The Three 1-Hop Checks")
Every time a plan or PR touches a state write, an error path, or a solver input, the agent must trace **exactly 1 hop downstream**:
- **Consumer Check (Lane B):** When writing/transitioning state $S$, verify at least one active reader/poller/UI consumes $S$. If none exists, flag as an Incomplete State Machine (`[Blocker]` in review).
- **Retry-Loop Check (Lane D):** When raising an exception or holding a claim on failure, trace what the enclosing retry or lease manager does on the next cycle. Verify whether it recovers cleanly or triggers an infinite retry loop (`[Blocker]` in review).
- **Parameter Role Check (Lane C):** When passing state into an engine/solver, verify whether the callee treats it as a *constraint* (restricts/filters) or a *generator* (creates new entities) to prevent entity duplication.

### 2. Deep Recon (`recon --deep`): Exhaustive Multi-Hop Simulation & Dataset Auditing
Reserved for complex migrations, cross-service contracts, and distributed engines:
- Multi-hop transitive call chains ($N+2, N+3$).
- Automated script-driven auditing of non-code datasets (parsing JSON/CSV rows against router tables).
- Distributed failure-mode matrix (clock skew, network partitions, split-brain, database locks).

---

## Acceptance Criteria
- [x] `skills/1-hourly/recon/SKILL.md` is updated to define the 3 mandatory 1-hop checks in Default mode and specify `--deep` mode capabilities.
- [x] `skills/2-daily/review-code/SKILL.md` is updated to integrate Step N+1 checks into Phase 1 (/recon audit) and Phase 4 grading (`[Blocker]` for orphaned states, stuck retry loops, and parameter generator inversions).
- [x] All cross-references between `/recon` and `/review-code` remain consistent and DRY.
