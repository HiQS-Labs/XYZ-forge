---
gh_issue: 435
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/435
title: "XYZ's coordination model is a sequential chain, not a DAG"
status: "Proposed (1-INBOX — not yet active)"
created: 2026-08-06
updated: 2026-08-06
owner: noel
doc_type: feedback
related: GH-241, GH-354, GH-359, GH-391, GH-396
effort: 1
complexity: 2
risk: 1
phases: 0
ratings_provisional: true
goal: >
  Record what XYZ's multi-phase coordination model actually is — a strictly sequential chain with
  a scalar-only `depends_on` that validates rather than schedules, no joins, no parallel execution,
  and halt-not-route on failure — document it in README.md where a reader first meets Marathon, and
  make "should XYZ execute a DAG?" an explicit decision rather than a drift.
---

# GH-435 · coordination model — sequential chain, not a DAG

## Why now

A question about whether XYZ fits the standard definition of "graph engineering" for agent systems
(a DAG of nodes and edges, parallel stages, routing decisions, verification gates). Reading the code
to answer it surfaced a documentation gap rather than a defect: the model is coherent and the
constraints look deliberate, but nothing a new reader encounters says so.

`README.md`'s Glossary describes Marathon as chaining phases "in `depends_on` order" and stops
there. Anyone carrying graph vocabulary will infer a DAG, parallel stages, and dependency-derived
scheduling. None of those exist.

## What the model actually is

| Property | Reality | Evidence |
|---|---|---|
| Joins / fan-in | **Inexpressible** — `depends_on` is scalar-only, one dependency per phase; a list form parses as a literal string and aborts the plan | `relay-automation/MARATHON.example.yaml:42-46` |
| Parallel phases | **None** — phases run strictly one at a time; a disjoint write-set does not buy parallelism | `MARATHON.example.yaml:7-11`; `relay-automation/marathon.sh:168` (single serial `while read` loop) |
| Scheduling | `depends_on` **validates** authored order, does not derive it | `MARATHON.example.yaml:8-9` — "does not create the ordering, it only constrains it" |
| Routing on failure | **Halt only** — nine exit codes, nine halt reasons, no conditional edge | `marathon.sh:214-226` |
| Waves | **Documentation, not execution** — `Wave` appears only in the renderers (`utils/marathon-plan.sh`, `utils/py/_marathon_plan.py`) and reporting (`utils/hq/marathon-scan.sh`), never in an executor | grep across `*.sh`/`*.py` |
| Plan→run coupling | Planner is deliberately not the executor | `utils/swarm-preflight.sh:28-29`, `GUIDING-PRINCIPLES.md` §8 |

## What does match the graph model

Stated so this is not read as a teardown — the micro level is genuinely graph-shaped:

- Nodes with non-deterministic bodies: `phases/<id>/RELAY.md`, a tick token, reviewer, brief,
  artifact allowlist, LLM turn.
- A real LLM-selected edge inside the relay loop — the reviewer writes `STATUS:`, and
  `utils/py/relay_drive.py:278` routes `Approved`/`Closed` as terminal, else another round, bounded
  by a round cap.
- Verification gates at every boundary, which must be able to *start* before turn 1.
- A live inspectable state machine: `.tick/events/`, `RELAY.md`, `ESCALATION.md` with typed reasons.

Graph structure at the micro level; deliberately refused at the macro level.

## Where the unstated assumption already shows

- **#354** — the parallel-stages question. Answered "no, by design" at the driver-lock level, but
  its Phase 0 found the exclusion weaker than advertised (marathon↔marathon excludes;
  marathon↔relay and relay↔relay silently do not).
- **#359** — the plan omits the write-sets that determine its wave grouping, so the
  concurrency-safety claim is unverifiable from the document making it. Sharper once the waves turn
  out never to execute.
- **#391** — nothing generates `MARATHON.yaml`; the chain is hand-transcribed from the planned
  waves. The graph is authored twice and only one copy runs.
- **#396** — conflict-as-signal, restated: reviewer disagreement escalates on a *count*
  (`relay_drive.py:439`, `:620` → `cap-or-close-mismatch`) rather than on the substance of the
  dispute. No conditional edge for substantive divergence — a retry counter and a dead end.

## Scope

1. **Document it** — a `## FAQ` section in `README.md` beside the Glossary, covering what XYZ is and
   isn't in graph terms, and what `depends_on` actually does. Shipped with this capture.
2. **Change nothing in the model.** No scheduler, no join support, no wave executor. §8 is a
   position, not an omission.
3. **Make the DAG question explicit** — downstream of #354's Phase 4 GO/NO-GO gate, not parallel
   to it.

## Non-goals

- Not a proposal to build a DAG executor, add fan-in to `depends_on`, or make waves executable.
- Not a re-litigation of GH-241, which fixed the example's prose; this is about the front-door docs
  a reader meets before ever opening a plan.
- Not a fix for #354 / #359 / #391 — they are cited as symptoms sharing one root assumption, and
  keep their own scopes.

## Provenance

- Issue: [#435](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/435)
- Related: [#241](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/241) ·
  [#354](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/354) ·
  [#359](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/359) ·
  [#391](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/391) ·
  [#396](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/396)
- All code citations re-verified against `development` at `80cab6b`.
