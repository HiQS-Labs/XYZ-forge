# GH-752 re-check (2026-11-27): no longer reproduces

This is the Day 3 (#1611) raw-candidate check. The re-fire halting at p1 no longer happens on `development`.

- **Tested commit:** `76808a53b73de06c617b3404af6400ee09cc1a54`, in a disposable full clone (`~/flywheel-day3-repro752`).
- **Command:** `python3 TESTS-RESULTS/2026-10-13+GH-1042/manual-replay.py --expect-fixed` → **exit 0**. All 34/34 checks matched their expected exit codes (`results.json`).
- **The #752 scenario:** `seed-two-phase` (exit 0) approves and attests p1, then a later commit lands. `two-phase-later-retry` runs `marathon.sh --plan … --retry p2` (exit 7, expected). The log (`two-phase-later-retry.log`) shows `phase p1 complete — lane_already_satisfied`, then p2 dispatching `MARATHON-P2-TURN-2`. The exit 7 comes from the fixture's always-failing builder stub at p2, which proves the run got past p1.
- **Why:** #1042/#1045 (commit `0275a7a0a`, PR #1054) record a `phase_completion` candidate. On re-fire, the phase is validated against that candidate instead of current HEAD.
- **Still strict by design:** approvals recorded before #1045 have no completion record and still refuse (`legacy-later-refuses`, exit 4); `--force` rebuilds them.
- Evidence comment: https://github.com/HiQS-Labs/XYZ-forge/issues/752#issuecomment-7221878085. It recommends closing as fixed by #1045 and leaves the issue open for the maintainer.

The first attempt ran inside the Claude Code Bash sandbox and failed with `marathon.sh: line 528: /dev/fd/62: Operation not permitted`, a sandbox limit rather than a product result. The recorded run was unsandboxed.
