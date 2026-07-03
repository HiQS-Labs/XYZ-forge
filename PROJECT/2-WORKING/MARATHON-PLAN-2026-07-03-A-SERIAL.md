---
title: Marathon Plan A (2026-07-03) — concurrency-safety core, SERIAL / Opus-direct
status: Active (2-WORKING)
created: 2026-07-03
updated: 2026-07-03
owner: noel
branch: main
doc_type: project
source: hand-curated from ROADMAP.md open ledger (operator-picked lane set)
generated_by: hand-authored (not utils/marathon-plan.sh — a curated subset, not the full-ledger ranking)
roadmap_exempt: true
goal: >
  Run the five items that make higher concurrency SAFE and higher throughput real —
  the token-terminality kernel plus the scheduler/coordinator trio — strictly SERIAL,
  Opus 4.8 (high), operator-direct (NOT headless marathon-drive). These lanes overlap
  the projection/containment/scheduler core, so only one may be in flight at a time.
lanes: [41, 3, 4, 5, 30]
execution: serial · Opus 4.8 · reasoning=high · operator-direct kernel pass
---

# Marathon Plan A — 2026-07-03 · concurrency-safety core (SERIAL)

> Curated subset of [ROADMAP.md](../../ROADMAP.md), not the full-ledger ranking. Sibling of
> [Plan B (parallel dogfood)](MARATHON-PLAN-2026-07-03-B-PARALLEL.md). Each lane's execution
> detail lives in its `PROJECT/**` doc / GH issue; this is the scheduling + rationale overlay.

## Why serial, why Opus-direct

Every lane here mutates the **serialization bottleneck** — the projection kernel
(`src/project.js`), the containment kernel (`relay-automation/relay-turn-lib.sh`), or the
scheduler/coordinator (`marathon-drive.sh` / `utils/swarm-preflight.sh`). Their write-sets
overlap, so they **cannot** be parallel-safe. And #41 rewrites token terminality — the invariant
every *other* concurrent lane depends on — so it is done first, by hand, under Opus 4.8 (high),
**not** headless (`builder=claude` is not headless-capable per [#58]; and kernel edits want an
operator in the loop, not a codex self-commit).

## The dependency spine

`#41` (make `done` terminal) is the foundation: with more parallel agents, more higher-epoch
`task.claimed` events race a completed task, and today a `done` token silently resurrects. Land
that invariant first; then the scheduler/coordinator trio can safely assume a sound token model.

## Serial sequence (run top-to-bottom; do not overlap)

| # | Item | cx/risk/eff | Zone (write-set) | Why here |
|---|------|-------------|------------------|----------|
| 1 | **#41** · `task.done` not terminal vs higher-epoch reclaim (terminality-seal) | 4/4/3 | **kernel** — `src/project.js` `foldWithMeta` | Foundation. Ready + contracted + spiked 7/7; Option A decided (`decisions/2026-07-02-terminality-seal.md`). Every concurrent lane's safety rests on this. |
| 2 | **#3** · Parked-claim threshold false-positives autonomous agents | —/—/— (rate) | coordinator — parked-claim detection (`src/` + `bin/tick`) | Small. Removes a *false reclaim* of long-atomic-tool-call agents; without it, #4's work-stealing would steal live claims. |
| 3 | **#4** · Lane imbalance + no work-stealing undercuts concurrency bar | —/—/— (rate) | scheduler — `relay-automation/marathon-drive.sh` (+`src`) | Raises *effective* parallelism (the ~51% bar left on the table). Depends on #3's honest parked signal. |
| 4 | **#5** · Promote pinned shared-contract seam + warn on coupled lanes | —/—/— (rate) | coordinator — `utils/swarm-preflight.sh` / `marathon-plan.sh` / `relay-turn-lib.sh` | Lets you fan out WIDER safely (auto-detect coupled write-sets). Builds on the sound token + scheduler model above. |
| 5 | **#30** · Optional centralized transcript archive (`XYZ_ARCHIVE_ROOT`) | 3/4/3 | **kernel** — `relay-automation/relay-turn-lib.sh` | Orthogonal kernel, phase-gated (Phase 1 resolver = safe slice; Phase 3 containment = risky). Last because least-coupled to the others. Phase-0 model A decided. |

`—/—/—` = not yet PDDA-rated. Rate (`utils/pdda/pdda.sh frontmatter`) before firing, or accept operator-direct sequencing as-is (these are hand-picked, not auto-ranked).

## Execution contract

- **Model:** Opus 4.8, reasoning **high**. Operator-direct (this window drives each lane) — **not** `marathon-drive.sh` headless.
- **One lane in flight at a time.** Finish → gate → commit → push → next. No worktree parallelism (write-sets overlap the kernel).
- **Per lane:** open/refresh the GH-<n> pointer doc (issue-first SOP), branch `marathon/gh-<n>-<slug>-2026-07-03`, implement, add/extend its test, `./validate.sh` green, commit file-scoped, push, move doc INBOX→COMPLETED, update ROADMAP/CHANGELOG.
- **#41 gate is special:** the terminality-seal canary (`canary-token-reuse` inversion + `claim-after-terminal`) must stay reorder-deterministic and 7/7; no `task.done`→`claimed` transition may survive.

## Not in Plan A
Everything else is in [Plan B](MARATHON-PLAN-2026-07-03-B-PARALLEL.md) (parallel dogfood) or parked (#87 behind PR #98, now merged).
