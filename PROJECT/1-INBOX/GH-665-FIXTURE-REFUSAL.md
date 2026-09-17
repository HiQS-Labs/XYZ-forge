---
title: Refuse unsafe GH-642 fixture construction before writes
status: Proposed
created: 2026-09-17
updated: 2026-09-17
gh_issue: 665
source: https://github.com/HiQS-Labs/XYZ-forge/issues/665
doc_type: bugfix
---

# GH-665 — Fixture refusal

Shared delivery with GH-653: reuse fixture-guard.sh, stop failed construction and
empty substitutions, and prove controlled caller preservation under injected faults.

## Quad Concepts

- Failed setup can retarget a seed commit → validate at write boundaries and refuse.
