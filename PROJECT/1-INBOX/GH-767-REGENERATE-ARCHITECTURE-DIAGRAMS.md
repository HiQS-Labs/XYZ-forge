---
title: "GH-767: Regenerate ARCHITECTURE diagrams from the current codebase"
status: Complete
created: 2026-09-23
updated: 2026-09-23
owner: Codex
goal: regenerate every JSON/HTML diagram pair under ARCHITECTURE from current code, refs, and canonical architecture sources
gh_issue: 767
source: https://github.com/HiQS-Labs/XYZ-forge/issues/767
doc_type: documentation
context_tags: [architecture, diagrams, swe-diagram, documentation]
effort: 2
complexity: 3
risk: 1
phases: 1
---

# GH-767 — Regenerate ARCHITECTURE diagrams

## Status

| What was just completed | What's next |
|---|---|
| All seven diagram specs were reconciled to current code, validated with zero warnings, and rebuilt as self-contained HTML | Review and land the generated documentation change; browser visual QA remains unavailable in this session because no browser surface was enabled |

## Scope

- Reconcile the shared multi-agent system graph with current entry points, state, trust boundaries, and governance surfaces.
- Apply that one graph consistently to the layered, top-down, hub-ring, and trust-clustered layouts.
- Regenerate Git history from current local refs rather than hand-editing ancestry.
- Refresh the releases-ledger and Skills Army HQ Git Pulse subsystem diagrams against their current implementations.
- Rebuild all self-contained HTML artifacts from their JSON specifications.

## Acceptance

- Every `ARCHITECTURE/*.json` source names current, auditable inputs and has no dangling or duplicate relationships.
- The four `system-diagram*` specs remain the same graph with layout-only differences.
- Every paired HTML file is regenerated through `utils/swe-diagram/assets/build-diagram.sh`.
- `node utils/swe-diagram/scripts/validate-spec.js ARCHITECTURE/*.json` passes.
- Representative renders are visually inspected, and relevant PDDA checks pass.
