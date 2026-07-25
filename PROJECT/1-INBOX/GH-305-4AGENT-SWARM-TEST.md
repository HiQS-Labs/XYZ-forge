---
title: Validate a 4-agent concurrent swarm on a large project, with codebase-memory preflight
status: Proposed (1-INBOX — not yet active)
created: 2026-07-24
owner: noel
gh_issue: 305
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/305
doc_type: spike
complexity: 3
risk: 2
effort: 3
phases: 5
ratings_provisional: true
non_goals:
  - Build an auto-recovery watchdog (stale-heartbeat → auto-release) — this test only scopes/recommends it
  - Ship a general headless concurrent-N agent launcher — the test decides IF one is needed
  - Validate >4 agents, or run on shared-file work (config/ROADMAP/CHANGELOG stay out of all lanes)
related:
  - GH-58 (headless `claude` builder broken — roster must avoid it)
  - decisions/2026-07-01-cross-agent-dep-conflict.md (non-overlapping paths, overlapping symbols)
  - GH-118 / GH-119 / GH-120 (Aider↔OpenRouter marathon — proven shim path)
goal: >
  One instrumented 4-agent concurrent-swarm run against a large target repo, with a
  codebase-memory preflight that cuts dependency-aware disjoint lanes, added observability
  (overlap-rejection counts, per-lane wall-clock, JSON run summary, graph-cut-vs-path-cut
  control arm), and a fault-injection phase — producing a findings report on whether 3–4
  agents are production-ready and whether an auto-reap watchdog / concurrent-N launcher are worth it.
---

# GH-305 — Validate a 4-agent concurrent swarm on a large project, with codebase-memory preflight

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Key concepts
- The swarm protocol (`tick` claim/scope/next) is agent-count-agnostic but marked
  ">2 agents … unvalidated at scale" ([skills/xyz/SKILL.md](../../skills/xyz/SKILL.md)). This is the validation run.
- Roster: reuse the existing `aider`/`pi` turn-shims and/or a 2nd instance of `agy`/`codex`
  (the shims bind on agent-id, not a singleton); avoid headless `claude` (GH-58).
- codebase-memory preflight cuts **dependency-aware** disjoint lanes (graph edges, not just
  path prefixes) — attacking the cross-agent dep-conflict failure mode directly.
- Fault tolerance today is **manual**: heartbeats only flag stale claims; `reap` is a
  manual coordinator lever ([src/scope.js](../../src/scope.js)) — no watchdog. The test measures this.

## Idea
Validate a 4-agent concurrent swarm on a large project, with codebase-memory preflight.

## Why
The concurrent swarm is proven at 2 agents; 3–4 is designed-for but unvalidated
([skills/xyz/SKILL.md](../../skills/xyz/SKILL.md) marks ">2 agents … unvalidated at scale").
Before we rely on it for real work we need one deliberate, instrumented run that produces
meaningful data: is 4-wide concurrency real (not serial-in-disguise via conservative
overlap false-positives), does codebase-memory pre-indexing produce better lanes than a
path-prefix cut, and what actually happens when a harness dies mid-run?

## Phase 0 — Explore & scope
> Discovery phase: its findings are written **back into this doc** before its QA gate can
> pass (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [ ] Pick the large target repo (candidates: `LTVera-Pandas`, `sleuth-app`) + confirm its codebase-memory index is fresh (`detect_changes` clean)
- [ ] Decide the concurrent launch model — 4 headless shim loops (`tick take`), 4 interactive sessions, or a thin concurrent launcher (possibly its own issue)
- [ ] Name the concrete deliverable + its write-set (observability additions + JSON run summary + findings report)
- [ ] Confirm the roster (`codex`/`agy`/`aider`/`pi`) and set/correct triage ratings; clear `ratings_provisional` once real
- [ ] Carry Phases 1–4 detail from the issue: launch → fault-inject → observability → report

### QA checklist — Phase 0
- [ ] The scope is grounded in real code/history, not a hypothetical
- [ ] Reuses the existing shims / `tick` rather than adding a parallel path (`/ponytail`)
- [ ] A human checkpoint remains before anything fires

## Test design (carried from issue #305)

### Phase 1 — Launch
- [ ] Assign 4 agent ids (`codex`, `agy`, `aider`, `pi`), one lane each via `tick claim --paths`
- [ ] Each agent loops `tick take` / `ping` / `done` on its lane

### Phase 2 — Fault injection
- [ ] Mid-run, kill one agent's harness
- [ ] Measure: time the lane stays blocked; whether `tick analyze` flags the stale claim;
      run `tick reap --agent <dead>`; confirm a peer reclaims and completes it

### Phase 3 — Observability (add what's missing)
- [ ] Capture existing `tick analyze` concurrent-claim % (the honest concurrency metric)
- [ ] Add if absent: per-lane wall-clock, overlap-rejection count, claim/done timeline,
      graph-lanes-vs-path-lanes concurrency delta, machine-readable JSON run summary

### Phase 4 — Report / meaningful data
- [ ] Concurrency real at 4-wide vs. a 2-agent baseline?
- [ ] Graph-cut vs. path-cut: fewer collisions / higher concurrency?
- [ ] Cross-agent dep conflicts observed (non-overlapping paths, overlapping symbols)?
- [ ] Fault behavior: blocked-lane duration, clean peer takeover post-reap?
- [ ] Recommendations: 3–4 agents production-ready? auto-reap watchdog worth it? concurrent-N launcher its own issue?

## Success criteria (meaningful-data bar)
- A 4-agent run completes with a signed-off concurrency metric > a 2-agent baseline, OR a
  documented reason it didn't (with overlap-rejection data to explain it)
- A quantified graph-cut vs. path-cut comparison
- A characterized fault path (numbers, not adjectives)
