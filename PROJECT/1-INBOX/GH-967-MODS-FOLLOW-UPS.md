---
gh_issue: 967
source: https://github.com/HiQS-Labs/XYZ-forge/issues/967
title: "Umbrella: Claude Code mods follow-ups after GH-964 (/xyz-status) — gated on its keep decision"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-05
doc_type: feedback
effort: M
complexity: low
risk: low
phases: 1
---

# GH-967: Claude Code mods follow-ups (umbrella)

## Gate

Nothing starts until GH-964 records D4/D5 (interactive terminal + VS Code) and a **keep** or
**extend** decision. On **drop**, close this umbrella.

## Candidate items (ranked; each gets its own issue when picked up)

1. Auto-load the mod instead of `--plugin-dir` each session (Skills Army HQ first, for DRY;
   marketplace or `CLAUDE_CODE_PLUGIN_DIRS` as alternatives).
2. Long-wait notifier for one named hosted run (toast/band; terminal and Desktop only). No auto-submit.
3. Listing relay threads that no driver runs: build a `utils/py/` CLI reader first, then have the mod call it.
4. `/xyz row N`: one RELEASES roadmap row by issue number via `releases_app.py roadmap list --json`.
5. Standalone mods starter kit for other developers — **deferred**. Anthropic's bundled skill and the
   `claude-code-playground` samples already cover the generic material. Share the patterns later
   (read-only status commands, the `plugin validate` safety rule, a manual check with a red control)
   through `push-downstream`, once `/xyz-status` is kept and one or two mods that aren't XYZ-specific exist.

## Constraints

Read-only by default; logic stays in CLIs (Codex/agy parity); no new suites (GH-831); no npm dependencies.
