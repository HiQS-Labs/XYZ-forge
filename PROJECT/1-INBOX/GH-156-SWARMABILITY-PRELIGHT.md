---
gh_issue: 156
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/156
title: "Prelight: swarmability scoring using codebase-memory-mcp graph signals"
status: Active (2-WORKING) — planning doc opened; Phase 0 scoring contract next
created: 2026-07-06
updated: 2026-08-07
owner: noel
doc_type: feature
complexity: 3
risk: 2
effort: 3
phases: 4
ratings_provisional: false
non_goals:
  - Not spinning up Claude Code sub-agents or any agent runtime; this ships a read, never a runner
  - Not changing the coordination kernel — tick claims, locks, heartbeats, relay containment, or the event schema
  - Not auto-firing, auto-splitting, or mutating swarm-preflight packets and marathon plans from a score
  - Not rewriting swarm-preflight's existing deterministic checks, and not pre-wiring a landing seam before Phase 3
  - Not building AST or parser infrastructure; an unresolvable graph means insufficient-confidence, not a new parser
  - Not a dashboard, TUI, or web surface — JSON/file output is the whole operator surface for this slice
  - Not a repo-wide architecture, dead-code, or code-quality report; task-scoped collision risk only
  - Not a hard dependency on codebase-memory-mcp; XYZ behaves as it does today when the MCP is absent or the repo unindexed
  - Not treating graph-derived parallelism as proof; this is a heuristic planning aid
  - Not quoting an accuracy number without the Phase 2 fixture set, and not tuning weights on synthetic examples
  - Not fleet-wide or multi-repo scoring across vendored .xyz copies in this slice
related:
  - utils/py/swarm_preflight.py
  - utils/marathon-plan.sh
  - utils/py/_marathon_plan_node.js
  - src/analyze.js
goal: >
  Define and prototype an advisory swarmability score that uses codebase-memory-mcp graph signals
  to estimate whether a requested change can be split into safe parallel lanes, with clear risk
  gates and operator-readable explanations.
roadmap_exempt: false
---

# GH-156 · Prelight swarmability scoring using codebase-memory-mcp graph signals

## Summary

Capture the proposed "prelight swarmability score" as a first-class work item: use the existing
`codebase-memory-mcp` graph signals to estimate whether a task can be split into safe parallel
lanes before firing a swarm or marathon run.

## Non-goals

Scope fence for whoever picks this up. These are boundaries, not preferences — the point is that
this issue ships a *read*, never a *runner*.

**Do not build**

- Not spinning up Claude Code sub-agents, or any agent runtime. The deliverable reviews a plan and
  emits a verdict; it never launches, schedules, or supervises a lane.
- Not touching the coordination kernel: no changes to `tick` claims, locks, or heartbeats, no relay
  containment changes, no event-schema changes.
- Not auto-firing, auto-splitting, or mutating swarm-preflight packets and marathon plans from a
  score. Advisory output, default-off, operator decides.
- Not rewriting or replacing swarm-preflight's existing deterministic checks (write-set collision,
  `fix_probes`). The score sits beside them. *Where* it eventually lands is the Phase 3 decision —
  do not pre-wire a seam in Phase 0/1.
- Not building AST or parser infrastructure. Consume the signals the graph already exposes. GH-163
  closed the "reuse a sibling repo's AST tooling" path and GH-169 already vendored acorn; when the
  graph cannot resolve enough structure, the correct output is `insufficient-confidence`, not a new
  parser.
- Not a dashboard, TUI, or web surface. JSON/file output is the entire operator surface for this
  slice.

**Do not widen or over-claim**

- Not a repo-wide architecture, dead-code, or code-quality report. Task-scoped collision risk only —
  what *this* plan touches.
- Not a hard dependency on `codebase-memory-mcp`. With the MCP absent, the repo unindexed, or the
  graph stale, XYZ must behave exactly as it does today.
- Not treating a graph-derived verdict as proof of safety. It is a heuristic planning aid, and the
  output wording must not imply otherwise.
- Not quoting an accuracy or hit-rate number without the Phase 2 fixture set behind it.
- Not tuning weights against synthetic examples — validation runs against real prior XYZ lanes with
  known outcomes.
- Not fleet-wide or multi-repo scoring across vendored `.xyz` copies in this slice.

Anything genuinely worth doing that falls outside these lines gets its own issue rather than being
absorbed into this one.

## Why

The graph already exposes the raw ingredients needed for this call: call paths, hotspots,
boundaries, clusters, packages, and complexity metrics. What XYZ does not yet have is a planning
layer that converts those signals into a concrete "parallelize / do not parallelize / low
confidence" recommendation an operator can trust enough to act on.

## Deliverables

Check an item only when the artifact exists and is committed — not when the thinking is done.

- [ ] **Scoring model spec.** Written into the working plan: the input signals (impacted
      symbols/files, package boundaries, cluster cohesion, hotspot fan-in, complexity), which are
      hard gates versus weighted signals, and the `search_graph` / `trace_path` / `query_graph` call
      behind each one.
- [ ] **Frozen output schema.** The JSON contract a planner or operator consumes:
      `swarmability_score`, `verdict` (`serial` | `parallel-safe` | `parallel-with-caveats` |
      `insufficient-confidence`), `confidence`, `candidate_lanes`, `shared_surfaces`, `hotspots`,
      `reasons`.
- [ ] **Lane-splitting heuristic.** The written rule that groups low-overlap packages/clusters into
      candidate lanes, penalizes shared writable surfaces and hotspot centrality, and spells out the
      conditions that force `serial` outright.
- [ ] **Task-scoped prototype.** A runnable analyzer that takes one task input (issue doc, explicit
      artifact list, or free text plus file hints) and emits the full schema, with reasons that name
      the concrete graph signals behind the verdict rather than only a number.
- [ ] **Fixture set and scored comparison.** At least three real prior XYZ lanes — one
      parallel-safe, one shared-file conflict, one that looks parallel but carries hidden
      shared-surface risk — run through the scorer, with verdict versus known outcome recorded,
      including the misses.
- [ ] **Landing-seam decision.** A written verdict on swarm-preflight versus marathon-plan versus a
      standalone analyzer, justified by the prototype results and blast radius. "Not trustworthy
      enough to land, here is why" is a valid and complete answer to this item.

## Acceptance criteria

- The working plan defines the score inputs, risk gates, and output schema
- The plan distinguishes task-scoped analysis from repo-wide heuristics
- The first implementation seam is explicit and reversible
- The score remains advisory until verified on real repos
- XYZ's behavior is unchanged when `codebase-memory-mcp` is unavailable or the repo is unindexed

## Promotion note

Per the operator request, this issue is captured here in `1-INBOX` **and** immediately mirrored by
an active working plan in `PROJECT/2-WORKING/GH-156-SWARMABILITY-PRELIGHT.md`. The working copy is
the execution surface; this inbox copy is the intake snapshot tied to the GitHub issue.
