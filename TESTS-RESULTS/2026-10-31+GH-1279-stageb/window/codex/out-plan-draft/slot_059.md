# Plan draft: #1175 Hosted factory control plane over Jog: continuous one-issue cycle (light plan + schema mapping; Anvil decision gate)

> draft; preflight and independent plan QA outstanding

- Request: `gh-1175-a383f3149bcf` (tick `slot_059`)
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

_Source: codex-authored (codex-authored)_

Verify the current Jog, Marathon, admission, landing, and ledger behavior against the issue's observations before drafting the design.

_Source: codex-authored (codex-authored)_

Design a local-first control plane for a continuous one-issue cycle, including a light plan, schema mapping, restart recovery, visibility, and approval boundaries.

_Source: codex-authored (codex-authored)_

Keep the design separate from implementation, scheduling, dispatch, ledger writes, and paid execution.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

The design preserves Marathon as execution authority and Jog as owner of queue rows, leases, park and land decisions, and its execution ledger.

_Source: codex-authored (codex-authored)_

The design addresses admission, contract readiness, landing, failure handling, host-local leases, per-checkout state, and cost information without assuming unverified sources.

_Source: codex-authored (codex-authored)_

Interrupted work is parked on cold start rather than silently refired, and landing remains subject to operator approval.

_Source: codex-authored (codex-authored)_

The plan identifies prerequisites, schema mappings, and the Anvil decision gate.

## Open questions

_Source: codex-authored (codex-authored)_

What remaining phases and decisions appear beyond the truncated issue body, including the details of the Anvil decision gate?

_Source: codex-authored (codex-authored)_

Which reported gaps and prerequisite issue states remain current?

_Source: codex-authored (codex-authored)_

What verified source can provide cost information for budget enforcement?

## Write set

- `MACHINE-CONTRACTS.md` (issue#1175:L20)
- `skills/1-hourly/start-task/SKILL.md` (issue#1175:L127)

## Unresolved file names

- `loop-cost.sh` (issue#1175:L35; 2 tracked files share this name)

## Contract probes

- none
