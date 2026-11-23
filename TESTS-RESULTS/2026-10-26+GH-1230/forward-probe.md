# GH-1230 step 0: forwarding probes (2026-10-27, one device, sanitized)

Session ids and titles are replaced with roles. All runs were ad-hoc Desktop scheduled tasks
saved in bypass permissions mode; the receiver was an interactive Desktop session started in
bypass mode with the sweeper's standing instruction.

| Probe | Route / check | Result |
|---|---|---|
| 0a-1 | `SendMessage` from a scheduled run, `to` = the receiver's title | **Fails.** `ListAgents` is not available in the run, and the send returns `No agent named '<receiver>' is reachable.` |
| 0a-2 | `mcp__ccd_session_mgmt__send_message` from a scheduled run, by session id | **Works.** `delivery: delivered; ... its turn has started on it`. The receiver rechecked and renamed the target, `renamed=1 skipped=0 declined=0`. |
| 0a-3 | The receiver's turn renames a title the operator typed | Pending: no `titleSource: user` session exists on the device, and none can be made by a tool (`start_session` and `set_session_title` both record `tool`). The earlier deciding probe showed an interactive bypass session renames one on a turn no person started (session timer). The live check renames one once the operator has typed a title. |
| 0b | Forward still wakes the receiver after a Desktop restart | Pending: restarting the app ends the session running the probes. Checked live at the next restart. |
| 0c | A scheduled run can create a session (`start_session`) | **No.** The tool is not offered to scheduled runs. A missing sweeper is therefore reported as `forward_failed` on every run until the per-device setup recreates it. |
| extra | A scheduled run can archive a finished run of a scheduled task | **Yes.** `archive_session` is offered and archived the finished probe run; `list_task_runs` is also offered. |
| extra | A scheduled run renames a tool-set title directly | **Yes**, without approval. |

Decision: step 3a with the `send_message` route. SendMessage is not used.
