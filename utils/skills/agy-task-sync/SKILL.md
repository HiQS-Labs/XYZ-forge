---
name: agy-task-sync
description: >-
  Antigravity-only task automation: auto-prefix conversation titles with today's US date (MM-DD),
  update sidebar task previews with the last action taken, manage the Pinned group, and schedule
  runs on a 15-minute recurring cadence. Use when asked to manage Antigravity task titles, update
  task descriptions from transcripts, organize pinned sessions, or automate recurring task maintenance.
---

# Antigravity Task Synchronizer (`agy-task-sync`)

Automates conversation and task hygiene specifically inside Google Antigravity (AGY):
1. **Auto Date Prefixing:** Prefixes task titles with today's US date (`MM-DD`, e.g. `09-29`), replacing stale previous dates while preserving custom titles.
2. **Last Action Previews:** Inspects session transcripts to extract the latest tool execution or response, updating the sidebar description preview.
3. **Auto-Pin Management:** Maintains target active tasks inside the Antigravity `Pinned` group across SQLite and Electron state.
4. **15-Minute Cadence:** Runs on-demand, continuously via daemon, through native Antigravity `/schedule`, or as a headless macOS `launchd` background job.

> [!IMPORTANT]
> **Antigravity-Only Surface:** This skill directly interfaces with Google Antigravity's local storage engine (`~/.gemini/antigravity/` and Electron's `~/Library/Application Support/Antigravity/app_storage.json`). It is not applicable to plain Claude CLI, Codex CLI, or external harness runners.

---

## Architecture & Storage Points

Antigravity persists session metadata across three synchronized storage layers:

| Layer | Path | Role |
|---|---|---|
| **Summaries Database** | `~/.gemini/antigravity/conversation_summaries.db` | SQLite database storing `title`, `preview` (subtitle description), `status`, and timestamps. |
| **Session Annotations** | `~/.gemini/antigravity/annotations/<conversation-id>.pbtxt` | Protobuf text record storing `title:"..."`, `last_user_view_time`, and `pinned:true`. |
| **App Storage (Electron)** | `~/Library/Application Support/Antigravity/app_storage.json` | JSON store holding `pinned_conversations_order` (the array of pinned conversation UUIDs). |
| **Session Transcripts** | `~/.gemini/antigravity/brain/<id>/.system_generated/logs/transcript.jsonl` | Append-only JSONL log containing step-by-step tool calls, arguments, and planner responses. |

---

## Core Operations

The core script is located at `utils/skills/agy-task-sync/scripts/agy_task_sync.py`.

### 1. Inspect Pinned Tasks
Inspect all currently pinned tasks, their titles, runtime statuses, and extracted last actions:

```bash
python3 utils/skills/agy-task-sync/scripts/agy_task_sync.py --list-pinned
```

### 2. Dry-Run Sync (Safe Preview)
Simulate date prefixing and description updates for pinned tasks without committing changes:

```bash
python3 utils/skills/agy-task-sync/scripts/agy_task_sync.py
```

### 3. Apply Updates to Pinned Tasks
Update titles with today's `MM-DD` date and refresh previews with the last action:

```bash
python3 utils/skills/agy-task-sync/scripts/agy_task_sync.py --apply
```

### 4. Process All Recent Sessions
To sync all active sessions from the last 48 hours (not just pinned ones):

```bash
python3 utils/skills/agy-task-sync/scripts/agy_task_sync.py --all --apply
```

### 5. Add Conversations to Auto-Pin Group
Ensure specific tasks are pinned in both `annotations/<id>.pbtxt` and `app_storage.json`:

```bash
python3 utils/skills/agy-task-sync/scripts/agy_task_sync.py --id <conversation-id> --auto-pin --apply
```

---

## 15-Minute Recurring Cadence Setup

You can schedule this automation to run every 15 minutes using either of two methods:

### Option A: In-Session Antigravity Schedule (Native Tool)
When working within an active Antigravity session, recommend or trigger the `/schedule` command or call the `schedule` tool:

```json
{
  "CronExpression": "*/15 * * * *",
  "Prompt": "Run agy-task-sync to update today's task titles with MM-DD dates and refresh previews with last actions: python3 utils/skills/agy-task-sync/scripts/agy_task_sync.py --apply",
  "IsDaemon": true
}
```

### Option B: Background Daemon (Headless)
Run the script continuously in background mode with a 900-second (15-minute) sleep interval:

```bash
python3 utils/skills/agy-task-sync/scripts/agy_task_sync.py --apply --daemon --interval 900
```

### Option C: macOS launchd Service (System Level)
For permanent headless automation that survives IDE restarts:

1. Create `~/Library/LaunchAgents/com.antigravity.task-sync.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.antigravity.task-sync</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>/Users/noelsaw/Documents/GH Repos/XYZ-forge/utils/skills/agy-task-sync/scripts/agy_task_sync.py</string>
        <string>--apply</string>
    </array>
    <key>StartInterval</key>
    <integer>900</integer>
    <key>StandardOutPath</key>
    <string>/tmp/agy_task_sync.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/agy_task_sync.err</string>
</dict>
</plist>
```
2. Load the service:
```bash
launchctl load ~/Library/LaunchAgents/com.antigravity.task-sync.plist
```
