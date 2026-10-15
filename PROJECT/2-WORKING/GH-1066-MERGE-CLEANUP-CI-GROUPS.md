---
gh_issue: 1066
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1066
title: "merge-cleanup: CI-heavy landing groups"
status: In Progress
created: 2026-10-14
updated: 2026-10-14
owner: Codex
goal: "Reduce repeated qualification through coherent group preparation without waiving required checks."
doc_type: feature
---

# GH-1066 — CI-heavy landing groups

## Status

| What was just completed | What's next |
|---|---|
| Added caller-owned group planning and explicit gate boundaries. | Documentation gate and PR publication. |

## Scope and decision

Documentation only: Phase4 gains an ordered group preparation, candidate freeze, full qualification,
supported landing and final verification strategy. No runtime, CI, new test or bypass change.
Easy to reverse by reverting this section. Existing Phase5 per-merge reconciliation remains binding.
The CI churn recovery SOP and #854 demonstrate that staging exceptions need their own authorization;
this general skill update does not renew that historical exception or claim automatic savings.

## Verification

Read the skill's Phase4/5 and batch regression-sweep contracts and the existing churn recovery SOP.
Manual review checks supported-path fallback, exact candidate/landed evidence, independent review,
no policy bypass, invalidation after changes and avoidance of duplicate broad runs. No performance
claim or execution of a merge batch is made. No new test required for this prose change.
