# Launch packet: wave 1 (slot_010)

> draft; preflight and independent plan QA outstanding

Nothing here has been launched. Each folder is one marathon for one lane; lanes in a wave are
write-disjoint, so each can run in its own clone at the same time. Copying a folder into
`PROJECT/2-WORKING/` of a clone is the approval step.
The builder must differ from the reviewer (`codex`), so the commands pass `--builder agy`.

## Lanes

- #1295: `GH-1295-LAUNCH/`
  - **Not launchable yet** (preflight would refuse it): no frozen capture identity; create a new snapshot and proposal before packet
- #670: `GH-670-LAUNCH/`
  - **Not launchable yet** (preflight would refuse it): no frozen capture identity; create a new snapshot and proposal before packet
- #1204 (provisional): `GH-1204-LAUNCH/`
  - **Not launchable yet** (preflight would refuse it): no Preflight Contract (the capture doc has none, or there is no capture doc)
- #446 (provisional): `GH-446-LAUNCH/`
  - **Not launchable yet** (preflight would refuse it): no Preflight Contract (the capture doc has none, or there is no capture doc)

## Skipped

- none
