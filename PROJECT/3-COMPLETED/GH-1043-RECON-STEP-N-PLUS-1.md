---
gh_issue: 1043
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1043
title: "feat(recon, review-code): Step N+1 bounded downstream verification in default and exhaustive simulation in deep mode"
status: Complete
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

### 1. Default Recon & Review-Code: Bounded Step N+1 ("Logical Downstream Boundary Checks")
Every time a plan or PR touches a state write, an error path, or a solver input, the agent traces past transparent delegation (wrappers, retry decorators) to the first logical downstream boundary:
- **Consumer Behavior & Progress Check (Lane B):** When writing/transitioning state $S$, verify that deployed consumers not only exist, but actually select the newly written state/value and advance it toward a terminal state or bounded timeout/recovery path (a UI badge or display-only reader alone does not prove progress). Proposing or approving an unadvancing non-terminal state without a progress owner is a `[Blocker]`. Justified terminal/audit-only records are permitted when documented.
- **Retry-Loop & Delegation Check (Lane D):** When raising an exception or holding a claim on failure, trace past intermediate wrapper helpers to verify how the enclosing retry or lease manager behaves on the next cycle (clean recovery vs. infinite stuck retry loop without backoff/dead-letter).
- **Parameter Role Check (Lane C):** When passing state into an engine/solver, verify at `file:line` whether the callee treats it as a *constraint* (restricts/filters) or a *generator* (creates new entities) to prevent entity duplication.
- **Rollout Coexistence & Rollback Invariant (Lane C / SWE Policy):** Check backward/forward coexistence across versions and rollback feasibility per SWE migration policy when persisted contracts or status values change.

### 2. Deep Recon (`recon --deep`): Exhaustive Multi-Hop Simulation & Dataset Auditing
Reserved for complex migrations, cross-service contracts, and distributed engines (not for finishing an ordinary check hidden behind one wrapper):
- Multi-hop transitive call chains ($N+2, N+3$).
- Automated script-driven auditing of non-code datasets (parsing JSON/CSV rows against router tables).
- Distributed failure-mode matrix (clock skew, network partitions, split-brain, database locks).

---

## Acceptance Criteria
- [x] `skills/1-hourly/recon/SKILL.md` is updated to define the mandatory logical downstream boundary checks in Default mode (verifying consumer advancement, tracing past transparent delegation, checking rollout coexistence) and specify `--deep` mode capabilities.
- [x] `skills/2-daily/review-code/SKILL.md` is updated to integrate Step N+1 checks into Phase 1 (/recon audit) and Phase 4 grading (`[Blocker]` for unadvancing stranded states, stuck retry loops, and parameter generator inversions) while remaining lean and DRY by invoking `recon`'s policy.
- [x] Generator Sharpening: `skills/3-weekly/weekly-planner/scripts/planner_core.py` and `skills/3-weekly/weekly-planner/SKILL.md` are updated to anchor weekly plans in release milestones (`releases_app.py next`), ground active intake in live GitHub open issues (dropping closed/retired/foreign issues), isolate held drafts / evidence carriers (#1039, #1033, #930, #954, #1024) in Phase 5 with explicit hold reasons, and ground task assignments in explicit assignees.
- [x] Regression verification: removed the unapproved new `test/test_planner_core.py` suite; retained and replayed its fixtures as manual evidence, plus original-failure witnesses, negative controls, actual CLI/DB parity and existing suites under `TESTS-RESULTS/2026-10-14+GH-1043/`.
- [x] All cross-references between `/recon`, `/review-code`, `/weekly-planner`, and `/daily-planner` remain consistent and DRY.

## Landing repair recon (2026-10-14)

- Source: PR head `b706ac89`; fresh development merged through the supported disjoint ledger writer (`5f2b8bb8`). Graph generation 2026-09-01 is stale and does not track the planner paths; source reads used instead.
- Entry: weekly/daily skill instructions invoke `planner_core.py main`, which obtains live PRs, classifies their dependencies, and renders weekly or daily output.
- State/contract: `get_open_issues` grounds `ingest_weekly_intake`; native DB and CLI input share eligibility/scoring; valid empty native input is authoritative. Read-only ledger queries supply release/manifest, marathon and Jog context; no queue is dispatched.
- Consumer: `format_weekly_markdown` and `format_daily_markdown` consume merge-ready groups. A held or cyclic prerequisite must keep successors out of landing instructions. Explicit receipt-only purpose is distinct from ordinary validation receipts.
- Repair: propagate unavailable/truncated live intake, preserve filtered-empty results, share DB/CLI scoring and risk enrichment, scope native rows to the selected repo, exclude cut releases from target fallback, retain deferred vision work, and match assignment/blocker prose to implemented behavior.
- Verification: retain the removed unapproved fixture as manual input under `TESTS-RESULTS/2026-10-14+GH-1043/manual/`; replay it and targeted adverse cases only in a disposable full clone. No new suite, registry entry, runtime dependency or gate.
- Unknown: actual IDE skill discovery must be observed separately from successful filesystem link read-through.

### Independent review follow-up

Round1 independently reproduced canonical deferred rows entering active work and the actual `roadmap list --json` producer omitting rating/risk fields. The additive JSON export in `utils/py/releases_app.py` now supplies all five rating fields and risk using the existing schema-tolerant column reader; site-build and HQ rollup consumers accept extra keys. Planner deferral now respects canonical sections and explicit pause markers, and DB repository identity follows the ledger setting. Actual producer/consumer probes verified parity (79 active,62 scored; GH-418321) and parked GH-920/GH-974, with negative controls and unchanged ledger hashes. Existing status-label suite42/42 passed.

### Final review and publication

Round3 independently approved the selected-repository fallback repair at reviewed head `2cef261b8c46fb1db37052b723a9e0b0bb2d7937`; relay-drive attestation is committed in `relay-system/2026-10-14/gh1044-landing.codex.md`. Actual shared-ledger probes prove foreign URL-less overlapping issue numbers are excluded; removing the filter reproduces contamination. Older CLI producers without selection/rating metadata stop with an update instruction. Weekly/daily instructions resolve the installed bundle and state producer-first compatibility.

Publication evidence: broad revision0200a962 passed409/409 full gate in1027s (one suite retry); final production revision2cef261b passed28/28 tier2 releases/docs checks in366s (no retry), selected by the normal push hook. Both ran in separate full clones; logs and telemetry are retained under `publication/`. These are development landing checks, not release-promotion evidence. GitHub smoke run38635391443 passed on2cef261b. No deployed-payload mutation has occurred before merge.
