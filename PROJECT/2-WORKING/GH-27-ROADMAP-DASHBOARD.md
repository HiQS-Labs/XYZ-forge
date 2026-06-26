---
title: ROADMAP dashboard renderer — refresh the pointer ledger into a static informational dashboard
status: Active — registered 2026-06-25; renderer contract next
created: 2026-06-25
updated: 2026-06-25
owner: Noel (operator) · Codex (author)
branch: main
gh_issue: 27
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/27
doc_type: tooling
goal: >
  Build one reusable, dependency-free refresh path that reads the canonical root ROADMAP.md and
  renders a static informational dashboard without turning ROADMAP.md into a second execution plan.
related:
  - ROADMAP.md
  - PROJECT/PDDA.md
  - FRONTDOOR.md
  - README.md
non_goals:
  - Replacing ROADMAP.md as the canonical pointer ledger
  - Introducing a live web app, server process, or external dependency stack
  - Moving execution detail out of PROJECT/** docs and back into ROADMAP.md
---

# ROADMAP dashboard renderer

> **In-repo capture of [issue #27](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/27), promoted to `PROJECT/2-WORKING/` on execution start.** The live issue is the signal stream; this doc is the canonical active-work record.

## Status

| What was just completed | What's next |
|---|---|
| **Project registered** — issue opened, active-work doc created, and `ROADMAP.md` now carries the ledger pointer for this work. | **Lock the renderer contract** — pick the entrypoint, output path, and deterministic verification for a static ROADMAP dashboard refresh command. |

## Why This Exists

`ROADMAP.md` already contains the right canonical information, but it is dense to skim in raw
markdown. The goal is to add a generated dashboard view that improves scanability while keeping the
pointer/ledger contract intact: `ROADMAP.md` remains the source of truth, and the dashboard is a
derived artifact.

## Bet / Blast Radius / Reversibility

**Bet:** a static generated dashboard is enough to improve usability; this does not need a runtime
app or a second planning surface.

**Tradeoff:** we add one parser/render path to maintain, but avoid hand-curating a parallel status
board.

**Failure mode:** if the renderer overfits to today's markdown shape, it becomes fragile and the
dashboard drifts the moment the ledger evolves.

**Reversibility:** Easy — keep it additive and derived; remove the renderer and artifact without
touching the underlying roadmap contract.

**Blast radius:** Small. The intended surface is `ROADMAP.md` parsing, one generated artifact, one
refresh command, and deterministic verification. No `tick`, relay, or schema work should be needed.

## Initial execution shape

1. Define one dependency-free renderer entrypoint that reads the root `ROADMAP.md` and writes one derived dashboard artifact.
2. Preserve the pointer-ledger contract by treating the dashboard as read-only output, never a second source of execution detail.
3. Add a deterministic refresh check so the generation path can be re-run and verified, not hand-waved.
