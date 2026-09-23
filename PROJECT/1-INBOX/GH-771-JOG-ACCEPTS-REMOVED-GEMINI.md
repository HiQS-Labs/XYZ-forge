---
gh_issue: 771
source: https://github.com/HiQS-Labs/XYZ-forge/issues/771
title: "jog accepts removed 'gemini' reviewer; marathon rejects it after the lease is taken"
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

# jog accepts removed 'gemini' reviewer; marathon rejects it after the lease is taken

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `HiQS-Labs/XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Bug
`utils/py/jog_run.py:176` `_MARATHON_REVIEWER_PREFIXES = ("codex", "gemini", "agy")` still accepts `gemini`, which marathon dropped in GH-346. Jog leases the item, then marathon exits 2. That defeats Jog's stated purpose: "an invalid reviewer fails before ANY lease mutation".

The root cause is that the agent-id list is copied by hand six times in `marathon_drive.py` plus once in `jog_run.py`.

## Source
Found in the #769 audit (F2): `PROJECT/1-INBOX/GH-769-MARATHON-DRIVE-AUDIT.md`.

## Acceptance
- A single exported source of truth for reviewer ids, imported by both `marathon_drive.py` and `jog_run.py`.
- A test proves that `jog` rejects `gemini` before any lease mutation.


🤖 Generated with [Claude Code](https://claude.com/claude-code)

## Why

TODO: why this matters now -- what prompted it, what breaks or slows without it.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
