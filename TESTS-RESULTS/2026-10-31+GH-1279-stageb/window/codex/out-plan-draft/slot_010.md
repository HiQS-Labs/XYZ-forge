# Plan draft: #1205 Audit D: split large core modules behind stable facades

> draft; preflight and independent plan QA outstanding

- Request: `gh-1205-3e4e8bb869c9` (tick `slot_010`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 80/75/85/35
- Capture doc: PROJECT/1-INBOX/GH-1205-MODULE-DECOMPOSITION.md (sha256 6cf55cff9a4d3e17082f3f0f103704972427f000a91c88e366b9ca8901e13576)
- Issue sha256: 3e4e8bb869c9045497ba6a5f43fc82a2ae2f91260363d3a698365ffaa575194d (updated 2026-10-24T21:37:39Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-1205-MODULE-DECOMPOSITION.md:L19 (frontmatter goal)_

Reduce large-core-module change risk through behavior-preserving extraction behind stable CLI and import facades, executing existing audit plans incrementally.

_Source: codex-authored (codex-authored)_

Use audits #768 and #769 to plan incremental, behavior-preserving extraction behind the existing releases and marathon facades.

_Source: codex-authored (codex-authored)_

Map external imports and make existing source-coupled tests and fixture lists layout-aware before moving code.

_Source: codex-authored (codex-authored)_

Extract pure helpers first, then coherent releases and marathon seams; consider other large modules only where the established approach reduces complexity.

_Source: codex-authored (codex-authored)_

Measure function sizes, import cycles, and indirection after each independent landing.

## Acceptance criteria

_Source: issue#1205:L30 (Acceptance criteria)_

- Existing CLI arguments, imported symbols, exit codes, machine artifacts, and dump bytes remain compatible unless separately approved.
- No extraction PR also changes runtime behavior.
- Existing routed suites cover every moved subsystem; no source-layout-sensitive fixture silently loses a new module.
- `marathon_drive.py` no longer depends on a roughly 2,500-line closure-heavy `main()`.
- Each extraction lands independently with a rollback path and appropriate full-gate evidence from an isolated clone.

_Source: PROJECT/1-INBOX/GH-1205-MODULE-DECOMPOSITION.md:L44 (Acceptance)_

- CLI arguments, imported symbols, exit codes, artifacts, and dump bytes remain compatible unless separately approved.
- Extraction changes do not also alter runtime behavior.
- Routed existing suites cover moved subsystems and fixture module lists cannot silently omit new files.
- Marathon no longer depends on a roughly 2,500-line closure-heavy `main()`.
- Each extraction has independent full-gate evidence and rollback.

_Source: codex-authored (codex-authored)_

Existing CLI arguments, imported symbols, exit codes, machine artifacts, and dump bytes remain compatible unless separately approved.

_Source: codex-authored (codex-authored)_

Extraction changes do not also change runtime behavior, and existing routed suites cover moved subsystems without silently omitting new modules.

_Source: codex-authored (codex-authored)_

Marathon no longer depends on a roughly 2,500-line closure-heavy main function.

_Source: codex-authored (codex-authored)_

Each extraction lands independently with a rollback path and appropriate full-gate evidence from an isolated clone.

_Source: codex-authored (codex-authored)_

The plan adds no new test suites or gate machinery and avoids a big-bang rearchitecture.

## Open questions

_Source: codex-authored (codex-authored)_

What work from audits #768 and #769 has already landed, and which seams remain?

_Source: codex-authored (codex-authored)_

Which external imports, re-exports, and layout-sensitive fixtures must each extraction preserve?

## Write set

- `utils/py/releases_app.py` (issue#1205:L3)
- `utils/py/marathon_drive.py` (issue#1205:L3)
- `utils/py/wave_reconcile.py` (issue#1205:L11)
- `utils/py/jog_run.py` (issue#1205:L12)
- `utils/py/swarm_preflight.py` (issue#1205:L12)
- `utils/py/relay_drive.py` (issue#1205:L13)

## Unresolved file names

- none

## Contract probes

- none
