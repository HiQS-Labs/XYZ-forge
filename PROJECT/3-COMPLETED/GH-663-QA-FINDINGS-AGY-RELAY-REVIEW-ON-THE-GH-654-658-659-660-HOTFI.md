---
title: "GH-663: QA findings (agy relay review) on the GH-654/658/659/660 hotfix chain: turn_prompt csv leak, drift-check CLI ambiguity + CRLF false positives, offlane rename-source omission"
status: Complete
created: 2026-09-16
updated: 2026-09-22
owner: operator (via /express)
gh_issue: 663
source: https://github.com/HiQS-Labs/XYZ-forge/issues/663
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): QA findings (agy relay review) on the GH-654/658/659/660 hotfix chain: turn_prompt csv leak, drift-check CLI ambiguity + CRLF false positives, offlane rename-source omission
---

# GH-663 — QA findings (agy relay review) on the GH-654/658/659/660 hotfix chain: turn_prompt csv leak, drift-check CLI ambiguity + CRLF false positives, offlane rename-source omission

## Status

| What was just completed | What's next |
|---|---|
| Fix qualified for /express; regression suite test/gh654-offlane-log.sh registered (green asserted at landing, Step 7; receipt in TESTS-RESULTS/) | Reconcile promotes this doc when issue #663 closes |

## Acceptance Criteria

- [x] Regression suite test/gh654-offlane-log.sh registered as the landing gate (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- Express commit `4481ab488ba88f98a2e582046808fa72fa7fc6a2` landed 2026-09-17 — agy relay review findings on containment hotfix chain; issue #663 closed 2026-09-17.


## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: QA fixes from the agy relay review (#663): trim the csv at the rtl_turn_prompt bridge, check the rename SOURCE path in the offlane mirror, normalize CRLF before drift hashing, and make --canonical accept repo root or skills dir directly
