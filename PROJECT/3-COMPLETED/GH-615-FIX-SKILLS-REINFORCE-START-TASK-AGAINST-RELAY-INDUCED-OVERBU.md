---
title: "GH-615: fix(skills): reinforce start-task against relay-induced overbuilding and gate thrashing"
status: Complete
created: 2026-09-13
updated: 2026-09-13
owner: operator (via /express)
gh_issue: 615
source: https://github.com/HiQS-Labs/XYZ-forge/issues/615
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): fix(skills): reinforce start-task against relay-induced overbuilding and gate thrashing
---

# GH-615 — fix(skills): reinforce start-task against relay-induced overbuilding and gate thrashing

## Status

| What was just completed | What's next |
|---|---|
| Fix landed via /express; regression suite test/gh615-start-task-reinforce.sh registered and green | Reconcile promotes this doc when issue #615 closes |

## Acceptance Criteria

- [x] Regression suite test/gh615-start-task-reinforce.sh green in the gate.
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: reinforce start-task against relay-induced overbuilding, missing test boundaries, and gate thrashing
