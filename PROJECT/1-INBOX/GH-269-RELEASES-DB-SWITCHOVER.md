---
title: Full switchover to Releases DB — retire ROADMAP.md
status: Proposed (1-INBOX — not yet active)
created: 2026-08-27
updated: 2026-08-27
owner: noel
gh_issue: 269
source: https://github.com/HiQS-Labs/XYZ-forge/issues/269
doc_type: feature
complexity: 4
risk: 3
effort: 3
phases: 6
ratings_provisional: true
non_goals:
  - Changing the DB schema or writer protocol — this migrates readers/writers/gates off the frozen file, not the ledger itself.
related:
  - GH-243 (items 3-4 — repoint agent docs + dashboard-staleness push, subsumed by this arc)
  - GH-141 (ATE/fuzzing is the verification backbone for the switchover)
---

# GH-269 — Full switchover to Releases DB: retire ROADMAP.md

ROADMAP.md is FROZEN legacy in releases-mode but still physically present, and
agents keep hand-editing it (two incidents this week). This arc retires it:
migrate every reader, writer, gate, and canary off the file so `releases.db`
is the only roadmap truth, with ATE/fuzzing verifying nothing regressed.

Scope: the 6 phases in the issue body — reader inventory, writer refusals,
gate/canary repointing, dashboard/preview coverage (RELEASES-PREVIEW.html is
the one human-readable artifact that must survive), ATE verification pass,
final file retirement. Source of truth for the checklist:
https://github.com/HiQS-Labs/XYZ-forge/issues/269

## Status

| Field | Value |
| --- | --- |
| Stage | 1-INBOX capture; 6 issue checkboxes open, none started |
