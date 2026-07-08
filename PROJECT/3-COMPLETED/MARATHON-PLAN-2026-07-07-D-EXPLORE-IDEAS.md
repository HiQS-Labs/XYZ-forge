---
title: Marathon Plan D (2026-07-07) — explore-and-plan cluster (GH-161..164)
status: completed (3-COMPLETED)
created: 2026-07-07
updated: 2026-07-07
owner: noel
branch: main
doc_type: project
source: hand-curated from the 2026-07-07 "five things before I compact" follow-up batch
generated_by: hand-authored (4 lanes, not ledger-ranked — all four are same-day intake with no prior rating)
roadmap_exempt: true
goal: >
  Unlike Plan C (build lanes), every lane in this plan is an EXPLORE lane: the deliverable is a
  filled-out plan doc (Phase 0 findings + a proposed Phase 1+ shape), not shipped code. Four
  independent ideas captured 2026-07-07 (GH-161 observability, GH-162 debug-mantra harness mode,
  GH-163 WP-sibling AST review, GH-164 idea-to-marathon pipeline), each with a skeleton doc already
  authored in PROJECT/1-INBOX/.
lanes: [161, 162, 163, 164]
execution: parallel Sonnet subagents, one per lane — no builder/reviewer/gate; each lane's own
  output IS the artifact (its plan doc, edited in place)
---

# Marathon Plan D — 2026-07-07 · explore-and-plan cluster

> Sibling of [Plan C](../3-COMPLETED/MARATHON-PLAN-2026-07-04-C-RELIABILITY.md) (build lanes,
> shipped) but a different shape: these four lanes don't build or ship code. Each lane's job is to
> explore its idea and turn the skeleton doc already in `1-INBOX` into a real plan — Phase 0
> findings filled in, a verdict recorded, and (where the Phase 0 checklist calls for it) a proposed
> Phase 1+ shape for a future build lane.

## Status

| What was just completed | What's next |
|---|---|
| GH-161, GH-162, GH-163, GH-164 filed 2026-07-07 as part of a five-item follow-up batch; each got a skeleton plan doc in `PROJECT/1-INBOX/` (frontmatter + Key Concepts + Idea/Why + a Phase 0 checklist), and a light-touch ROADMAP queue line. **#163 fired on this device (has `wp-code-check`/`WP-DB-Toolkit` on disk) — Phase 0 complete, verdict recorded, finding also written into GH-156's Phase 0 section.** #161/#162/#164 not touched here. | Fire #161, #162, #164 (elsewhere/another device or session). Each lane completes its doc's Phase 0 checklist in place and records a verdict. |

## Why this cluster, why now

All four surfaced in the same operator batch ("five things before I compact") right after the
GH-160 debug-mantra session — they're connected in spirit (observability, debugging discipline,
reusable tooling, and the intake pipeline that produced these very docs) but have no code
dependency on each other. Explore-marathon lanes are cheap and safe to run in parallel: no shared
write-set, no build gate, no commit-side containment risk beyond editing one doc file each.

## The one safety rule

Two lanes are safe to run concurrently **iff their write-sets are disjoint**. Trivially true here —
each lane's only writable output is its own `PROJECT/1-INBOX/GH-<n>-*.md` doc.

## Collision map

| Zone (shared file) | Parallel-safe? | Lanes |
|---|---|---|
| independent (one doc per lane) | ✅ parallel | #161 (`GH-161-HARNESS-OBSERVABILITY.md`), #162 (`GH-162-DEBUG-MANTRA-HARNESS-MODE.md`), #163 (`GH-163-WP-SIBLING-AST-REVIEW.md`, read-only reads of `wp-code-check`/`WP-DB-Toolkit`), #164 (`GH-164-IDEA-TO-MARATHON-PIPELINE.md`) |

No two lanes write to the same file. #163 reads two foreign repos but writes nothing there —
read-only, so it doesn't need `--target-root` or cross-repo containment.

## Per-lane summary

| # | Item | Deliverable | Write-set | cx/risk/eff | Lens |
|---|------|-------------|-----------|-------------|------|
| #161 | Harness observability audit | Phase 0 findings + instrumentation proposal (into existing transcripts, not a new log) | `PROJECT/1-INBOX/GH-161-HARNESS-OBSERVABILITY.md` | 3/1/3 | `/ponytail` |
| #162 | Debug-mantra harness mode | Phase 0 findings + chosen integration seam | `PROJECT/1-INBOX/GH-162-DEBUG-MANTRA-HARNESS-MODE.md` | 2/1/2 | `/ponytail` |
| #163 | WP-sibling AST tooling review | Phase 0 findings + reuse verdict | `PROJECT/1-INBOX/GH-163-WP-SIBLING-AST-REVIEW.md` | 1/1/1 | — (fact-finding review, not a design) |
| #164 | Idea→marathon intake pipeline | Phase 0 findings + proposed tool shape | `PROJECT/1-INBOX/GH-164-IDEA-TO-MARATHON-PIPELINE.md` | 3/2/3 | `/ponytail` |

## Recommended waves

**Wave 1 — parallel (4 lanes ‖):** #161 ‖ #162 ‖ #163 ‖ #164

No kernel track — none of these touch containment, tick, or the relay kernel; they're all
research/documentation work about the harness, not changes to it.

## Execution contract

- **Path:** each lane fires as a worktree-isolated Sonnet subagent (or plain Explore-then-Edit,
  since there's no build/gate/commit cycle) scoped to its own doc via `ALLOW_PATHS` = that doc's
  path (plus read access to the two WP sibling repos for #163).
- **No builder/reviewer split, no `--pre-advance-cmd` gate:** these are single-agent explore lanes,
  not build↔review relay turns. The lane's own edit to its doc is the deliverable.
- **Per lane:** complete the doc's Phase 0 checklist and QA checklist in place, record an explicit
  verdict/finding (not just "explored, see below" — a concrete answer to each checklist item), and
  leave a one-line status update in the doc's own Status table.
- **Do not implement any Phase 1+ build work in this pass** — that's out of scope for an explore
  lane; a future marathon plan picks up any lane whose Phase 0 concludes a build is warranted.
- **Rated:** all 4 lanes carry provisional cx/risk/eff in their own doc frontmatter (`ratings_
  provisional: true`) — not yet validated against `pdda.sh doc-ready`, since Phase 0 hasn't run.

## How to fire a lane

```bash
# No swarm-preflight/marathon-drive needed — these are plain explore-and-edit lanes, not
# builder/reviewer relay turns. Fire each as its own agent scoped to its doc:
#   #161 -> PROJECT/1-INBOX/GH-161-HARNESS-OBSERVABILITY.md
#   #162 -> PROJECT/1-INBOX/GH-162-DEBUG-MANTRA-HARNESS-MODE.md
#   #163 -> PROJECT/1-INBOX/GH-163-WP-SIBLING-AST-REVIEW.md (+ read wp-code-check, WP-DB-Toolkit)
#   #164 -> PROJECT/1-INBOX/GH-164-IDEA-TO-MARATHON-PIPELINE.md
```

---

*Source docs:* [GH-161](../1-INBOX/GH-161-HARNESS-OBSERVABILITY.md) ·
[GH-162](../1-INBOX/GH-162-DEBUG-MANTRA-HARNESS-MODE.md) ·
[GH-163](../1-INBOX/GH-163-WP-SIBLING-AST-REVIEW.md) ·
[GH-164](../1-INBOX/GH-164-IDEA-TO-MARATHON-PIPELINE.md) ·
sibling: [Plan C](../3-COMPLETED/MARATHON-PLAN-2026-07-04-C-RELIABILITY.md).
