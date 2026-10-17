---
title: "task-sync: Claude Code adapter and Claude Code install target"
status: Active
created: 2026-10-17
updated: 2026-10-17
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
  - Change skills-army-hq code; its claude target already exists
related:
  - GH-896
  - GH-901
goal: >
  Stamp Claude Code session titles (local transcripts and cloud sessions) with
  each session's own last-activity mm-dd, and deploy task-sync to Claude Code
  through the Skills Army HQ target SOP.
---

# GH-1105 - task-sync: Claude Code adapter and Claude Code install target

## Status

| What was just completed | What's next |
|---|---|
| Intake parked (rated 55/25/50/65), recon and plan written | Independent plan review, then implement the `claude` adapter and docs |

## Key concepts

- Local sessions: append the `/rename` record (`custom-title`, last-wins) to the session transcript.
- Cloud sessions: read-only planner; native `set_session_title` owns mutation (GH-901 pattern).
- Deployment: enable the existing disabled `claude` Skills Army HQ target; never hand-copy.

## Recon (base `f3072139`)

- `skills/3-weekly/task-sync/scripts/task_sync.py` dispatches adapters through `_build_adapter`;
  `ADAPTERS = ("zcode", "agy", "codex")`; Codex is plan-only and is guarded in `main()`.
- `core.py` owns `clean_base`, `local_stamp`, `new_ide_report`, `write_receipt`, `AdapterError`.
- `adapters/codex.py` is the read-only planner pattern: fresh snapshot (≤300s), refuse empty or
  ambiguous inventory, actual turn activity required, never a fallback timestamp.
- **Claude Code local store** (observed in Claude Code 2.1.302): one JSONL transcript per session at
  `~/.claude/projects/<cwd-slug>/<sessionId>.jsonl` (subagent transcripts live in subfolders).
  `/rename` appends `{"type":"custom-title","customTitle":T,"sessionId":S}`; title records are
  `last-wins`. The list label resolves as
  `agentName || customTitle || aiTitle || summary || firstPrompt`. Messages carry ISO `timestamp`.
  A live session re-appends its in-memory title on resume and when it rewrites its tail, so a live
  session can revert a stamp. That's the existing "App-overwrites-active-titles" caveat.
- **Claude Code cloud sessions**: `list_sessions` returns `id`, `title`, `session_status`,
  `environment_kind` (`anthropic_cloud` = cloud container; `bridge` = a local session mirrored via
  Remote Control) and `updated_at`. `list_events(kinds=["user","assistant"])` returns events with
  `created_at`. `set_session_title` renames. `updated_at` moves on renames, so it only selects
  candidates; it is never the activity date.
- `skills/3-weekly/skills-army-hq/scripts/intake.py` already ships a disabled
  `{"id": "claude", "path": "~/.claude/skills"}` target; `references/targets.md` lists it.
  Enabling it is `intake.py --apply targets --id claude ...` then `sync.py --apply`. No code change.

## Plan

One new adapter module, `adapters/claude.py`, with two classes sharing the core:

1. **`ClaudeLocalAdapter`** (apply-capable, like ZCode):
   - Store: `~/.claude/projects/*/*.jsonl` (top level only), overridable with `--claude-root PATH`
     for probes. A missing root is an `AdapterError`, not an empty sweep.
   - Candidates: file mtime within `--hours`. Stream each file; activity = latest `timestamp`
     on a `user`/`assistant` record; current label from the last `agent-name`/`custom-title`/
     `ai-title`/`summary` record (last-wins), following the precedence above.
   - Skip: `agentName` set (it outranks `customTitle`); activity older than `--hours`; activity
     within the last 10 minutes (live session; restamped on a later tick); no title record at all
     → `needs_summary` (same contract as ZCode; the heartbeat writes it via `--set-title`).
   - Desired = `local_stamp(activity) + " " + clean_base(label, max_length=None)`; write only on change.
   - Write: before appending, re-stat the file; require the size and mtime recorded at read time
     and a trailing newline, else skip it this tick. Append one `custom-title` line with
     `O_APPEND`, then restore the original atime/mtime with `os.utime`, so the session list's
     recency order doesn't jump. Undo = another `custom-title` (the old title is in the report).
   - `--set-title <sessionId> TITLE` stamps with the session's own activity date (existing CLI verb).
   - `doctor()`: root readable, ≥1 transcript parsed, the record shapes above are present.
