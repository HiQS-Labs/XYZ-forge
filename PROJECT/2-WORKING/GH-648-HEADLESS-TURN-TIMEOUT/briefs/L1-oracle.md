---
title: "L1 brief — instrument + de-claw the idle oracle (umbrella #648 foundation)"
status: "Brief (input to the GH-648 headless turn-timeout marathon — not a tracked plan)"
created: 2026-09-16
updated: 2026-09-16
owner: Noel Saw
goal: >
  Make idle-kill / wall-cap / child-orphan / unknown distinguishable and stop the no-progress overclaim in utils/py/turn_diagnostics.py.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/648
---

# L1 — Instrument + de-claw the idle oracle (foundation)

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-16) | Lane fires when the marathon chain reaches this phase |

Umbrella: #648 · Radar: #293 `RADAR-class-headless-turn-timeout` · Wave 1

## Goal
In `utils/py/turn_diagnostics.py` only (callers adopt the model in L3/L5):
1. Emit a structured termination record that makes **idle-kill, wall-cap, child-orphan, and unknown** distinguishable in the run log — this is the radar precondition task in #293 ("a later radar run can answer 'how many of the last N runs' at useful N").
2. Stop the overclaim. Today sustained cpu=0 + no transcript growth yields `timeout-idle-no-progress` ("locally blocked"), but the docstring admits no network probe exists, so the same signature is a healthy turn awaiting a slow/queued backend. Without a positive in-flight check, classify `idle-unknown` (honest label); keep a `no-progress` claim only when something was actually checked. A one-shot cheap `lsof -i`-style probe at classify time is acceptable if you keep it best-effort and degrade to `unclassified` on failure — the docstring's cost concern applies to per-interval sampling, not a single classify-time probe; your call, documented in the suite.
3. Exit codes unchanged (callers keep seeing 7). Probe failure never fails the turn it describes.

## Facts (verified at HEAD a0ba9b22)
- Docstring: "A network probe (`lsof -i` ...) was considered and left out" (`turn_diagnostics.py:33`).
- `REASON_IDLE = "timeout-idle-no-progress"` (~`:90`); `idle_seconds()` `None` means "not measured yet", never "idle".
- Kill sites on this signal: `utils/py/consult.py:306`, turn shims' idle caps.

## Rules (every lane)
Python twins are authoritative — edit `utils/py/*.py`, never `relay-automation/*.sh` (frozen, GH-308). No new `.sh` under `utils/` or `relay-automation/` (GH-551). Register your suite in `validate.sh`'s TESTS array (the tier guard is bidirectional). `bash validate.sh` must pass before done.

## Acceptance / Guard
`test/gh648-l1-turn-termination.sh`: (a) a stub turn with 0 CPU growth and an established outbound connection classifies as in-flight/unknown, NOT `timeout-idle-no-progress`; (b) termination records distinguish idle-kill / wall-cap / child-orphan; (c) a failing probe degrades to `unclassified` without failing the turn. Mutation-proof the assertions (see AGENTS.md "a check that cannot fail is not a check").
