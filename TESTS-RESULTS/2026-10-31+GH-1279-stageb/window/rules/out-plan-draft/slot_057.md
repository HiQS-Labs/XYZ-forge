# Plan draft: #1175 Hosted factory control plane over Jog: continuous one-issue cycle (light plan + schema mapping; Anvil decision gate)

> draft; preflight and independent plan QA outstanding

- Request: `gh-1175-a383f3149bcf` (tick `slot_057`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: a383f3149bcf3c5819c006202461276a60cb0db7051b906f81207f67bb8b7878 (updated 2026-10-30T16:05:50Z)
- Dependencies: none

## Scope

_Source: issue#1175:L1 (Outcome)_

A control plane (local-first, hosted later) that keeps one XYZ-enabled repository's flywheel turning: admit one eligible issue, run it through Jog → Preflight → Marathon, get it landed, then pick the next — continuously, across restarts, with remote visibility and approvals. XYZ Forge is the first factory (dogfood: drive the backlog toward closed); other repos with vendored `.xyz` are later factories using the same control plane.

This issue records design only. Creating it does not authorize implementation, scheduling, dispatch, ledger writes, or paid execution.

## Acceptance criteria

_missing_

## Open questions

_missing_

## Write set

- `MACHINE-CONTRACTS.md` (issue#1175:L20)
- `skills/1-hourly/start-task/SKILL.md` (issue#1175:L127)

## Unresolved file names

- `loop-cost.sh` (issue#1175:L35; 2 tracked files share this name)

## Contract probes

- none
