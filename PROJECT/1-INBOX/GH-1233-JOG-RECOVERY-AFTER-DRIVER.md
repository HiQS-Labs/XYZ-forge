---
gh_issue: 1233
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1233
title: "jog recovery after a driver crash: retry-build has no guidance for leftovers (isolation worktree, claimed tick token, clone driver lock, local branch)"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-27
owner: unassigned
doc_type: bugfix
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - TODO: what this explicitly is NOT (scope boundary).
related:
  - TODO: related files/docs, if any.
goal: >
  TODO: one-paragraph statement of what "done" looks like for this idea.
---

## Key concepts

- TODO: 2-4 bullets on what this idea concretely is and why it matters.

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# jog recovery after a driver crash: retry-build has no guidance for leftovers (isolation worktree, claimed tick token, clone driver lock, local branch)

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `HiQS-Labs/XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Observed (GH-1175 Phase 0, 2026-10-26)
After SIGKILL of the jog/marathon tree and a correct cold-start park, the target clone still held: a local `marathon/gh-416-…` branch with a render commit, the `rtl-wt.*` isolation worktree, tick token `MARATHON-…-TURN` `claimed` by agy, and `.git/relay-driver.lock` with the dead pid. `jog resume` says "use jog retry-gate / retry-build / land" but neither it nor jog/SKILL.md says whether retry-build may reuse that clone or how to clear the leftovers. Recovery was done by hand: `git worktree remove --force`, then a fresh clone for retry-build.

## Proposed remedy (for review)
Document in jog/SKILL.md "Recovery Verbs": after a cold-start park, retry-build into a fresh disposable clone (and retire the old one via /merge-cleanup), or have `_execution_root` refuse a target with a non-trunk branch / live tick claim / leftover worktree, naming them. Doc-first; code only if the doc proves insufficient.

---
Found in the GH-1175 Phase 0 spike (#1175). Evidence: [`TESTS-RESULTS/2026-10-25+GH-1175-phase0/`](https://github.com/HiQS-Labs/XYZ-forge/tree/development/TESTS-RESULTS/2026-10-25+GH-1175-phase0) · draft `D3-crash-leftovers-recovery.md`.

## Why

TODO: why this matters now -- what prompted it, what breaks or slows without it.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
