# GH-1230: earlier batteries re-run, expected deltas

Re-run against this branch: `gh1191-probes.log` (16/17) and `gh1196-probes.log` (9/11). Every
failure is a behaviour this fix changes on purpose; no other probe moved.

| Battery | Probe | Old expectation | Now | Why |
|---|---|---|---|---|
| GH-1191 | archived/running/self/old skipped | running and 2-day-old rows skipped | both proposed; archived and self still skipped | R3 (running rows) and R2 (no age window) |
| GH-1196 | running -> pin, no rename | pinned, not renamed | pinned **and** renamed | R3 |
| GH-1196 | --no-pin -> no pins | no pins; only the idle row renamed | no pins; the running row is renamed too | R3; the pin assertion still holds |

Red control (`red-control.log`): the new battery against the pre-fix planner fails exactly the
four probes for running rows, old rows and `--hours`, and passes the four fail-closed probes.
