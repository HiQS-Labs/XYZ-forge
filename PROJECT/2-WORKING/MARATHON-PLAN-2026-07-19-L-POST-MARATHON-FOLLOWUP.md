---
title: "Marathon Plan L — post-marathon follow-up queue (2026-07-19)"
status: Active (2-WORKING) — 3 lanes, all contracts preflight exit 0; not yet fired
created: 2026-07-19
updated: 2026-07-20
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
| Seeded with **GH-251** (lane 1), then filled from a 2026-07-19 `/10days` recon (27 open in window). **Contract-authoring pass 2026-07-20 corrected two first-pass picks:** #248's core fix already landed (I misread the `$HERE/..` *fallback* in the fixed code) and #170 preflights **STALE (exit 4)** — both dropped. Genuine, contract-ready lanes: **#251**, **#241** (contract authored + promoted to 2-WORKING), **#218**. All three **preflight exit 0 (ready)** and have **disjoint write-sets** → one wave. | Fire the 3 lanes (worktree-isolated; independent zone, no serialization) via `swarm-preflight → marathon`, or hand to `/10days`. **Not yet fired.** |

## The one safety rule

Two lanes run concurrently **iff their write-sets (contract `artifacts`) are disjoint** and zone caps
hold (kernel ≤ 1 per wave). Re-check the collision map below every time a lane is added.

## Lanes

| # | Item | Zone | cx | risk | eff | Contract (preflight) | Artifacts (write-set) |
|---|---|---|---|---|---|---|---|
| 1 | [GH-251] OpenRouter/aider reviewer seam doesn't persist its review | independent | 2 | 2 | 2 | ✅ **ready (exit 0)** | `relay-automation/aider-turn.sh` |
| 2 | [GH-241] `MARATHON.example.yaml` `depends_on` list-form silently fails — remaining fix 3 (a `bin/marathon-yaml` guard) | independent | 1 | 2 | 1 | ✅ **ready (exit 0)** — authored 2026-07-20 | `bin/marathon-yaml`, `test/marathon-yaml.sh` |
| 3 | [GH-218] Cross-repo live marathon status query (repo + lane + in-flight task), no per-repo MCP servers | independent | 3 | 2 | 3 | ✅ **ready (exit 0)** | `utils/hq/marathon-live.sh`, `utils/hq/rollup.sh`, `test/hq-marathon-live.sh`, `test/hq-rollup.sh` |

**Dropped during the contract pass (verified already-done — not build lanes):**

| Was | Why dropped |
|---|---|
| ~~GH-248~~ turn-shim `$HERE/..` root | **Core fix already landed** on development (`git rev-parse --show-toplevel` form present in the shims; issue body itself says "Fix shipped in `fd98856`"). Only a minor follow-up remains (make the silent cross-repo warning a hard error) — not marathon-critical. |
| ~~GH-170~~ validate.sh failing tests | **Preflight STALE (exit 4)** — fix-probe reports the bug landed; heavily overlaps GH-232's already-shipped environmental-skip handling. |

## Collision map

| Zone | Parallel-safe? | Active items here |
|---|---|---|
| independent | ✅ one lane per file — **all three write-sets are disjoint** | #251, #241, #218 |
| kernel | ❌ serialize — one at a time | — |

**No serialization needed.** With #248 dropped, the three surviving lanes touch disjoint files —
`relay-automation/aider-turn.sh` (#251), `bin/marathon-yaml` + `test/marathon-yaml.sh` (#241),
`utils/hq/*` + `test/hq-*` (#218) — verified against each contract's `artifacts`. **Single wave:**
#251 ‖ #241 ‖ #218.

## Lanes in detail

### Lane 1 — GH-251 · OpenRouter/aider reviewer seam
- Doc: [GH-251-OPENROUTER-AIDER-REVIEWER-SEAM.md](GH-251-OPENROUTER-AIDER-REVIEWER-SEAM.md) · [#251](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/251)
- Surfaced by the 2026-07-19 marathon's GLM 5.2 QA relay: aider produces a correct review but doesn't
  persist the relay-file append, so review turns land as stalls. Fix: review-mode / transcript-salvage
  for `aider-turn.sh`, or document builder-only and route reviews to codex/agy.
- Write-set: `relay-automation/aider-turn.sh` (independent zone). Contract auto-drafted, flagged for
  operator verification (see the doc's Swarm Preflight Contract). **Preflight: ready (exit 0).**

### Lane 2 — GH-241 · MARATHON.example.yaml depends_on list-form guard (remaining fix 3)
- Doc: [GH-241-MARATHON-EXAMPLE-SEQUENCING.md](GH-241-MARATHON-EXAMPLE-SEQUENCING.md) · [#241](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/241) — **contract authored + promoted to 2-WORKING 2026-07-20.**
- The docs fixes (1)(2)(4) shipped 2026-07-18; **fix (3) remains**: `depends_on: [p1]` parses as the literal
  string `[p1]` and fails at `bin/marathon-yaml:102-105` as an unknown-phase lookup. Add a guard that rejects
  the YAML flow-sequence form with a shape-specific message, plus a `test/marathon-yaml.sh` regression case.
- Write-set: `bin/marathon-yaml`, `test/marathon-yaml.sh` (independent zone). **Preflight: ready (exit 0).**
  Contract auto-drafted — its `fix_probes` pattern (`flow sequence`) must be reconciled with the actual fix message.

### Lane 3 — GH-218 · cross-repo live marathon status query
- Doc: [GH-218-CROSS-REPO-LIVE-MARATHON-STATUS.md](GH-218-CROSS-REPO-LIVE-MARATHON-STATUS.md) · [#218](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/218) — operator-promoted to 2-WORKING; carries a contract.
- Query live marathon status across repos (repo + lane + in-flight task) without standing up per-repo MCP
  servers — an HQ rollup extension. Highest-effort lane of the three; genuine operator-requested capability.
- Write-set: `utils/hq/marathon-live.sh`, `utils/hq/rollup.sh`, `test/hq-marathon-live.sh`, `test/hq-rollup.sh`
  (independent zone). **Preflight: ready (exit 0).**

## How to fire a lane

Per lane, the existing pipeline applies:

```
utils/swarm-preflight.sh --gh-issue <N>          # ready packet (candidate/freshness/fix-still-required)
   → then execute per the marathon execution pattern (worktree-isolated lanes; kernel Claude-direct)
```

---

*Curated follow-up queue. 3 lanes, all contracts preflight exit 0, disjoint write-sets → one wave. Fire when ready.*
