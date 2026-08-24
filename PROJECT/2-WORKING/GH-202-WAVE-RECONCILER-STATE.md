---
title: "GH-202: wave_reconcile aborts on marathon-plan exit 5 and promotes docs for OPEN issues"
status: active
created: 2026-08-24
updated: 2026-08-24
owner: orchestrator (GLM 5.3)
goal: the post-merge reconciler tolerates normal planning state and only completes work that is actually complete
gh_issue: 202
source: https://github.com/HiQS-Labs/XYZ-forge/issues/202
branch: fix/gh202-wave-reconcile
doc_type: bugfix
effort: 2
complexity: 2
risk: 2
related:
  - "#179 — release 0.7.3 Bulkhead carrier; GH-168 lane family (reconciler scoping)"
  - "Found during PRs #198/#200 reconciliation; evidence on #202"
---

# GH-202 — wave_reconcile state correctness

## Status

| What was just completed | What's next |
|---|---|
| Both fixes implemented + regression suite 7/7 (fixture: open-issue doc stays w/ evidence, closed promotes, exit-5 tolerated, legacy manifests unchanged) | Gates → PR → Agy QA relay → merge |

## Plan

1. `marathon-plan` exit 5 (items held) logged-and-tolerated (exit 4 drift already was).
2. `fetch_issue_state` (gh live or offline manifest `issues[]`; unknown → None → promote, backward-compatible); OPEN + merged → doc stays in 2-WORKING with an idempotent `## Merge evidence` block.

## Acceptance

test/gh202-wave-reconcile-issue-state.sh 7/7; existing test/wave-reconcile.sh unchanged-green; live `--pr 198 --dry-run` no longer aborts.

## Lessons Learned (For Future Agents)
- Exit codes are contracts: marathon-plan's exit 5 means "items held", a normal planning state — treating it as failure made the reconciler unusable whenever any item was held, which is near-always.
- A merged PR completes an issue only when the issue says so: promotion must consult issue state, not PR state (plan-capture PRs and phased umbrellas otherwise get falsified lifecycle state).
