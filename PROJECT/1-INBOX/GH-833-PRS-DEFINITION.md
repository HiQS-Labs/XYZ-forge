---
gh_issue: 833
source: https://github.com/HiQS-Labs/XYZ-forge/issues/833
title: "docs: codify PRS — the Product Release System (the RELEASES ledger) — as the third part of the XYZ Forge / PDDA / PRS trinity"
status: Proposed (1-INBOX — not yet active)
created: 2026-09-26
updated: 2026-09-26
owner: operator (via /start-task)
doc_type: docs
non_goals:
  - Renaming code, files, tables, CLI verbs or the RELEASES-* docs.
  - Any new check or suite (AGENTS.md, No new tests).
  - Any file the tier router treats as non-docs; this landing must qualify through the hosted Small run.
related:
  - "#831 — the three-tier gate; Phase 3 is the first hosted Small run"
  - "#836 — step 6 is the same run"
goal: >
  An agent that meets "PRS" finds one canonical definition, and every canonical doc that discusses the
  ledger spells it out on first use. The merge is docs-only, so it is the first landing the hosted
  reconcile qualifies with the Small gate.
---

# GH-833 — define PRS, the Product Release System

## Status

| What was just completed | What's next |
|---|---|
| Captured, and parked and rated in the roadmap ledger. | Recon of each canonical doc's first ledger mention and the tier router, then promote to `2-WORKING` with the plan. |

## Idea

The canonical statement is [#833](https://github.com/HiQS-Labs/XYZ-forge/issues/833): its trinity table, scope
steps 1–3, non-goals and acceptance. This capture points there and does not restate them.

## Rating — 2026-09-26: `55/20/50/85` (pri/sev/appeal/effort)

- **Severity 20.** No crash, data loss or blocked work. An agent that meets "PRS ratings" or "the PDDA, PRS and
  canary suites" (`ROUTER.md:119`) has to guess the term.
- **Priority 55.** Above what severity alone supports, because the operator scheduled it now, on 2026-09-26. It
  is the docs-only landing that the hosted Small run needs for #831 Phase 3 and #836 step 6.
- **Appeal 50.** Neutral; the operator gave no score.
- **Effort 85.** A docs-only change to about eight docs and a few skills. No code.
- **Recurrence:** PRS is used undefined in #443, #522, #645, #698 and #777, plus `LEADERBOARD.md` titles and
  three skills. These are uses of the term, not incidents; the incident trend is unknown.
