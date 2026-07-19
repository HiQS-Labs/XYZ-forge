---
gh_issue: 66
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/66
title: Self-healing harness — session/transcript-log audit for stale-instruction drift
status: Closed — Proposed (1-INBOX — not yet active)
created: 2026-06-30
updated: 2026-06-30
owner: noel
doc_type: feature
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
non_goals:
  - Not building a transcript storage/archive location — GH-30 already owns where transcripts live
  - Not making the audit write back to skills/guardrails automatically — findings are a report, a
    human or a separate change applies them
related:
  - AUDIT/relay-automation-transcripts/
  - relay-automation/relay-loop.sh
  - PROJECT/1-INBOX/GH-30-CENTRALIZED-TRANSCRIPT-ARCHIVE.md
roadmap_exempt: false
---

# GH-66 · Session/transcript-log audit for stale-instruction drift

**Why:** A review of an external "self-healing agent harness" doc against this repo's actual
architecture found most of its principles already implemented. One concrete gap: transcripts are
captured (`AUDIT/relay-automation-transcripts/`) but nothing routinely audits them for
stale-instruction drift or wasted exploration across turns.

## Status

| What was just completed | What's next |
|---|---|
| Issue [#66](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/66) opened, doc captured, parked in ROADMAP. | Confirm scope, promote to `2-WORKING`, then define the audit's report shape. |

## Table of contents

- [Status](#status)
- [Checklist](#checklist)
- [QA gate](#qa-gate)

## Checklist

- [ ] Define a periodic (scheduled, not per-commit — per the token-cost principle already used by
      `relay-loop.sh`'s adaptive cadence) pass over `AUDIT/relay-automation-transcripts/` and
      `relay-system/**` transcripts.
- [ ] The audit flags: reads of stale/superseded instruction files, repeated exploration of the same
      stale directory across turns, and turns that stalled without a bounded exit code.
- [ ] Output is a structured report (not prose) an operator can scan — consistent with the four
      pillars (Attested, Relevant, Fresh, Structured) in GUIDING-PRINCIPLES.md.
- [ ] Findings feed back into skill/guardrail updates (e.g., an outdated file referenced repeatedly
      signals a doc that PDDA's `stale` check should also catch) rather than being a dead-end report.

## QA gate

- [ ] Run the audit against an existing transcript directory and confirm it produces a non-empty,
      structured finding on at least one real historical drift case (if one exists in
      `AUDIT/relay-automation-transcripts/`).
- [ ] Audit is read-only — it does not modify transcripts, skills, or guardrails itself; it only
      reports.
