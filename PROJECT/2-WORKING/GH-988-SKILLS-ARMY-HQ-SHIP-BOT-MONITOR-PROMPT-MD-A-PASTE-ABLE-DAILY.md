---
title: "GH-988: skills-army-hq: ship bot-monitor-prompt.md, a paste-able daily QA prompt for always-on agents (foreign skill folders + broken symlinks)"
status: Active
created: 2026-10-07
updated: 2026-10-07
owner: operator (via /express)
gh_issue: 988
source: https://github.com/HiQS-Labs/XYZ-forge/issues/988
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): skills-army-hq: ship bot-monitor-prompt.md, a paste-able daily QA prompt for always-on agents (foreign skill folders + broken symlinks)
---

# GH-988 — skills-army-hq: ship bot-monitor-prompt.md, a paste-able daily QA prompt for always-on agents (foreign skill folders + broken symlinks)

## Status

| What was just completed | What's next |
|---|---|
| Fix qualified for /express; existing suite test/skills-army-hq.sh covers it (green asserted at landing, Step 7; receipt in TESTS-RESULTS/) | Reconcile promotes this doc when issue #988 closes |

## Acceptance Criteria

- [x] Existing suite test/skills-army-hq.sh covers the fix and is its landing gate; no new suite (GH-831). (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: skills-army-hq: ship bot-monitor-prompt.md, a paste-able daily read-only QA prompt for always-on agents (foreign skill folders, shadowing copies, broken symlinks, drift)
