---
gh_issue: 48
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/48
title: Generalize marathon-plan's zone model for true cross-repo pre-pre-flight
status: Proposed (1-INBOX — not yet active)
created: 2026-06-29
doc_type: feedback
---

> **Inbox capture.** Per PDDA, a `1-INBOX/GH-*.md` doc carries no `## Status` table while it sits
> here; it is the capture, not the active-work doc. Promote to `2-WORKING/` (keeping the `GH-48`
> prefix + adding the exact status table) when execution starts.

## Problem

`utils/marathon-plan.sh` (the pre-pre-flight planner) computes swarm-vs-serialize batching from a
**zone model hardcoded to this repo's architecture**. `zoneOf()` labels each item
`kernel | shim | independent`:

- **proven zone** (from a contract write-set): artifacts touching `relay-turn-lib.sh` / `bin/tick` /
  `relay-drive` → `kernel`; `*-turn.sh` / `consult.sh` → `shim`; else `independent`.
- **keyword-inferred** (no contract): regex on `relay-turn-lib|containment kernel|bin/tick|relay-drive|commit semantics`
  → kernel; `-turn.sh|consult.sh|shim` → shim; else independent.

Run it against an **external repo** (e.g. `rebalance-OS`, a Swift/Python app) and every item
collapses to `independent` — the classifier has no model of that repo's own collision zones. It would
**miss** rebalance's real serialization constraint: the shared signed helper
`scripts/apple_reminders_helper_app.swift`, which the rebalance QUEUE explicitly flags as
"one writer at a time."

Separately, marathon-plan reads **this** repo's `ROADMAP.md` ledger format; a foreign repo's
hand-authored queue (e.g. rebalance's `QUEUE-2026-06-27.md`) is a different shape it can't parse.

The generic part already exists: `swarm-preflight`'s **write-set disjointness** (`artifacts[]` /
`lanes`) is repo-agnostic and supports `--target-root`. The gap is the **ranker/zone classifier**.

## Goal

Make marathon-plan usable as a **true cross-repo pre-pre-flight**: the swarm-vs-serialize decision
should come from **declarative, per-repo collision zones** (or purely from contract write-set
disjointness), not hardcoded xyz filenames.

## Ideas (park-and-discuss — not committed)

1. **Configurable zone rules** — a `.marathon-plan-zones.json` (or a contract field) declaring
   serialization zones as path globs + a "max 1 per wave" flag, replacing the hardcoded
   `kernel`/`shim` regexes. xyz ships its current rules as the default config (no behavior change here).
2. **Contract-only mode** — when every item carries a swarm-preflight contract, derive collision
   purely from `artifacts[]` / `lanes` write-set disjointness (already generic) and skip keyword
   inference entirely. This is the cheapest path and already correct for repos whose lanes are
   contract-backed (e.g. the rebalance 3-lane queue once each lane has a contract).
3. **Foreign roadmap/queue input** — `--target-root` + a small queue-format adapter so
   `marathon-plan --target-root <repo>` reads another repo's ledger (or a directory of per-lane
   contracts) and emits that repo's wave plan.

## Acceptance (when worked)

- marathon-plan computes a correct swarm/serialize wave plan for an external repo (validated against the
  rebalance-OS 3-lane queue) without xyz-specific keyword coupling.
- A shared write-set across two lanes is detected as a serialize constraint **regardless of repo**
  (the rebalance shared-helper case).
- xyz's own planning is unchanged (its current zones ship as the default config).

## Provenance

Filed 2026-06-29 while planning the rebalance-OS cross-repo marathon dogfood (the ROADMAP queue
entry). The swarm-vs-relay compute was found to be **generic in `swarm-preflight`** (write-set
disjointness, `--target-root`) but **xyz-coupled in `marathon-plan`** (ledger format + kernel/shim
keywords). Recommended near-term path: use `swarm-preflight` per lane for cross-repo work today;
this issue generalizes `marathon-plan` so cross-repo *ranking/batching* becomes first-class. Relates to
the rebalance dogfood ROADMAP entry and GH-33 / #46 (the marathon path itself).
