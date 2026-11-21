# Launch packet: wave 1 (slot_015)

> draft; preflight and independent plan QA outstanding

Nothing here has been launched. Each folder is one marathon for one lane; lanes in a wave are
write-disjoint, so each can run in its own clone at the same time. Copying a folder into
`PROJECT/2-WORKING/` of a clone is the approval step.
The builder must differ from the reviewer (`codex`), so the commands pass `--builder agy`.

## Lanes

- #722: `GH-722-LAUNCH/`
  - `cp -R GH-722-LAUNCH <clone>/PROJECT/2-WORKING/`
  - `relay-automation/marathon.sh --plan PROJECT/2-WORKING/GH-722-LAUNCH/MARATHON.yaml --builder agy --dry-run`
- #670: `GH-670-LAUNCH/`
  - `cp -R GH-670-LAUNCH <clone>/PROJECT/2-WORKING/`
  - `relay-automation/marathon.sh --plan PROJECT/2-WORKING/GH-670-LAUNCH/MARATHON.yaml --builder agy --dry-run`
- #1204 (provisional): `GH-1204-LAUNCH/`
  - `cp -R GH-1204-LAUNCH <clone>/PROJECT/2-WORKING/`
  - `relay-automation/marathon.sh --plan PROJECT/2-WORKING/GH-1204-LAUNCH/MARATHON.yaml --builder agy --dry-run`
- #216 (provisional): `GH-216-LAUNCH/`
  - `cp -R GH-216-LAUNCH <clone>/PROJECT/2-WORKING/`
  - `relay-automation/marathon.sh --plan PROJECT/2-WORKING/GH-216-LAUNCH/MARATHON.yaml --builder agy --dry-run`
- #446 (provisional): `GH-446-LAUNCH/`
  - `cp -R GH-446-LAUNCH <clone>/PROJECT/2-WORKING/`
  - `relay-automation/marathon.sh --plan PROJECT/2-WORKING/GH-446-LAUNCH/MARATHON.yaml --builder agy --dry-run`

## Skipped

- none
