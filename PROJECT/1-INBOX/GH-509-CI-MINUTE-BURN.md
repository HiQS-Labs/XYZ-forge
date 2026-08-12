---
gh_issue: 509
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/509
title: "GH-509 — tier CI to stop per-push Actions minute burn"
status: parked
created: 2026-08-11
updated: 2026-08-11
owner: noel
doc_type: infrastructure
effort: 3
complexity: 3
risk: 3
phases: 3
ratings_provisional: true
roadmap_exempt: false
goal: >
  Keep the complete regression inventory while routing fast, documentation, and full integration
  gates so private-repository Actions minutes are spent once at the appropriate boundary.
---

# GH-509 — tier CI to stop per-push Actions minute burn

## Status

| What was just completed | What's next |
|---|---|
| Captured the 2026-08-11 read-only audit: 100 runs in roughly 66 hours consumed an estimated 976 rounded runner minutes; the full 181-test manifest dominates successful runs. | Measure per-test cost and design a branch-protection-safe fast/docs/full routing proposal before editing the workflow. |

**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/509

## Scope

The suite is valuable; its trigger topology is not. Preserve full coverage for Tick event shape,
relay containment, frozen twins, and worktree safety while adding stale-run cancellation,
docs-only routing, exact duplicate removal, and a single deliberate full-regression boundary.
