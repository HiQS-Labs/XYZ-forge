# GH-1191 step 4: first unattended Desktop scheduled run (one device, 2026-10-24)

Scheduled task `task-sync-desktop-titles` (hourly at :22) was created from a Desktop Code session. Its prompt is the procedure in `SKILL.md`, "Claude Desktop (GH-1191)", titles only, run from `~/git-pulse-sync/Deployed Skills/task-sync`. One run was started with "Run now"; it starts exactly as a scheduled run does.

| Fact | Observed |
|---|---|
| Permission mode | Default mode (the creating session's bypass mode is **not** saved with the task); nobody present |
| Duration | ~40 s, status `succeeded` |
| Run's report | `task-sync desktop: proposed=2 renamed=1 skipped=0 declined=1` |
| App-generated title | Renamed (stamp added; one undo line appended to `~/.cache/task-sync/claude-desktop-renames.jsonl`) |
| Operator-set title | **Declined** by `set_session_title`: it needs approval and nobody could give it. The run continued (not an error) and reported it under `declined=1`, separate from `skipped=0` |
| Script call | The `task_sync.py` Bash call did not block the run |
| Run session record | Carries `scheduledTaskId: task-sync-desktop-titles` |

Session IDs and titles are omitted (public repo).

Not yet witnessed: re-stamping a title already marked `titleSource: tool` on a later day, which needs a date change.
