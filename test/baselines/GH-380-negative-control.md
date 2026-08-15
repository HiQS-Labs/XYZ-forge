# GH-380 — recorded negative control (#419)

Test:     `test/gh380-claude-trust.sh`
Baseline: `commit 4642c58f6c74962b230945548e1f3d828e92f464` — `utils/py/claude-turn.py`
Date:     2026-08-15

## Defect Summary

Before GH-380, a `--builder claude` turn ran with the target repo's `permissions.allow`
silently ignored unless the directory was trusted interactively in Claude Code beforehand.
Neither `claude-turn` twin contained any check or warning for workspace trust.

## Verification

`test/gh380-claude-trust.sh` verifies that:
1. When a workspace is not trusted (no `hasTrustDialogAccepted: true` in `~/.claude.json`),
   `warn_if_workspace_untrusted` emits a clear actionable warning to stderr.
2. When the workspace is trusted in `~/.claude.json`, no warning is emitted.
