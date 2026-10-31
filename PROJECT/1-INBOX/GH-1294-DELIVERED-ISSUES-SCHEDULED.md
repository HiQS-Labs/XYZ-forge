---
gh_issue: 1294
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1294
title: "factory-primitive proposal: delivered issues with a draft brief are scheduled into waves"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-31
owner: noelsaw1
doc_type: feedback
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - no new tests (GH-831)
  - no change to the delivered computation itself
related:
  - #1279
  - #1248
  - #522
goal: >
  Delivered-but-open issues with a draft brief appear under held with the possibly-delivered reason and in no provisional wave; closed-issue controls still hold; no new test file.
---

## Key concepts

- second loop in _build_proposal lacks the delivered hold
- reuse manifest[delivered]
- first observation, trend unknown

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# factory-primitive proposal: delivered issues with a draft brief are scheduled into waves

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

Issues open but already delivered by a merged PR are scheduled into provisional waves by the rules arm (#384 wave 1, #484 wave 15). See the issue for cause, repro and the proposed one-line fix.

## Why

Found by the #1279 window: _build_proposal's second loop skips the delivered check, so #384 and #484 were scheduled. A loop building from the proposal would duplicate delivered work.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
