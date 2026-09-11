---
title: "GH-565: fix(reconcile): correlate squashed/rebased PR commit lineage in check_provenance_receipts (--gate)"
status: Active
created: 2026-09-10
updated: 2026-09-10
owner: operator (via /express)
gh_issue: 565
source: https://github.com/HiQS-Labs/XYZ-forge/issues/565
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
roadmap_exempt: true
goal: >
  Express hotfix (GH-267 lane): fix(reconcile): correlate squashed/rebased PR commit lineage in check_provenance_receipts (--gate)
---

# GH-565 — fix(reconcile): correlate squashed/rebased PR commit lineage in check_provenance_receipts (--gate)

## Status

| What was just completed | What's next |
|---|---|
| Fix landed via /express; regression suite test/gh425-gate-provenance-pr.sh registered and green | Reconcile promotes this doc when issue #565 closes |

## Acceptance Criteria

- [x] Regression suite test/gh425-gate-provenance-pr.sh green in the gate.
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: correlate squashed PR commit lineage in wave reconcile gate
