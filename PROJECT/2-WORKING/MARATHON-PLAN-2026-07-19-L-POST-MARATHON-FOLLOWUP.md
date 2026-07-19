---
title: "Marathon Plan L — post-marathon follow-up queue (2026-07-19)"
status: Active (2-WORKING) — assembling; not yet fired
created: 2026-07-19
updated: 2026-07-19
owner: noel
doc_type: project
roadmap_exempt: true
goal: >
  A hand-curated follow-up marathon queue seeded after the 2026-07-19 /10days marathon merged to
  development. Lane 1 is GH-251 (OpenRouter/aider reviewer seam), surfaced by that marathon's own
  GLM 5.2 QA relay. Lanes 2-4 are the most critical survivors of a fresh /10days recon pass. Each
  lane carries (or will carry) a swarm-preflight contract before firing.
---

# Marathon Plan L — post-marathon follow-up (2026-07-19)

> Curated queue, NOT a generated `marathon-plan.sh` snapshot. Assembled by hand after the 2026-07-19
> marathon; each lane is verified real and contract-backed before it fires. **Not yet fired** — this
> file is the queue, the operator fires it (or re-runs `/10days` on it) when ready.

## Status

| What was just completed | What's next |
|---|---|
| Seeded 2026-07-19 with **GH-251** (lane 1), promoted 1-INBOX → 2-WORKING with its auto-drafted contract. Lanes 2-4 pending a `/10days` recon pass (task 6). | Fill lanes 2-4 from the recon's most-critical survivors, run `swarm-preflight` per lane, then fire wave-by-wave (or hand to `/10days`). |

## The one safety rule

Two lanes run concurrently **iff their write-sets (contract `artifacts`) are disjoint** and zone caps
hold (kernel ≤ 1 per wave). Re-check the collision map below every time a lane is added.

## Lanes

| # | Item | Zone | cx | risk | eff | Contract? | Artifacts (write-set) |
|---|---|---|---|---|---|---|---|
| 1 | [GH-251] OpenRouter/aider reviewer seam doesn't persist its review | independent | 2 | 2 | 2 | ✅ draft | `relay-automation/aider-turn.sh` |
| 2 | _(pending /10days recon — task 6)_ | — | — | — | — | — | — |
| 3 | _(pending /10days recon — task 6)_ | — | — | — | — | — | — |
| 4 | _(pending /10days recon — task 6)_ | — | — | — | — | — | — |

## Collision map

| Zone | Parallel-safe? | Active items here |
|---|---|---|
| independent | ✅ one lane per file | #251 |
| kernel | ❌ serialize — one at a time | — |

_(Update when lanes 2-4 land.)_

## Lanes in detail

### Lane 1 — GH-251 · OpenRouter/aider reviewer seam
- Doc: [GH-251-OPENROUTER-AIDER-REVIEWER-SEAM.md](GH-251-OPENROUTER-AIDER-REVIEWER-SEAM.md) · [#251](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/251)
- Surfaced by the 2026-07-19 marathon's GLM 5.2 QA relay: aider produces a correct review but doesn't
  persist the relay-file append, so review turns land as stalls. Fix: review-mode / transcript-salvage
  for `aider-turn.sh`, or document builder-only and route reviews to codex/agy.
- Write-set: `relay-automation/aider-turn.sh` (independent zone). Contract auto-drafted, flagged for
  operator verification (see the doc's Swarm Preflight Contract).

## How to fire a lane

Per lane, the existing pipeline applies:

```
utils/swarm-preflight.sh --gh-issue <N>          # ready packet (candidate/freshness/fix-still-required)
   → then execute per the marathon execution pattern (worktree-isolated lanes; kernel Claude-direct)
```

---

*Curated follow-up queue. Add survivors from the /10days recon as lanes 2-4, then re-check the collision map before firing.*
