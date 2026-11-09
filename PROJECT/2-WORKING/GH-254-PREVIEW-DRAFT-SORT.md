---
title: "Show active releases before drafts"
status: In progress
created: 2026-11-09
updated: 2026-11-09
gh_issue: 254
source: https://github.com/HiQS-Labs/XYZ-forge/issues/254
doc_type: bugfix
owner: B trial
goal: Order active release cards before drafts while preserving shipped history.
---

# GH-254 — Show active releases before drafts

## Status

| What was just completed | What's next |
|---|---|
| Implemented the scoped correction; manual negative/positive controls and independent QA retained. | Finish current exact-head qualification and land PR1397; reconcile this document after merge. |

## Scope and acceptance

Rank active before draft regardless of missing/equal/conflicting target dates. Preserve shipped/cut chronology and nullable-version behavior.

Evidence: `TESTS-RESULTS/2026-11-09+GH-254/`. Trial/accounting: #1386. No new suite, runner or configuration. Manual agent-assisted progression; automatic continuation unproven.
