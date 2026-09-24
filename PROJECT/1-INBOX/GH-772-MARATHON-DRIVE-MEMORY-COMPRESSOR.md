---
gh_issue: 772
source: https://github.com/HiQS-Labs/XYZ-forge/issues/772
title: "marathon_drive: memory-compressor figure assumes 4K pages, logs 4x low on 16K-page Macs"
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

# marathon_drive: memory-compressor figure assumes 4K pages, logs 4x low on 16K-page Macs

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `HiQS-Labs/XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Bug
The memory-compressor figure in `utils/py/marathon_drive.py` assumes a 4096-byte page. Apple Silicon Macs report 16384 (`sysctl hw.pagesize`), so the value is logged 4x too low.

## Source
Found in the #769 audit (F18): `PROJECT/1-INBOX/GH-769-MARATHON-DRIVE-AUDIT.md`.

## Acceptance
- Page size is read at runtime (`os.sysconf("SC_PAGE_SIZE")` or `vm_stat` header), not hardcoded.
- A test covers both 4K and 16K page sizes.


🤖 Generated with [Claude Code](https://claude.com/claude-code)

## Why

TODO: why this matters now -- what prompted it, what breaks or slows without it.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.

## Merge evidence

- PR #776 merged 2026-09-24 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
