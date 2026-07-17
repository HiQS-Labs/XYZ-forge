---
gh_issue: 226
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/226
title: "Full provenance follow-up should coordinate with the already-reworked consult/relay summary surface"
status: Proposed (1-INBOX — not yet active)
created: 2026-07-17
updated: 2026-07-17
owner: noel
doc_type: enhancement
complexity: 2
risk: 2
effort: 2
phases: 2
ratings_provisional: true
related:
  - PROJECT/2-WORKING/GH-173-JEDI-WRIGHT-FEEDBACK.md
  - PROJECT/2-WORKING/GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md
  - PROJECT/1-INBOX/GH-211-CONSULT-RELAY-TLDR-SUMMARIES.md
  - skills/consult/SKILL.md
non_goals:
  - Not implementing the fuller provenance taxonomy in this capture doc.
  - Not reopening GH-178's already-shipped narrow A4 slice unless the coordinated pass proves it insufficient.
  - Not editing the external giant-brains relay skill from this intake doc; that repo boundary is part of what this issue must clarify first.
goal: >
  Capture the coordination gap Jedi Wright pointed out on 2026-07-17: GH-211 already reworked the
  consult/relay operator-summary surface, GH-178 intentionally shipped only a narrow provenance
  slice, and the next "full provenance" pass should decide those surfaces together so the
  human-facing reporting layer is not reworked twice.
---

# GH-226 · provenance follow-up vs. summary-surface coordination

## Status

| What was just completed | What's next |
|---|---|
| Opened [#226](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/226) from Jedi Wright's Slack follow-up and parked this local capture so he can edit the issue directly. A standalone marathon surface exists at `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-17-I-PROVENANCE-SUMMARY-COORDINATION.md`. | Let Jedi confirm or refine scope on the issue, then run the standalone planning marathon to inventory the touched surfaces and decide whether the next pass stays one issue or splits by repo/surface. |

## Problem summary

Jedi's note was not about re-opening the already-shipped GH-211 TLDR/category formatting work or
GH-178's narrow provenance stamp in isolation. The point was the overlap between them:

- **GH-211** intentionally changed the **operator-facing summary shape** only.
- **GH-178** intentionally shipped only a **narrow provenance slice**, not the full firsthand-vs-asserted taxonomy.
- A future provenance pass that ignores GH-211's changed summary surface will likely touch the same
  operator-facing layer a second time and drift between consult, relay, and transcript semantics.

That makes this a coordination/design issue first, not a "small missing patch" bug.

## Why this is a separate follow-up

This issue exists because neither parent issue actually owned the boundary between format and provenance:

- **GH-178** deliberately stopped at presence/absence-style provenance stamping.
- **GH-211** deliberately avoided verdict/provenance semantics.

The missing work is deciding how fuller provenance should appear in the **human-facing report**
without fighting the already-shipped TLDR/category structure.

## Questions this issue owns

1. Which operator-facing surfaces are in scope for the coordinated provenance pass?
2. Should consult and relay present provenance identically, or only consistently?
3. What is the minimum viable next distinction:
   - cited vs uncited
   - firsthand-read vs operator-asserted
   - conditional vs verified verdicts
4. Does the next execution stay one issue, or split into:
   - this repo's consult/transcript surfaces
   - the external relay skill/reporting surface in `giant-brains-claude-skills`

## Definition of done

- [ ] Inventory the operator-facing summary surfaces touched by GH-211 and the provenance surfaces touched by GH-178.
- [ ] Decide the reporting contract for fuller provenance so the operator-facing layer is edited once, not twice.
- [ ] Record explicit file ownership and repo boundaries for the next implementation pass.
- [ ] Either:
  - [ ] promote this issue into active execution with a bounded contract, or
  - [ ] split it into narrower follow-up issue(s) with clear per-surface ownership.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "utils/pdda/pdda.sh roadmap-coverage",
  "fix_probes": [
    {
      "type": "grep_absent",
      "path": "PROJECT/1-INBOX/GH-226-PROVENANCE-SUMMARY-SURFACE-COORDINATION.md",
      "pattern": "## Inventory of touched surfaces"
    },
    {
      "type": "grep_absent",
      "path": "PROJECT/1-INBOX/GH-226-PROVENANCE-SUMMARY-SURFACE-COORDINATION.md",
      "pattern": "## Decision"
    }
  ],
  "artifacts": [
    "PROJECT/1-INBOX/GH-226-PROVENANCE-SUMMARY-SURFACE-COORDINATION.md",
    "PROJECT/2-WORKING/MARATHON-PLAN-2026-07-17-I-PROVENANCE-SUMMARY-COORDINATION.md"
  ],
  "remediation": {
    "source": "issue#226",
    "criteria": "GH-226's local doc gains an Inventory of touched surfaces section covering GH-211 and GH-178 operator-facing/provenance surfaces, plus a Decision section stating whether the next pass stays one coordinated issue or splits by repo/surface. The standalone marathon plan is kept in sync with that decision. utils/pdda/pdda.sh roadmap-coverage passes."
  },
  "lanes": { "agy_safe": [], "orchestrator_only": [] }
}
```
