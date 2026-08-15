# GH-555 negative control — `test/meter-release.sh`

Recorded 2026-08-15. Per #419: a check never observed failing is not evidence.

## What had to be falsifiable

Meter (release 0.6.0) defines its exit criterion via `bash test/meter-release.sh --release-gate`.
The release goalpost has two halves:
- **Half A:** Manifest audit verifying that every frozen manifest entry (#378, #379, #380, #382, #491, #551, #555)
  has an existing gate script, is registered in `validate.sh`'s `TESTS` array, has a recorded negative control
  in `test/baselines/`, and matches `RELEASES.md`.
- **Half B:** Execution of the six member cases. Half B enforces the same structural criteria as Half A: a member
  case is only evaluated for execution if its suite exists, is registered in `validate.sh`'s `TESTS`, and has a
  recorded control in `test/baselines/`. An exit-0 stub that lacks registration or a recorded control is detected
  as `NOT COVERED`, never credited as `PASS`.

The negative control mode (`bash test/meter-release.sh --mutate-evidence`) copies `validate.sh` and `test/baselines/`
into a fixture, mutates them in four distinct ways (unregistering a manifest gate, deleting a control, evaluating
exit-0 stubs, and verifying unregistration drops a case from Half B PASS), verifies that the audit detects all mutations,
and then restores the unmutated inputs and verifies that they return to green in the same run.

## Observations

### 1. Negative Control via `--mutate-evidence`

```
== meter-release --mutate-evidence ==
-- baseline: the unmutated inputs
  PASS: #380 complete — test/gh380-claude-trust.sh registered, control recorded
  PASS: #555 complete — test/meter-release.sh registered, control recorded
  PASS: unmutated inputs report no false completion claims (complete=2)
  PASS: unmutated member cases execute 1 passing case (#380) and 5 not-covered cases
-- mutation 1: unregister a manifest gate from validate.sh (the #461 defect)
  PASS: unregistering a gate is DETECTED by audit_manifest (complete 2 -> 1)
-- mutation 2: delete a recorded negative control
  PASS: deleting a recorded control is DETECTED by audit_manifest (complete 2 -> 1)
-- mutation 3: a stub that exits 0 without registration/control must be detected as NOT COVERED, not PASS
  PASS: exit-0 stub without registration/control is detected as NOT COVERED, not PASS (CASE_PASS=1)
-- mutation 4: unregistering a passing member case from validate.sh removes it from Half B PASS
  PASS: unregistering member case drops it from Half B PASS (1 -> 0)
-- restore: the unmutated inputs must be green again in this same run
  PASS: restoring the inputs restores the verdict — the detector is not simply always-red

  meter-release --mutate-evidence: 7 passed, 0 failed
  negative control OBSERVED in both directions
```

### 2. Goalpost Red on Arrival via `--release-gate`

```
== meter-release (gate) — release 0.6.0 frozen-manifest goalpost ==

-- half A: the frozen manifest
  PASS: the frozen manifest here matches RELEASES.md's Meter block (7 entries)
  INFO: #378 remaining — not-registered-in-validate.sh no-recorded-control(test/baselines/GH-378-negative-control.md)  (a run against a red-suite target proceeds under a recorded baseline and halts on a new failure)
  INFO: #379 remaining — not-registered-in-validate.sh no-recorded-control(test/baselines/GH-379-negative-control.md)  (a budget-exhausted builder is escalated as budget-exhausted, not pre-advance-failed)
  PASS: #380 complete — test/gh380-claude-trust.sh registered, control recorded
  INFO: #382 remaining — not-registered-in-validate.sh no-recorded-control(test/baselines/GH-382-negative-control.md)  (a phase boundary records memory and swap)
  INFO: #491 remaining — not-registered-in-validate.sh no-recorded-control(test/baselines/GH-491-negative-control.md)  (a re-fire of an already-satisfied phase runs only the gate and says so)
  INFO: #551 remaining — not-registered-in-validate.sh no-recorded-control(test/baselines/GH-551-negative-control.md)  (a resolver that cannot determine its answer refuses rather than returning a default)
  PASS: #555 complete — test/meter-release.sh registered, control recorded

-- half B: the member cases, EXECUTED
  INFO: member case NOT COVERED — red-suite baseline allows progress and halts on new failure (test/gh378-gate-requires-green-suite.sh not registered in validate.sh)
  INFO: member case NOT COVERED — budget-exhausted builder escalated as budget-exhausted (test/gh379-claude-builder-diagnosis.sh not registered in validate.sh)
  PASS: member case OK — untrusted target reported before first paid turn (via gh380-claude-trust.sh)
  INFO: member case NOT COVERED — phase boundary records memory and swap telemetry (test/gh382-marathon-memory-telemetry.sh not registered in validate.sh)
  INFO: member case NOT COVERED — satisfied phase refire runs only the gate (test/gh491-gate-only-refire.sh not registered in validate.sh)
  INFO: member case NOT COVERED — unresolvable input causes resolver refusal (test/gh551-resolver-refuses.sh not registered in validate.sh)

manifest: 2 complete, 5 remaining, 0 false completion claim(s)
member cases: 1 passing, 0 failing, 5 NOT COVERED

GOALPOST NOT MET — Meter is not done.
  This is the correct state until the release is finished. Turning this command green is
  what 0.6.0's exit criterion means; a closed backlog is not a substitute for it.
```
Exit code: 1 (RED on arrival by design).
