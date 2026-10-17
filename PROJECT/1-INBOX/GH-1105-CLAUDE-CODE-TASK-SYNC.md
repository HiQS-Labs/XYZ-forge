---
title: "task-sync: Claude Code adapter and Claude Code install target"
status: "Proposed (1-INBOX - not yet active)"
created: 2026-10-17
owner: claude
gh_issue: 1105
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1105
doc_type: feature
complexity: 2
risk: 1
effort: 2
phases: 1
non_goals:
  - Change the ZCode, Antigravity or Codex adapters or the default --ide set
  - Add test/ suites (AGENTS.md, GH-831)
  - Manage pins (Claude Code has no session pinning)
related:
  - GH-896
  - GH-901
goal: >
  Stamp Claude Code session titles (local transcripts and cloud sessions) with
  each session's own last-activity mm-dd, and deploy task-sync to Claude Code
  through the Skills Army HQ target SOP.
---

# GH-1105 - task-sync: Claude Code adapter and Claude Code install target

> 1-INBOX capture, not the active-work doc. On promotion to `PROJECT/2-WORKING/`, add the status
> table and per-phase QA gates (`PROJECT/PDDA.md`).

## Key concepts

- Local sessions: append the `/rename` record (`custom-title`, last-wins) to the session transcript.
- Cloud sessions: read-only planner; native `set_session_title` owns mutation (GH-901 pattern).
- Deployment: enable the existing disabled `claude` Skills Army HQ target; never hand-copy.

## Idea

Add a `claude` adapter to task-sync so the Claude Code session list (desktop app, VS Code
extension, CLI, claude.ai/code) gets the same date-stamped titles as ZCode, Antigravity and Codex.

## Why

The operator now works in Claude Code; its session list is the one not groomed by the heartbeat.
