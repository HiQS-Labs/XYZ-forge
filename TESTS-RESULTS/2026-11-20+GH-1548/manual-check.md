# Manual Check — GH-1548 (KS-05: Verbatim Stop Reasons, Fresh Turn Logs, and U13 429→provider-quota)

- **Date:** 2026-11-20
- **Code Head Verified by Full Gate:** `b280e6709ce93b7e89676d0ac61c859bce119968`
- **Changed Files Covered (`outputs/code-and-docs.patch`):** `utils/py/relay_drive.py`, `utils/py/harness.py`, `skills/1-hourly/relay-xyz/SKILL.md`
- **Route:** `full` (`outputs/ci-route.txt`; touches `utils/py/` core harness code)

## 1. Full Disposable-Clone Gate R2 (`outputs/disposable-full-gate.log` + `outputs/disposable-full-gate.done.json`)
- Executed `./validate.sh` detached in a fresh disposable full clone of exact code head `b280e6709ce93b7e89676d0ac61c859bce119968` with `mypy==1.14.1` on `PATH`.
- Complete `PRE-GATE SNAPSHOT` and `POST-GATE SNAPSHOT` recorded in `outputs/disposable-full-gate.log`: `HEAD=b280e6709ce93b7e89676d0ac61c859bce119968`, `core.bare=false`, `origin` preserved, local `user.email` unset (`rc=1`, unchanged), `git status --short` clean (`''`).
- Result: **`validate_rc=0`**, `elapsed_s=996`, including `test/gh648-l7-checkout-aftermath.sh`, `python:test_python_layer.py`, `clone-identity-invariant`, and `gamma-poison-staleness-probe`.

## 2. Targeted Red/Green Controls (`outputs/manual-controls.txt`)
- **Control 1 (`CONTROL_1_STALE_OVERWRITE_NO_ACTION_STALL`, exit 3):** Pre-seeded stale `.relay-scratch/escalation-reason` (`cap-stalled`) and stale `relay-drive-RELAY-KS05-1.log` (`STALE_OLD_RUN_LOG_LINE`); invoked real `relay_drive.py --review-once` with no-op shim; verified legacy `escalation-reason` overwritten to `no-action-stall`, per-invocation JSON receipt created with `reason="no-action-stall"` and `exit_code=3`, and stale legacy log untouched.
- **Control 2 (`CONTROL_2_U13_PROVIDER_QUOTA`):** Verified `is_provider_quota_error` classifies 429 / quota / rate-limit errors as `True` and non-quota failures as `False`.
- **Control 3 & 4 (`CONTROL_3_AND_4_429_PROVIDER_QUOTA_FRESH_RECEIPT`):** Invoked real `relay_drive.py --review-once` with HTTP 429 quota shim; verified verbatim `provider-quota` stop reason and distinct per-invocation receipt (`invocation_id` differs from Control 1).

## 3. Governance & Route
- `utils/ci-route.sh pull_request` (piped): `route=full` (`outputs/ci-route.txt`).
- `./utils/pdda/pdda.sh run`: 0 errors (`outputs/pdda-run.log`).
- No new test suites added (GH-831).
