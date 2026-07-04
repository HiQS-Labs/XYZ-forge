---
title: Marathon Plan B (2026-07-03) — reliability + cross-repo, PARALLEL dogfood
status: Active (2-WORKING)
created: 2026-07-03
updated: 2026-07-03
owner: noel
branch: main
doc_type: project
source: hand-curated from ROADMAP.md open ledger (operator-picked lane set)
generated_by: hand-authored (curated subset; write-sets confirmed by grep, not full-ledger ranking)
roadmap_exempt: true
goal: >
  Clear the reliability bugs + cross-repo/model-diversity backlog as a real PARALLEL
  dogfood of the swarm harness itself: fan out disjoint-write-set lanes concurrently,
  and let the two shared-file zones (swarm-preflight.sh, marathon-plan.sh) plus the one
  cross-zone lane (#54) exercise the collision engine that this harness exists to run.
lanes: [92, 93, 96, 23, 94, 61, 89, 55, 86, 48, 54]
execution: parallel · dogfood via swarm-preflight → marathon-drive (or Sonnet subagents, Opus integrates)
---

# Marathon Plan B — 2026-07-03 · reliability + cross-repo (PARALLEL dogfood)

> Curated subset of [ROADMAP.md](../../ROADMAP.md). Sibling of
> [Plan A (serial kernel)](MARATHON-PLAN-2026-07-03-A-SERIAL.md). This is deliberately run as a
> **parallel dogfood**: the lane set was chosen so that most lanes are write-disjoint, and the
> few that aren't force the harness to serialize them itself.

## Status

| What was just completed | What's next |
|---|---|
| Hold lifted, waves planned (below), collision map confirmed by grep. Not yet fired — all 11 lanes (#92, #93, #96, #23, #94, #61, #89, #55, #86, #48, #54) remain **open** as of 2026-07-03 (checked live, not inferred). Sibling [Plan A](MARATHON-PLAN-2026-07-03-A-SERIAL.md) is 4/5 shipped in the meantime, so its recommended sequencing ("Plan A first, then Plan B") is nearly satisfied. | Fire Wave 1 (8 lanes) once #94's re-verify-vs-`5972ef4` gate is resolved one way or the other (fix-if-still-broken, or close-as-already-fixed). |

## ✅ HOLD LIFTED (2026-07-03)

The concurrent vendor-installer work **landed in `5972ef4`** (*full-mirror XYZ install + vendor-aware
consult*) and is pushed. Contention is over. Re-confirmed against that commit:

- **#94 — UNBLOCKED, but RE-VERIFY first.** `5972ef4` rewrote `relay-automation/xyz-vendor.sh` (73 lines,
  mostly deletions) and did **not** touch `install.sh`. So the ground under #94 moved: **reproduce the
  heredoc `!`→`\!` mangling against the new `xyz-vendor.sh`/`install.sh` before building** — the bug may
  have been incidentally fixed. If it no longer repros, close #94 as fixed-by-5972ef4 instead of building.
- **#96 — CLEAR.** `relay-automation/xyz-sync.sh` was **not** touched by the vendor work (last change
  `f2a52a9`), so #96 is genuinely independent. WATCH flag removed.
- **Plan A is unaffected** (kernel/scheduler files only) and is being started now.

## Can we dogfood it with parallel runs? — Yes.

