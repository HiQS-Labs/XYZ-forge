---
title: GH-68 · Cross-agent dependency conflict detection
status: Captured
created: 2026-07-01
owner: noelsaw
priority: 4
complexity: 3
risk: 3
effort: 3
roadmap_exempt: false
---

# GH-68: Cross-agent dependency conflict detection

## Problem

When two agents work concurrently in the harness, there is no automated detection when Agent A's landed commit silently breaks a dependency Agent B is mid-flight on. Current mitigation is process-only: the Reviewer in the relay loop is expected to catch "this breaks X" before approving a turn. That is best-effort, not structural.

Specific gaps:
- No dependency graph between agents' active work items
- No pre-turn signal that an upstream shared surface (event schema, `src/project.js` API, `relay-turn-lib.sh`) changed since the agent last ran
- `validate.sh` runs per turn but only the agent whose turn it is runs it — Agent B does not re-validate after Agent A's commit lands between turns
- The turn lock (`relay-driver.lock`) only covers the turn boundary, not cross-turn dependency breakage

## Proposed fix

A lightweight **cross-agent break signal** mechanism in three steps:

1. **Post-commit hook** — after every relay turn commit lands, run `validate.sh` (or a fast subset) and diff the event schema / exported JS API surface against the previous HEAD
2. **Signal emission** — if a shared surface changed, append a `dependency.drift` event to `.tick/events/` with: `surface` (file/glob), `changed_by` (agent/turn id), `diff_summary`
3. **Pre-turn read** — each agent shim (`codex-turn.sh`, `agy-turn.sh`) reads any unacknowledged `dependency.drift` events before seeding its turn prompt, injecting a summary into the brief

## Reversibility

**Costly** — touches `.tick/events/` schema (new verb `dependency.drift`), `relay-turn-lib.sh` pre-turn read path, and both worker shims. Requires a `decisions/` record before landing. Treat as at least Costly per AGENTS.md §3.

## Out of scope (Phase 1)

- Full symbol-level dependency graph (too heavy; surface-change notification is sufficient)
- Blocking a turn on drift (warn-only initially; a blocking gate is a follow-on)

## Success criteria

- A `dependency.drift` event is emitted when a landed turn changes a shared surface
- Both `codex-turn.sh` and `agy-turn.sh` inject the drift summary into the next turn's brief
- `validate.sh` stays green; regression test covers emit + read path
- Kernel event schema change has a `decisions/` record

## Links

→ [#68](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/68)
