---
gh_issue: 69
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/69
title: marathon-plan/swarm-preflight — suggest branch name + agent confirmation prompt before execution
status: Proposed (1-INBOX — not yet active)
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
| Issue [#69](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/69) opened, doc captured, parked in ROADMAP. | Confirm scope, promote to `2-WORKING`, implement in three stages (marathon-plan → swarm-preflight → agent prompt). |

## Design

Three-stage addition staying within each tool's existing role:

**Stage 1 — `marathon-plan.sh`:** Add `suggested_branch: marathon/<slug>-<date>` to each active wave lane entry in the generated plan doc. Deterministic from item slug + run date. No git writes — script stays read-only.

**Stage 2 — `swarm-preflight.sh`:** Read `suggested_branch` from the plan, check `git branch -a` for existence, emit `branch_ready: true/false` in the run packet (alongside existing `SP_BRANCH`/`target.ref`).

**Stage 3 — Orchestrating agent prompt:** When agent reads `branch_ready: false` from packet, ask operator before proceeding to `marathon-drive`:
> "This lane will commit to `main`. Suggested branch: `marathon/gh-67-tick-release-2026-07-01`. Cut it now? [yes / no / custom name]"

**Carve-out:** Doc-only/trivial lanes (`risk: 1`, zone `independent`) skip the prompt and proceed on `main` — ratings make this deterministic.

## Checklist

- [ ] `marathon-plan.sh`: generate `suggested_branch: marathon/<slug>-<date>` per active wave lane
- [ ] `swarm-preflight.sh`: check branch existence, emit `branch_ready: true/false` in run packet
- [ ] Orchestrating agent instruction: surface branch prompt when `branch_ready: false`
- [ ] Carve-out: skip prompt when `risk == 1` and zone is `independent`
- [ ] `test/marathon-plan.sh` + `test/swarm-preflight.sh`: regression assertions

## QA gate

- [ ] `marathon-plan.sh` on a kernel-lane queue produces `suggested_branch` in the wave table
- [ ] `swarm-preflight.sh` on a non-existent branch emits `branch_ready: false`
- [ ] `swarm-preflight.sh` on an existing branch emits `branch_ready: true`
- [ ] No branch is auto-created without operator confirmation
