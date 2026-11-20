# Manual Check — GH-1548 (KS-05: Verbatim Stop Reasons, Fresh Turn Logs, and U13 429→provider-quota)

Date: 2026-11-20
Code Head Verified by Full Gate: `b280e6709ce93b7e89676d0ac61c859bce119968`
Route: `full` (`outputs/ci-route.txt`; touches `relay-automation/` kernel scripts).

## 1. Full Disposable-Clone Gate (`outputs/disposable-full-gate.log`)
- Executed `./validate.sh` detached in a fresh disposable full clone of `b280e6709ce93b7e89676d0ac61c859bce119968` with `mypy==1.14.1` on `PATH`.
- Result: **`validate_rc=0`**, `elapsed_s=1031`, `core.bare: false`, clean working tree (`status:`), including `test/gh648-l7-checkout-aftermath.sh`, `python:test_python_layer.py`, `clone-identity-invariant`, and `gamma-poison-staleness-probe`.

## 2. Targeted Red/Green Controls (`outputs/manual-controls.txt`)
- Retained KS-05 red/green controls verifying verbatim stop-reason preservation, fresh per-attempt logs (no stale-log tail leakage), and U13 429/quota classification (`provider-quota`, non-quota failures untouched), plus post-fix `bash test/gh648-l7-checkout-aftermath.sh` () on `b280e6709ce93b7e89676d0ac61c859bce119968`.

## 3. Governance & Route
- `utils/ci-route.sh pull_request` (piped): `route=full` (`outputs/ci-route.txt`).
- `./utils/pdda/pdda.sh run`: 0 errors (`outputs/pdda-run.log`).
- No new test suites added (GH-831).
