---
title: "GH-496: Reduce merge churn, then select CI by impact"
status: In progress
created: 2026-09-07
updated: 2026-09-10
owner: Antigravity (implementation); independent reviewer (QA)
goal: Reduce merge churn by relocating routine telemetry and decoupling generated views first, then select CI by impact across four profiles using the existing selector
gh_issue: 496
source: https://github.com/HiQS-Labs/XYZ-forge/issues/496#issuecomment-5611834496
branch: feat/gh496-selective-ci
doc_type: enhancement
effort: 4
complexity: 3
risk: 2
---

# GH-496 — Reduce Merge Churn, Then Select CI by Impact

Canonical implementation plan: [Issue 496 Comment 5611834496](https://github.com/HiQS-Labs/XYZ-forge/issues/496#issuecomment-5611834496)
Steering / Execution alignment: XYZ AgentChorus #358084 (stored in AgentChorus store)

## Status

| What was just completed | What's next |
|---|---|
| Full gate passed (368/368) in disposable clone; test logs & provenance recorded in TESTS-RESULTS/2026-09-09+GH-496-PR1 | Commit test receipts; run relay review; push & open PR 1 |

## Problem statement

Historical merge landing data (last 40 first-parent commits on `development`) shows routine churn on 6 shared files:
- `releases.sql` / `releases.db` (22/40)
- `ROADMAP-DASHBOARD.md` (19/40)
- `LEADERBOARD.md` (18/40)
- `harnesses.sql` / `harnesses.db` (7/40)

These shared files cause repeated merge collisions across parallel task branches, dirty checkouts, and trigger expensive Tier-3 gate runs. Per the canonical plan synthesized by Astra and consensus reached in AgentChorus #358084, we address this in an ordered sequence of focused PRs.

## Multi-PR Sequence (AgentChorus #358084 Consensus)

1. **PR 1: Phase 0 (Baseline Freeze & Recon) + Phase 1 (Out-of-Tree Telemetry Relocation)**
   - Replay baseline file sets and commit recon map.
   - Route live invocation/evaluation telemetry in `harness_app.py` out of task checkouts to stable runtime location (`~/.xyz/projects/<stable-project-key>/telemetry/harnesses.db`), preserving versioned curated registry configurations in git.
2. **PR 2: Phase 2 (Single Reconciliation Owner, View Decoupling & Pre-Merge Closeout Checks)**
   - Task branches stop committing routine `ROADMAP-DASHBOARD.md` and `LEADERBOARD.md`; reconciler owns generated views.
   - Pre-merge closeout checks detect missing metadata (e.g. Lessons Learned) before merge.
3. **PR 3: Phase 3 (Conditional Release DB Transport Change Spike)**
   - Spike untracking `releases.db`, treating `releases.sql` as versioned logical transport, with atomic `check --rebuild` bootstrap.
4. **PR 4: Phase 4 (Four Impact Profiles in `ci-route.sh`)**
   - CI/CD, Skills, Core harness, and Accessories profiles extending existing subsystem registry.
5. **PR 5: Phase 5 (Contention Serialization & Speed Benchmark)**
   - Serialize known-flaky contention (GH-528) and measure performance across replay corpus.

## PR 1 Execution Checklist (Phase 0 & Phase 1)

### Phase 0: Baseline Freeze, Recon Map, and Preservation Spikes
- [x] Create fresh full clone at `~/marathon-clones/xyz-gh496-build` on `feat/gh496-selective-ci`.
- [x] Install and verify git hooks (`bash githooks/install.sh --check`).
- [x] Grounded recon of `harness_app.py`, writers, readers, callers, and runtime paths.
- [x] Isolated preservation spikes: verify existing path overrides, assert no writes to tracked repo during turns, ensure model/device registry reads remain intact.
- [x] Baseline replay of changed-file sets from #495, #526, #531.

### Phase 1: Stop Routine Telemetry from Rewriting Task Branches
- [x] Update `harness_app.py` path resolution to default runtime telemetry to `~/.xyz/projects/<stable-project-key>/telemetry/harnesses.db` when not overridden.
- [x] Preserve environment overrides: `XYZ_HARNESS_DB`, `XYZ_HARNESS_SQL`, `XYZ_HARNESS_GENERATED_MD`, `XYZ_HARNESS_DOCS_DIR`.
- [x] Keep versioned model/harness registry inputs intact in git while runtime logs append to external store.
- [x] Concurrency, migration, and idempotent import tests with fixture-contained paths (`test/gh496-telemetry-isolation.sh`).
- [x] Witnessed red controls: dropped row, writer directed to checkout, conflicting ID, foreign key validation.
- [x] Verify clean git status on ordinary harness/relay turns.

## Acceptance Criteria (PR 1)
- [x] Live harness turns write invocation logs and evaluations to external runtime store without modifying tracked files in task clone.
- [x] Tests hermetically contain all telemetry writes to fixture directories with zero writes to real home directory.
- [x] Curated model registry configurations and benchmarks remain versioned and accessible in git.
- [x] Full gate passes in a disposable clone with committed provenance and test logs.
