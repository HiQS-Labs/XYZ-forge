# Plan draft: #1171 relay-drive preflight treats a backticked branch name on the "Artifact under review:" line as a missing worktree path and exits 2

> draft; preflight and independent plan QA outstanding

- Request: `gh-1171-58683ea13933` (tick `slot_051`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: 58683ea13933b806b8a31abda5ad268c1d5b3142384a95ed40825a7fa83b7a47 (updated 2026-10-31T03:48:18Z)
- Dependencies: none

## Scope

_Source: codex-authored (codex-authored)_

Verify the reported preflight failure and current artifact-path parsing before planning a targeted fix.

_Source: codex-authored (codex-authored)_

Distinguish branch references from missing file paths while preserving preflight validation.

## Acceptance criteria

_Source: issue#1171:L28 (Acceptance)_

- A thread naming a branch `fix/foo` on the `Artifact under review:` line passes preflight.
- A thread naming a genuinely missing file path (e.g. `docs/missing.md`) still fails preflight with the existing message.
- Regression test covering both cases.

_Source: codex-authored (codex-authored)_

A thread naming an existing branch such as fix/foo passes preflight.

_Source: codex-authored (codex-authored)_

A genuinely missing file such as docs/missing.md still fails with the existing error message.

_Source: codex-authored (codex-authored)_

A regression test covers both cases.

## Open questions

_Source: codex-authored (codex-authored)_

Has the issue already been fixed, and which existing test suite covers relay preflight?

_Source: codex-authored (codex-authored)_

How should unresolved branch names be distinguished from missing paths?

## Write set

- `relay-automation/relay-drive.sh` (issue#1171:L3)

## Unresolved file names

- none

## Contract probes

- none
