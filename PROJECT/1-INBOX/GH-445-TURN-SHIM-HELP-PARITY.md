---
title: "GH-445: runtime:parity — turn shims reject --help when RELAY_AGENT is unset under XYZ_PYTHON=0"
status: Queued
created: 2026-09-05
updated: 2026-09-05
owner: orchestrator (Claude Code)
gh_issue: 445
source: https://github.com/HiQS-Labs/XYZ-forge/issues/445
doc_type: plan
effort: 1
complexity: 1
risk: 1
rating: "pri/sev/appeal/effort 50/40/60/80 · calc 230"
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/299
goal: >
  Ensure turn shims handle --help / -h flags cleanly before enforcing mandatory RELAY_AGENT
  environment checks across both Python and Bash twins.
---

# GH-445: turn shim help parity under XYZ_PYTHON=0

## Why

During the GH-299 Gen 4 ATE 3-hour soak (14,825 mutations), the differential cross-twin parity oracle
recorded 1,144 divergences between authoritative Python entry points (`utils/py/agy_turn.py`,
`utils/py/codex_turn.py`) and their Bash twin fallbacks (`relay-automation/agy-turn.sh`,
`relay-automation/codex-turn.sh` under `XYZ_PYTHON=0`).

Authoritative Python turn shims parse `--help` / `-h` early and output usage with exit code 0 regardless
of environment. The frozen Bash fallbacks (`XYZ_PYTHON=0`) perform an immediate mandatory check for
`RELAY_AGENT` before inspecting arguments:
```bash
[ -n "${RELAY_AGENT:-}" ] || { echo "<shim>: RELAY_AGENT required" >&2; exit 2; }
```
When invoked with `--help` without `RELAY_AGENT` set in the environment, the Bash twin rejects with exit
code 2 and `<shim>: RELAY_AGENT required`, whereas the Python twin succeeds with exit code 0.

## Plan

1. In `relay-automation/agy-turn.sh` and `relay-automation/codex-turn.sh`, evaluate `--help` / `-h` before
   enforcing `RELAY_AGENT`. Include frozen-twin-exception trailers per GH-308 / GH-321.
2. Add regression tests asserting twin agreement on `--help` with `XYZ_PYTHON=0`.
