---
title: "GH-608: fix(relay): honor Qwen/DeepSeek reasoning effort and correct false idle timeout attribution"
status: Active
created: 2026-09-13
updated: 2026-09-13
owner: operator (via /express)
gh_issue: 608
source: https://github.com/HiQS-Labs/XYZ-forge/issues/608
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): fix(relay): honor Qwen/DeepSeek reasoning effort and correct false idle timeout attribution
---

# GH-608 — fix(relay): honor Qwen/DeepSeek reasoning effort and correct false idle timeout attribution

## Status

| What was just completed | What's next |
|---|---|
| Fix landed via /express; regression suite test/gh608-deepseek-effort.sh registered and green | Reconcile promotes this doc when issue #608 closes |

## Acceptance Criteria

- [x] Regression suite test/gh608-deepseek-effort.sh green in the gate.
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: wire DEEPSEEK_REASONING_EFFORT and normalize logger vocabulary
