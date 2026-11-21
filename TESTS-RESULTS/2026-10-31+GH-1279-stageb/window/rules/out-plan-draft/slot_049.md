# Plan draft: #1171 relay-drive preflight treats a backticked branch name on the "Artifact under review:" line as a missing worktree path and exits 2

> draft; preflight and independent plan QA outstanding

- Request: `gh-1171-58683ea13933` (tick `slot_049`)
- Draft status: **missing-scope** (held: no sourced scope)
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: 58683ea13933b806b8a31abda5ad268c1d5b3142384a95ed40825a7fa83b7a47 (updated 2026-10-31T03:48:18Z)
- Dependencies: none

## Scope

_missing_

## Acceptance criteria

_Source: issue#1171:L28 (Acceptance)_

- A thread naming a branch `fix/foo` on the `Artifact under review:` line passes preflight.
- A thread naming a genuinely missing file path (e.g. `docs/missing.md`) still fails preflight with the existing message.
- Regression test covering both cases.

## Open questions

_missing_

## Write set

- `relay-automation/relay-drive.sh` (issue#1171:L3)

## Unresolved file names

- none

## Contract probes

- none
