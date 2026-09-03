---
title: Local debugging mock harness for GitHub Projects V2 API
status: Proposed (1-INBOX — not yet active)
created: 2026-09-03
owner: noelsaw1
gh_issue: 405
source: https://github.com/HiQS-Labs/XYZ-forge/issues/405
doc_type: feature
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Wiring into automated test suites (validate.sh stays offline, hermetic, and independent).
  - General-purpose GitHub API simulation (scoped strictly to Projects V2 GraphQL queries and mutations).
related:
  - GH-402 (Projects board sync)
goal: >
  Provide developers with an offline, local mock GraphQL server/shim and simulator for GitHub
  Projects V2 boards so board automation (board_sync.py and adapters) can be manually test-driven
  and debugged locally without sending mutation requests or cards to real GitHub boards.
---

# GH-405: Local debugging mock harness for GitHub Projects V2 API

> **1-INBOX capture**, not an active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, create the status table and outline execution phases.

## Context & Problem

With the arrival of GitHub Projects V2 board sync tools (`utils/py/board_sync.py`, GH-402, and subsequent Phase 2/3 adapters), testing board mutations locally requires either:
1. Dry-run mode (`--dry-run`), which skips the mutation execution paths entirely.
2. Real API execution against production GitHub Projects boards (`addProjectV2ItemById`, `updateProjectV2ItemFieldValue`, `deleteProjectV2Item`), which requires valid GitHub credentials, consumes API rate limits, and clutters real user boards with test cards.

## Proposed Solution

A standalone developer mock harness for Projects V2 GraphQL interactions:
1. **GraphQL Interceptor / Shim**: Local runner / CLI adapter intercepting `gh api graphql` calls for Projects V2 queries and mutations.
2. **Stateful In-Memory / File-Backed Board Simulator**: Simulates Project V2 fields, single-select options, item nodes, and multi-repo issue cards with pagination support.
3. **Developer Inspection & Reset Tools**: CLI verbs to seed test boards, dump state, reset state, and simulate failure scenarios (e.g. stale option IDs, network errors).
