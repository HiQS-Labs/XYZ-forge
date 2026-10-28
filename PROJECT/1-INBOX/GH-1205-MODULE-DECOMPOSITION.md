---
gh_issue: 1205
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1205
title: "Audit D: split large core modules behind stable facades"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-24
updated: 2026-10-24
owner: noelsaw
doc_type: plan
effort: 4
complexity: 4
risk: 3
phases: 6
rating: "pri/sev/appeal/effort 80/75/85/35 · calc 275"
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1201
  - https://github.com/HiQS-Labs/XYZ-forge/issues/768
  - https://github.com/HiQS-Labs/XYZ-forge/issues/769
goal: Reduce large-core-module change risk through behavior-preserving extraction behind stable CLI and import facades, executing existing audit plans incrementally.
---

# GH-1205 — Large core module decomposition

## Quad Concepts

- Monolithic core files make small changes expensive → behavior-preserving seams behind existing facades.
- Source-coupled tests can hide extraction breakage → layout-aware compatibility coverage before movement.

## Evidence

Current inspection measured `releases_app.py` at 6,928 lines, `marathon_drive.py` at 3,677 lines with a roughly 2,578-line `main()`, `wave_reconcile.py` at 2,495, `jog_run.py` at 2,014, `swarm_preflight.py` at 1,891, and `relay_drive.py` at 1,159 with a roughly 1,105-line `main()`.

Prior #768/#769 audits already identify module seams, imported-symbol surfaces, and source-text/fixture-list hazards. Execute those rather than creating a parallel architecture.

## Phases

1. Make existing source-coupled suites layout-aware and map external imports/re-exports; strengthen existing suites only.
2. Extract low-risk pure helpers and value objects, keeping behavioral fixes separate.
3. Split `releases_app.py` behind its current CLI/import facade using #768 boundaries.
4. Introduce an explicit marathon run context and extract coherent groups using #769, removing closure-shared mutable cells incrementally.
5. Apply the proven pattern to other large modules only where it reduces rather than relocates complexity.
6. Review function/entry-point size, import cycles, and indirection after each independent landing.

## Acceptance

- CLI arguments, imported symbols, exit codes, artifacts, and dump bytes remain compatible unless separately approved.
- Extraction changes do not also alter runtime behavior.
- Routed existing suites cover moved subsystems and fixture module lists cannot silently omit new files.
- Marathon no longer depends on a roughly 2,500-line closure-heavy `main()`.
- Each extraction has independent full-gate evidence and rollback.

## Non-goals

No big-bang rearchitecture, abstractions for small files, runtime-language migration, or new test/gate machinery.

## Merge evidence

- PR #1209 merged 2026-10-28 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