11 lanes → **3 waves, ~8 lanes wide at peak** (#94 rejoins Wave 1 pending its re-verify gate). Six lanes
are fully write-disjoint and run together; two shared-file zones are each 2 deep; one lane (#54) edits the
brief template in *both* zone files, so it runs last, alone. This is a *good* dogfood precisely because it
isn't embarrassingly parallel — it makes `swarm-preflight`'s write-set disjointness check do real work.

## The one safety rule

Two lanes are safe to run concurrently **iff their write-sets are disjoint**. Confirmed by grep
(2026-07-03), not inferred.

## Collision map

| Zone (shared file) | Parallel-safe? | Lanes (in order) |
|---|---|---|
| `utils/swarm-preflight.sh` | ❌ serialize | **#89** → **#55** |
| `utils/marathon-plan.sh` | ❌ serialize | **#86** → **#48** |
| `swarm-preflight.sh` **and** `marathon-plan.sh` (brief template) | ❌ cross-zone — run alone, last | **#54** |
| independent (one lane per distinct file) | ✅ parallel | #92, #93, #96, #23, #61, #94 (⚠️ re-verify repro vs 5972ef4 first) |

## Per-lane write-sets (confirmed)

| # | Item | Write-set (primary) | Zone |
|---|------|---------------------|------|
| #92 | poll.sh whole-line-bold pointer → turn-1 deadlock (🔴) | `relay-automation/poll.sh` (+test) | independent |
| #93 | tick analyze % spans whole log, not the run | `src/analyze.js` (+`bin/tick`, +test) | independent* |
| #96 | XYZ⇄Rebalance: xyz-sync check · XYZ.json emit · tick-lane consume | `relay-automation/xyz-sync.sh` + `src/take.js` | independent* (xyz-sync.sh clear of 5972ef4) |
| #23 | Cursor CLI lane (3rd cross-model worker) | **new** `relay-automation/cursor-turn.sh` + routing in `marathon-agent.sh`/`marathon-drive.sh` | independent |
| #94 | Installer heredoc mangles `!`→`\!` | `install.sh` / `xyz-vendor.sh` (installer runtime) | independent · ⚠️ **re-verify repro vs 5972ef4 before building** |
| #61 | CI: GitHub Actions Tier-1 lint + Tier-2 validate gate | **new** `.github/workflows/*.yml` | independent |
| #89 | swarm-preflight: no greenfield (new-file) ready path | `utils/swarm-preflight.sh` (+test) | swarm-preflight |
| #55 | swarm-preflight: auto-include changed artifact's tests | `utils/swarm-preflight.sh` (+test) | swarm-preflight |
| #86 | marathon-plan: surface PR-review lanes (don't drop) | `utils/marathon-plan.sh` (+test) | marathon-plan |
| #48 | marathon-plan: generalize zone model for cross-repo | `utils/marathon-plan.sh` (+test) | marathon-plan |
| #54 | marathon brief: forbid in-turn fs-touching tests | brief template in **both** `swarm-preflight.sh` + `marathon-plan.sh` | cross-zone |

`*` #93 and #96 both may touch `bin/tick` (subcommand dispatch). They edit *different* `src/*.js`
files (`analyze.js` vs `take.js`), so they're parallel-safe unless a lane needs to register a new
`bin/tick` verb — if so, serialize those two on `bin/tick` only. Flag for the driver.

## Recommended waves

**Wave 1 (8 lanes ‖):** #92 ‖ #93 ‖ #96 ‖ #23 ‖ #94 ‖ #61 ‖ **#89** ‖ **#86**  *(#94 gated on its re-verify — see hold-lifted note)*
**Wave 2 (2 lanes ‖):** **#55** ‖ **#48**  *(second lane of each shared-file zone)*
**Wave 3 (1 lane):** **#54**  *(cross-zone brief template — after both zones settle)*

Suggested branches: `marathon/gh-<n>-<slug>-2026-07-03` per lane (one per worktree).

## Execution contract (dogfood)

- **Path:** each Wave-1 lane fires via `swarm-preflight → marathon-drive` (or a Sonnet subagent per
  lane with disjoint `ALLOW_PATHS`; **Opus reviews + integrates + commits centrally** — do not trust
  a per-agent "green," re-run `./validate.sh` at the integration point). This is the pattern that
  caught the Wave-1 (GH-88) 9/4-vs-13/0 discrepancy.
- **Worktree isolation on** for parallel lanes (`RELAY_WORKTREE_ISOLATION`) so concurrent lanes never
  share a checkout — and one global driver lock still serializes anything that slips a shared file.
- **Zone ordering is mandatory:** never run #89+#55 or #86+#48 in the same wave; never run #54 beside
  either zone. The collision map above is the gate.
- **Per lane:** GH-<n> pointer doc (issue-first), branch, implement, extend the *covering* test,
  `./validate.sh` green at integration, file-scoped commit, push, INBOX→COMPLETED, ROADMAP/CHANGELOG.
- **Rate before firing:** several lanes are unrated — a quick `utils/pdda/pdda.sh frontmatter` pass
  gives `swarm-preflight` the cx/risk/eff it needs; greenfield lanes (#23, #61) will exercise #89's
  own gap (new-file artifacts), so expect #89 to land before those two can get a clean "ready" packet.

## Sequencing note vs Plan A
Plan B lanes assume Plan A's token model. If run before Plan A, the parallel waves still work
(disjoint writes), but the concurrency *metrics* (#93) and work-stealing safety are only fully
trustworthy after #41. Recommended: **Plan A first (serial), then Plan B (parallel).**
