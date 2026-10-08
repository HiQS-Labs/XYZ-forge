---
title: "GH-993: skills-army-hq: intake --apply leaves Git Pulse collection dirty, which stalls the hourly pulse entirely; commit own paths when the root is a git repo"
status: Active
created: 2026-10-07
updated: 2026-10-07
owner: operator (via /express)
gh_issue: 993
source: https://github.com/HiQS-Labs/XYZ-forge/issues/993
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): skills-army-hq: intake --apply leaves Git Pulse collection dirty, which stalls the hourly pulse entirely; commit own paths when the root is a git repo
---

# GH-993 — skills-army-hq: intake --apply leaves Git Pulse collection dirty, which stalls the hourly pulse entirely; commit own paths when the root is a git repo

## Status

| What was just completed | What's next |
|---|---|
| Fix qualified for /express; existing suite test/skills-army-hq.sh covers it (green asserted at landing, Step 7; receipt in TESTS-RESULTS/) | Reconcile promotes this doc when issue #993 closes |

## Acceptance Criteria

- [x] Existing suite test/skills-army-hq.sh covers the fix and is its landing gate; no new suite (GH-831). (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: skills-army-hq: intake --apply commits only its own skill folder when the collection is in a git repo (never pushes; refuses over unrelated changes) and sync --status warns on a dirty, detached or behind collection repo, so Git Pulse no longer stalls
