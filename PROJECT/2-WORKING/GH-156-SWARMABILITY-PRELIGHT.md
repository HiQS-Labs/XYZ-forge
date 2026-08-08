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
| GH-156 opened and captured 2026-07-06. The earlier feasibility read already established that the graph side is strong enough to support this: `codebase-memory-mcp` exposes clusters, hotspots, package boundaries, call paths, and complexity metrics, but XYZ has no scoring layer that turns those into lane recommendations. **2026-08-07:** the issue body gained a full scope fence and a deliverables checklist; both are mirrored below so the execution surface and the remote agree. | Phase 0 — lock the scoring contract: inputs, gates, output schema, and the narrow prototype seam (`swarm-preflight` advisory layer vs. separate analyzer). |

## Table of contents

- [Non-goals](#non-goals)
- [Deliverables](#deliverables)
- [Phase 0 — Define the scoring contract](#phase-0--define-the-scoring-contract)
- [Phase 1 — Build a task-scoped prototype scorer](#phase-1--build-a-task-scoped-prototype-scorer)
- [Phase 2 — Validate on known-safe and known-bad lane shapes](#phase-2--validate-on-known-safe-and-known-bad-lane-shapes)
- [Phase 3 — Decide the landing seam and operator surface](#phase-3--decide-the-landing-seam-and-operator-surface)

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

## Deliverables

The six artifacts this issue owes, mapped to the phase that produces each. Check an item only when
the artifact exists and is committed — not when the thinking is done. Full wording lives on
[#156](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/156); the phase
checklists below are how each one gets built.

| # | Deliverable | Phase |
|---|---|---|
| 1 | **Scoring model spec** — input signals, hard gates versus weighted signals, and the `search_graph` / `trace_path` / `query_graph` call behind each | [Phase 0](#phase-0--define-the-scoring-contract) |
| 2 | **Frozen output schema** — the JSON contract a planner or operator consumes | [Phase 0](#phase-0--define-the-scoring-contract) |
| 3 | **Lane-splitting heuristic** — grouping rule, shared-surface and hotspot penalties, and the conditions that force `serial` outright | [Phase 0](#phase-0--define-the-scoring-contract) → [Phase 1](#phase-1--build-a-task-scoped-prototype-scorer) |
| 4 | **Task-scoped prototype** — one task input in, full schema out, with reasons naming concrete graph signals rather than only a number | [Phase 1](#phase-1--build-a-task-scoped-prototype-scorer) |
| 5 | **Fixture set and scored comparison** — three real prior lanes scored against known outcomes, misses recorded | [Phase 2](#phase-2--validate-on-known-safe-and-known-bad-lane-shapes) |
| 6 | **Landing-seam decision** — swarm-preflight versus marathon-plan versus standalone, justified by results and blast radius; "not trustworthy enough to land" is a complete answer | [Phase 3](#phase-3--decide-the-landing-seam-and-operator-surface) |

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

> **Input from GH-163** (2026-07-07): reviewed `wp-code-check` and `WP-DB-Toolkit` for reusable
> AST/call-graph infra. Verdict: **not applicable as-is** — neither repo ships a general symbol/call
> graph. `wp-code-check` has a real but narrow PHP-only AST subsystem (nikic/php-parser,
> CLI-only, not wired into its own scanner, external non-vendored dependency) whose output is flat
> findings/hook-wiring lists, not a graph; `WP-DB-Toolkit` has no code-AST infra at all (only a
> stdlib-`ast` docstring linter and a regex-based RAG chunker). **Implication for this Phase 0:**
> budget for building fresh parsing infra (e.g. `nikic/php-parser` + a JS parser) if graph signals
> ever need source-level symbol/call data beyond what `codebase-memory-mcp` already provides — do
> not plan around reusing either sibling repo's tooling. Full detail:
> [GH-163](../1-INBOX/GH-163-WP-SIBLING-AST-REVIEW.md).

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
