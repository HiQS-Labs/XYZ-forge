# GH-854 daily staging qualification — 2026-09-29 PT

Target: `staging/stabilize-2026-10` at `a66407cfdb7cc3ec1ad163fffdfc79410d69bfb2`. The remote tip matched before and after the checks.

## Local Mac gate

`caffeinate -i bash ci-local.sh` ran in a separate disposable full clone on `noels-Mac-Studio`. It exited 0 after **3,568.603 seconds** (2026-09-29 23:07:06 UTC to 2026-09-30 00:06:34 UTC). All 9 stages passed. The gate record contains **412 passing and one skipped suite verdict** for a declared registry of 411; `acorn-extract.sh` was skipped in the registry loop because its stage had already run above. The clone-identity invariant reported no drift. The clone's `HEAD`, `core.bare=false`, origin URL, and local user identity were unchanged afterward. The full gate record and JSONL telemetry are committed beside this summary. This local run is self-reported and is not promotion evidence.

## Hosted staging dispatch

[CI run 36643711275](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36643711275) was dispatched at the same SHA. Blocking `vendored-smoke` succeeded. Advisory `canary-ubuntu` succeeded with **411/411** and zero re-runs; `gh153-releases-sidebar-rollup.sh`, `gh478-runaway-guard.sh`, and `gh425-gate-provenance-pr.sh` each returned `rc=0`. The macOS promotion job was skipped on this staging dispatch, as configured.

## Daily metrics

- M1: no fix PR became ready or merged during this daily interval, so queue wait is not applicable.
- M2: zero PR-closed hosted Large runs for these staging fixes; this dispatch ran the Ubuntu canary and vendored smoke.
- M3: zero failures in suites outside the edited area in today's local full run.

The #886 capture and roadmap row are later governance work and were not part of the checked SHA.
