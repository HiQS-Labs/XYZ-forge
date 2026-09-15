---
title: "GH-616: fix(skills): enforce commensurate machinery and review-packet envelope in start-task"
status: Complete
created: 2026-09-13
updated: 2026-09-13
owner: operator (via /express)
gh_issue: 616
source: https://github.com/HiQS-Labs/XYZ-forge/issues/616
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): fix(skills): enforce commensurate machinery and review-packet envelope in start-task
---

# GH-616 — fix(skills): enforce commensurate machinery and review-packet envelope in start-task

## Status

| What was just completed | What's next |
|---|---|
| Fix landed via /express; regression suite test/gh616-start-task-commensurate-envelope.sh registered and green | Reconcile promotes this doc when issue #616 closes |

## Acceptance Criteria

- [x] Regression suite test/gh616-start-task-commensurate-envelope.sh green in the gate.
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: enforce commensurate complexity mantra and review-packet operational envelope in start-task
