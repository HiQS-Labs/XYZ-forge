# Plan draft: #445 runtime:parity — turn shims reject --help when RELAY_AGENT is unset under XYZ_PYTHON=0

> draft; preflight and independent plan QA outstanding

- Request: `gh-445-f7b1f8743df1` (tick `slot_023`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 50/40/60/80
- Capture doc: PROJECT/1-INBOX/GH-445-TURN-SHIM-HELP-PARITY.md (sha256 e784cdd227ebfa124e2f6e471b99a5221a305db659b963d0a4608f2d2578ac62)
- Issue sha256: f7b1f8743df114de0abb5a5a81fb810fdc47d39de7ff36affd8e5a2cc4fd4d29 (updated 2026-09-05T16:30:24Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-445-TURN-SHIM-HELP-PARITY.md:L16 (frontmatter goal)_

Ensure turn shims handle --help / -h flags cleanly before enforcing mandatory RELAY_AGENT environment checks across both Python and Bash twins.

## Acceptance criteria

_missing_

## Open questions

_missing_

## Write set

- `relay-automation/agy-turn.sh` (issue#445:L3)
- `relay-automation/codex-turn.sh` (issue#445:L3)

## Unresolved file names

- none

## Contract probes

- none
