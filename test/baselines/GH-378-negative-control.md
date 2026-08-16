# GH-378 — recorded negative control (#419)

Test:     `test/gh378-gate-requires-green-suite.sh`
Baseline: `commit b8fce265f02c6767faee169116e91f1659714856` — `utils/py/marathon_drive.py`
Date:     2026-08-15

## Defect Summary

Before GH-378, `run_pre_advance_gate()` in `utils/py/marathon_drive.py` treated any non-zero exit code as an immediate failure, escalating with `pre-advance-failed` and halting the marathon. Target repositories with pre-existing suite failures before phase 1 could not run marathons even if the phase changes introduced no new regressions.

## Verification & Controls

`test/gh378-gate-requires-green-suite.sh` verifies that:
1. `decisions/2026-08-10-marathon-gate-baseline-strategy.md` decision record exists and documents the baseline strategy (Option 1c + Option 4).
2. **Positive Control:** When `--pre-advance-baseline 1` (or `MARATHON_GATE_BASELINE=1`) is configured, a phase running on a target with pre-existing failure exit 1 advances successfully.
3. **Negative Control (Regression):** When a phase introduces a new regression worsening the exit code (exit 2 > baseline 1), the phase halts and escalates with `pre-advance-failed`.
4. **Negative Control (Unconfigured):** When no baseline allowance is set, a non-zero exit code halts and escalates with `pre-advance-failed`.
5. `README.md` and `relay-automation/MARATHON.example.yaml` document `--pre-advance-baseline` and disclose its guarantees.
