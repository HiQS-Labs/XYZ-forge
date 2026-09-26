---
gh_issue: 844
source: https://github.com/HiQS-Labs/XYZ-forge/issues/844
title: "GH-833 evidence: V1b must scope the PRS entry to the glossary, the witness recipe must return an aggregate status, and the plan's non-goal wording (CodeRabbit on #840)"
status: Proposed (1-INBOX — not yet active)
created: 2026-09-26
updated: 2026-09-26
owner: operator (via umbrella #845)
doc_type: fix
non_goals:
  - Any change to the PRS wording or links.
  - Turning the manual checks into a suite or gate (AGENTS.md, No new tests).
related:
  - "#845 — umbrella for #840's CodeRabbit follow-ups"
  - "#833 / #840 — the change whose evidence this fixes"
goal: >
  GH-833's manual checks can fail on what they claim to check: V1b confines the PRS entry to the glossary, and
  the witness recipe exits non-zero on any unexpected result.
---

# GH-844 — GH-833 evidence hygiene

## Status

| What was just completed | What's next |
|---|---|
| Captured, parked and rated. | Promote with the plan. |

## Idea

The canonical statement is [#844](https://github.com/HiQS-Labs/XYZ-forge/issues/844). This capture points there.

## Rating — 2026-09-26: `20/10/50/90` (pri/sev/appeal/effort)

Severity 10: evidence tooling and plan wording only; nothing shipped is wrong. Priority 20: a check that cannot
fail on a moved entry, or a recipe that hides a failure, weakens a future re-run. Appeal 50: neutral. Effort 90:
small edits and one re-run. Recurrence: none; these are review findings, not incidents.
