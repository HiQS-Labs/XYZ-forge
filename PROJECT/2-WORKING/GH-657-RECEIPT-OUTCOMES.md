---
title: Reject contradictory pre-merge receipts
status: Active
created: 2026-09-16
updated: 2026-09-21
owner: Claude Code (merge-cleanup-deep → fresh-clone re-delivery)
gh_issue: 657
source: https://github.com/HiQS-Labs/XYZ-forge/issues/657
doc_type: bugfix
goal: Reject explicit failed-test outcomes in the existing pre-merge guard.
---

# GH-657 — Pre-merge receipt outcomes

## Status

| What was just completed | What's next |
|---|---|
| Guard repaired (`outcome_ok` predicate in `validate_pre_merge_receipts`); 29 committed outcome cases pass and the unfixed guard is red on the same block — `TESTS-RESULTS/2026-09-21+GH-656/`. Shared delivery with GH-656 (same PR). | Operator review and merge of the shared PR; do not auto-merge. |

## Quad Concepts

- Contradictory test outcomes → fail closed in the existing pre-merge check.

The shared Jog repair plan lives in `GH-656-CLOSEOUT-EVIDENCE.md` beside this capture.
GH-657 owns its outcome-validation acceptance criteria, separate rating and issue closure.
No changes to the attribution-only post-merge guard (GH-425).

## Merge evidence

- (recorded at landing, shared with GH-656)

## Lessons Learned (For Future Agents)

- See `GH-656-CLOSEOUT-EVIDENCE.md`; the two repairs share one evidence seam and one PR.
