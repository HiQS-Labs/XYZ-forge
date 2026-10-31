---
gh_issue: 1295
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1295
title: "factory-primitive plan-draft: injected instruction text in an issue body is carried into briefs and launch packets"
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
  - no model-based classifier
  - no new tests (GH-831)
related:
  - #1279
  - #1248
  - #1294
goal: >
  Issue text reaches briefs and launch packets only as quoted data that a builder prompt cannot read as an instruction; a recorded manual round trip on the injection canaries shows it.
---

## Key concepts

- text from issue bodies is copied into briefs
- decide fence-as-data versus strip
- human approval is the only barrier today

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# factory-primitive plan-draft: injected instruction text in an issue body is carried into briefs and launch packets

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

Instruction text injected in an issue body is carried verbatim into plan-draft briefs and launch packets. See the issue for evidence and the proposed fix.

## Why

Found by the #1279 window: injection-canary lanes passed the structure and Marathon dry runs. Nothing executes automatically, but the text reaches future builder prompts and a human approves launch by copying a folder.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
