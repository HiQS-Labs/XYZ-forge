---
gh_issue: 1332
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1332
title: "jog: promotion repoint lands in the primary's ledger, and retry-gate refuses a relay-receipt-only tail"
status: Proposed (1-INBOX — not yet active)
created: 2026-11-04
owner: unassigned
doc_type: feedback
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - TODO: what this explicitly is NOT (scope boundary).
related:
  - TODO: related files/docs, if any.
goal: >
  TODO: one-paragraph statement of what "done" looks like for this idea.
---

## Key concepts

- TODO: 2-4 bullets on what this idea concretely is and why it matters.

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# jog: promotion repoint lands in the primary's ledger, and retry-gate refuses a relay-receipt-only tail

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

Found while running the #1298 factory batch (agent-assisted, policy #1328) on 2026-11-04. Both cost a hand repair on item #1267 and will recur for every `1-INBOX` item.

## 1. Promotion repoint is written to the primary's ledger, not the branch's
`jog run` promotes a `1-INBOX` contract to `2-WORKING` on the execution branch, but the matching `roadmap repoint` lands in the primary checkout's `releases.db`. The branch then carries a `2-WORKING` doc with no ledger pointer and its pre-push gate fails `pdda-check-roadmap-coverage` (tier2:pdda).
- Observed: PR #1331's first push refused; fixed by `adapt(GH-1267)` (`roadmap repoint` on the branch).
- Expected: the repoint is committed on the execution branch together with the doc move.

## 2. `jog retry-gate` refuses a relay-receipt-only tail
After the relay hit its 5-turn cap (`cap-stalled`) one turn before the reviewer's approval, the review was completed by driving one more codex turn on the same relay. That adds two commits that change only `marathon-system/<lane>/RELAY.md`. `jog retry-gate` then refuses: "head is eb293bc5 but the execution ran on 5507c226 … use jog retry-build". A rebuild throws away an approved build.
- Expected: retry-gate accepts a head whose only commits after the execution head touch the lane's relay file (the same "candidate + receipt-only tail" rule Phase 0 set for landing), and still refuses any other movement.

## Related
- `relay-drive` round cap counts turns, not review rounds; #1267's review was converging (R1 real bug fixed, R3 approved) when the cap fired.
- Jog stops the whole queue on one failed task (see #1328 Updated notes, item 3).

## Why

TODO: why this matters now -- what prompted it, what breaks or slows without it.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
