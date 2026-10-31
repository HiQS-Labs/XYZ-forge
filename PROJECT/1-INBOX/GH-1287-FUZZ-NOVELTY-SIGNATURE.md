---
gh_issue: 1287
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1287
title: "GH-1280 fuzz supervisor: no-new-signal stop never fires because usage signatures echo mutated tokens"
status: Parked (1-INBOX — prerequisite for a stateful factory-primitive campaign)
created: 2026-10-31
updated: 2026-10-31
owner: unassigned
doc_type: feedback
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Harness or production code changes
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1280
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1248
goal: >
  Make the campaign supervisor's no-new-signal stop able to fire by signing argparse usage
  refusals on the error kind only. Full problem, evidence and acceptance are in the issue.
---

## Key concepts

- GH-1280 disposition D6; 2,302 of 2,313 signatures were usage lines.
- Campaign tooling only (`TESTS-RESULTS/2026-10-30+GH-1280/tools/supervisor.py`).
