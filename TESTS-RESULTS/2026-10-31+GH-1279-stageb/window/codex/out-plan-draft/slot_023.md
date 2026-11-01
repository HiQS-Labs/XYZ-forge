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

_Source: codex-authored (codex-authored)_

Verify the current status of issue #445 and the held-lane findings in #470, including the applicable frozen-file policy and remedy options.

_Source: codex-authored (codex-authored)_

Reproduce help behavior across the Python and Bash turn shims, then plan the appropriate parity fix and regression coverage.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

Both --help and -h display usage and exit 0 without RELAY_AGENT across the Python and Bash twin entry points.

_Source: codex-authored (codex-authored)_

Regression coverage checks both turn shims with XYZ_PYTHON=0 and compares their help behavior with the authoritative Python entry points.

_Source: codex-authored (codex-authored)_

Any changes to frozen Bash twins follow the applicable exception requirements.

## Open questions

_Source: codex-authored (codex-authored)_

What are the two remedy options recorded in #470, and has either been adopted or implemented?

_Source: codex-authored (codex-authored)_

What frozen-twin exception requirements currently apply?

## Write set

- `relay-automation/agy-turn.sh` (issue#445:L3)
- `relay-automation/codex-turn.sh` (issue#445:L3)

## Unresolved file names

- none

## Contract probes

- none
