---
gh_issue: 451
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/451
title: Marathon: support Pi builders on the Python-default path
status: Inbox
created: 2026-08-08
updated: 2026-08-08
owner: Codex
goal: Route Pi builders through the Python-default marathon path and fail before any run state is created when Pi is unavailable.
---

## Status

| What was just completed | What's next |
|---|---|
| Issue captured and a narrow implementation branch opened | Verify focused Pi and marathon coverage, then request review |

## Scope

- Route `pi*` agents through the existing `marathon-agent.sh` dispatcher and `pi-turn.py`.
- Preflight `PI_BIN` before relay or tick mutation.

## Non-goals

- No provider allowlist, model alias, autonomous fuzzing, or frozen Bash `marathon-drive.sh` edit.
