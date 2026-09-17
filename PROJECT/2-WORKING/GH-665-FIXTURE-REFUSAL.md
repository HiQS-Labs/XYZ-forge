---
title: Refuse unsafe GH-642 fixture construction before writes
status: Active
created: 2026-09-17
updated: 2026-09-17
gh_issue: 665
source: https://github.com/HiQS-Labs/XYZ-forge/issues/665
doc_type: bugfix
owner: noel
goal: Prevent failed GH-642 fixture construction from committing into caller checkouts.
---

# GH-665 — Fixture refusal

## Status

| What was just completed | What's next |
|---|---|
| Combined delivery with GH-653 registered and rated 95/95/50/85 | Execute shared reviewed plan; caller-preserving fault checks and normal gated PR |

Canonical execution, recon, rating rationale and acceptance:
[GH-653-FIXTURE-SAFETY.md](GH-653-FIXTURE-SAFETY.md). One test file/clone/branch/PR
for both issues. This issue adapter preserves a distinct ledger and issue identity.
No caller damage is claimed outside prior controlled reproductions.

## Quad Concepts

- Failed setup can retarget a seed commit → validate at write boundaries and refuse.
