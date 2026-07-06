---
gh_issue: 156
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/156
title: "Prelight: swarmability scoring using codebase-memory-mcp graph signals"
status: parked
created: 2026-07-06
updated: 2026-07-06
owner: noel
doc_type: feature
complexity: 3
risk: 2
effort: 3
phases: 4
ratings_provisional: false
non_goals:
  - Not changing relay containment, tick locking, or the event schema in the first slice
  - Not auto-firing swarm lanes from a score alone without an operator-visible explanation
  - Not treating graph-derived parallelism as proof; this is a heuristic planning aid
related:
  - utils/py/swarm_preflight.py
  - utils/marathon-plan.sh
  - utils/py/_marathon_plan_node.js
  - src/analyze.js
roadmap_exempt: false
---

# GH-156 · Prelight swarmability scoring using codebase-memory-mcp graph signals

## Summary

Capture the proposed "prelight swarmability score" as a first-class work item: use the existing
`codebase-memory-mcp` graph signals to estimate whether a task can be split into safe parallel
lanes before firing a swarm or marathon run.

## Why

The graph already exposes the raw ingredients needed for this call: call paths, hotspots,
boundaries, clusters, packages, and complexity metrics. What XYZ does not yet have is a planning
layer that converts those signals into a concrete "parallelize / do not parallelize / low
confidence" recommendation an operator can trust enough to act on.

## Desired outcome

- A documented score model grounded in `search_graph`, `trace_path`, and `query_graph`
- A task-scoped collision-risk read, not only a repo-wide architecture summary
- A narrow prototype seam that can be tested without rewriting the runtime
- A validation plan using real lanes and known collision cases

## Acceptance criteria

- The working plan defines the score inputs, risk gates, and output schema
- The plan distinguishes task-scoped analysis from repo-wide heuristics
- The first implementation seam is explicit and reversible
- The score remains advisory until verified on real repos

## Promotion note

Per the operator request, this issue is captured here in `1-INBOX` **and** immediately mirrored by
an active working plan in `PROJECT/2-WORKING/GH-156-SWARMABILITY-PRELIGHT.md`. The working copy is
the execution surface; this inbox copy is the intake snapshot tied to the GitHub issue.
