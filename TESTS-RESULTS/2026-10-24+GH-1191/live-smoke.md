# GH-1191 live smoke: Claude Desktop native sweep (one device, 2026-10-24)

Followed `SKILL.md` → "Claude Desktop (GH-1191)" verbatim from a Claude Desktop Code session on macOS.
Sanitized: `<self>` is the sweeping session, `<target>` the one other Desktop session (idle, app-generated title "<T>").
Desktop record path `~/Library/Application Support/Claude/claude-code-sessions/<account>/<org>/local_<id>.json`, read only.

| Step | Command / tool | Observed | Verdict |
|---|---|---|---|
| 1 | `list_sessions(limit=100)` | 1 row: `<target>`, `isArchived:false`, `isRunning:false`, `lastActivityAt` 18:22:40.603Z | PASS |
| 2 | `task_sync.py --ide claude-desktop --desktop-snapshot temp/desktop-snapshot.json --exclude-thread <self>` | exit 0, error null, 1 proposal `"<T>"` → `"10-24 <T>"` | PASS |
| 3 | `get_session(<target>)` recheck | same title, not archived, not running, not `<self>`, same `lastActivityAt` | PASS |
| 4 | `set_session_title(<target>, "10-24 <T>")` | "Renamed session … (was "<T>")" | PASS |
| 5 | `get_session(<target>)` re-read; receipt append | title `"10-24 <T>"`; one line in `~/.cache/task-sync/claude-desktop-renames.jsonl` | PASS |
| Adjacent: rerun | fresh `list_sessions` → planner again | exit 0, swept 1, renamed 0 (idempotent) | PASS |
| Untraced 1 | `lastActivityAt` after rename (`get_session` and record) | unchanged (18:22:40.603Z; record 1792866160603 before and after) | Rename does not bump activity |
| Untraced 2 | record `titleSource` before → after | `auto` → `tool` (`titleTurn` 0 → 2) | A native rename is marked `tool`, not user-set |
| Undo | `set_session_title(<target>, "<T>")` from the receipt, then re-stamp | restored to `"<T>"`, then `"10-24 <T>"` again | PASS |

Also on this device: the session list showed the new title on re-read; the sweeping session (`<self>`, running) was never a candidate.

Not covered here:
- **Unattended decline:** this session ran in bypass permissions mode, where `set_session_title` never asks, so whether an unattended run may re-stamp a `tool`-sourced title without approval is unwitnessed. The first scheduled run on a device (#1191 step 4) must show it.
- **Visual check:** the sidebar wasn't checked by eye. The agent session can't see the Desktop window, so the operator does this check. The evidence for R3 is native state (`get_session`, `list_sessions`) plus the app's own session record, whose `title` the sidebar is drawn from, which read `"10-24 <T>"` after the rename.
