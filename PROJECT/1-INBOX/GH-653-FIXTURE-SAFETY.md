---
title: Repair unborn fixture and fail closed on unsafe fixture paths
status: Proposed
created: 2026-09-17
updated: 2026-09-17
gh_issue: 653
source: https://github.com/HiQS-Labs/XYZ-forge/issues/653
doc_type: bugfix
---

# GH-653 — Fixture safety

Seed the existing GH-642 fixture before using HEAD; deliver with GH-665 safety
guards in one task clone and PR. Keep runtime behavior and actual worktree coverage.

## Quad Concepts

- Unborn fixture prevents complete checks → seed only a validated sandbox repository.
