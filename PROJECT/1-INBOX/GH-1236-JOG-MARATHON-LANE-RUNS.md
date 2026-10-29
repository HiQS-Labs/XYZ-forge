---
gh_issue: 1236
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1236
title: "Jog/Marathon lane runs the full gate twice on the identical tree (pre-advance + lane pre-push)"
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

# Jog/Marathon lane runs the full gate twice on the identical tree (pre-advance + lane pre-push)

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `HiQS-Labs/XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Observed (GH-1175 Phase 0, gh416-exec2, 2026-10-26)
Pre-advance `validate.sh --auto development` (tier 3, 409/409, 787 s) on `80a11644`, then the lane PR push's pre-push hook ran the full gate again (634 s) on the same tree. 23m41s of a 28m07s run were gates; agent turns were 2m54s.

## Proposed remedy (for review)
Let the lane push reuse the pre-advance gate receipt for the identical tree/SHA (the receipt already exists at `.xyz/receipts/<sha>.json`), the same way merge-cleanup reuses qualifying runs whose SHA covers the scope. No new gate machinery; measure before/after.

---
Found in the GH-1175 Phase 0 spike (#1175). Evidence: [`TESTS-RESULTS/2026-10-25+GH-1175-phase0/`](https://github.com/HiQS-Labs/XYZ-forge/tree/development/TESTS-RESULTS/2026-10-25+GH-1175-phase0) · draft `D8-double-full-gate.md`.

## Why

TODO: why this matters now -- what prompted it, what breaks or slows without it.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
