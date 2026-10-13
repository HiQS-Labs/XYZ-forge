---
title: "GH-989: skills-army-hq: rename bot-monitor-prompt.md to BOT-DAILY-HEALTH-CHECK.md"
status: Complete
created: 2026-10-07
updated: 2026-10-07
owner: operator (via /express)
gh_issue: 989
source: https://github.com/HiQS-Labs/XYZ-forge/issues/989
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): skills-army-hq: rename bot-monitor-prompt.md to BOT-DAILY-HEALTH-CHECK.md
---

# GH-989 — skills-army-hq: rename bot-monitor-prompt.md to BOT-DAILY-HEALTH-CHECK.md

## Status

| What was just completed | What's next |
|---|---|
| Fix qualified for /express; existing suite test/skills-army-hq.sh covers it (green asserted at landing, Step 7; receipt in TESTS-RESULTS/) | Reconcile promotes this doc when issue #989 closes |

## Acceptance Criteria

- [x] Existing suite test/skills-army-hq.sh covers the fix and is its landing gate; no new suite (GH-831). (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: skills-army-hq: rename bot-monitor-prompt.md to BOT-DAILY-HEALTH-CHECK.md (follow-up to GH-988)
