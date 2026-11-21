# GH-1196 live smoke — pin one idle Claude Desktop session

- Base: `0db33392` plus the working-tree change under review. One Mac, Claude Desktop Code session, bypass permissions mode.
- IDs, titles and paths are sanitized; this repo is public.

| Step | Result |
|---|---|
| `list_sessions(limit=100)` | 6 rows: 2 already pinned, 4 unpinned, all idle and active today |
| Planner (`--ide claude-desktop`, own session excluded) | exit 0, `error: null`; 4 pin proposals, 2 rename proposals |
| Pin proposals | 3 of the 4 were this Mac's own hourly task-sync scheduled runs (`get_session` shows `scheduledTaskId`); 1 was an ordinary session |
| Finding | A scheduled task starts a new session every run, so pinning them would add a pin an hour, and a pinned session is never auto-archived. The SKILL pin step now skips any session whose `get_session` has a `scheduledTaskId`. The planner can't see that field (`list_sessions` rows don't carry it), so this is a procedure rule. |
| Recheck (fresh `list_sessions` + `get_session`) on the ordinary session | still present, not archived, idle, `pinned` missing, no `scheduledTaskId`, activity inside 24 h |
| `set_pinned(<id>, true)` | "Session pinned." |
| Re-read `list_sessions` | `pinned: true`; `lastActivityAt` unchanged (a pin isn't activity) |
| Planner rerun on a fresh snapshot | the pinned session is no longer proposed; only the 3 scheduled runs remain, which the procedure skips |
| Receipt | one `{"at", "session_id", "op": "pin"}` line appended to the machine-local receipt |
| Rename proposals | not applied in this smoke (titles are GH-1191's and unchanged) |

Not witnessed: an unattended default-mode run applying a pin. The hourly scheduled task stays titles-only (#1191 step 4); pinning another session asks first in default mode, so an unattended run would decline.
The pin is kept; whether to unpin it is the operator's call.
