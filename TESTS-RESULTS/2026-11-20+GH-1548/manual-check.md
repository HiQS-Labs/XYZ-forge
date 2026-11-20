# GH-1548 (KS-05) — Paired Red/Green Manual Check

- **Issue:** #1548 (KS-05: stop reasons are quoted, never inferred, and attributed to the current run; U13 429 → `provider-quota`)
- **Date:** 2026-11-20
- **No new test suite (GH-831):** Verified via existing `test/gh115-round-cap.sh`, `test/gh505-relay-attest.sh`, and four paired red/green manual controls recorded in `outputs/manual-controls.txt`.

## Controls Summary
1. **Control 1 (Stale `cap-stalled` vs fresh exit-3 `no-action-stall`):**
   - **Pre-change / Red:** Legacy `.relay-scratch/escalation-reason` held stale `cap-stalled` from an earlier run; exit-3 paths wrote no receipt and left the stale file untouched.
   - **Changed / Green:** `relay_drive.py --invocation-id inv-ctrl1 --stop-receipt ...` exited `3`, emitted verbatim stderr trailer `relay-drive: stop-reason=no-action-stall invocation_id=inv-ctrl1 exit_code=3`, wrote the attributed JSON receipt (`reason=no-action-stall`, `stop_reason=no-action-stall`, `exit_code=3`), and updated `.relay-scratch/escalation-reason`.
2. **Control 2 (U13 `429`/quota → `provider-quota` vs `turn-error` vs `cap-stalled`):**
   - **Pre-change / Red:** `utils/py/harness.py` normalized `429`/quota as `rate-limited` and `relay_drive.py` emitted generic `turn-failed-rcN`.
   - **Changed / Green:** `harness.is_provider_quota_error` classifies `429`/quota as `provider-quota` while rejecting word-boundary false positives (`line 4290`). `relay_drive.py` classifies 429 stderr as `provider-quota` (preserving shim exit 5) and non-quota failures as `turn-error`.
3. **Control 3 (Fresh per-turn log isolation + repeated 429 + caller-reused `<ENV>_LOG` isolation):**
   - Driver-owned turns allocate 3 distinct per-turn log paths via child-only `turn_env`; identical repeated 429s both classify `provider-quota`, and an immediately following non-quota failure classifies `turn-error`.
   - Caller-reused `<ENV>_LOG` pre-populated with stale 429 is never scanned (non-quota turn returns `turn-error`), while a live 429 on stderr still classifies `provider-quota`.
4. **Control 4 (Preflight lock isolation + orphaned-grandchild stderr non-hang + KS-04 receipt compatibility):**
   - Preflight `driver-lock-active` writes its own invocation receipt (`exit_code=1`) without overwriting the active run's `.relay-scratch/escalation-reason`.
   - An orphaned grandchild (`sleep 10`) holding `proc.stderr` open no longer hangs the driver (exited in `<1s` via non-blocking `select()` drain in `_StderrTee`) while still capturing `provider-quota`.
   - Direct compatibility check with KS-04's `kickstart_status.py` confirmed `--receipt` reports `stop_reason: "provider-quota"` (`attribution: "run-receipt"`) and an unattributed shared `escalation-reason` reports `stop_reason: "unknown"`.

## Evidence Files
- `outputs/manual-controls.txt` — paired red/green manual control execution transcript
- `outputs/disposable-full-gate.log` — full classified gate run in a fresh disposable full clone (recorded after gate completion)
- `provenance.jsonl` — SHA-256 manifest of all evidence files
