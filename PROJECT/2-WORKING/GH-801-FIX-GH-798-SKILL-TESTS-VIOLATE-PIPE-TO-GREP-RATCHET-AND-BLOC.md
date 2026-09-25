---
title: "GH-801: fix: GH-798 skill tests violate pipe-to-grep ratchet and block full gate"
status: Active
created: 2026-09-24
updated: 2026-09-24
owner: operator (via /express)
gh_issue: 801
source: https://github.com/HiQS-Labs/XYZ-forge/issues/801
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): fix: GH-798 skill tests violate pipe-to-grep ratchet and block full gate
---

# GH-801 — fix: GH-798 skill tests violate pipe-to-grep ratchet and block full gate

## Status

| What was just completed | What's next |
|---|---|
| Fix qualified for /express; regression suite test/gh798-status-skill.sh registered (green asserted at landing, Step 7; receipt in TESTS-RESULTS/) | Reconcile promotes this doc when issue #801 closes |

## Acceptance Criteria

- [x] Regression suite test/gh798-status-skill.sh registered as the landing gate (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: fix(test): convert GH-798 pipe-to-grep sites to capture-then-match
