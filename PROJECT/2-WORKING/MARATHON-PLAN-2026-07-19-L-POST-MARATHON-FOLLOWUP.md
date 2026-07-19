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
| Seeded with **GH-251** (lane 1), then filled lanes 2-4 from a 2026-07-19 `/10days` recon pass (27 open issues in window; 13 were the just-fired lanes, excluded as merged; #239/#238 excluded as already-landed, #216 excluded as resolved, #201/#235 excluded as shipped). Lanes 2-4: **#248**, **#170**, **#241** — the 3 most critical verified-open survivors. | Author/verify each lane's swarm-preflight contract (lanes 2 & 4 need one; lane 3 has one), re-check the collision map (lane 2 shares `aider-turn.sh` with lane 1 → serialize), then fire wave-by-wave or hand to `/10days`. **Not yet fired.** |

## The one safety rule

Two lanes run concurrently **iff their write-sets (contract `artifacts`) are disjoint** and zone caps
hold (kernel ≤ 1 per wave). Re-check the collision map below every time a lane is added.

## Lanes

| # | Item | Zone | cx | risk | eff | Contract? | Artifacts (write-set) |
|---|---|---|---|---|---|---|---|
| 1 | [GH-251] OpenRouter/aider reviewer seam doesn't persist its review | shim | 2 | 2 | 2 | ✅ draft | `relay-automation/aider-turn.sh` |
| 2 | [GH-248] Turn shims root at the shim's own repo (`$HERE/..`), not the target, on non-vendored runs | shim | 2 | 3 | 2 | ⚠️ needed | `relay-automation/{agy,aider,codex,claude}-turn.sh` (root resolution) |
| 3 | [GH-170] `validate.sh` pre-existing failing tests (gate integrity) | independent | 3 | 2 | 3 | ✅ (2-WORKING doc) | the failing `test/*.sh` + the code each exercises |
| 4 | [GH-241] `MARATHON.example.yaml` `depends_on` list-form silently fails — deferred fix 3 (a `bin/marathon-yaml` guard) | independent | 1 | 2 | 1 | ⚠️ needed | `bin/marathon-yaml` (+ `relay-automation/MARATHON.example.yaml`) |

## Collision map

| Zone | Parallel-safe? | Active items here |
|---|---|---|
| shim | ⚠️ serialize — **#251 and #248 both write `relay-automation/aider-turn.sh`** | #251, #248 |
| independent | ✅ one lane per file | #170, #241 |
| kernel | ❌ serialize — one at a time | — |

**Serialization required:** #251 and #248 share `relay-automation/aider-turn.sh`, so they **cannot** run
in the same wave. Suggested waves: **Wave 1** = #251 ‖ #170 ‖ #241 (disjoint write-sets); **Wave 2** = #248
(after #251's `aider-turn.sh` edit lands). Re-derive once each lane's real contract `artifacts` are pinned.

## Lanes in detail

### Lane 1 — GH-251 · OpenRouter/aider reviewer seam
- Doc: [GH-251-OPENROUTER-AIDER-REVIEWER-SEAM.md](GH-251-OPENROUTER-AIDER-REVIEWER-SEAM.md) · [#251](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/251)
- Surfaced by the 2026-07-19 marathon's GLM 5.2 QA relay: aider produces a correct review but doesn't
  persist the relay-file append, so review turns land as stalls. Fix: review-mode / transcript-salvage
  for `aider-turn.sh`, or document builder-only and route reviews to codex/agy.
- Write-set: `relay-automation/aider-turn.sh` (shim zone). Contract auto-drafted, flagged for
  operator verification (see the doc's Swarm Preflight Contract).

### Lane 2 — GH-248 · turn shims root at `$HERE/..`, not the target, on non-vendored runs
- [#248](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/248) · **no capture doc / contract yet — author before firing.**
- Verified **bug present 2026-07-19**: `relay-automation/agy-turn.sh:8/78` and `aider-turn.sh:8/86` still
  fall back to `(cd "$HERE/.." && pwd)` for `ROOT` — on a non-vendored run that resolves to the shim's OWN
  repo, not the target. Same regression family as GH-234 (find-harness root) and ddb6c40 (turn-shim root).
- Write-set: the turn shims' root-resolution (`relay-automation/{agy,aider,codex,claude}-turn.sh`). **Shim
  zone — shares `aider-turn.sh` with lane 1 (#251); serialize into a later wave.**

### Lane 3 — GH-170 · validate.sh pre-existing failing tests (gate integrity)
- Doc: [GH-170-VALIDATE-FAILING-TESTS.md](GH-170-VALIDATE-FAILING-TESTS.md) · [#170](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/170) — has a Swarm Preflight Contract.
- Real: the 2026-07-19 marathon confirmed 4 still-red baseline tests (`marathon-drive.sh`, `relay-pkg-freshness.sh`,
  `acorn-extract.sh`, `python:test_python_layer.py`). A gate carrying pre-existing reds erodes trust in every
  future green. **Scope caveat:** reconcile with GH-232 first — some of these are genuinely environmental
  (acorn needs `npm ci`; ubuntu-only) and GH-232 already gates those out on CI; this lane targets the ones
  that are real, fixable local failures, not the environmental set.
- Write-set: the specific failing `test/*.sh` scripts and the code each covers (pin per contract).

### Lane 4 — GH-241 · MARATHON.example.yaml depends_on list-form guard (deferred fix 3)
- Doc: [GH-241-MARATHON-EXAMPLE-SEQUENCING.md](../1-INBOX/GH-241-MARATHON-EXAMPLE-SEQUENCING.md) · [#241](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/241) — **no contract yet; author before firing.**
- The docs fixes (1)(2)(4) shipped 2026-07-18; **fix (3) is explicitly deferred, not done**: `depends_on: [p1]`
  parses as the literal string `[p1]` and fails at `bin/marathon-yaml:102` as an unknown-phase lookup. A
  `^\[.*\]$` guard would catch the author who writes the list form anyway — small, defensive, real footgun.
- Write-set: `bin/marathon-yaml` (the guard) + optionally `relay-automation/MARATHON.example.yaml`. Independent zone.

## How to fire a lane

Per lane, the existing pipeline applies:

```
utils/swarm-preflight.sh --gh-issue <N>          # ready packet (candidate/freshness/fix-still-required)
   → then execute per the marathon execution pattern (worktree-isolated lanes; kernel Claude-direct)
```

---

*Curated follow-up queue. Add survivors from the /10days recon as lanes 2-4, then re-check the collision map before firing.*
