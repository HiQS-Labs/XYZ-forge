# Plan draft: #1284 factory-primitive: status on an uninitialized run root creates state.db, then init refuses

> draft; preflight and independent plan QA outstanding

- Request: `gh-1284-c6da09c84510` (tick `slot_049`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: c6da09c84510956bd30651d09c54f4726061b7ab1f9b286a45dd36716dc5428d (updated 2026-10-31T03:56:29Z)
- Dependencies: none

## Scope

_Source: codex-authored (codex-authored)_

Verify the current status and initialization paths and whether the reported behavior remains reproducible.

_Source: codex-authored (codex-authored)_

Plan a change so querying an uninitialized run root does not create instance state.

## Acceptance criteria

_Source: issue#1284:L27 (Acceptance)_

Run `status` and then `init` on a fresh run root: `init` exits 0 and no `state.db` exists after `status` alone. Confirm on the existing `factory-primitive` suite (no new tests, GH-831).

_Source: codex-authored (codex-authored)_

After status alone on a fresh run root, no state.db exists and status reports that the instance is not initialized or returns a documented refusal.

_Source: codex-authored (codex-authored)_

Running init after that status query succeeds.

_Source: codex-authored (codex-authored)_

Confirm the behavior using the existing factory-primitive suite without adding tests.

## Open questions

_Source: codex-authored (codex-authored)_

Has the reported behavior already been fixed, and what status response does the current interface support?

## Write set

- `utils/py/harness.py` (issue#1284:L13)

## Unresolved file names

- none

## Contract probes

- none
