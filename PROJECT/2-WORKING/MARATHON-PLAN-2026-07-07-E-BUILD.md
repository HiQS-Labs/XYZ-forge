---
title: Marathon Plan E (2026-07-07) — acorn-integration + aider-turn.sh + hq-resolve bugfix cluster
status: Ready to fire (2-WORKING) — docs authored + rated, not yet fired
created: 2026-07-07
updated: 2026-07-07
owner: noel
branch: main
doc_type: project
source: hand-curated — GH-163's acorn verdict (build follow-through) + a live aider-turn.sh bug found via a `.xyz`-vendored relay run in the pdda repo + a hq_repo_resolve dedup gap found live via GH-158
generated_by: hand-authored (3 lanes, same-day intake, not ledger-ranked)
lanes: [159, 168, 169]
execution: parallel Sonnet subagents, one per lane — independent write-sets, no builder/reviewer relay needed for any
roadmap_exempt: true
goal: >
  Three independent build lanes for today: a one-line aider-turn.sh gitignore fix (#168) found live
  during a vendored relay run, the first-pass acorn+acorn-walk vendoring (#169) that follows through
  on GH-163's license-vetted, smoke-tested verdict, and a hq_repo_resolve dedup fix (#159) found live
  via GH-158's marathon-scan dogfood. None depend on each other; none touch GH-156's still-open
  scoring contract or the relay kernel.
---

# Marathon Plan E — 2026-07-07 · acorn-integration + aider-turn.sh + hq-resolve bugfix cluster

> Sibling of [Plan D](MARATHON-PLAN-2026-07-07-D-EXPLORE-IDEAS.md) (same-day explore cluster,
> GH-161..164) but a different shape: all three lanes here are **build** lanes — real code changes
> with tests, not doc-only Phase 0 exploration.

## Status

| What was just completed | What's next |
|---|---|
| GH-168 and GH-169 filed 2026-07-07; GH-159 (captured 2026-07-06, found live via GH-158) got its missing local doc authored 2026-07-07 and added as this cluster's third lane. All three rated and scoped (see their own docs in `PROJECT/1-INBOX/`). Nothing built yet. | Fire all three lanes in parallel — fully independent write-sets, no shared file, no kernel-zone risk. |

## Why this cluster, why now

- **#168** (aider-turn.sh gitignore bug) surfaced live during a real relay run in a `.xyz`-vendored
  install of this harness (pdda repo) — a small, real, already-diagnosed bug with a one-line fix
  direction. Cheap to land immediately rather than let it sit.
- **#169** (acorn first-pass integration) is the natural build follow-through on GH-163's verdict
  (MIT license, zero deps, real-world tested) — wiring the dependency in now, while it's still a
  small additive unit, de-risks GH-156's later Phase 1 work.
- **#159** (`hq_repo_resolve` dedup) was captured a day earlier (2026-07-06, found live via GH-158's
  `marathon-scan.sh` dogfood run) but never got a local doc, so it sat in the held/`needs-doc`
  list. A repo-state audit surfaced it as small, real, and root-caused enough to fire today rather
  than stay parked.

All three surfaced from real dogfood/field use of the harness, not speculative work; none depend on
each other and each touches an entirely different file.

## The one safety rule

Two lanes are safe to run concurrently **iff their write-sets are disjoint**. Trivially true here:

## Collision map

| Zone (shared file) | Parallel-safe? | Lanes |
|---|---|---|
| `relay-automation/aider-turn.sh` (+ its test) | ✅ only one lane touches this | **#168** |
| new dependency + new utility module (package.json, new file, its test) | ✅ only one lane touches this | **#169** |
| `utils/hq/hq-lib.sh` (+ its test) | ✅ only one lane touches this | **#159** |
| independent | ✅ parallel | #159, #168, #169 — no shared file between any of them |

No two lanes share a write-set. None touches the relay kernel (`relay-turn-lib.sh`), containment,
or tick — all three are zone `independent`/`shim`, not `kernel`.

## Per-lane summary

| # | Item | Deliverable | Write-set | cx/risk/eff |
|---|------|-------------|-----------|-------------|
| #159 | `hq_repo_resolve` dedup | Dedup-by-resolved-path fix + regression test | `utils/hq/hq-lib.sh` (+test) | 2/1/2 |
| #168 | aider-turn.sh missing `--add-gitignore-files` | One-line flag fix + regression test | `relay-automation/aider-turn.sh` (+test) | 1/1/1 |
| #169 | Acorn first-pass integration | `acorn`+`acorn-walk` dependency + tested extractor utility | new dependency entry + new utility module + test | 2/1/2 |

## Recommended waves

**Wave 1 — parallel (3 lanes ‖):** #159 ‖ #168 ‖ #169

No kernel track — none of these lanes touch containment, tick, or the relay kernel core.

## Execution contract

- **Path:** each lane fires as a worktree-isolated Sonnet subagent, scoped via `ALLOW_PATHS` to its
  own write-set above.
- **Per lane:** complete the doc's Phase 0 checklist and QA checklist in place, land the change with
  a passing regression test, and leave a one-line status update in the doc's own Status table.
- **#169 stays scoped to infra-only** — do not start wiring it into GH-156's active code path in
  this pass; that's gated on GH-156's own Phase 0 scoring-contract decision, which is separate,
  unresolved work.
- **#159 stays scoped to the dedup fix only** — do not use it as an opportunity to refactor
  `hq_xyz_lookup`/`hq_repo_resolve` more broadly; the genuine-collision disambiguation path
  (Blocker 1, differing directories with the same basename) must keep working unchanged.
- **Rated:** all three lanes carry provisional cx/risk/eff in their own doc frontmatter (`ratings_
  provisional: true`) — same-day/prior-day intake, not yet validated against `pdda.sh doc-ready`.

## How to fire a lane

```
utils/swarm-preflight.sh --gh-issue 159   # or --project-doc PROJECT/1-INBOX/GH-159-*.md
utils/swarm-preflight.sh --gh-issue 168   # or --project-doc PROJECT/1-INBOX/GH-168-*.md
utils/swarm-preflight.sh --gh-issue 169   # or --project-doc PROJECT/1-INBOX/GH-169-*.md
   → ready packet (candidate/freshness/fix-still-required + lane assignment)
relay-automation/marathon-drive.sh ...   # build→gate→review, contained
```

---

*Source docs:* [GH-159](../1-INBOX/GH-159-HQ-REPO-RESOLVE-DEDUPE.md) ·
[GH-168](../1-INBOX/GH-168-AIDER-TURN-GITIGNORE-BUG.md) ·
[GH-169](../1-INBOX/GH-169-ACORN-FIRST-PASS-INTEGRATION.md) ·
sibling: [Plan D](MARATHON-PLAN-2026-07-07-D-EXPLORE-IDEAS.md).
