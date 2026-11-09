---
gh_issue: 1353
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1353
title: "Next-gen flywheel recommendations: instrument the loop and close the no-row discovery seam"
status: proposed
created: 2026-11-07
owner: unassigned
doc_type: feature
complexity: 3
risk: 2
effort: 4
phases: 1
ratings_provisional: true
non_goals:
  - no changes to PR #1351's scope (its findings close in #1345 first)
  - no new test or suite (GH-831)
  - no commitment that every recommendation is adopted; this is a decision-input doc
related:
  - "#1298"
  - "#1340"
  - "#1345"
  - "#1333"
  - "#1200"
  - "#1224"
goal: >
  The flywheel's bottleneck is verification, not build capacity, but the loop is uninstrumented:
  name the next-gen changes (metrics, discovery seam, meta-machinery freshness) with sizes and
  falsifiable success measures, and let the operator decide what enters the roadmap.
updated: 2026-11-07
---

# GH-1353: Next-gen flywheel recommendations

## Status

| What was just completed | What's next |
|---|---|
| Filed by the orchestrator (operator-requested, 2026-11-07) from the PR #1351 review + a design discussion. Issue body carries the observed evidence and acceptance criteria. | Triage: adopt into a lane or defer. If adopted, row and rating are created at pickup per decision 6. |

## Plan

1. Read the findings on #1298 (review verdict) and #1353 (issue body).
2. Decide the P1 discovery seam from PR #1351 first — it is a current-milestone defect, not next-gen.
3. Size each recommendation small/medium/large with blast radius and a falsifiable success measure.
4. Land as a recommendations report; any code instrumentation follows issue-first SOP.

## Context

Filed 2026-11-07 after reviewing PR #1351 (the GH-1345 cutover). The full review — verdict, four findings, receipt discrepancy, and the design discussion that produced these recommendations — is recorded as a comment on the flywheel arc issue #1298. The immediate code findings belong to #1345; this doc tracks what comes after the cutover lands.
