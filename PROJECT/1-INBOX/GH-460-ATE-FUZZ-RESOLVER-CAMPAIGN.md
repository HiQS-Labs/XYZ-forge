---
title: "GH-460 — ATE/Fuzz campaign vs the model-alias resolver: counterexamples must land as fixes"
status: active
created: 2026-09-06
owner: orchestrator (Claude Code)
goal: run the Gen4 fuzz engine against resolve-model-alias.sh as a standing loop; every counterexample becomes a resolver fix + regression test or a documented non-defect
doc_type: plan
gh_issue: 460
source: https://github.com/HiQS-Labs/XYZ-forge/issues/460
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/457
  - https://github.com/HiQS-Labs/XYZ-forge/issues/141
  - https://github.com/HiQS-Labs/XYZ-forge/issues/299
---

# GH-460 — ATE/Fuzz campaign vs the model-alias resolver

Captured from the 2026-09-05/06 model-aliasing session: the Gen4 fuzz engine
(`utils/py/fuzz_engine.py`, GH-299 Phase 3) was wired against `resolve-model-alias.sh` and
demonstrated (seed 7, 30 iterations, structural-contract oracle, 30/30 clean). Issue #460 owns
turning that wiring into a standing loop with a hard contract: **every counterexample becomes a
resolver fix + regression test (corpus entry pinned, replayable), or a documented non-defect with
the oracle narrowed.** Accept requires zero untriaged counterexamples.

Full spec, work items, and non-goals live in the issue:
<https://github.com/HiQS-Labs/XYZ-forge/issues/460>

## Rating

`rated 60/40/50/70` — pri 60 (operator-directed; hardens model selection that silently
misrouted turns this week, feeds #457/#141); sev 40 (test-infra + campaign — no direct data
loss, but guards the defect class that produced wrong-model turns on 2026-09-05); appeal 50
(neutral default, no operator score); effort 70 (small diff: one test case + campaign runs +
triage; the engine already exists). Recurrence: one distinct incident (2026-09-05, r4/r5 404s),
no prior same-class reports found in a 14-day lookback — one-off, but consequence-bearing.

## Loop contract (not academic)

Every counterexample has exactly two exits, both tracked on #460: (1) defect → fix PR with a
regression test derived from the corpus entry, landing together; (2) not-a-defect → rationale
posted + oracle narrowed. Null campaigns are valid and reported as nulls; the committed smoke
test remains as permanent coverage either way.
