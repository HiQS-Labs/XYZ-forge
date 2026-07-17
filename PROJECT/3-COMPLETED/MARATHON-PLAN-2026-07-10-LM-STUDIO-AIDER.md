---
title: Marathon Plan (2026-07-10) — LM Studio × Aider integration (ATE fuzzer + production relay lane)
status: Both scoped lanes now shipped — Lane 1 (#195 ATE LM Studio driver) merged to `main` via
  PR #195 (2026-07-10); Lane 2 (GH-147 Phase 2, production Aider relay shim) shipped 2026-07-17 via
  the `/10days` sweep (commit `8af755c`, `test/aider-turn.sh` 55/55). Issue #147 stays OPEN — Phases
  3-5 remain, tracked in GH-147-LM-STUDIO.md, not this doc. Retired to 3-COMPLETED 2026-07-17 as
  part of a 2-WORKING marathon-file consolidation.
created: 2026-07-10
updated: 2026-07-17
owner: noel
branch: main
doc_type: project
gh_issue: 147
complexity: 3
risk: 3
effort: 3
phases: 2
ratings_provisional: true
roadmap_exempt: true
lanes: [195, 147]
execution: hand-authored dispatch surface; Lane 2 recommended to run as a dogfood relay (Aider/LM Studio builder + independent reviewer) per this repo's dogfood-relay protocol
related:
  - PROJECT/2-WORKING/GH-147-LM-STUDIO.md
  - utils/ate/scripts/run_variations.py
  - relay-automation/aider-turn.sh
  - utils/py/aider-turn.py
  - relay-automation/consult.sh
non_goals:
  - Not re-specifying GH-147's phase checklist — GH-147-LM-STUDIO.md stays the canonical detail for the Phase 2 work; this file is the execution/dispatch surface that groups the two related lanes.
  - Not making LM Studio the default for any existing lane — every change stays opt-in, byte-identical for the OpenRouter/Codex/agy/Claude defaults unless LM Studio is explicitly selected.
  - Not doing GH-147 Phases 3-4 (swarm-preflight routing, live operator proof) here — those stay in GH-147.
goal: >
  Group the two related "LM Studio × Aider" efforts under one execution surface. Lane 1 (#195) taught
  the ATE variation-fuzzer to drive Aider against an OpenAI-compatible endpoint (LM Studio) and is
  already shipped. Lane 2 threads the SAME LM Studio base-URL/model/dummy-key contract through the
  production Aider relay turn shim (relay-automation/aider-turn.sh + utils/py/aider-turn.py) so a real
  relay/marathon turn can be built by a local LM Studio model under containment — GH-147 Phase 2.
---

# Marathon Plan — 2026-07-10 · LM Studio × Aider integration

Two lanes, same theme, different surface. Lane 1 proved the Aider↔LM Studio seam in a **throwaway
fuzzer** (`utils/ate/`); Lane 2 wires the identical env-var contract into the **production relay turn
shim** so a driven relay/marathon lane can use a local model. Lane 1 de-risks Lane 2: the base-URL /
model / dummy-key contract, the empty-`content`/reasoning-token failure mode, and the flag surface are
all already characterised in `relay-system/2026-07-10/` and GH-147's spike.

## Status

| What was just completed | What's next |
|---|---|
| **Lane 1 (#195) shipped — merged to `main` via PR #195, 2026-07-10.** The ATE variation fuzzer (`utils/ate/scripts/run_variations.py`) now drives Aider against LM Studio via `AIDER_OPENAI_API_BASE`/`AIDER_OPENAI_API_KEY` (the GH-147 contract), with a per-variation disposable-repo reset (guarded against a mis-pointed `--repo`), a 0-commit-repo fix, deterministic `edited` detection, and an 18-check regression test (`test/ate-run-variations.sh`, in `validate.sh`). Independently reviewed pre-merge via an agy+codex consult (transcripts in `relay-system/2026-07-10/pr195-review-093811/`); two `[Blocker]`s fixed before merge. Proven live: 361/361 clean on the full flag grid, then a re-run confirming the fixes. | **Fire Lane 2 — GH-147 Phase 2.** Thread the LM Studio base-URL/model/dummy-key contract through `relay-automation/aider-turn.sh` (+ its Python port `utils/py/aider-turn.py`) so a review-only and a single-file build turn complete under containment against LM Studio, failing closed on bad config. **Execution detail is canonical in [GH-147-LM-STUDIO.md → Phase 2](GH-147-LM-STUDIO.md#phase-2--reuse-the-aider-relay-seam-for-lm-studio-turns) — do not duplicate its checklist here.** Recommended: run it as a dogfood relay (LM Studio/Aider builder + independent reviewer). |

## Table of contents

- [Lane 1 — ATE LM Studio driver (#195)](#lane-1--ate-lm-studio-driver-195--shipped-2026-07-10)
- [Lane 2 — Production Aider relay shim LM Studio threading (GH-147 Phase 2)](#lane-2--production-aider-relay-shim-lm-studio-threading-gh-147-phase-2--open)

## The one safety rule

Two lanes are safe to run concurrently **iff their write-sets are disjoint**. Here they are also
**sequential in time** (Lane 1 already merged), so there is no concurrency question — but note the
collision surface below in case future LM-Studio lanes are added.

## Collision map

| Zone (shared file) | Lane 1 (#195) | Lane 2 (GH-147 P2) | Overlap? |
|---|---|---|---|
| `utils/ate/scripts/run_variations.py` (+ its test) | ✅ owns it | — | none |
| `relay-automation/aider-turn.sh` | — | ✅ owns it | none |
| `utils/py/aider-turn.py` | — | ✅ owns it | none |
| the shared **contract** (`AIDER_OPENAI_API_BASE`/`AIDER_OPENAI_API_KEY`/`AIDER_MODEL`) | consumes it | consumes it | contract only — no code overlap; both reuse GH-147's env names |

Disjoint write-sets. The only shared thing is the *env-var contract name*, which both reuse verbatim
from `relay-automation/consult.sh` — reused, not redefined.

## Lane 1 — ATE LM Studio driver (#195) ✅ SHIPPED 2026-07-10

The ATE variation fuzzer can now point Aider at any OpenAI-compatible endpoint (proven against LM
Studio's `deepseek-coder-v2-lite-instruct-mlx`). Shipped via PR #195, reviewed pre-merge by an
independent agy+codex consult.

### What landed

- `run_aider()` takes `--openai-api-base`/`--openai-api-key` from `AIDER_OPENAI_API_BASE`/
  `AIDER_OPENAI_API_KEY`; OpenRouter stays the default when the base URL is unset.
- `CLASSIFY_PROMPT` pipeline name is a `--pipeline-name` argument, not a hardcoded string.
- Per-variation disposable reset (`git reset --hard` + `git clean -fdx`, keep-file-aware), gated by
  `assert_disposable_repo()` (refuses the harness repo unconditionally; refuses a remote-having repo
  unless `--allow-destructive-reset`).
- 0-commit scratch repo no longer crashes (`ensure_base_commit()` auto-creates a base commit).
- Deterministic `edited` signal recorded per variation + fed to the classifier as `EDIT_APPLIED`, so an
  exit-0/no-edit run is a `fail`, not a false pass.
- New `test/ate-run-variations.sh` (18 checks) in `validate.sh`.

### Acceptance criteria — Lane 1 (all met)

- [x] Aider drives LM Studio via the GH-147 env contract without changing the OpenRouter default path.
- [x] Destructive reset cannot silently wipe a mis-pointed `--repo` (guard + explicit opt-in).
- [x] Deterministic tests cover the new git helpers; `validate.sh` green except the 2 pre-existing env failures.
- [x] Independently reviewed before merge (agy+codex consult) — not self-graded.
- [x] Merged to `main` (PR #195).

## Lane 2 — Production Aider relay shim LM Studio threading (GH-147 Phase 2) ⏳ OPEN

Thread the same LM Studio contract through the **production** Aider relay turn shim so a real driven
relay/marathon turn can be built by a local model under containment. Today `relay-automation/aider-turn.sh`
and `utils/py/aider-turn.py` have **zero** `openai-api-base` support (confirmed 2026-07-10): they only
route `--model openrouter/…` + `OPENROUTER_API_KEY`.

**Canonical execution detail lives in [GH-147-LM-STUDIO.md → Phase 2](GH-147-LM-STUDIO.md#phase-2--reuse-the-aider-relay-seam-for-lm-studio-turns).** This section is the dispatch pointer, not a
second checklist — update GH-147's doc as the work progresses, and reflect the lane's completion back
into the Status table above.

### Acceptance criteria — Lane 2 (defers to GH-147 Phase 2 QA gates)

- [ ] One LM Studio-backed **review-only** turn completes under containment with no off-lane edits.
- [ ] One narrow LM Studio-backed **build/edit** turn completes under containment and commits only the allowlisted artifact.
- [ ] Bad LM Studio config **fails closed** before the harness reports a successful turn.
- [ ] Existing Aider/OpenRouter turns stay byte-identical when LM Studio is not selected.
- [ ] `test/aider-turn.sh` covers config pass-through + failure at the shim boundary; `bash validate.sh` green.
- [ ] Lane run as a dogfood relay (independent reviewer), per this repo's dogfood-relay protocol.

## Provenance

Lane 1 surfaced 2026-07-10 while wiring ATE to a local LM Studio model on operator request, then
hardened via the ATE consult review (`relay-system/2026-07-10/pr195-review-093811/`). Lane 2 is the
long-standing GH-147 Phase 2, unblocked now that the Aider↔LM Studio seam is proven end-to-end in the
fuzzer. Grouped into one marathon file on operator request to keep the two related LM-Studio efforts
under a single execution surface.
