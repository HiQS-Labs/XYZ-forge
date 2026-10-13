---
gh_issue: 1045
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1045
title: "GH-1045: historical phase recovery"
status: In progress — shared plan approved
created: 2026-10-13
updated: 2026-10-13
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
| Shared plan approved via Codex relay. | Implement and verify the canonical shared plan. |

A completed approved phase becomes unsatisfiable after later commits because recovery validates current HEAD as its merge candidate. Repair together with #1042 in the [canonical shared plan](GH-1042-FORCE-GATE-ONLY-REFIRE.md). Keep GH1045 historical-recovery acceptance separate from GH1042 force gate-only acceptance. No duplicate implementation plan.
