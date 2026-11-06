---
gh_issue: 1296
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1296
title: "factory-primitive launch packets: lanes fail preflight on a stale artifact path or missing Preflight Contract"
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
  - no auto-repair of contracts (separate optional track)
  - no new tests (GH-831)
related:
  - #1279
  - #1298
  - #522
  - #1251
goal: >
  Packets are not emitted for lanes the live preflight would reject, or each emitted lane names its preflight result; the frozen #1279 set is re-checked with residuals reported.
---

## Key concepts

- stale paths and missing contracts pass structure checks
- live preflight is the discriminator
- fold into the #522 admission work

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# factory-primitive launch packets: lanes fail preflight on a stale artifact path or missing Preflight Contract

## Status

| What was just completed | What's next |
|---|---|
| `make_packet` flags lanes preflight would refuse (no Preflight Contract, or a contract artifact missing at the frozen ref) and drops their launch commands; checked against live `swarm-preflight --dry-run` on wave 1 (`TESTS-RESULTS/2026-11-03+GH-1296/`). | The contracts for #1204, #216, #446 are not authored (owner decisions on their own issues; #722 is closed). Re-check the frozen set under the #522 admission experiment. |

## Idea

Launch lanes that fail the preflight dry run are still emitted. See the issue for the four observed lanes.

## Why

Found by the #1279 window: #722 (moved artifact path) and #1204, #216, #446 (no Preflight Contract) passed the structure checks but failed preflight. Low severity because preflight catches them before launch; it caps how many lanes a loop can use.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
