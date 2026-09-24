---
gh_issue: 773
source: https://github.com/HiQS-Labs/XYZ-forge/issues/773
title: "marathon_drive: gate memory guard silently disables when ps is denied, logs peak 0MB"
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

# marathon_drive: gate memory guard silently disables when ps is denied, logs peak 0MB

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `HiQS-Labs/XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Bug
The gate's memory guard in `utils/py/marathon_drive.py` switches itself off without any message when `ps` is not permitted (reproduced in the Claude Code sandbox). The run log then reports a peak of `0MB`, which reads as a real measurement.

## Source
Found in the #769 audit (F19): `PROJECT/1-INBOX/GH-769-MARATHON-DRIVE-AUDIT.md`.

## Acceptance
- When `ps` fails, the guard logs a one-line warning and records the peak as unknown, not 0.
- A test stubs a failing `ps` and asserts both.


🤖 Generated with [Claude Code](https://claude.com/claude-code)

## Why

TODO: why this matters now -- what prompted it, what breaks or slows without it.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
