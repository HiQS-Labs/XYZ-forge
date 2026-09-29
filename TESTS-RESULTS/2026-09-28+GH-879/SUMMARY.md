# GH-879 skill rules and GH-139 N5 guard

Target: `staging/stabilize-2026-10` at `d92df347f354d6337ec9d58b0a7e2ab0bfc99539` before these edits. Checks ran in a separate full clone under `temp/gh879-n5-verify/`; the task clone's `.git` state was not exposed to the suites.

## GH-879 manual decision checks

- The independent source count on the target is 411 `TESTS` entries and 13 top-level `EXEMPT` names, with empty intersection. All eight GH-831 calibration suites are in `EXEMPT` and absent from the target registry. The newest `validate.sh` commit is `b2c307b4e6be45f105b5d1030d75578d91572db2` (2026-09-26).
- Existing `validation/measured.json` reports `gh610` 6/105, `gh123` 2/107, and `registry-lock-concurrency` 2/107, each with same-SHA divergence. #854's newer handoff says no red since 2026-09-25; the skill now keeps them at INVESTIGATE until an ongoing failure or landed fix is established.
- The same measured file gives `gh798-status-skill.sh` 16 document greps among 21 assertions (0.76), and `registered:false`. The calibration rule requires the same scoring pass as the target rows and a stop before publication if calibration fails.
- Red-rule witness: the old skill said a log-only LOW-confidence suite could not get a non-KEEP verdict, and the heavy-suite fallback assigned KEEP without the rule-7 evidence. A log-only suite with no source read is now INVESTIGATE; no target-row publication is allowed on a failed calibration.

These are method checks, not a new full audit. The #854 handoff schedules the full audit for 2026-10-08 after Landing 2.

## GH-139 N5 measurement and red control

- Old literal `| grep -q` inventory: 11 lines in 5 files. Widened matcher: **81 lines in 27 files** on this target; 16 lines start with a comment, and 65 are code lines. The baseline pins those existing per-file counts. Baseline entries are inventory, not a claim that all sites are safe under `pipefail`; #853 owns further suite-isolation cleanup.
- Existing `test/gh139-pipe-grep-guard.sh` on the widened baseline: 3 pass, 0 fail.
- Injecting one extra `printf "x" |grep -Fq x` line into an existing disposable-clone suite made the guard fail: `gh75-dashboard.sh grew from 1 to 2` (exit 1). The same result held for `-iq`, `--quiet`, `-qF`, and `-F --quiet`.
- Replacing that probe with `false || grep -Fq x <<<"x"` passed (3 pass, 0 fail). The existing `gh460-pipe-buffer-sigpipe.sh` suite passed 12/12. The disposable file was restored from a byte copy, not Git checkout/reset.

No new suite, registry entry, or gate machinery was added.
