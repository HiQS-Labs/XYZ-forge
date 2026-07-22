---
title: Marathon Plan — 2026-07-23 · GH-279/GH-280 aider-qwen follow-up
status: Triaged, NOT fired — GH-280 is being started now per operator direction; GH-279 stays queued
created: 2026-07-23
updated: 2026-07-23
owner: noel
branch: development
doc_type: project
source: PROJECT/1-INBOX/GH-279-AIDER-QWEN-MARATHON-TRIAL-FINDINGS.md + GH-280-AIDER-QWEN-VS-SONNET-INVESTIGATION.md
generated_by: hand-authored (operator-directed follow-up to the GH-268 aider-qwen marathon trial, PR #282)
lanes: [279, 280]
execution: GH-280 fired now on its own branch (operator step 3); GH-279 queued for a later fire
roadmap_exempt: true
goal: >
  Follow-up work from trialing aider-qwen as a marathon builder on GH-268: GH-279 is a punch list of
  harness defects found along the way (independently fixable, no urgency); GH-280 is the focused
  experiment that determines whether Aider+Qwen is a usable builder at all, gated at $5 OpenRouter
  spend. GH-280 is being started immediately; GH-279 is documented and queued, not fired this pass.
---

# Marathon Plan — 2026-07-23 · GH-279/GH-280 aider-qwen follow-up

## Status

| What was just completed | What's next |
|---|---|
| GH-268 Phase 1 installer marathon shipped (PR #282, merged `f38d23a`) via an aider+qwen3.8-max builder trial (2/9 files, partially reliable) then codex+agy (7/9, 0 failures). Two follow-up issues filed and now properly PDDA-captured: GH-279 (consolidated harness findings) and GH-280 (Aider+Qwen vs Aider+Sonnet reliability investigation, $5 OpenRouter budget). | **Fire GH-280 now** on its own branch — start with the cheap `--edit-format` diagnostic before spending any of the $5 matrix budget. **Queue GH-279** — independently actionable punch list, no dependency on GH-280's result, fire whenever convenient. |

## The one safety rule

Two lanes are safe to run concurrently **iff their write-sets are disjoint**. Current caps: kernel≤1/wave.

## Collision map

| Zone | Parallel-safe? | Active items here |
|---|---|---|
| kernel | ❌ serialize — one at a time | #279 (touches `aider-turn.py`/`aider-turn.sh`), #280 Phase 2 fix-if-confirmed (same files) |
| independent | ✅ | #280 Phase 1 (diagnostic script + scratch test repo, no core file edits) |

**Note:** GH-279's timeout-drift fix and GH-280's Phase-2 edit-format fix (if the diagnostic confirms
one) both land in `relay-automation/aider-turn.sh` / `utils/py/aider-turn.py` — do not run both as
simultaneous build lanes. GH-280 Phase 1 (the diagnostic) has no such collision; it's scratch-only.

## Per-item scoring

| Item | cx | risk | eff | zone | deps | score | wave |
|---|---|---|---|---|---|---|---|
| [#280] Aider+Qwen vs Aider+Sonnet reliability investigation ($5 OpenRouter budget) | 3 | 2 | 3 | independent (Phase 1) → kernel (Phase 2 fix) | — | 15 | now |
| [#279] aider-qwen marathon trial — consolidated harness findings | 2 | 1 | 2 | kernel | soft: avoid concurrent edit with #280 Phase 2 | 8 | queued |

## Recommended waves

**Now (operator step 3):** #280 — cut a fresh branch off `development`, start with the
`--edit-format` diagnostic (near-zero cost) before touching the $5 matrix budget.

- #280 → suggested_branch: `marathon/gh-280-aider-qwen-vs-sonnet-2026-07-23`

**Queued (fire later, not this pass):** #279 — independently actionable, no dependency on #280's
outcome. Serialize against #280 Phase 2 if both are ever in flight (see collision map).

## Contract seams — pin a contract before launching both concurrently (GH-5)

`relay-automation/aider-turn.sh` and `utils/py/aider-turn.py` are the shared seam between #279 and
#280 Phase 2. If both are ever fired in the same wave, scope `ALLOW_PATHS`/preflight write-sets so
only one lane edits either file at a time.

## Held / flagged — excluded from this pass

- GH-279 is fully specified and PDDA-captured but deliberately not fired this pass — operator directed
  step 3 (GH-280) as the immediate next action; GH-279 has no urgency and no dependency on GH-280.
