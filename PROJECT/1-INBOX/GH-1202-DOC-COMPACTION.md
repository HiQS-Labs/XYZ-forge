---
gh_issue: 1202
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1202
title: "Audit A: safely compact active documentation and source commentary"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-24
updated: 2026-10-24
owner: noelsaw
doc_type: plan
effort: 3
complexity: 3
risk: 2
phases: 4
rating: "pri/sev/appeal/effort 70/55/80/65 · calc 270"
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1201
goal: Reduce duplicated active documentation and commentary while preserving canonical contracts, safety rationale, links, and historical evidence.
---

# GH-1202 — Safe documentation and commentary compaction

## Quad Concepts

- Repeated active guidance obscures current contracts → consolidate into canonical owners and leave pointers.
- Unbounded summarization can erase evidence → explicit protected classes and per-diff preservation review.

## Evidence and decision

The repository has about 409,000 Markdown lines, but roughly 270,400 are relay transcripts. Raw volume is therefore not the right target. Active operational docs and dense runtime commentary are the comprehension problem. Comments in `marathon_drive.py`, `rtl.py`, and `src/project.js` include load-bearing incident rationale and must not be treated as disposable prose.

Compact selectively. Do not autonomously rewrite changelogs, raw transcripts, evidence receipts, generated views, or completed plans merely to reduce size.

## Preservation contract

Preserve current behavior, commands, ownership, canonical routing, safety warnings, invariants, rollback/failure semantics, incident identifiers, evidence links, and machine-readable contracts. Remove duplicated narration, superseded instructions, and comments that only restate code. Point to existing canonical history rather than creating a parallel archive.

## Phases

1. Inventory and classify active canonical docs, code commentary, completed plans, generated files, and evidence; establish a baseline and protected classes.
2. Pilot a small set of low-risk compactions with per-file rationale and independent meaning-preservation review.
3. Consolidate repeated active policy into canonical owners, leaving pointers and incident context intact.
4. Run existing PDDA and affected source checks; measure only selected-file changes and stop at diminishing returns.

## Acceptance

- Eligible and protected content are distinguishable in the inventory.
- Every changed file has a specific readability/duplication rationale.
- No generated file, transcript, receipt, or changelog is rewritten only for size.
- Links, commands, safety semantics, and incident references survive.
- Existing covering checks pass in an isolated clone.

## Non-goals

No blanket LLM summarization, age/length-based deletion, evidence retention purge, or new gates/tests.

## Merge evidence

- PR #1209 merged 2026-10-28 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
