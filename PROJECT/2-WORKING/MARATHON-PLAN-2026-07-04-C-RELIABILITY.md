---
title: Marathon Plan C (2026-07-04) — dogfood-reliability cluster (Plan B follow-through)
status: Ready to fire (2-WORKING) — docs authored + rated, not yet fired
created: 2026-07-04
updated: 2026-07-04
owner: noel
branch: main
doc_type: project
source: hand-curated from a live vendored-install marathon dogfood field report (#106/#107/#108) + tick/marathon-yaml bugs (#113/#114/#116/#117) + PR #125's own review follow-ups (#126/#127) + GH-87 dogfood hardening (#124)
generated_by: hand-authored (curated subset; write-sets confirmed by grep against current main, not full-ledger ranking)
roadmap_exempt: true
goal: >
  With Marathon Plan B (all 3 waves) and the 2026-07-04 Fable/Gemini/Aider blend plan both fully
  shipped, this is the next cohesive cluster: reliability findings from real dogfood runs of the
  harness on itself and on a foreign repo, plus the two follow-ups from independently reviewing
  Plan B's own Wave 2+3 PR (#125). Five buildable lanes, one already-shipped item confirmed out of
  scope, one Opus-serial kernel item, six issues total (#106, #107, #108+#126+#127 bundled, #116,
  #117, #124).
lanes: [106, 107, 108, 116, 117, 124]
lanes_bundled_into_108: [126, 127]
execution: mixed — parallel Sonnet subagents for 5 independent/shim/swarm-preflight lanes, Opus-direct serial for the 1 kernel lane (#107)
---

# Marathon Plan C — 2026-07-04 · dogfood-reliability cluster

> Sibling of [Plan B](MARATHON-PLAN-2026-07-03-B-PARALLEL.md) (fully shipped — all 3 waves) and the
> [2026-07-04 blend plan](../3-COMPLETED/MARATHON-PLAN-2026-07-04.md) (also fully shipped). This
> plan exists because those two are done and the queue still has a real, cohesive cluster left:
> reliability bugs surfaced by dogfooding the harness itself.

## Status

| What was just completed | What's next |
|---|---|
| All 6 capture docs authored and rated (2026-07-04): #106, #107 (kernel), #108 (bundles #126/#127), #116 (Bug B only — Bug A already shipped in `bb9138b`), #117, #124. Collision map confirmed by grep against current `main` — zero write-set overlap across the 5 parallel lanes; #107 flagged kernel-zone for touching `relay-turn-lib.sh`. Not yet fired. | Fire Wave 1 (#106 ‖ #108 ‖ #116 ‖ #117 ‖ #124, parallel worktree-isolated Sonnet subagents) and separately schedule the #107 kernel track (Opus-serial, `decisions/` record). |

## Why this cluster, why now

Two independent surveys converged on the same handful of issues:

1. **A live vendored-install marathon dogfood run** (2026-07-03, against a foreign Node repo) hit
   three distinct friction points that each individually blocked an otherwise-correct build from
   advancing cleanly: `#106` (codex approval hang), `#107` (containment tool-cache false-positive),
   `#108` (gate-scoping assumption).
2. **This session's own PDDA-compliance + PR review work** found `#113`/`#114` were already fixed
   (closed without building — see CHANGELOG 2026-07-04), `#116` Bug A already shipped (`bb9138b`,
   leaving only Bug B — the `--retry` flag), and independent review of PR #125 (Plan B's own Wave
   2+3) filed two more findings in the exact same file `#108` already touches (`#126`, `#127`).
   `#124` (GH-87's real-agy hardening follow-up) rounds out the cluster as the one item not about
   the marathon harness's own turn-taking, but about a tool the harness ships.

Every item here is independently real (verified against current `main` before writing its capture
doc — none were already fixed, unlike the `#113`/`#114` false starts this session already caught and
closed).

## The one safety rule

Two lanes are safe to run concurrently **iff their write-sets are disjoint**. Confirmed by grep
against current `main` (2026-07-04), not inferred.

## Collision map

| Zone (shared file) | Parallel-safe? | Lanes |
|---|---|---|
| `relay-automation/relay-turn-lib.sh` | ❌ kernel — Opus-serial, alone | **#107** |
| `utils/swarm-preflight.sh` | N/A — only one lane touches this file this round | **#108** (bundles #126, #127 into the same turn to avoid 3x same-file serialization for a combined small change) |
| independent (one lane per distinct file) | ✅ parallel | #106 (`codex-turn.sh`), #116 (`marathon.sh`), #117 (`marathon-drive.sh`), #124 (`deep-research.mjs` + its test + README) |

No two lanes here share a write-set. `#107` is flagged kernel-zone not because of a collision but
because it edits the containment core itself (`relay-turn-lib.sh`) — this repo's own
model-assignment convention routes that to Opus-serial with a `decisions/` record, regardless of
whether anything else is running concurrently.

## Per-lane summary

| # | Item | Write-set | Zone | cx/risk/eff |
|---|------|-----------|------|-------------|
| #106 | codex-turn: default `CODEX_FLAGS` hangs headless | `relay-automation/codex-turn.sh` (+test) | independent (shim) | 2/2/2 |
| #107 | Containment reverts a passing turn on off-lane tool-cache dirs | `relay-automation/relay-turn-lib.sh` | **kernel** | 3/**4**/2 |
| #108 | swarm-preflight hardening bundle (gate-scoping caveat + #126 substring tightening + #127 regex gap) | `utils/swarm-preflight.sh` (+test) | swarm-preflight (sole lane this round) | 3/2/3 |
| #116 | marathon.sh `--retry <phase-id>` flag (Bug B; Bug A already shipped) | `relay-automation/marathon.sh` (+test) | independent | 2/1/2 |
| #117 | marathon-drive: probe builder/reviewer binary before tick mutation | `relay-automation/marathon-drive.sh` (+test) | independent | 2/1/2 |
| #124 | deep-research: real-agy smoke test + runaway-grounding guard | `relay-automation/deep-research.mjs`, `test/deep-research.sh`, README | independent | 2/1/2 |

## Recommended waves

**Wave 1 — parallel (5 lanes ‖):** #106 ‖ #108 ‖ #116 ‖ #117 ‖ #124
**Kernel track — separate, Opus-direct, serial (not a wave, runs on its own schedule):** #107

This mirrors Plan A/B's own established split: independent/shim work fires as parallel
worktree-isolated Sonnet subagents with Opus integrating centrally; kernel-correctness work
(containment, epoch-fencing) routes to an Opus-direct serial pass with a `decisions/` record, never
a parallel lane.

## Execution contract (same as Plan B)

- **Path:** each Wave-1 lane fires via a worktree-isolated Sonnet subagent with disjoint
  `ALLOW_PATHS`; **Opus reviews + integrates + commits centrally** — re-run `./validate.sh` at each
  integration point, never trust a per-agent "green" (the standing lesson from GH-88 and reconfirmed
  by this session's own PR #125 review, which found the PR's *specific* validate.sh-failure
  attribution was wrong even though its bottom-line claim held).
- **#107 runs separately**, Opus-direct, not inside a worktree-isolated Sonnet subagent, per this
  repo's kernel-track convention. Do not fire it in the same wave as anything else touching
  `relay-turn-lib.sh`, `bin/tick`, or `relay-drive.sh` (none of Wave 1's lanes do).
- **Per lane:** GH-<n> pointer doc (already authored, this batch), branch, implement, extend the
  covering test, `./validate.sh` green at integration, file-scoped commit, push, `2-WORKING` →
  `3-COMPLETED`, ROADMAP/CHANGELOG.
- **Rated:** all 6 lanes already carry cx/risk/eff in their frontmatter (this doc's own table above);
  no `pdda.sh frontmatter` gap to fix before firing.

## How to fire a lane

```bash
utils/swarm-preflight.sh --gh-issue 106   # or 108 (bundle covers 126/127 too), 116, 117, 124

relay-automation/marathon-drive.sh \
  --builder codex \
  --reviewer agy \
  --allow-paths "<ALLOW_PATHS from the lane's capture doc>" \
  --branch "marathon/gh-<n>-<slug>-2026-07-04"
```

`#107` is driven Opus-direct (not via `swarm-preflight → marathon-drive`'s parallel-Sonnet path) —
see its own capture doc's Swarm Preflight Contract `lanes.orchestrator_only` note.

---

*Source docs:* [GH-106](GH-106-CODEX-FLAGS-HEADLESS-HANG.md) ·
[GH-107](GH-107-CONTAINMENT-OFFLANE-TOOLCACHE.md) ·
[GH-108 bundle](GH-108-SWARM-PREFLIGHT-HARDENING-BUNDLE.md) ·
[GH-116](GH-116-MARATHON-RETRY-FLAG.md) ·
[GH-117](GH-117-MARATHON-DRIVE-BINARY-PREFLIGHT.md) ·
[GH-124](GH-124-DEEP-RESEARCH-REAL-AGY-HARDENING.md) ·
sibling: [Plan B](MARATHON-PLAN-2026-07-03-B-PARALLEL.md).