2. **`ClaudeCloudAdapter`** (plan-only, mirrors `CodexAdapter`):
   - Snapshot `{captured_at, sessions: <list_sessions data>, activity_at: {id: unix seconds}}`,
     ≤300s old, non-empty, unique ids; `--claude-snapshot PATH` + `--exclude-thread <own session>`.
   - Candidates: `environment_kind == "anthropic_cloud"` only (bridge sessions are local and owned
     by the local adapter), `session_status` not running, `updated_at` within `--hours`, not
     excluded. Activity is required for each candidate; missing → abort.
   - Report `renamed` proposals with observed old title; `execution: native-tools-required`.
3. **CLI wiring** (`task_sync.py`): `ADAPTERS += ("claude", "claude-cloud")`; `_build_adapter`
   branches; `--claude-root`, `--claude-snapshot`; `claude-cloud` gets the same plan-only guard as
   Codex. Default `--ide zcode,agy` unchanged.
4. **Docs** (`task-sync/SKILL.md`): description/when_to_use mention Claude Code; a "Claude Code
   (GH-1105)" section with the local semantics, the cloud native-sweep procedure
   (list_sessions → list_events → snapshot → plan → recheck → `set_session_title` → read back),
   heartbeat note (local: add `claude` to the existing ZCode heartbeat command or a Claude Code
   `/loop`/scheduled task; cloud: a scheduled task running the native sweep), and Install SOP
   step 2 gains Claude Code `~/.claude/skills/task-sync` via
   `intake.py --apply targets --id claude --path ~/.claude/skills --consumer "Claude Code"`
   then `sync.py` (preview, then `--apply`). No hand-copying.

## Bet check

- *Outcome:* the Claude Code session list shows each session's last-worked date at a glance.
- *Smallest bet:* one adapter file + CLI wiring + docs. Not built: pins, summaries generated by
  the CLI, a scheduler, skills-army-hq code changes.
- *Rejected alternative:* use only cloud `set_session_title` for everything. Local CLI/desktop
  sessions not attached via Remote Control would be missed, and bridge renames aren't documented
  to write back to the local transcript.
- *Rollback:* revert the PR; stamped sessions keep their titles, and an undo is one more
  `custom-title` record (old titles are in the report).

## Risks

- Undocumented local format may change → the doctor names the missing record shapes; the adapter
  refuses rather than guessing.
- Concurrent append from a live session → 10-minute quiet window + size/mtime precheck + single
  `O_APPEND` line write.

## Verification (no new test/ suites)

Manual probes against fixture roots in `temp/`, recorded under
`TESTS-RESULTS/2026-10-17+GH-1105/`:

1. Stamp happy path: fixture with an `ai-title` and activity 2 days ago → `renamed` proposal,
   `--apply` appends exactly one line, mtime unchanged, re-run is a no-op.
2. Red controls: missing root → error, exit 3; a file with no trailing newline → skipped, no write;
   activity inside 10 minutes → skipped; an `agent-name` session → skipped; no title → `needs_summary`.
3. Cloud planner: fresh snapshot → proposals only for `anthropic_cloud` idle sessions; stale
   snapshot, missing activity, `--apply` → refused.
4. Existing behavior: `--ide zcode,agy` and `--ide codex` paths unchanged (argparse help + a codex
   snapshot probe). The route-selected gate on the final commit.

## Rating rationale (2026-10-17)

`rated 55/25/50/65`. Severity 25: a convenience gap with no data loss or blocked work. Priority 55:
the operator asked for it now. Appeal 50: neutral (no explicit score given). Effort 65: one adapter
of about 200 lines, reusing the core. Recurrence: not applicable (a feature, not a defect).
