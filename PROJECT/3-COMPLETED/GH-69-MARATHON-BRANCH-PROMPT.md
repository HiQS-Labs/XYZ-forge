---
gh_issue: 69
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/69
title: marathon-plan/swarm-preflight — suggest branch name + agent confirmation prompt before execution
status: Shipped
created: 2026-07-01
updated: 2026-07-01
owner: noel
doc_type: feature
complexity: 2
risk: 1
effort: 2
roadmap_exempt: false
non_goals:
  - Not auto-cutting the branch without asking (violates GUIDING-PRINCIPLES §8)
  - Not changing relay-turn-lib.sh commit semantics (containment is separate)
  - Not handling cross-repo branch cutting in --target-root foreign repos (follow-on)
related:
  - utils/marathon-plan.sh
  - utils/swarm-preflight.sh
  - relay-automation/marathon-drive.sh
---

# GH-69 · Marathon branch suggestion + agent confirmation prompt

## Status

| What was just completed | What's next |
|---|---|
| **SHIPPED 2026-07-01.** All three stages implemented and tested. `marathon-plan.sh` emits a deterministic `suggested_branch: marathon/<slug>-<date>` per active wave lane. `swarm-preflight.sh` checks real branch existence (`git show-ref`) and emits `branch_ready`/`skip_branch_prompt` in the packet (JSON + packet.md + text report). The orchestrating-agent contract is documented inline in `swarm-preflight.sh`'s header and self-stated in every packet's "Suggested branch" line, so a driving agent doesn't need to recompute it. `test/marathon-plan.sh` 34/34, `test/swarm-preflight.sh` 44/44, `validate.sh` 77/77. | Nothing — fully shipped, no deferred remainder. |

## Design

Three-stage addition staying within each tool's existing role:

**Stage 1 — `marathon-plan.sh`:** Add `suggested_branch: marathon/<slug>-<date>` to each active wave lane entry in the generated plan doc. Deterministic from item slug + run date. No git writes — script stays read-only.

**Stage 2 — `swarm-preflight.sh`:** Read `suggested_branch` from the plan, check `git branch -a` for existence, emit `branch_ready: true/false` in the run packet (alongside existing `SP_BRANCH`/`target.ref`).

**Stage 3 — Orchestrating agent prompt:** When agent reads `branch_ready: false` from packet, ask operator before proceeding to `marathon-drive`:
> "This lane will commit to `main`. Suggested branch: `marathon/gh-67-tick-release-2026-07-01`. Cut it now? [yes / no / custom name]"

**Carve-out:** Doc-only/trivial lanes (`risk: 1`, zone `independent`) skip the prompt and proceed on `main` — ratings make this deterministic.

## Checklist

- [x] `marathon-plan.sh`: generate `suggested_branch: marathon/<slug>-<date>` per active wave lane
- [x] `swarm-preflight.sh`: check branch existence, emit `branch_ready: true/false` in run packet
- [x] Orchestrating agent instruction: surface branch prompt when `branch_ready: false`
- [x] Carve-out: skip prompt when `risk == 1` and zone is `independent`
- [x] `test/marathon-plan.sh` + `test/swarm-preflight.sh`: regression assertions

## QA gate

- [x] `marathon-plan.sh` on a kernel-lane queue produces `suggested_branch` in the wave table
- [x] `swarm-preflight.sh` on a non-existent branch emits `branch_ready: false`
- [x] `swarm-preflight.sh` on an existing branch emits `branch_ready: true`
- [x] No branch is auto-created without operator confirmation
