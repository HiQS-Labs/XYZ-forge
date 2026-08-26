# Lane brief — GH-123 remainder: gh358 lock contention on shared runners

Source of truth: `PROJECT/2-WORKING/GH-123-LINUX-CANARY-REMAINDER.md` (issue
https://github.com/HiQS-Labs/XYZ-forge/issues/123; Linux-RC umbrella #224 Phase 2).

## Deliverable

`test/gh358-lock-instrumentation.sh` passes deterministically under shared-runner CPU load
(the hosted Ubuntu canary shape from the GH-123 run). Fix inside the suite/harness seam:
tune `XYZ_LOCK_WAIT_S` for the instrumented path or add bounded lock retry under contention.
No sleeps-as-sync; no lock-semantics change for real drivers (existing lock suites stay
green — see the GH-354 exclusion matrix and `test/gh448-driver-lock-resolver.sh`).

## Hard constraints

- Write-set is exactly `test/gh358-lock-instrumentation.sh` — a fix that needs driver-side
  changes escalates to the orchestrator instead of widening the lane.
- The other four original GH-123 suites are already fixed (development / PR #209) — out of
  scope here.
