---
title: "GH-779: radar: trunk CI health, new-guard re-run on open PRs, regressed-after-declared-fixed table"
status: Active
created: 2026-09-23
updated: 2026-09-23
owner: operator (via /express)
gh_issue: 779
source: https://github.com/HiQS-Labs/XYZ-forge/issues/779
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): radar: trunk CI health, new-guard re-run on open PRs, regressed-after-declared-fixed table
---

# GH-779 — radar: trunk CI health, new-guard re-run on open PRs, regressed-after-declared-fixed table

## Status

| What was just completed | What's next |
|---|---|
| Fix qualified for /express; regression suite test/gh779-radar-ci-health.sh registered (green asserted at landing, Step 7; receipt in TESTS-RESULTS/) | Reconcile promotes this doc when issue #779 closes |

## Acceptance Criteria

- [x] Regression suite test/gh779-radar-ci-health.sh registered as the landing gate (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): fix, suite, this doc and the CHANGELOG entry in one
  motion; the .tick express-fired event carries the run's receipts.
- **Found by comparison, not by radar.** Measuring radar against a hand-written retrospective
  (HiQS-Labs/rebalanceOS#257) exposed three blind spots radar's own runs could never report,
  because each was a signal radar did not read: CI results, guards that predate an open PR, and a
  "came back after fixed" view. When a detector has never been checked against an independently
  produced answer key, its clean runs prove nothing.
- **A red trunk hides new failures behind old ones.** rebalanceOS `development` was red for 9 days;
  every PR in that window reported the same 8 failures, so reviewers learned to ignore red — and a
  genuinely new failure (#231 vs the GH-241 ratchet) landed on top. Consecutive red days is the
  number that makes this visible.
- **Collision is not only file overlap.** #231 and GH-241's #242 shared no files, yet the second to
  land broke trunk. Any new check must be re-run against every open PR head it predates.
- **Rule + mechanical guard is the portable unit.** #257's classes that stayed fixed had a failing
  test or ratchet; the ones that regressed had prose. The report table forces that pairing and
  treats `prose only` as a finding.
- Sections are pinned by `test/gh779-radar-ci-health.sh` (20 assertions, including a negative
  control that deletes signal 9); editing radar's wording means updating the pins in the same PR.
