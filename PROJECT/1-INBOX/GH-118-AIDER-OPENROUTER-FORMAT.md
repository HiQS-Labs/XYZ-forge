---
gh_issue: 118
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/118
title: Make Aider edit formats more forgiving for OpenRouter models
status: Proposed (1-INBOX — not yet active)
created: 2026-07-03
doc_type: feedback
effort: 2
complexity: 2
risk: 1
phases: 1
---

# GH-118: Make Aider edit formats more forgiving for OpenRouter models

## Background
During a multi-turn headless review via `aider-turn.sh` using `openrouter/z-ai/glm-5.2`, the model correctly identified changes but failed to output Aider's required file-editing syntax (it defaulted to a standard unified diff instead of Aider's `whole` edit format or `SEARCH/REPLACE` blocks). Aider couldn't parse the diff to apply the edits, causing the relay to stall with `aider turn produced no tracked changes (token-only move?)`.

Aider usually handles this automatically for natively supported models, but for many diverse models proxied via OpenRouter, the auto-detected or default format (`whole` or `udiff`) may not match what the model can actually reliably produce.

## Proposal
How can we make it easier for diverse OpenRouter models to use Aider's system within the harness?

1. **Explicit Edit Format Config**: Expose an `AIDER_EDIT_FORMAT` environment variable in `aider-turn.sh`. When set, this would append `--edit-format "$AIDER_EDIT_FORMAT"` to the Aider invocation, allowing the operator or driver script to force a parsing strategy (like `diff` or `udiff`) tailored to the specific OpenRouter model.
2. **System Prompt Augmentation**: Inject instructions into the `aider-turn.sh` prompt for OpenRouter models, reminding them of the exact syntax Aider expects, or configuring Aider to better guide them.
3. **Fallback Handling**: If Aider exits 0 but produces no tracked changes (as caught by the existing empty-output guard), we might want to capture Aider's "I didn't understand the format" warning and fail the turn so it doesn't get stuck in a loop or pretend it succeeded.

## Acceptance Criteria
- [ ] Provide a clear mechanism (e.g. `AIDER_EDIT_FORMAT` env var) in `aider-turn.sh` to configure Aider's edit format.
- [ ] Document best practices for using Aider with diverse OpenRouter models in the project's guides (e.g., in `AGENTS.md` or the `relay-xyz` skill).
- [ ] (Optional) Add a fail-fast catch in `aider-turn.sh` if Aider warns about edit-format failures, preventing silent stalls.
