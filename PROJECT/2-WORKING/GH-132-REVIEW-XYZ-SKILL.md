---
title: "GH-132: Formal /review-xyz Code Review Skill & Multi-Model Harness"
gh_issue: 132
source: "https://github.com/HiQS-Suite/XYZ-forge/issues/132"
status: active
created: 2026-08-21
updated: 2026-08-21
owner: Antigravity
goal: "Ship a deterministic, first-class /review-xyz code review skill and Python engine supporting throwaway-worktree multi-model reviews and automated PR/issue comments."
doc_type: feature
---

# GH-132 — Formal `/review-xyz` Code Review Skill & Multi-Model Harness

## Status

| What was just completed | What's next |
|---|---|
| Created tracking issue #132, parked in ROADMAP.md, created PDDA working doc, and cut branch `feat/gh132-review-xyz-skill`. | Implement `skills/review-xyz/SKILL.md`, `utils/py/review_xyz.py`, and regression test suite `test/gh132-review-xyz-skill.sh`. |

## Quad Concepts
- **Deterministic Review Execution:** Standardized, structured finding schema (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) with citation verification.
- **Throwaway Worktree Isolation:** Safe, no-mutation review runs using `git stash create` and disposable worktree checkouts.
- **Frontier Multi-Model Dispatch:** Direct invocation of Command Code (`Qwen/Qwen3.8-Max`, `zai-org/GLM-5.3`), Aider/OpenRouter, Codex, and Agy.
- **Automated GitHub Integration:** Seamless PR diff extraction and structured review/checklist posting to PRs and linked issues via `gh`.

## Bet and boundary

Adding a dedicated `/review-xyz` skill and engine formalizes the invocation of non-Codex/Agy models (like Qwen 3.8-Max and GLM-5.3) for code review. This is an **Easy** reversibility change: all new files are contained within `skills/review-xyz/`, `utils/py/review_xyz.py`, and `test/`, with zero breaking changes to existing turn shims or kernel primitives.

## Phase 1 — Core Review Engine (`utils/py/review_xyz.py`)
- Diff extraction: support local uncommitted diff, branch vs base, and `gh pr diff <PR#>`.
- Throwaway worktree isolation: create disposable worktrees to prevent advisor mutation.
- Model adapters: Command Code (`cmd -p`), Aider/OpenRouter (`aider --message`), Codex (`codex exec -s read-only`), Agy (`agy -p`).
- Citation checking: enforce that claims cite `file:line` or symbols.
- Finding extraction: parse verdict and findings into structured Markdown/JSON.

## Phase 2 — Skill Interface & GitHub Integration (`skills/review-xyz/`)
- Create `skills/review-xyz/SKILL.md`, `PROJECT.md`, `install.sh`, and scripts.
- Support `--post-pr` to post review critique as a PR comment or review via `gh pr comment`.
- Support `--post-issues` to post checklist follow-ups to linked issues detected in PR body (`Fixes #...`, `Closes #...`).

## Phase 3 — QA & Dogfooding
- Author comprehensive test suite `test/gh132-review-xyz-skill.sh`.
- Execute dogfood review using Command Code -> `Qwen/Qwen3.8-Max`.
- Validate with `./validate.sh` and `utils/pdda/pdda.sh run`.
