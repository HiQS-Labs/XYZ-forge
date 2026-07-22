---
gh_issue: 280
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/280
title: "Investigate Aider+Qwen3.8-Max reliability vs Aider+Claude-Sonnet-5 control ($5 OpenRouter budget) — test/debug/fix/iterate"
status: "Proposed (1-INBOX — not yet active)"
created: 2026-07-22
doc_type: feedback
effort: 3
complexity: 3
risk: 2
phases: 2
---

# GH-280 · Aider+Qwen vs Aider+Sonnet reliability investigation

Focused, budget-capped (~$5 OpenRouter) experiment to determine whether the empty-artifact/no-op
failures seen driving Aider + `qwen3.8-max-preview` (GH-279) are a Qwen problem, an Aider problem, or a
harness (ours) problem — using Aider + Claude Sonnet 5 as the control on identical tasks.

**Recommended sequencing (cheap-first):**
- Phase 1 — quick, near-zero-cost diagnostic: try Aider against Qwen with an explicit `--edit-format`
  override (`diff`/`diff-fenced`/`udiff`) instead of its auto-selected `whole`, on the exact failing
  installer task. Aider auto-picks `whole` for unlisted/custom model ids; this is Aider's most common
  failure mode for models it has no built-in metadata for, and has a known, cheap remedy.
- Phase 2 — if Phase 1 doesn't fully resolve it, run the fuller model × edit-format × files-per-turn
  matrix against both Qwen and the Sonnet control, K repetitions per cell (stochastic behavior observed:
  1 of ~4 lanes succeeded with default settings), hard-capped at $5 total OpenRouter spend.

Hypotheses to discriminate: H1 (Qwen doesn't reliably honor Aider's edit-format contract), H2 (Aider's
format selection/parsing is wrong for this model), H3 (harness prompt/containment degrades compliance).
Full experiment design, matrix, and deliverables are in the GitHub issue.

Depends on nothing else being fired first; independent of GH-279's punch-list items.
