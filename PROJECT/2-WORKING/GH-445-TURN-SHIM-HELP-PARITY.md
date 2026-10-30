---
title: "GH-445: runtime:parity — turn shims reject --help when RELAY_AGENT is unset under XYZ_PYTHON=0"
status: Active
created: 2026-09-05
updated: 2026-10-30
owner: orchestrator (Claude Code)
gh_issue: 445
source: https://github.com/HiQS-Labs/XYZ-forge/issues/445
doc_type: plan
effort: 1
complexity: 1
risk: 1
rating: "pri/sev/appeal/effort 50/40/60/80 · calc 230"
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/470
  - https://github.com/HiQS-Labs/XYZ-forge/issues/299
goal: >
  Ensure turn shims handle --help / -h flags cleanly before enforcing mandatory RELAY_AGENT
  environment checks across both Python and Bash twins.
---

# GH-445: turn shim help parity under XYZ_PYTHON=0

## Status

| What was just completed | What's next |
|---|---|
| Fix `311b47b9`: both Bash fallbacks answer `--help`/`-h` like their Python twins, under a `Frozen-twin-exception` trailer; checks in `TESTS-RESULTS/2026-10-30+GH-445/` | Final Codex QA and the PR |

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

## Held-lane findings (attempt 1, 2026-09-06)

The GH-462 10-day arc held this lane rather than forcing it (frozen-file refusal, GH-308);
its findings and the two remedy options are tracked in
[#470](https://github.com/HiQS-Labs/XYZ-forge/issues/470).

## Delivery plan (2026-10-30, GH-470 remedy (a))

- **Decision:** the operator chose remedy (a) from #470: hand-carry the fix into the frozen Bash twins with a `Frozen-twin-exception:` trailer naming both files (AGENTS.md, GH-308/GH-321 rule). Remedy (b), a preflight exception path, is not built.
- **Change:** in `relay-automation/agy-turn.sh` and `relay-automation/codex-turn.sh`, answer `-h`/`--help` before the `RELAY_AGENT`/`RELAY_FILE` checks, printing the same two lines and exit 0 as the Python twins (`utils/py/agy-turn.py`, `utils/py/codex-turn.py` `main()`), byte for byte, so the GH-299 cross-twin oracle sees no divergence.
- **Simple change:** two local, reversible edits with no open design decision, so plan QA is skipped; final Codex QA still runs.
- **Verify:** `XYZ_PYTHON=0` and `XYZ_PYTHON=1` `--help` / `-h` give identical stdout and exit 0 with `RELAY_AGENT` unset; without `--help` the Bash shim still exits 2 `RELAY_AGENT required` (red control); `bash test/gh308-frozen-twin-guard.sh` accepts the commit only with the trailer; full gate once (changed `.sh` → full route).
- **Rating:** #445 keeps `50/40/60/80`; #470 rated `45/30/50/85` (a decision issue; fixed by the same change).
