---
title: "GH-781: whack-a-mole: seed candidate clusters from recent radar reports (re-verified, freshness-gated)"
status: Active
created: 2026-09-23
updated: 2026-09-23
owner: operator (via /express)
gh_issue: 781
source: https://github.com/HiQS-Labs/XYZ-forge/issues/781
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): whack-a-mole: seed candidate clusters from recent radar reports (re-verified, freshness-gated)
---

# GH-781 — whack-a-mole: seed candidate clusters from recent radar reports (re-verified, freshness-gated)

## Status

| What was just completed | What's next |
|---|---|
| Fix qualified for /express; regression suite test/gh781-wam-radar-seed.sh registered (green asserted at landing, Step 7; receipt in TESTS-RESULTS/) | Reconcile promotes this doc when issue #781 closes |

## Acceptance Criteria

- [x] Regression suite test/gh781-wam-radar-seed.sh registered as the landing gate (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): fix, suite, this doc and the CHANGELOG entry in one
  motion; the .tick express-fired event carries the run's receipts.
- **The ledger link only ran one way.** Radar already re-scored whack-a-mole's umbrellas (signal 8),
  but whack-a-mole never read radar's clusters, so each run rediscovered what radar's latest report
  already listed with IDs, members and day spans (e.g. the 2026-09-21 report's three ranked
  `RADAR-class-…` targets). When two tools share a contract, check that both sides read it.
- **A seed must not become evidence.** The danger in reusing another tool's clusters is inheriting
  its mistakes and its window. The step keeps whack-a-mole's own two-signal rule and window as the
  only scoring authority, lists out-of-window members as `prior only`, and reports seeds that do not
  reproduce instead of dropping them, so a stale or wrong radar target is visible, not laundered.
- **Silence is a result.** "No radar report found" and "report too old — not seeded" are stated
  outputs, the same yield discipline radar uses, so a reader can tell "no seed" from "seed ignored".
- Pinned by `test/gh781-wam-radar-seed.sh` (17 assertions, including placement inside §2 before
  clustering and a negative control that removes the re-verification rule).
