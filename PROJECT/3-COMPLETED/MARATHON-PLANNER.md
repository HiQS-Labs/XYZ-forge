---
title: Marathon Planner — deterministic pre-pre-flight queue review + sequencing
status: Complete (3-COMPLETED)
created: 2026-06-28
updated: 2026-06-30
closed: 2026-06-30
owner: noel
branch: main
doc_type: project
complexity: 3
risk: 2
effort: 3
goal: >
  A deterministic "pre-pre-flight" planner (utils/marathon-plan.sh) that reviews the ROADMAP.md
  ledger, validates each item is still real (not already fixed / silently half-done), factors
  in the PDDA complexity/risk/effort ratings, and emits a validation report plus a sequenced,
  collision-aware MARATHON-PLAN-YYYY-MM-DD.md. It is the stage BEFORE utils/swarm-preflight.sh.
related:
  - utils/marathon-plan.sh
  - utils/swarm-preflight.sh
  - utils/roadmap-dashboard.sh
  - utils/pdda-check-ratings.sh
  - PROJECT/PDDA.md
  - PROJECT/2-WORKING/QUEUE-2026-06-27.md
roadmap_exempt: false
---

# Marathon Planner — pre-pre-flight

> **Pointer/ledger context:** detail lives here; [ROADMAP.md](../../ROADMAP.md) carries the one-line
> pointer. This doc owns the execution detail for the marathon-planner effort.

## Status

| What was just completed | What's next |
|---|---|
| **Phase 1 + 2 built on `feat/queue-builder`.** `utils/marathon-plan.sh` parses the ROADMAP ledger, validates each item (already-closed / already-landed / undocumented-partial / drift / unrated — all deterministic, flag-for-human), ranks survivors by the new PDDA ratings, and writes a sequenced collision-aware `MARATHON-PLAN-YYYY-MM-DD.md`. `test/marathon-plan.sh` (28 assertions) green; `validate.sh` **55/55**. The `complexity`/`risk`/`effort` frontmatter contract is codified in `PROJECT/PDDA.md` and surfaced by the warn-level `utils/pdda-check-ratings.sh` (never blocks). | **Phase 3 (operator-gated):** confirm/correct the provisional ratings backfilled across the sequenceable `PROJECT/**` docs, then re-run `utils/marathon-plan.sh` to regenerate today's queue. Optionally `ratings_exempt: true` on briefs / completed dogfood records / superseded overlays. |

## Why this exists

The marathon pipeline is `ROADMAP.md ledger → utils/swarm-preflight.sh (per-item readiness) →
relay-automation/marathon-drive.sh (build)`. The stage *before* preflight — deciding **which** queued
items are still real, which are secretly already done, and **in what order** — was done by hand
(the hand-authored [QUEUE-2026-06-27.md](QUEUE-2026-06-27.md)). This planner automates that, reusing
swarm-preflight's contract + probe semantics rather than standing up a second control plane.

## What it does (deterministic; flag-for-human, never auto-fix)

1. **Reviews the ledger** — parses `ROADMAP.md` (parser lifted from `utils/roadmap-dashboard.sh`).
2. **Validates each item** — `gh` open/closed state, contract `fix_probes` (already-landed), artifact /
   branch / changelog signals (undocumented partial completion, ≥2-signal threshold), dead-pointer and
   coverage drift. Ambiguous cases are flagged, never resolved.
3. **Ranks survivors** — by the PDDA `complexity`/`risk`/`effort` ratings (a transparent printed score;
   `--policy quick-wins` default, `--policy derisk-first` inverts risk).
4. **Sequences** — packs collision-safe lanes into waves (≤1 kernel lane per wave; deps push later) and
   writes `PROJECT/2-WORKING/MARATHON-PLAN-YYYY-MM-DD.md`. `--check` is a determinism/drift guard.

## Overlap with swarm-preflight (intended)

`swarm-preflight` is per-item ("is THIS one ready to fire"); `marathon-plan` is whole-queue ("which are
still real, and in what order"). marathon-plan can delegate to swarm-preflight per item with `--deep`.

## Verification

- `bash test/marathon-plan.sh` — 28 assertions (scoring, wave collision-safety, every validation signal,
  policy flip, gh degradation, `--check` determinism, JSON shape).
- `bash validate.sh` — 55/55 (unsandboxed; sandboxed runs false-fail the lock/worktree/agent tests).
- `utils/marathon-plan.sh --dry-run` against the live ledger — report only, writes nothing.
