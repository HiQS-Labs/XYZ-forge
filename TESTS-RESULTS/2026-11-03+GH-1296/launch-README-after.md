# Launch packet: wave 1 (slot_015)

> draft; preflight and independent plan QA outstanding

Nothing here has been launched. Each folder is one marathon for one lane; lanes in a wave are
write-disjoint, so each can run in its own clone at the same time. Copying a folder into
`PROJECT/2-WORKING/` of a clone is the approval step.
The builder must differ from the reviewer (`codex`), so the commands pass `--builder agy`.

## Lanes

- #670: `GH-670-LAUNCH/`
  - `cp -R GH-670-LAUNCH <clone>/PROJECT/2-WORKING/`
  - `relay-automation/marathon.sh --plan PROJECT/2-WORKING/GH-670-LAUNCH/MARATHON.yaml --builder agy --dry-run`
- #1267: `GH-1267-LAUNCH/`
  - `cp -R GH-1267-LAUNCH <clone>/PROJECT/2-WORKING/`
  - `relay-automation/marathon.sh --plan PROJECT/2-WORKING/GH-1267-LAUNCH/MARATHON.yaml --builder agy --dry-run`
- #1265: `GH-1265-LAUNCH/`
  - `cp -R GH-1265-LAUNCH <clone>/PROJECT/2-WORKING/`
  - `relay-automation/marathon.sh --plan PROJECT/2-WORKING/GH-1265-LAUNCH/MARATHON.yaml --builder agy --dry-run`
- #1266: `GH-1266-LAUNCH/`
  - `cp -R GH-1266-LAUNCH <clone>/PROJECT/2-WORKING/`
  - `relay-automation/marathon.sh --plan PROJECT/2-WORKING/GH-1266-LAUNCH/MARATHON.yaml --builder agy --dry-run`
- #1204 (provisional): `GH-1204-LAUNCH/`
  - **Not launchable yet** (preflight would refuse it): no Preflight Contract in the capture doc (preflight exits 3)
- #216 (provisional): `GH-216-LAUNCH/`
  - **Not launchable yet** (preflight would refuse it): no Preflight Contract in the capture doc (preflight exits 3)
- #446 (provisional): `GH-446-LAUNCH/`
  - **Not launchable yet** (preflight would refuse it): no Preflight Contract in the capture doc (preflight exits 3)
- #1175 (provisional): `GH-1175-LAUNCH/`
  - **Not launchable yet** (preflight would refuse it): no Preflight Contract in the capture doc (preflight exits 3)
- #1317 (provisional): `GH-1317-LAUNCH/`
  - **Not launchable yet** (preflight would refuse it): no Preflight Contract in the capture doc (preflight exits 3)
- #1315 (provisional): `GH-1315-LAUNCH/`
  - **Not launchable yet** (preflight would refuse it): no Preflight Contract in the capture doc (preflight exits 3)

## Skipped

- none
