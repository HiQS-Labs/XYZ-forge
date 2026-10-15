---
gh_issue: 1045
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1045
title: "GH-1045: historical phase recovery"
status: Complete
created: 2026-10-13
updated: 2026-10-15
owner: Codex
goal: Preserve historical phase satisfaction without weakening merge approval.
doc_type: bugfix
complexity: 3
risk: 3
effort: 3
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Combined repair verified; plan/final QA Approved; full gate409/409. | Await shared PR #1054 merge and verified reconciliation. |

A completed approved phase becomes unsatisfiable after later commits because recovery validates current HEAD as its merge candidate. Repair together with #1042 in the [canonical shared plan](GH-1042-FORCE-GATE-ONLY-REFIRE.md). Keep GH1045 historical-recovery acceptance separate from GH1042 force gate-only acceptance. No duplicate implementation plan.

PR: [https://github.com/HiQS-Labs/XYZ-forge/pull/1054](https://github.com/HiQS-Labs/XYZ-forge/pull/1054). Base development; GitHub MERGEABLE; issues remain open pending landing.
