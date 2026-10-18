---
title: "task-sync: Claude Code adapter and Claude Code install target"
status: Complete
created: 2026-10-17
updated: 2026-10-17
owner: claude
gh_issue: 1105
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1105
doc_type: feature
complexity: 2
risk: 2
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
| Implemented; 24/24 probes; docs gate green; final QA Approved (round 2) | PR ready, awaiting merge; operator enables the Claude Code target per device after merge |

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
  `agentName || customTitle || aiTitle || summary || firstPrompt`. Messages carry ISO `timestamp`
  (`…Z`). The session list reads only a 64 KiB head and a 64 KiB tail (`fv=65536`):
  `customTitle` = last occurrence in the tail, else the sidecar
  `<project-dir>/<sessionId>/custom-title.json` (`{"customTitle":…}`), else the head;
  `aiTitle` = tail, else head. A running session keeps its title in memory and re-appends it when
  it rewrites its tail, so stamping a running session can be reverted. Running sessions are listed
  in `~/.claude/sessions/<pid>.json` (`{"pid","sessionId",…}`).
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
     on a `user`/`assistant` record (`Z` normalized to `+00:00`, so macOS Python 3.9 parses it).
   - Current label = the app's own resolution (above): tail → sidecar → head for `customTitle`,
     then `aiTitle`, then `summary`. Comparing against what the app shows (not "last record in the
     file") makes a stamp that scrolled out of the tail get re-appended on a later tick.
   - Skip (fail closed): session listed as running in `~/.claude/sessions/*.json` with a live pid,
     or that registry unreadable/unparseable (same rule as the Antigravity app gate; a missing
     `~/.claude/sessions/` directory means nothing is running); `agentName` set (it
     outranks `customTitle`); activity older than `--hours`; activity within the last 10 minutes
     (backstop only). Running sessions include the heartbeat's own session.
   - No title at all (only a first prompt) → `needs_summary`, no write. This deliberately differs
     from ZCode, which stamps the raw prompt too: a stamped prompt would become a permanent
     `customTitle` that outranks the AI title Claude Code generates later.
   - Desired = `local_stamp(activity) + " " + clean_base(label, max_length=None)`; write only on change.
   - Write: before appending, re-stat the file; require the size and mtime recorded at read time
     and a trailing newline, else skip it this tick. Append one `custom-title` line with
     `O_APPEND`; restore the original atime/mtime with `os.utime` only if the size is exactly
     the precheck size plus our line, so the session list's recency order doesn't jump.
   - `--set-title <sessionId> TITLE` stamps with the session's own activity date (existing CLI verb).
   - `--group`/`--unpin-days` refused (no pins/groups in Claude Code).
   - `doctor()`: root readable, sessions registry readable, ≥1 transcript parsed with `timestamp`
     and a known title record shape; each missing shape is named.
2. **`ClaudeCloudAdapter`** (plan-only, mirrors `CodexAdapter`):
   - Snapshot `{captured_at, sessions: <list_sessions data>, activity_at: {id: unix seconds}}`,
     ≤300s old, non-empty, unique ids; `--claude-snapshot PATH` + `--exclude-thread <own session>`.
   - Candidates: `environment_kind == "anthropic_cloud"` only (bridge sessions are local and owned
     by the local adapter), `session_status == "SESSION_STATUS_IDLE"`, `updated_at` within
     `--hours`, not excluded. Activity is required for each candidate; missing → abort.
   - Activity = the inner turn `timestamp` of the newest user/assistant event, else its
     `created_at`. The native procedure pages `list_events` with `before_id` (bounded, 5 pages)
     until one appears, because `kinds` filters after the page is read and a page can hold none;
     `list_sessions` is paged on `has_more` up to 100 sessions.
   - Report `renamed` proposals with observed old title; `execution: native-tools-required`.
3. **CLI wiring** (`task_sync.py`): `ADAPTERS += ("claude", "claude-cloud")`; `_build_adapter`
   maps both to `adapters/claude.py`; `--claude-root`, `--claude-snapshot`. The Codex-only
   plan-only guard, required-argument checks and doctor receipt skip become a `PLAN_ONLY =
   ("codex", "claude-cloud")` set. Default `--ide zcode,agy` unchanged.
4. **Docs** (`task-sync/SKILL.md`): description/when_to_use mention Claude Code; a "Claude Code
   (GH-1105)" section with the local semantics and the cloud native-sweep procedure
   (list_sessions → list_events → snapshot → plan → recheck → `set_session_title` → read back).
   **Single scheduler:** local Claude Code joins the one existing heartbeat
   (`--ide zcode,agy,claude`), whose prompt also handles `needs_summary` from the `claude`
   section; no second local writer. The summary source is the transcript's last `last-prompt` record, else the last user message text.
   Cloud titles have exactly one writer, a Claude Code scheduled
   task running the native sweep (the same exception the Codex native heartbeat already has).
   Install SOP step 2 gains Claude Code `~/.claude/skills/task-sync`.
5. **Skills Army HQ deployment to Claude Code (requirement 2, docs only):**
   `references/targets.md` row becomes "Claude Code (CLI, desktop app, VS Code extension)".
   The per-device operator step (run on each Mac, not from a cloud container):
   `intake.py targets` (record before) →
   `intake.py --apply targets --id claude --path ~/.claude/skills --consumer "Claude Code CLI, desktop app and VS Code extension"`
   → `sync.py` preview → `sync.py --apply` → `sync.py --status`. Enabling the target links
   **every** collection skill into `~/.claude/skills`; an existing same-name folder or foreign link
   is reported and preserved, not overwritten (resolve with `--adopt`/`--migrate` per the skill).
   Rollback: `intake.py --apply targets --id claude --disable` then `sync.py --apply`.

## Bet check

- *Outcome:* the Claude Code session list shows each session's last-worked date at a glance.
- *Smallest bet:* one adapter file + CLI wiring + docs. Not built: pins, summaries generated by
  the CLI, a scheduler, skills-army-hq code changes.
- *Rejected alternative:* use only cloud `set_session_title` for everything. Local CLI/desktop
  sessions not attached via Remote Control would be missed, and bridge renames aren't documented
  to write back to the local transcript.
- *Rollback:* revert the PR. Stamped sessions keep their titles. The adapter only appends, so
  each earlier `custom-title` line stays in the transcript and an undo is one more record with
  that value. Not fully reversible: a session that only had an AI title now has a `customTitle`
  that outranks later AI titles, so its description is frozen at the AI title seen when stamped.
  Refreshing it from newer `ai-title` records was considered and rejected for this PR
  (it can't tell an AI title from an operator `/rename`).

## Risks

- Undocumented local format may change → the doctor names the missing record shapes; the adapter
  refuses rather than guessing.
- Concurrent append from a live session → running-session registry (fail closed) + 10-minute
  backstop + size/mtime precheck + single `O_APPEND` line write.
- The mtime restore also hides the append from mtime-based file watchers, and a write landing
  between the post-write size check and the restore gets its mtime rolled back (ordering only).
  Accepted: running sessions and those active in the last 10 minutes are skipped.

## Verification (no new test/ suites)

Manual probes against fixture roots in `temp/`, recorded under
`TESTS-RESULTS/2026-10-17+GH-1105/`:

1. Stamp happy path: fixture with an `ai-title` and `…Z` activity 2 days ago → `renamed`
   proposal, `--apply` appends exactly one line, mtime unchanged, re-run is a no-op.
2. Red controls (each must leave the fixture byte-identical): missing root → error, exit 3;
   no trailing newline → skipped; file changed between read and write → skipped; activity inside
   10 minutes → skipped; session in the running registry → skipped; unreadable registry → error;
   `agent-name` session → skipped; no title → `needs_summary`; doctor with a transcript missing
   `timestamp` → red naming it; unparseable pid file → error; missing registry dir → treated as
   nothing running. On the Mac (operator): confirm CLI, desktop and VS Code sessions each write
   `~/.claude/sessions/<pid>.json`.
3. Sidecar: sidecar holds title A, no `custom-title` in the tail → proposal re-stamps A; after
   apply, a re-run is a no-op.
4. Cloud planner: fresh snapshot → proposals only for idle `anthropic_cloud` sessions (a
   `bridge` and a running session in the fixture get none); stale snapshot, missing activity,
   `--apply`/`--set-title` → refused.
5. Existing behavior: `--ide zcode,agy` and `--ide codex` paths unchanged (argparse help + a codex
   snapshot probe). The route-selected gate on the final commit.
6. Requirement 2 is operator-run per device (cloud containers can't reach the Mac); the SOP
   above names the before/after evidence to record (`intake.py targets`, `sync.py --status`,
   resolved `~/.claude/skills/task-sync` link, the skill listed in Claude Code).

Receipts under `TESTS-RESULTS/2026-10-17+GH-1105/` with `provenance.jsonl` (AGENTS.md).

## Plan QA

Independent review (Claude subagent; the operator chose it because this cloud session has no
Codex CLI), round 1: Changes requested, 6 Major / 6 Minor / 2 Nit, no blockers. All accepted and
folded in above (sidecar-aware label, running-session gate, single scheduler, requirement-2 SOP
and rollback, append-only undo wording, cloud paging, `Z` parsing, CLI generalization, guarded
mtime restore, red controls, rating and risk). The AI-title refresh suggestion was considered and
rejected (see Rollback). Round 2: Approved; its Minor (missing registry = nothing running, red
control each way, Mac probe that CLI/desktop/VS Code sessions all write a pid file) and two Nits are
folded in.

## Rating rationale (2026-10-17)

`rated 55/25/50/55`. Severity 25: a convenience gap with no data loss or blocked work. Priority 55:
the operator asked for it now. Appeal 50: neutral (no explicit score given). Effort 55 (re-rated
from 65 after plan QA): two adapters (one writes, one plans), CLI generalization, docs and the
install SOP. Recurrence: not applicable (a feature, not a defect).

## Final QA

Independent final review (Claude subagent), round 1: Changes requested, 2 Major / 2 Minor /
4 Nit. Fixed: `provenance.jsonl` and the probe script committed with the receipt; the cloud
procedure runs the planner with the operator's `TZ` (cloud containers are UTC); the Install SOP
heartbeat command includes `claude`; the doctor checks the 20 newest transcripts for a timestamp
and a known title record shape. Nits: the typed-record read is commented; the remaining nits
(unparseable cloud `updated_at` skips, dry-run vs apply on a no-newline file, the generic
`found: false` on a refused set-title) are left as they are and harmless.

Round 2: Approved; its Minor (the live read-only receipt mis-stated the doctor exit code) is corrected in
`provenance.jsonl`.
