---
title: "GH-645: merge-cleanup: ledger gate and reconcile fail in repos that vendor PRS tools under gitignored .xyz/"
status: Active
created: 2026-09-16
updated: 2026-09-16
owner: operator (via /express)
gh_issue: 645
source: https://github.com/HiQS-Labs/XYZ-forge/issues/645
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): merge-cleanup: ledger gate and reconcile fail in repos that vendor PRS tools under gitignored .xyz/
---

# GH-645 — merge-cleanup: ledger gate and reconcile fail in repos that vendor PRS tools under gitignored .xyz/

## Status

| What was just completed | What's next |
|---|---|
| Fix qualified for /express; regression suite test/gh645-merge-cleanup-xyz-tools.sh registered (green asserted at landing, Step 7; receipt in TESTS-RESULTS/) | Reconcile promotes this doc when issue #645 closes |

## Acceptance Criteria

- [x] Regression suite test/gh645-merge-cleanup-xyz-tools.sh registered as the landing gate (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: merge-cleanup resolves vendored .xyz PRS tools via the primary and passes --force-local-reconcile only when advertised
