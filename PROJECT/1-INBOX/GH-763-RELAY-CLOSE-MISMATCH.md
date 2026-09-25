---
gh_issue: 763
source: https://github.com/HiQS-Labs/XYZ-forge/issues/763
title: "Relay approved reviewer turn leaves token open with close-mismatch"
status: Proposed (1-INBOX — not yet active)
created: 2026-09-23
owner: unassigned
doc_type: bugfix
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

# Relay approved reviewer turn leaves token open with close-mismatch

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ Forge** → repo `HiQS-Labs/XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Observed

An Agy `relay-drive.sh --review-once` review wrote and committed a relay file with `STATUS: Approved` and `NEXT: done`, but `agy-turn.sh` warned that `tick done` failed because Agy was not the current owner. `tick info` then showed the task still `open` with `handoff-to: done`; `relay-drive` exited 4 (`close-mismatch`). The content review was complete, but the coordination token remained open.

## Reproduction context

- Reviewer: Agy; read-only `ALLOW_PATHS=""`; `RELAY_WORKTREE_ISOLATION=1`.
- Relay thread: `relay-system/2026-09-23/gh762-start-marathon-final.md` on the GH-762 branch.
- No artifact-file seeding in this attempt; the review packet was embedded in the committed relay file.

## Expected

An approved reviewer turn should close the token and return success, or retain an actionable ownership state that allows a bounded retry. Inspect release-to-`done` versus `tick done` ordering and add a negative control for the observed state transition.

This is parked follow-up; it does not change the GH-762 skill routing scope.

## Why

TODO: why this matters now -- what prompted it, what breaks or slows without it.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.

## Merge evidence

- PR #765 merged 2026-09-25 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
