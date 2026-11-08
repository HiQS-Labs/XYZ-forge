# Plan draft: #1205 Audit D: split large core modules behind stable facades

> draft; preflight and independent plan QA outstanding

- Request: `gh-1205-3e4e8bb869c9` (tick `slot_008`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 80/75/85/35
- Capture doc: PROJECT/1-INBOX/GH-1205-MODULE-DECOMPOSITION.md (sha256 6cf55cff9a4d3e17082f3f0f103704972427f000a91c88e366b9ca8901e13576)
- Issue sha256: 3e4e8bb869c9045497ba6a5f43fc82a2ae2f91260363d3a698365ffaa575194d (updated 2026-10-24T21:37:39Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-1205-MODULE-DECOMPOSITION.md:L19 (frontmatter goal)_

Reduce large-core-module change risk through behavior-preserving extraction behind stable CLI and import facades, executing existing audit plans incrementally.

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

## Open questions

_missing_

## Write set

- `utils/py/releases_app.py` (issue#1205:L3)
- `utils/py/marathon_drive.py` (issue#1205:L3)
- `utils/py/wave_reconcile.py` (issue#1205:L11)
- `utils/py/jog_run.py` (issue#1205:L12)
- `utils/py/swarm_preflight.py` (issue#1205:L12)
- `utils/py/relay_drive.py` (issue#1205:L13)

## Unresolved file names

- none
