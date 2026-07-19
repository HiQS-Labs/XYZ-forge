---
title: Marathon Plan B (2026-07-03) — reliability + cross-repo, PARALLEL dogfood
status: Complete (3-COMPLETED) — waves 1-3 fired 2026-07-04; final parked lane #94 subsequently closed (COMPLETED); status word corrected 2026-07-19 (marathon-cleanup)
created: 2026-07-03
updated: 2026-07-04
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
lanes: [92, 93, 96, 94, 89, 55, 86, 48, 54]
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
| **Waves 1–3 fired 2026-07-04, with #94 still intentionally parked.** Wave 1 remained as recorded here (**#92**, **#93**, **#96**, **#89**, **#86**). **Wave 2** then landed **#55** (auto-include covering tests/helpers in the builder allowlist) and **#48** (configurable cross-repo zone model, README docs, live rebalance validation). **Wave 3** then landed **#54** (fs-touching tests are read-only specs in-turn). Relevant targeted tests stayed green throughout; the repo-wide `validate.sh` rerun was blocked only by the live-network `test/relay-self-sufficiency.sh` agy gate. | Only **#94** remains from this plan, still behind its own "re-verify the repro vs `5972ef4`" gate. GH-48's live rebalance proof corrected one design assumption: a lone helper-writing lane classifies as `signed-helper`, but it does **not** become a solo wave without a second lane in that same capped zone. |

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

## Can we dogfood it with parallel runs? — Yes, on the 5 clean lanes today.

9 remaining lanes (post #23/#61 removal) → **3 waves**. All three planned waves were fired on
2026-07-04 except **#94**, which stayed out exactly as this doc required. The key dogfood property
held: the harness serialized the two shared-file zones correctly (`#89 → #55`, `#86 → #48`) and
kept the cross-zone brief lane `#54` for the final pass.

## The one safety rule

Two lanes are safe to run concurrently **iff their write-sets are disjoint**. Confirmed by grep
(2026-07-03), not inferred.

## Collision map

| Zone (shared file) | Parallel-safe? | Lanes (in order) |
|---|---|---|
| `utils/swarm-preflight.sh` | ❌ serialize | **#89** → **#55** |
| `utils/marathon-plan.sh` | ❌ serialize | **#86** → **#48** |
| `swarm-preflight.sh` **and** `marathon-plan.sh` (brief template) | ❌ cross-zone — run alone, last | **#54** |
| independent (one lane per distinct file) | ✅ parallel | #92, #93, #96, #94 (⚠️ re-verify repro vs 5972ef4 first) |

**Removed 2026-07-04 (operator instruction):**
- **#23** (Cursor CLI lane) — ROADMAP shows the operator explicitly parked this 2026-07-02
  ("skip/park — Codex + agy already give cross-model coverage"), predating this plan; this doc had
  scheduled it in Wave 1 anyway.
- **#61** (CI Tier 1/2) — Tier 1 already shipped (`d9b8a14`, 2026-07-02); the scope as written here
  would have duplicated shipped work. The genuine remainder (Tier 2) is blocked on an operator
  runner-flavor decision (`macos-latest` vs `ubuntu-latest`), not something a lane can resolve.

## Per-lane write-sets (confirmed)

| # | Item | Write-set (primary) | Zone |
|---|------|---------------------|------|
| #92 | poll.sh whole-line-bold pointer → turn-1 deadlock (🔴) | `relay-automation/poll.sh` (+test) | independent |
| #93 | tick analyze % spans whole log, not the run | `src/analyze.js` (+`bin/tick`, +test) | independent* |
| #96 | XYZ⇄Rebalance: xyz-sync check (Seam #2 only — this lane's actual scope; XYZ.json emit and tick-lane consume are separate seams, not built here) | `relay-automation/xyz-sync.sh` (corrected 2026-07-04: dropped `src/take.js` — zero relevance to Seam #2, see [GH-96-XYZ-REBALANCE-SYNC-CHECK.md](GH-96-XYZ-REBALANCE-SYNC-CHECK.md)) | independent (xyz-sync.sh clear of 5972ef4) |
| #94 | Installer heredoc mangles `!`→`\!` | `install.sh` / `xyz-vendor.sh` (installer runtime) | independent · ⚠️ **re-verify repro vs 5972ef4 before building** — not fired this round |
| #89 | swarm-preflight: no greenfield (new-file) ready path | `utils/swarm-preflight.sh` (+test) | swarm-preflight |
| #55 | swarm-preflight: auto-include changed artifact's tests | `utils/swarm-preflight.sh` (+test) | swarm-preflight — queued behind #89 |
| #86 | marathon-plan: surface PR-review lanes (don't drop) | `utils/marathon-plan.sh` (+test) | marathon-plan |
| #48 | marathon-plan: generalize zone model for cross-repo | `utils/marathon-plan.sh` (+test) | marathon-plan — consult-vetted design ready ([doc](GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md)), queued behind #86, not fired this round |
| #54 | marathon brief: forbid in-turn fs-touching tests | brief template in **both** `swarm-preflight.sh` + `marathon-plan.sh` | cross-zone — queued behind both zones settling |

`*` #93 may touch `bin/tick` (subcommand dispatch) if `analyze`'s report fields need surfacing
there. #96 was originally flagged alongside it on the same basis (`take.js`'s `bin/tick` dispatch)
but corrected 2026-07-04 — Seam #2 (this lane's actual scope) is `relay-automation/xyz-sync.sh`'s
own dispatcher, not `bin/tick`, so #93 and #96 no longer share any potential file.

## Recommended waves

**Wave 1 — SHIPPED 2026-07-04 (5 lanes ‖):** #92 ‖ #93 ‖ #96 ‖ **#89** ‖ **#86**
**Wave 2 — SHIPPED 2026-07-04 (2 lanes ‖):** **#55** ‖ **#48**
**Wave 3 — SHIPPED 2026-07-04 (1 lane):** **#54**
**Not fired from this plan:** #94 (its own unresolved re-verify gate).

Suggested branches: `marathon/gh-<n>-<slug>-2026-07-04` per lane (one per worktree).

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
  gives `swarm-preflight` the cx/risk/eff it needs.

## Sequencing note vs Plan A
Plan B lanes assume Plan A's token model. If run before Plan A, the parallel waves still work
(disjoint writes), but the concurrency *metrics* (#93) and work-stealing safety are only fully
trustworthy after #41. Recommended: **Plan A first (serial), then Plan B (parallel).**
**Satisfied as of 2026-07-04** — Plan A shows 5/5 lanes shipped (re-verified live, not just per its
own doc), so this precondition is cleanly cleared for the Wave 1 fire below.
