---
title: "GH-1648: docs(merge-cleanup): state that a sweep timeout or launch failure also exits 4"
status: Active
created: 2026-11-27
updated: 2026-11-27
owner: operator (via /express)
gh_issue: 1648
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1648
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): docs(merge-cleanup): state that a sweep timeout or launch failure also exits 4
---

# GH-1648 — docs(merge-cleanup): state that a sweep timeout or launch failure also exits 4

## Status

| What was just completed | What's next |
|---|---|
| Fix qualified for /express; existing suite test/gh436-merge-cleanup.sh covers it (green asserted at landing, Step 7; receipt in TESTS-RESULTS/) | Reconcile promotes this doc when issue #1648 closes |

## Acceptance Criteria

- [x] Existing suite test/gh436-merge-cleanup.sh covers the fix and is its landing gate; no new suite (GH-831). (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
- [x] Bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## PRS proposal

- pri 70: express hotfix critical path priority
- sev 60: express lane bounded fix severity
- appeal 50: express lane neutral appeal default
- effort 85: express lane cheap single-suite effort

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite and this doc moved as
  one motion (plus the CHANGELOG entry when CHANGELOG_WRITES=branch); consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: merge-cleanup SKILL.md: one clause stating that a sweep timeout (900 s) or launch failure also records findings and exits 4; matches run_auto_sweep (TimeoutExpired and OSError return 4); verified by gh436, whose parity guard reads this file
