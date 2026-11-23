# GH-1230 live check (2026-10-27, one device, sanitized)

The device's existing 30-minute task-sync scheduled task was pointed at this branch's SKILL.md and
script for two witnessed runs, then the device's `task-sync sweeper` was started and pinned by the
setup session. Ids and titles are replaced with roles.

| Check | Result |
|---|---|
| R3: a running session renamed, title persists | The session driving this work was running when run 1 renamed it from a 10-26 stamp to 10-27; `get_session` still showed the new title after many later turns. |
| R2: an old wrong stamp corrected | Run 1 re-stamped a run session last active two days earlier (10-24 to 10-25, its local activity date). Before the fix the 24 h window hid it. |
| R4: inventory complete | Run 1 read 93 rows, run 2 read 79, both from `limit=500`, so neither was cut off. Run 1 (via `list_task_runs`) archived 15 of the task's own day-old runs and showed the 50-run cap would strand older ones; run 2 (inventory plus `get_session`) archived the remaining 27. Three other day-old sessions without the task's `scheduledTaskId` were left alone. |
| Sweeper lookup | Run 1 proposed stamping the sweeper, which would break an exact-title lookup; the run held it back. The procedure now matches the title with or without one leading stamp, and run 2 stamped the sweeper and still found it. |
| R1: forwarded rename | A forwarded rename of a tool-set title worked from a scheduled run (`forward-probe.md`, 0a-2). No session on the device has a title the operator typed, so a forwarded rename of one has not happened yet; neither run had a decline to forward. |
| R5 | Neither run needed an operator step; the reports carry no approval state. |
| forward_failed | Not exercised live: the sweeper existed for both runs. |
