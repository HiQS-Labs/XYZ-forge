---
gh_issue: 605
source: https://github.com/HiQS-Labs/XYZ-forge/issues/605
title: Work-state projection correctness
status: Proposed
created: 2026-09-13
doc_type: bugfix
effort: 3
complexity: 3
risk: 3
phases: 3
---

# Work-state projection correctness

Follow-up to GH-549/GH-564, within GH-402's broader board-signal work. Unify live/backfill lifecycle classification, emit terminal sweep events atomically, and expose read-only work readiness/evidence diagnostics. No automatic board writes, migration, retirement of cards, or prompt-derived starts.

Acceptance: section/marker precedence; no metadata regression from review; receipt-linked batch events and rollback; schema-7 and missing/stale-history diagnostics; Agy then DeepSeek 4.1 Flash plan/final QA; isolated deterministic gates and PR to development.
