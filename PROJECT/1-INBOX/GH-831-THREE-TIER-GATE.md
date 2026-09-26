---
gh_issue: 831
source: https://github.com/HiQS-Labs/XYZ-forge/issues/831
title: "gate: no new tests, and three tiers (Small/Medium/Large) chosen by ci-route for push, per-merge reconcile and promotion; non-core suites off"
status: Proposed (1-INBOX — not yet active)
created: 2026-09-25
updated: 2026-09-25
owner: operator (via /start-task)
doc_type: feature
non_goals:
  - Deleting test files; "off" keeps them on disk.
  - New gate machinery of any kind (lanes, runners, telemetry, guard suites).
  - Moving tests to another repository (#816).
related:
  - "#802 — CI retrospective; the operator decision is recorded there (comment 5841529958)"
  - "#819, #815, #816, #817 — superseded by this issue"
  - "#830 / #829 — the flaky non-core suite that failed #828's 79-minute reconcile"
goal: >
  The gate runs what a change needs: Small (PDDA + PRS + canaries) for docs and skill files, Medium for
  non-core code, Large for the core harness, chosen by utils/ci-route.sh for the push hook, the hosted
  reconcile after each merge, and promotion. Suites outside those sets are off, and no new tests are added.
---

# GH-831 — no new tests; three gate tiers; non-core suites off

## Status

| What was just completed | What's next |
|---|---|
| Captured from the operator decision on #802 and parked in the roadmap ledger. | Recon: map every registered suite to Small, core or off, and trace the tier mechanics. Then promote to `2-WORKING` with the plan. |

## Idea

The canonical statement is [#831](https://github.com/HiQS-Labs/XYZ-forge/issues/831): its Problem, Decision,
Acceptance and Non-goals sections. This capture points there and does not restate them.
