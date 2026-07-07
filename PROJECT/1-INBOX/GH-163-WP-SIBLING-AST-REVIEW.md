---
gh_issue: 163
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/163
title: "Review wp-code-check / WP-DB-Toolkit for existing fast AST tooling reusable for swarmability"
status: Queued (1-INBOX) — awaiting explore-marathon lane
created: 2026-07-07
updated: 2026-07-07
owner: noel
doc_type: research
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Not a commitment to adopt either repo's tooling verbatim
  - Not a build lane — this is a review that feeds GH-156's Phase 0, not a standalone feature
related:
  - PROJECT/1-INBOX/GH-156-SWARMABILITY-PRELIGHT.md
  - ~/Documents/GH Repos/wp-code-check
  - ~/Documents/GH Repos/WP-DB-Toolkit
goal: >
  Determine whether wp-code-check or WP-DB-Toolkit already ship fast AST parsing infrastructure
  that could be reused for GH-156's swarmability-scoring work, instead of building fresh parsing
  infra from scratch.
roadmap_exempt: false
---

## Key concepts

- GH-156 (swarmability prelight) needs to reason about task-scoped code impact; building an AST
  parser from scratch may be unnecessary if a sibling repo already has one.
- `wp-code-check` and `WP-DB-Toolkit` are sibling repos on disk (`~/Documents/GH Repos/`), same
  author, built for a related static-analysis purpose.
- This is a review/spike, not a build: confirm existence, language coverage, and whether the output
  shape fits GH-156's graph-signal model.
- Feeds directly into GH-156's Phase 0 scoring contract — the outcome here is an input to that
  doc, not a standalone deliverable.

# GH-163 · Review wp-code-check / WP-DB-Toolkit for existing fast AST tooling

## Status

| What was just completed | What's next |
|---|---|
| Captured as an issue (2026-07-07); both sibling repos confirmed present on disk. No code has been read yet. | Fire the explore-marathon lane: open both repos, confirm what AST/static-analysis tooling exists (if any), its language coverage, and whether its output shape fits GH-156. |

## Idea

Review sibling repos `wp-code-check` and `WP-DB-Toolkit` (both on disk under
`~/Documents/GH Repos/`) for already-existing fast AST tooling that could be reused for this
repo's swarmability/parallelization scoring work (GH-156) instead of building fresh parsing
infra.

## Why

GH-156 (Prelight: swarmability scoring using codebase-memory-mcp graph signals) needs to reason
about task-scoped code impact to suggest safe parallel lanes. If `wp-code-check` or
`WP-DB-Toolkit` already ship a fast AST parser (for JS/PHP or similar) built for a related static-
analysis purpose, reusing or adapting it could be materially cheaper than building new parsing
infra from scratch for the swarmability prelight.

## Phase 0 — Explore & scope

Purpose: confirm what actually exists before GH-156 commits to building anything new.

### Checklist

- [ ] Open `wp-code-check`: identify whether it has AST parsing (vs. regex/heuristic checks), which
      language(s) it covers, and how the parser is invoked (library, CLI, or embedded).
- [ ] Open `WP-DB-Toolkit`: same three questions.
- [ ] For any AST tooling found, note its output shape (raw AST, symbol list, call graph, etc.) and
      compare against GH-156's proposed output schema (`swarmability_score`, `candidate_lanes`,
      `shared_surfaces`, `hotspots`, `reasons`).
- [ ] Record a clear verdict: reusable as-is, reusable with adaptation, or not applicable — with the
      concrete reason in each case (language mismatch, output shape mismatch, licensing, etc.).
- [ ] If reusable, note the adaptation cost so GH-156's Phase 0 can factor it into that doc's scoring
      contract decision.

### QA checklist — Phase 0

- [ ] Both repos were actually opened and read, not assumed from memory or naming.
- [ ] The verdict is one of the three concrete outcomes above, with a stated reason.
- [ ] If a reusable candidate is found, the finding is written back into GH-156's doc (or flagged for
      that doc's owner to incorporate).
