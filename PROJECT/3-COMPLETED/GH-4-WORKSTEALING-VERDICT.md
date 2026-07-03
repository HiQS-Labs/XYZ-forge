---
gh_issue: 4
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/4
title: Lane imbalance + no work-stealing undercuts the >=2-done & concurrency bars
status: Shipped (2026-07-03 — Plan A lane 3, PR pending)
created: 2026-07-03
updated: 2026-07-03
owner: noel
doc_type: improvement
complexity: 3
risk: 2
effort: 3
related:
  - src/analyze.js
  - src/take.js
  - test/workstealing-verdict.sh
  - test/analyze.sh
non_goals:
  - No runner rewrite to auto-loop `take`. The `take` candidate filter already work-steals (cross-lane, collision-free); an agent/brief loops it (the "poor-man's work-stealing" the issue names). Rewiring the containment runner (`relay-automation/runner.sh`) to auto-drain is a separate, riskier change and is deferred.
  - The verdict is advisory (a report line + JSON field); it does not gate a marathon exit code. Wiring it into a hard harness gate is a follow-up.
---

# GH-4 · Lane imbalance + work-stealing + a lane-count-independent verdict

## Status

| Most recently completed | What's next |
|---|---|
| **✅ SHIPPED (Plan A lane 3).** The success bar was `concurrency% AND each agent >= 2 done` — but a clean 2-lane/2-agent split gives 1 done each *by construction*, so a flawless run failed the bar (and an imbalanced split let the fast agent idle, sinking concurrency). Fixed all three ways: **(1)** `tick analyze` now emits a **VERDICT** gating on concurrency% + zero parked + all-lanes-done + zero-collisions — **NOT** per-agent done count; **(2)** work-stealing is unblocked — the existing `tick take` candidate filter already pulls a collision-free task from any free lane, and the new verdict *rewards* the resulting imbalance instead of punishing it; **(3)** a **lane-balance** line surfaces each agent's idle-tail so imbalance is visible. | Merge PR + cross-model review. Follow-ups (non_goals): auto-`take`-loop in the runner; wire the verdict into a marathon exit gate. |

## Problem

`tick analyze` computes concurrency% + parked-suspects, but the run's *pass/fail* was a documented experiment convention (`RUN-4-META-BRIEF.md`, `P1-TRINITY-ROUND2.md`): **≥50% concurrency AND each agent ≥2 done**. The `≥2 done/agent` half is wrong when tasks ≈ agents: a 2-lane/2-agent split gives 1 done each, failing a perfect run — a false negative that trains operators to distrust the gate. It also fought work-stealing: the manual `handoff-exclusive` rule *prevented* a fast agent from crossing lanes precisely to protect the (broken) per-agent bar, leaving idle tail-time on the table (the Run-3 concurrency sink).

## Design

Three additive changes, events-only (no git):

1. **Verdict (`computeVerdict`).** `pass` iff `concurrent_pct >= TICK_CONCURRENCY_TARGET_PCT` (default 50, finite-tunable) **AND** zero parked suspects **AND** every claimed task reached `task.done` (a `circuit_broken` or still-open lane counts as not-done) **AND** zero collisions. `incomplete` when the run window is too short to compute concurrency. Emitted as a `verdict` JSON field + a `VERDICT:` human line with the failing reasons. Never references per-agent done counts.
2. **Collisions (`computeCollisions`).** Pairs of time-overlapping claim windows held by *different* agents whose paths overlap. The claim lock should make this 0; surfacing it *verifies* the containment invariant held rather than assuming it. Reused `paths.setsOverlap`.
3. **Balance (`computeBalance`).** Per-agent idle-tail = run-end minus the agent's last event; worst-first. The imbalance signal (fix 3) — and the human line points the operator at `tick take` to fill the tail.

**Work-stealing (fix 2)** needed no new mechanism: `src/take.js` already selects the highest-priority `open` task whose paths don't overlap *any* active claim, so a free agent that calls `take` after finishing pulls a collision-free item from another lane. What blocked it was the per-agent-done bar; removing that (fix 1) makes the imbalance a *win*.

## QA gate

- [x] `test/workstealing-verdict.sh` (6 checks): beta finishes its lane, **steals C1** from a free lane via `take` (collision-free), can't steal a lane-overlapping task, board drains all-done → **VERDICT PASS on an imbalanced 2-vs-1 done split** (the exact case the old bar failed) + a lane-balance line.
- [x] `test/analyze.sh` (+2): 0 collisions on disjoint lanes; **VERDICT FAIL** when a claimed lane (`TASK-003`, circuit_broken) didn't reach done — proving the verdict isn't fooled by "2 done" when a lane failed.
- [x] `validate.sh` green (87/87). Existing `take`/`analyze`/`watchdog`/`heartbeat` suites unchanged (additive JSON fields).
