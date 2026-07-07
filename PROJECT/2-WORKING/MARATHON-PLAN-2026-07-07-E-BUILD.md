---
title: Marathon Plan E (2026-07-07) — acorn-integration + aider-turn.sh bugfix cluster
status: Ready to fire (2-WORKING) — docs authored + rated, not yet fired
created: 2026-07-07
updated: 2026-07-07
owner: noel
branch: main
doc_type: project
source: hand-curated — GH-163's acorn verdict (build follow-through) + a live aider-turn.sh bug found via a `.xyz`-vendored relay run in the pdda repo
generated_by: hand-authored (2 lanes, same-day intake, not ledger-ranked)
lanes: [168, 169]
execution: parallel Sonnet subagents, one per lane — independent write-sets, no builder/reviewer relay needed for either
roadmap_exempt: true
goal: >
  Two independent build lanes for today: a one-line aider-turn.sh gitignore fix (#168) found live
  during a vendored relay run, and the first-pass acorn+acorn-walk vendoring (#169) that follows
  through on GH-163's license-vetted, smoke-tested verdict. Neither depends on the other; neither
  touches GH-156's still-open scoring contract.
---

# Marathon Plan E — 2026-07-07 · acorn-integration + aider-turn.sh bugfix cluster

> Sibling of [Plan D](MARATHON-PLAN-2026-07-07-D-EXPLORE-IDEAS.md) (same-day explore cluster,
> GH-161..164) but a different shape: both lanes here are **build** lanes — real code changes with
> tests, not doc-only Phase 0 exploration.

## Status

| What was just completed | What's next |
|---|---|
| GH-168 and GH-169 filed 2026-07-07 (see their own docs in `PROJECT/1-INBOX/`), each rated and scoped. Nothing built yet. | Fire both lanes in parallel — fully independent write-sets, no shared file, no kernel-zone risk. |

## Why this cluster, why now

- **#168** (aider-turn.sh gitignore bug) surfaced live during a real relay run in a `.xyz`-vendored
  install of this harness (pdda repo) — a small, real, already-diagnosed bug with a one-line fix
  direction. Cheap to land immediately rather than let it sit.
- **#169** (acorn first-pass integration) is the natural build follow-through on GH-163's verdict
  (MIT license, zero deps, real-world tested) — wiring the dependency in now, while it's still a
  small additive unit, de-risks GH-156's later Phase 1 work.

Both surfaced the same day, from the same broader thread (GH-163's AST review → acorn evaluation),
but they don't depend on each other and touch entirely different files.

## The one safety rule

Two lanes are safe to run concurrently **iff their write-sets are disjoint**. Trivially true here:

## Collision map

| Zone (shared file) | Parallel-safe? | Lanes |
|---|---|---|
| `relay-automation/aider-turn.sh` (+ its test) | ✅ only one lane touches this | **#168** |
| new dependency + new utility module (package.json, new file, its test) | ✅ only one lane touches this | **#169** |
| independent | ✅ parallel | #168, #169 — no shared file between them |

No two lanes share a write-set. Neither touches the relay kernel (`relay-turn-lib.sh`), containment,
or tick — both are zone `independent`/`shim`, not `kernel`.

## Per-lane summary

| # | Item | Deliverable | Write-set | cx/risk/eff |
|---|------|-------------|-----------|-------------|
| #168 | aider-turn.sh missing `--add-gitignore-files` | One-line flag fix + regression test | `relay-automation/aider-turn.sh` (+test) | 1/1/1 |
| #169 | Acorn first-pass integration | `acorn`+`acorn-walk` dependency + tested extractor utility | new dependency entry + new utility module + test | 2/1/2 |

## Recommended waves

**Wave 1 — parallel (2 lanes ‖):** #168 ‖ #169

No kernel track — neither lane touches containment, tick, or the relay kernel core.

## Execution contract

- **Path:** each lane fires as a worktree-isolated Sonnet subagent, scoped via `ALLOW_PATHS` to its
  own write-set above.
- **Per lane:** complete the doc's Phase 0 checklist and QA checklist in place, land the change with
  a passing regression test, and leave a one-line status update in the doc's own Status table.
- **#169 stays scoped to infra-only** — do not start wiring it into GH-156's active code path in
  this pass; that's gated on GH-156's own Phase 0 scoring-contract decision, which is separate,
  unresolved work.
- **Rated:** both lanes carry provisional cx/risk/eff in their own doc frontmatter (`ratings_
  provisional: true`) — same-day intake, not yet validated against `pdda.sh doc-ready`.

## How to fire a lane

```
utils/swarm-preflight.sh --gh-issue 168   # or --project-doc PROJECT/1-INBOX/GH-168-*.md
utils/swarm-preflight.sh --gh-issue 169   # or --project-doc PROJECT/1-INBOX/GH-169-*.md
   → ready packet (candidate/freshness/fix-still-required + lane assignment)
relay-automation/marathon-drive.sh ...   # build→gate→review, contained
```

---

*Source docs:* [GH-168](../1-INBOX/GH-168-AIDER-TURN-GITIGNORE-BUG.md) ·
[GH-169](../1-INBOX/GH-169-ACORN-FIRST-PASS-INTEGRATION.md) ·
sibling: [Plan D](MARATHON-PLAN-2026-07-07-D-EXPLORE-IDEAS.md).
