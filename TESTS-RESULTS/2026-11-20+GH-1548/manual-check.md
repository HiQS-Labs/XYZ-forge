# Manual Check — GH-1548 (KS-05: Verbatim Stop Reasons, Fresh Per-Turn Logs, and U13 429→`provider-quota`)

- **Issue:** #1548 (KS-05 from #1541)
- **Date:** 2026-11-20
- **Branch:** `feat/XYZ-forge-gh1548-ks05-stop-reasons-2026-11-20`
- **Route:** `full` (`outputs/ci-route.txt`)

## Reproducible Probe & Controls Evidence (`outputs/controls-r3-probe.py` + `outputs/controls-r3.txt`)
Executed verbatim via `python3 TESTS-RESULTS/2026-11-20+GH-1548/outputs/controls-r3-probe.py <ks05_clone> <landed_ks04_clone> TESTS-RESULTS/2026-11-20+GH-1548/outputs/controls-r3.txt`:
1. **Control 1 (Red pre-change base vs Green candidate `zero-output-stall`):**
   - `CONTROL_1A_RED_PRE_CHANGE_BASE`: pre-change `origin/development` `relay_drive.py` leaves stale `.relay-scratch/escalation-reason` (`cap-stalled`) untouched and writes 0 stop-reason receipts.
   - `CONTROL_1B_GREEN_ZERO_OUTPUT_STALL`: candidate overwrites `.relay-scratch/escalation-reason` with `zero-output-stall` and writes `.relay-scratch/stop-reasons/<invocation_id>.json` (`reason="zero-output-stall"`, `exit_code=3`).
2. **Control 2 (U13 Adapter-Level & Live-Stderr `provider-quota` Classification):**
   - `CONTROL_2A_ADAPTER_CODEX_DECIDE`: pre-change vs candidate `harness.py:codex_decide` with mocked `run_bounded` on HTTP 429/quota (`provider-quota`) vs non-quota error (`adapter-error`).
   - `CONTROL_2B_LIVE_STDERR_QUOTA_VS_TURN_ERROR`: `relay_drive.py` classifies live stderr HTTP 429 as `provider-quota` and generic stderr failure as `turn-error`.
3. **Control 3 (Per-Turn Fresh Log Isolation & Caller-Reused Log Falsifiers):**
   - Three consecutive runs on the SAME relay task without `CODEX_LOG` receive 3 distinct fresh per-turn `CODEX_LOG` paths: Turn 1 quota -> `provider-quota`, Turn 2 repeated identical quota -> `provider-quota`, Turn 3 generic error -> `turn-error`.
   - Caller-reused `CODEX_LOG` pre-seeded with stale HTTP 429: partial overwrite with generic error -> `turn-error`; live stderr HTTP 429 -> `provider-quota`.
4. **Control 4 (Post-Start Consult Escalation Write Failure & Preflight Lock Contention):**
   - `CONTROL_4A_POST_START_CONSULT_ESCALATION_WRITE_FAILED`: relay file missing `STATUS:` header with stubbed `consult.sh` divergence exits `1`, sets legacy `escalation-reason` to `consult-escalation-write-failed`, and writes matching receipt.
   - `CONTROL_4B_PREFLIGHT_LOCK_CONTENTION_PRESERVES_LEGACY`: live `.git/relay-driver.lock` causes competing driver to exit `1`, write `driver-lock-active` receipt, and preserve the active driver's `.relay-scratch/escalation-reason` (`active-driver-preserved-reason`).
5. **Control 5 (Direct KS-04 Compatibility):**
   - Executed landed `origin/development` (`6062aa2ea7`) KS-04 `skills/1-hourly/kickstart/scripts/kickstart_status.py --record ... --skip-prs --receipt <receipt> --json` directly against candidate `provider-quota` and `driver-lock-active` receipts — both exit `0` and parse cleanly.
6. **Existing Regression Suites:** `test/gh115-round-cap.sh` and `test/gh505-relay-attest.sh` both exit `0`.

## Full Disposable-Clone Gate Receipt (`outputs/disposable-full-gate.log` + `outputs/disposable-full-gate.done.json`)
- Executed full `./validate.sh` in a fresh disposable clone at code head `b280e6709ce93b7e89676d0ac61c859bce119968` with `user.email` unset and `mypy==1.14.1` on PATH: `validate_rc=0`, `elapsed_s=996`, complete PRE-GATE + POST-GATE snapshots retained in `outputs/disposable-full-gate.log` (34345 bytes) and `outputs/disposable-full-gate.done.json` (188 bytes) — previously accepted in Final QA R2 (Turn 4).
- `outputs/pdda-run.log`: `./utils/pdda/pdda.sh run` 0 errors.
- `provenance.jsonl`: exact SHA-256 + byte lengths verified across all artifacts.
