---
gh_issue: 764
source: https://github.com/HiQS-Labs/XYZ-forge/issues/764
title: "Baseline macOS gate failures in ATE, work state, and work events suites"
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

# Baseline macOS gate failures in ATE, work state, and work events suites

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ Forge** → repo `HiQS-Labs/XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Observed on untouched `development`

The macOS `validate.sh` gate was red in a disposable full clone while reviewing #762. The same focused failures reproduce on an untouched `development` clone with the same Python/Node environment, so they should be diagnosed separately from the skill refactor:

- `gh142-ate-exit-contract.sh`: section 5 reports `FAIL: no child-failure line`.
- `gh605-work-state.sh`: `test_wal_header_without_sidecars_refuses_before_open_for_schema_seven_and_eight` sees a sidecar that the test expects absent.
- `gh549-work-events.sh`: 105 passed / 20 failed, including `github_board: FAILED — communicate failed: ValueError('I/O operation on closed file.')`, card-column assertions, and dispatch cursor assertions.

The initial #762 run also failed `gh425-gate-provenance-pr.sh` because the temporary Python environment lacked `pytest`; after installing it, the focused suite passed. Document the required gate toolchain so a missing `pytest` is identified before the long run.

## Next steps

1. Reproduce each focused suite in fresh disposable full clones with a pinned toolchain and preserve logs.
2. Trace the failure path and establish a failing control for each root cause; split into separate issues if fixes touch disjoint subsystems.
3. Restore the full macOS gate and retain a provenance receipt before considering #762 merge readiness.

This is parked baseline follow-up, outside #762’s skill routing scope. Related ATE work: #298.

## Why

TODO: why this matters now -- what prompted it, what breaks or slows without it.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
