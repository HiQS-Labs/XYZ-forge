---
gh_issue: 156
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/156
title: "Prelight: swarmability scoring using codebase-memory-mcp graph signals"
status: Active (2-WORKING) — planning doc opened; Phase 0 scoring contract next
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
goal: >
  Define and prototype an advisory swarmability score that uses codebase-memory-mcp graph signals
  to estimate whether a requested change can be split into safe parallel lanes, with clear risk
  gates and operator-readable explanations.
roadmap_exempt: false
---

# GH-156 · Prelight swarmability scoring using codebase-memory-mcp graph signals

The bet is that XYZ can improve lane selection without touching the coordination kernel by adding a
graph-informed prelight step ahead of swarm-preflight or marathon planning. The failure mode is
false confidence: a score that looks precise but hides shared-surface risk. This plan keeps the
first slice advisory, task-scoped, and explainable.

Reversibility: **Easy** for the scoring prototype itself because the first seam is planner-only and
default-off. If the work later mutates scheduling defaults or containment policy, that becomes
**Costly** and needs a separate rollback story.

## Status

| What was just completed | What's next |
|---|---|
| GH-156 opened and captured 2026-07-06. The earlier feasibility read already established that the graph side is strong enough to support this: `codebase-memory-mcp` exposes clusters, hotspots, package boundaries, call paths, and complexity metrics, but XYZ has no scoring layer that turns those into lane recommendations. | Phase 0 — lock the scoring contract: inputs, gates, output schema, and the narrow prototype seam (`swarm-preflight` advisory layer vs. separate analyzer). |

## Table of contents

- [Phase 0 — Define the scoring contract](#phase-0--define-the-scoring-contract)
- [Phase 1 — Build a task-scoped prototype scorer](#phase-1--build-a-task-scoped-prototype-scorer)
- [Phase 2 — Validate on known-safe and known-bad lane shapes](#phase-2--validate-on-known-safe-and-known-bad-lane-shapes)
- [Phase 3 — Decide the landing seam and operator surface](#phase-3--decide-the-landing-seam-and-operator-surface)

## Working scoring shape

The score should be task-scoped, not repo-scoped. Given a requested task, the prototype should:

1. Resolve starting symbols/files from the task description or explicit artifact list.
2. Expand the likely impact set via `trace_path` and graph neighbors.
3. Score the touched surface for **independence**, **shared-surface risk**, **hotspot centrality**,
   and **confidence**.
4. Emit recommended lane candidates plus an explanation of why they are or are not safe to split.

Proposed output shape:

```json
{
  "task": "short description",
  "swarmability_score": 0,
  "verdict": "serial|parallel-safe|parallel-with-caveats|insufficient-confidence",
  "confidence": "low|medium|high",
  "candidate_lanes": [],
  "shared_surfaces": [],
  "hotspots": [],
  "reasons": []
}
```

Proposed first-pass gates:

- **Hard serial gate** if the impact set includes a high-fan-in hotspot, kernel/core orchestration
  file, or a narrow shared file set every candidate lane must edit.
- **Parallel-safe candidate** only when candidate lanes have low cross-boundary traffic and disjoint
  writable surfaces.
- **Low-confidence fallback** when the graph cannot resolve enough structure to support the call.

## Phase 0 — Define the scoring contract

Purpose: decide what the score actually means before building anything. A bad metric here creates a
false precision problem that is worse than no score at all.

### Checklist

- [ ] Define the score inputs explicitly:
      impacted symbols/files, package boundaries, cluster cohesion, hotspot fan-in, and complexity /
      transitive-loop signals where they affect risk.
- [ ] Separate **hard gates** from **weighted signals**:
      e.g. shared writable file or kernel-path overlap should force serial or low-confidence even if
      other signals look good.
- [ ] Define the output schema and operator-facing verdicts:
      `serial`, `parallel-safe`, `parallel-with-caveats`, `insufficient-confidence`.
- [ ] Decide the initial task input contract:
      issue doc, explicit artifacts, or a free-text task description plus optional file hints.
- [ ] Record the first prototype seam:
      separate analyzer output first, not automatic scheduling.

### QA checklist — Phase 0

- [ ] The score contract distinguishes advisory heuristics from hard safety gates.
- [ ] The output schema is specific enough for a planner or operator to consume.
- [ ] The prototype seam is reversible and default-off.

## Phase 1 — Build a task-scoped prototype scorer

Purpose: produce one concrete advisory read from a task input using the current graph tools without
changing scheduling behavior.

### Checklist

- [ ] Implement a prototype that resolves task scope into starting files/symbols and queries the
      graph through `search_graph`, `trace_path`, and targeted `query_graph` calls.
- [ ] Compute lane candidates by grouping low-overlap packages/clusters first, then penalizing
      cross-boundary traffic and shared files.
- [ ] Emit operator-readable explanations:
      which hotspots, boundaries, or shared files pushed the verdict toward serial or caveated parallelism.
- [ ] Keep the prototype external/advisory:
      file or JSON output is enough; no auto-fire or scheduling mutation in this phase.

### QA checklist — Phase 1

- [ ] The prototype can analyze at least one real task input and emit the full output schema.
- [ ] The emitted reasons mention concrete graph-derived signals rather than only a raw score.
- [ ] No runtime scheduling behavior changes as part of the prototype.

## Phase 2 — Validate on known-safe and known-bad lane shapes

Purpose: test whether the score is directionally useful on real examples rather than merely
plausible in the abstract.

### Checklist

- [ ] Assemble a small fixture set of prior XYZ lanes:
      one clearly parallel-safe case, one shared-file conflict case, and one "looks parallel but has
      hidden shared-surface risk" case.
- [ ] Run the scorer on those cases and compare the verdict to the known outcome.
- [ ] Record where the score overestimates safety or collapses to low confidence.
- [ ] Refine gates or explanations only where the validation examples prove a miss.

### QA checklist — Phase 2

- [ ] At least one historically good parallel case is scored as parallel-safe or caveated parallel.
- [ ] At least one historically bad overlap case is scored serial or low-confidence.
- [ ] Any refinement is justified by a concrete misclassification, not intuition alone.

## Phase 3 — Decide the landing seam and operator surface

Purpose: choose where this belongs after the prototype proves or disproves itself.

### Checklist

- [ ] Decide whether the right first home is:
      `swarm-preflight`, `marathon-plan`, or a standalone analyzer command.
- [ ] Define the minimal operator surface:
      score only, score plus recommended lanes, or score plus packet annotations.
- [ ] Record what must remain advisory until further proof.
- [ ] If the score is not trustworthy enough, stop and document why rather than auto-promoting it.

### QA checklist — Phase 3

- [ ] The chosen landing seam is justified by the prototype results and blast radius.
- [ ] The operator surface explains why a task is or is not swarmable.
- [ ] Any follow-on implementation path is explicitly default-off until validated.
