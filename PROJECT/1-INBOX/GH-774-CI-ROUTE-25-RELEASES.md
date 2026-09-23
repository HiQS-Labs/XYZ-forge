---
gh_issue: 774
source: https://github.com/HiQS-Labs/XYZ-forge/issues/774
title: "ci-route: ~25 releases_app suites missing from SUBSYSTEM_TESTS_releases; 2 test files never run"
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

# ci-route: ~25 releases_app suites missing from SUBSYSTEM_TESTS_releases; 2 test files never run

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `HiQS-Labs/XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Problem
`utils/ci-route.sh:24-26` `SUBSYSTEM_TESTS_releases` lists 23 suites. About 25 more suites exercise `releases_app.py` and are registered in `validate.sh`, but are missing from that list. A change to `releases_app.py` alone therefore runs tier 2 without them; they only run in the full gate.

Missing: `jog-queue`, `gh280`, `gh351`, `gh349`, `gh423`, `gh424`, `gh491`, `gh492`, `gh527`, `gh75-dashboard`, `gh360` (both), `gh454`, `gh525`, `gh418`, `gh421`, `gh238`, `gh239`, `gh290`, `gh291`, `gh197`, `gh605-*`.

These are not wired into `validate.sh` or CI at all:
- `test/gh534_phase_b_tests.py` (it also misses pytest's `test_*.py` pattern)
- `test/flightdeck/test_work_status.py`

## Why now
This blocks the #768 refactor. Without this fix, a split PR can pass tier 2 while breaking about 25 suites.

## Source
Appendix A4 of `PROJECT/1-INBOX/GH-768-RELEASES-APP-AUDIT.md`.

## Acceptance
- `SUBSYSTEM_TESTS_releases` includes every suite that exercises `releases_app`.
- The two orphan test files are wired in or explicitly retired.
- A drift check fails when a new suite imports or invokes `releases_app` without being routed.


🤖 Generated with [Claude Code](https://claude.com/claude-code)

## Why

TODO: why this matters now -- what prompted it, what breaks or slows without it.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
