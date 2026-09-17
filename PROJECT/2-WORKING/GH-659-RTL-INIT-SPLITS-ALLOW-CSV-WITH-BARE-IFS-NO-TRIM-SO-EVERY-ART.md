---
title: "GH-659: rtl_init splits allow_csv with bare IFS=',' — no trim, so every artifact AFTER THE FIRST in a "a, b, c" allowlist is invisible to containment (reproduced; root cause #2 of #654)"
status: Active
created: 2026-09-16
updated: 2026-09-16
owner: operator (via /express)
gh_issue: 659
source: https://github.com/HiQS-Labs/XYZ-forge/issues/659
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): rtl_init splits allow_csv with bare IFS=',' — no trim, so every artifact AFTER THE FIRST in a "a, b, c" allowlist is invisible to containment (reproduced; root cause #2 of #654)
---

# GH-659 — rtl_init splits allow_csv with bare IFS=',' — no trim, so every artifact AFTER THE FIRST in a "a, b, c" allowlist is invisible to containment (reproduced; root cause #2 of #654)

## Status

| What was just completed | What's next |
|---|---|
| Fix qualified for /express; regression suite test/gh654-offlane-log.sh registered (green asserted at landing, Step 7; receipt in TESTS-RESULTS/) | Reconcile promotes this doc when issue #659 closes |

## Acceptance Criteria

- [x] Regression suite test/gh654-offlane-log.sh registered as the landing gate (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: rtl.py normalizes the allowlist CSV (trim) before the rtl_init bridge — bare IFS split kept ' b'/' c' leading spaces in RTL_ALLOW, making artifacts after the first invisible to containment (#659, reproduced via RTL_TRACE fixture)
