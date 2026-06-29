---
gh_issue: 41
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/41
title: task.done not terminal against a higher-epoch reclaim (silent token resurrection)
status: Proposed (1-INBOX — not yet active)
created: 2026-06-28
doc_type: bugfix
related:
  - PROJECT/2-WORKING/GH-40-DOUBLE-BLIND-REVIEWER.md
---

# GH-41 · `task.done` not terminal against a higher-epoch reclaim

**Latent kernel gap** found by GH-40 Phase 2 canary #1. In `src/project.js` `foldWithMeta`, a
completed task (`task.done`) is silently resurrected by a later `task.claimed` at a higher epoch on the
same token: status flips `done`→`claimed` with **0 rejections logged** — no fence fires, no audit
trace. The epoch fence stops *lower*-epoch zombie writers but has no guard against a *higher*-epoch
reclaim of a terminal token.

## Repro (deterministic, read-only)

`bash test/fixtures/canary-token-reuse/verify-fixture.sh` — mutated stream folds to `claimed 0`
(silent resurrection), control to `done 0`. The canary stream is a ready-made regression test.

## Proposed fix (from the GH-40 double-blind Reviewer)

Terminality dominates the fence: once a task has an authorized terminal, seal it — later claims/mutations
are rejected into the log (`claim-after-terminal`); a legitimate reopen must be an explicit, audit-logged
`task.reopened` event, never an implicit `task.claimed` after `task.done`.

## Reversibility

Changes projection/fold (event/verb) semantics → **at least Costly** per `AGENTS.md`. Needs a regression
test (canary stream ready) + a `decisions/` record before landing.
