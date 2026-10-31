# Plan draft: #1210 relay-drive --review-once: four launch traps surface one per run (shim, token seed, block validator, CODEX_AGENT) — add a single preflight or launcher

> draft; preflight and independent plan QA outstanding

- Request: `gh-1210-d95ad16fa003` (tick `slot_071`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: d95ad16fa0035e8472303ef2e0845899c2c90ab4046d34c53a1b9c1769efd8b4 (updated 2026-10-24T22:12:03Z)
- Dependencies: none

## Scope

_Source: codex-authored (codex-authored)_

Verify the reported review-once launch failures and existing token-seeding mechanisms, then assess either a consolidated preflight or a launcher that reuses existing code.

_Source: codex-authored (codex-authored)_

Resolve the fresh-thread contradiction between relay scaffolding and release validation or its documentation.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

The selected approach addresses the agent command, token handoff, and required agent environment in a single launch workflow.

_Source: codex-authored (codex-authored)_

Fresh-thread token seeding is compatible with the documented workflow.

_Source: codex-authored (codex-authored)_

Verify with the existing relay review-once and handoff suites and a recorded manual launch; add no new tests.

## Open questions

_Source: codex-authored (codex-authored)_

Are the reported launch traps reproducible in the current driver and shims?

_Source: codex-authored (codex-authored)_

Which approach can reuse the existing token-seeding behavior without duplicating it?

## Write set

- `relay-automation/relay-drive.sh` (issue#1210:L7)
- `relay-automation/codex-turn.sh` (issue#1210:L8)
- `relay-system/2026-10-24/gh1195-plan-qa.md` (issue#1210:L9)
- `relay-automation/README.md` (issue#1210:L13)
- `utils/py/relay_drive.py` (issue#1210:L17)
- `utils/py/marathon_drive.py` (issue#1210:L18)
- `utils/py/jog_run.py` (issue#1210:L18)
- `test/relay-review-once.sh` (issue#1210:L22)
- `test/relay-turn-handoff.sh` (issue#1210:L22)

## Unresolved file names

- `find-harness.sh` (issue#1210:L8; 2 tracked files share this name)
- `new-relay.sh` (issue#1210:L13; 2 tracked files share this name)

## Contract probes

- none
