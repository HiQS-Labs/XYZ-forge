---
title: "GH-778: feat: review-code and review-PR ground-truth code review skill"
status: Active
created: 2026-09-23
updated: 2026-09-23
owner: operator (via /express)
gh_issue: 778
source: https://github.com/HiQS-Labs/XYZ-forge/issues/778
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): feat: review-code and review-PR ground-truth code review skill
---

# GH-778 — feat: review-code and review-PR ground-truth code review skill

## Status

| What was just completed | What's next |
|---|---|
| Fix qualified for /express; regression suite test/gh778-review-code-skill.sh registered (green asserted at landing, Step 7; receipt in TESTS-RESULTS/) | Reconcile promotes this doc when issue #778 closes |

## Acceptance Criteria

- [x] Regression suite test/gh778-review-code-skill.sh registered as the landing gate (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: feat: add review-code and review-PR ground-truth code review skill
