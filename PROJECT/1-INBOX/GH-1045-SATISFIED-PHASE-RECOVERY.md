---
gh_issue: 1045
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1045
title: "GH-1045: historical phase recovery"
status: Proposed — grouped repair plan awaiting QA
created: 2026-10-13
doc_type: bugfix
complexity: 3
risk: 3
effort: 3
phases: 1
---

A completed approved phase becomes unsatisfiable after later commits because recovery validates current HEAD as its merge candidate. Repair together with #1042 in the [canonical shared plan](../2-WORKING/GH-1042-FORCE-GATE-ONLY-REFIRE.md). Keep GH1045 historical-recovery acceptance separate from GH1042 force gate-only acceptance. No duplicate implementation plan.
