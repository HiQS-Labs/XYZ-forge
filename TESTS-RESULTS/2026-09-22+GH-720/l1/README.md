# GH-720 L1 (marathon GH-749 phase p1) — gate evidence

- Lane commit: `45b7d2cd` (codex), reviewed by agy → Approved (`8d8b6d9f`), see `lane-commit-45b7d2cd.stat`.
- Gate under the driver: refused 406/410 (`validate-nested-under-driver-EXCERPT.log`). One real miss — stale
  `relay-pkg.tar.gz` after `new-relay.sh` changed — fixed by `make-pkg.sh` (commit `396d6978`). The other two,
  `marathon-drive.sh` (GH-171 case) and `gh280-jog-marathon-adapter.sh` (E4), exit 8 only when nested inside a
  live `marathon-drive.sh`: open issue #507 (vendored fixture shares the `p1`/`MARATHON-P1-TURN` shape with the
  real lane).
- Standalone proof: `validate-standalone-396d6978.log` — **410/410**, all three suites `rc=0`, no driver running.
- Re-fire: `--pre-advance-cmd 'bash validate.sh --skip marathon-drive.sh --skip gh280-jog-marathon-adapter.sh'`
  for the remaining chain, per #507's documented workaround; a `--skip` run is not promotion evidence on its own —
  this standalone run is the evidence. #507 owns the durable fix; this is a labelled bridge, not a fix.
