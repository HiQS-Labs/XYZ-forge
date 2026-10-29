---
gh_issue: 1235
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1235
title: "merge-cleanup: a `jog land` refusal in the Jog hook leaves the post-merge reconcile writes uncommitted in the primary"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-27
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

# merge-cleanup: a `jog land` refusal in the Jog hook leaves the post-merge reconcile writes uncommitted in the primary

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `HiQS-Labs/XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Observed (GH-1175 Phase 0, PR #1225, 2026-10-27)
After merge + local `wave_reconcile --pr 1225` passed, the Jog hook's `jog land` refused (GH-1208) and merge-cleanup stopped (exit 2) **before** its post-merge commit/push. The primary was left with modified `releases.db/.sql`, `LEADERBOARD.md`, the doc move to 3-COMPLETED, and an untracked generated MARATHON-PLAN file. A concurrent session (#1217) could not land until these were committed by hand (`5265cfad`).

## Proposed remedy (for review)
Treat a Jog-hook refusal as "row stays parked" rather than a landing failure: commit/push the reconcile writes, report the refusal, exit non-zero after the durable step. Or document the manual commit as the recovery. GH-1208 removes the common trigger but not the class.

---
Found in the GH-1175 Phase 0 spike (#1175). Evidence: [`TESTS-RESULTS/2026-10-25+GH-1175-phase0/`](https://github.com/HiQS-Labs/XYZ-forge/tree/development/TESTS-RESULTS/2026-10-25+GH-1175-phase0) · draft `D7-mc-jog-hook-dirty-primary.md`.

## Why

TODO: why this matters now -- what prompted it, what breaks or slows without it.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
