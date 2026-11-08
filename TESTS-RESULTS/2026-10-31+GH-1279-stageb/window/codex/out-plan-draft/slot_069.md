# Plan draft: #1216 resolve-profile: Aider profile with gateway openrouter emits AIDER_MODEL without the openrouter/ prefix

> draft; preflight and independent plan QA outstanding

- Request: `gh-1216-e9763e64b97d` (tick `slot_069`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: e9763e64b97d85d3b4f7f781e9307921a16f18777215c64d770902cc0b886fb1 (updated 2026-10-25T05:23:32Z)
- Dependencies: none

## Scope

_Source: codex-authored (codex-authored)_

Verify the reported Aider profile behavior and current gateway handling, then plan the smallest compatible correction.

_Source: codex-authored (codex-authored)_

Preserve already-prefixed OpenRouter model values and assess the validation alternative if prefixing is unsuitable.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

An Aider profile using the openrouter gateway emits an OpenRouter-prefixed AIDER_MODEL.

_Source: codex-authored (codex-authored)_

An already-prefixed model is not prefixed twice, and other gateway behavior remains correct.

## Open questions

_Source: codex-authored (codex-authored)_

Is the reported behavior still reproducible on the current code, and what existing tests cover profile environment output?

## Write set

- `relay-automation/resolve-profile.sh` (issue#1216:L2)
- `utils/py/aider-turn.py` (issue#1216:L19)
- `utils/py/profile_resolve.py` (issue#1216:L22)

## Unresolved file names

- none

## Contract probes

- none
