---
title: "GH-1624: Factory architecture field notes: observer and recovery session → Flywheel outer loop → workers and reviewers"
status: Active
created: 2026-11-25
updated: 2026-11-25
owner: operator (via /express)
gh_issue: 1624
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1624
doc_type: documentation
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express documentation update (GH-267 lane): Factory architecture field notes: observer and recovery session → Flywheel outer loop → workers and reviewers
---

# GH-1624 — Factory architecture field notes: observer and recovery session → Flywheel outer loop → workers and reviewers

## Status

| What was just completed | What's next |
|---|---|
| Documentation update qualified for /express; docs gate test/pdda-repo-contract.sh; no runtime coverage claim (green asserted at landing, Step 7; receipt in TESTS-RESULTS/) | Reconcile promotes this doc when issue #1624 closes |

## Operating lessons

Kickstart keeps one observer and recovery parent above a resumable child running Flywheel. The child owns queue decisions and dispatches bounded workers and independent reviewers. The November runs demonstrated assisted recovery, including adoption of a completed landing after interruption.

The field notes are preserved in [#1624](https://github.com/HiQS-Labs/XYZ-forge/issues/1624). Track deliberate fresh-observer recovery in [#1611](https://github.com/HiQS-Labs/XYZ-forge/issues/1611).

## Acceptance Criteria

- [x] Documentation gate test/pdda-repo-contract.sh verifies doc hygiene, not runtime behavior; manual content/link/rendering evidence belongs in the operator summary. (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
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
  run's receipts. Operator-supplied summary: Checked the capture against issue #1624 and verified that the linked fresh-observer qualification is tracked in #1611.
