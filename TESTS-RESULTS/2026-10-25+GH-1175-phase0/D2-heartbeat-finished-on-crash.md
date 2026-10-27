TITLE: rtl_driver_heartbeat_status reports `finished` for a SIGKILLed driver until the heartbeat ages past stale_after

## Observed (GH-1175 Phase 0, 2026-10-26)
Marathon driver pid 32725 killed with SIGKILL at 03:22:37Z. `rtl_driver_heartbeat_status <clone>` returned `finished` (rc 1) at 03:22:45Z and `stale` (rc 2) only after 120 s (03:24:30Z). The heartbeat file stayed on disk with `updated_utc == started_utc` (never refreshed in the 18 s the driver lived).

## Why it matters
#1188 rule 2: a stale/dead heartbeat means **uncertain**, never done. `finished` for a crashed driver is the opposite signal; a reconciler or L2 lease check reading it during the first 120 s would treat a crash as a clean finish. (Jog cold start still parked correctly because it keys on the receipt, not the heartbeat.)

## Cause
`relay-automation/relay-turn-lib.sh` `rtl_driver_heartbeat_status` (≈L650-683): pid dead AND age ≤ stale_after → `finished`. A clean exit removes or finalizes the file; a dead pid with the file still present is a crash, not a finish.

## Proposed remedy (for review)
Dead pid + heartbeat file still present → `stale` (or a distinct `dead`) regardless of age; `finished` only when the file is absent or marked terminal. Fold into #1188 L2 rather than a separate mechanism.

## Acceptance
SIGKILL a driver → status reads non-`finished` immediately; clean exit → `finished`. Manual receipts under TESTS-RESULTS/.
