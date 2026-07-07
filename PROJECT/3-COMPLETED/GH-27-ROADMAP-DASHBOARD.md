---
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
title: ROADMAP dashboard renderer — refresh the pointer ledger into a static informational dashboard
status: Completed (3-COMPLETED)
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

## Ad-Hoc Detour: HQ Rollup

Following the success of this dependency-free parser, an ad-hoc detour project was executed to build a cross-repo HQ Rollup system (`utils/hq/rollup.sh`).
- It extracts active and queued items from `ROADMAP.md` across all `hq_known_repos` (reusing the parser logic).
- It synthesizes the data using `agy` and writes a clean markdown dashboard to the user's Obsidian Vault.
- This is registered as a daily LaunchAgent (`com.neochro.hq-rollup`) that runs at 5:50 PM PT.

## Builder brief

→ [briefs/gh-27-roadmap-dashboard-brief.md](briefs/gh-27-roadmap-dashboard-brief.md) (the single-phase
`--phase-brief` the Marathon harness feeds the headless Codex builder).

## Swarm Preflight Contract

Consumed by `utils/swarm-preflight.sh` to turn this doc into a marathon-ready packet (same-repo build;
`target.ref: main` — the renderer is genuinely unbuilt there). Codex lane (a normal code-writing task;
no kernel/`tick`/relay paths, so nothing is orchestrator-only).

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash test/roadmap-dashboard.sh",
  "fix_probes":  [ { "type": "path_absent", "path": "utils/roadmap-dashboard.sh" } ],
  "artifacts":   [ "utils/roadmap-dashboard.sh", "ROADMAP-DASHBOARD.md", "test/roadmap-dashboard.sh" ],
  "remediation": { "source": "GH-27#initial-execution-shape", "criteria": "dependency-free renderer + one static ROADMAP-DASHBOARD.md artifact + a deterministic --check refresh test wired into validate.sh" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
