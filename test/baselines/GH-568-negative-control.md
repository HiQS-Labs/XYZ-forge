# GH-568 — Recorded Negative Control Evidence

Issue:    https://github.com/HiQS-Labs/XYZ-forge/issues/568
Task:     `feat(ledger): end-to-end retirement of RELEASES.md in favor of releases.db`
Date:     2026-09-12
Branch:   `feat/gh568-retire-releases-md`

This document records durable negative control evidence demonstrating that:
1. The goalpost manifest checkers (`test/nightwatch-release.sh`, `test/meter-release.sh`, `test/ballast-release.sh`) have been completely decoupled from `RELEASES.md`, rewired to `releases.db`, and their silent-skip fallback (`[ -f "$rel" ] || return 0`) eliminated.
2. When perturbed (dropped members, extra members, missing DB), the goalpost checkers report RED and fail closed.
3. The permanent regression guard `test/gh568-releases-md-retired.sh` enforces the complete absence of `RELEASES.md` and `RELEASES.generated.md`, auditing all production paths for write redirections, and detects mutated injections independently.

---

## 1. Nightwatch Goalpost Manifest Check (`test/nightwatch-release.sh --mutate-evidence`)

```
== nightwatch-release --mutate-evidence ==
-- baseline: the unmutated inputs
  PASS: #408 complete — test/gh408-tick-failure-visibility.sh registered, control recorded
  PASS: #409 complete — test/gh409-claim-leak.sh registered, control recorded
  PASS: #426 complete — test/gh426-worktree-leak.sh registered, control recorded
  PASS: #388 complete — test/gh388-run-log-durability.sh registered, control recorded
  PASS: #387 complete — test/gh387-gate-not-first-executor.sh registered, control recorded
  PASS: #384 complete — test/gh384-crash-recovery.sh registered, control recorded
  PASS: #358 complete — test/gh358-lock-instrumentation.sh registered, control recorded
  PASS: #354 complete — test/gh376-relay-drive-lock-parity.sh registered, control recorded
  PASS: unmutated inputs report no false completion claims (complete=8)
-- mutation 1: unregister a manifest gate from validate.sh (the #461 defect)
  PASS: unregistering a gate is DETECTED (complete 8 -> 7)
-- mutation 2: delete a recorded negative control
  PASS: deleting a recorded control is DETECTED (complete 8 -> 7)
-- mutation 3: ledger in releases.db drops a member
  PASS: incomplete manifest in releases.db is DETECTED (missing members caught)
-- mutation 4: missing releases.db must not silently pass
  PASS: missing releases.db is DETECTED (fail-closed)
-- mutation 5: extra member in releases.db manifest must be rejected
  PASS: extra member in releases.db is DETECTED (bidirectional cross-check works)
-- restore: the unmutated inputs must be green again in this same run
  PASS: restoring the inputs restores the verdict — the detector is not simply always-red

  nightwatch-release --mutate-evidence: 38 passed, 0 failed
  negative control OBSERVED in both directions
```

---

## 2. Meter / Front-Door Goalpost Manifest Check (`test/meter-release.sh --mutate-evidence`)

```
== meter-release --mutate-evidence ==
-- baseline: the unmutated fixture artifact
  PASS: unmutated fixture artifact passes every Half A check (7 checks) — the control is discriminating, not always-red
-- mutation 1: plant a private path in a tracked file
  PASS: a planted private path is DETECTED by the private-marker sweep
-- mutation 2: remove CHANGELOG.md
  PASS: a removed CHANGELOG.md is DETECTED
-- mutation 2b: a MODIFIED CHANGELOG.md (not carried verbatim) is detected
  PASS: a modified CHANGELOG.md is DETECTED — 'verbatim' is enforced, not just 'present'
-- mutation 3: leave a relay-system/ directory behind
  PASS: a surviving relay-system/ is DETECTED
-- mutation 4: add a second commit (fresh history violated)
  PASS: a second commit is DETECTED — fresh history is enforced
-- mutation 5: an internal working doc survives in PROJECT/
  PASS: a surviving internal PROJECT doc is DETECTED
-- mutation 5b: an unpinned secret-scan record is detected
  PASS: a secret-scan record with no pinned version or commit is DETECTED
-- mutation 6: ledger declares a RETIRED member (direction 2 — ledger has one this file lacks)
  PASS: a ledger declaring retired #378 is DETECTED (direction 2 works)
-- mutation 7: ledger drops a current member (direction 1 — this file has one the ledger lacks)
  PASS: a ledger missing #563 is DETECTED (direction 1 works)
-- mutation 8: the OLD prose-matching failure must not be reproducible
  PASS: a prose Manifest: paragraph cannot satisfy the cross-check (the original defect stays fixed)
-- mutation 9: missing releases.db must not silently pass
  PASS: missing releases.db is DETECTED (fail-closed)
-- restore: the unmutated fixture must be green again in this same run
  PASS: restoring the inputs restores the verdict — the detector is not simply always-red

  meter-release --mutate-evidence: 13 passed, 0 failed
  negative control OBSERVED in both directions
```

---

## 3. Ballast Goalpost Manifest Check (`test/ballast-release.sh --mutate-evidence`)

```
== ballast-release --mutate-evidence ==
-- baseline: the unmutated fixture
  PASS: unmutated fixture: #999 complete, 0 false claims — the control is discriminating, not always-red
-- mutation 1: unregister the gate (remove it from TESTS but leave the file)
  PASS: an unregistered gate on a CLOSED issue is DETECTED as a false completion claim
-- mutation 2: delete the recorded control
  PASS: a deleted recorded control on a CLOSED issue is DETECTED as a false completion claim
-- mutation 3: forge a passing stranger-run record — Half B must not read it
  PASS: a forged stranger-run PASS record has NO EFFECT — Half B still reports NOT COVERED with no clone to execute against
-- mutation 4: ledger declares a member this file does not measure (direction 2)
  PASS: a ledger declaring an unmeasured #999 is DETECTED (direction 2 works)
-- mutation 5: this file measures a member the ledger drops (direction 1)
  PASS: a ledger missing #3 is DETECTED (direction 1 works)
-- mutation 6: missing releases.db must not silently pass
  PASS: missing releases.db is DETECTED (fail-closed)
-- restore: the unmutated fixture and ledger must be green again in this same run
  PASS: restoring the inputs restores the verdict — the detector is not simply always-red

  ballast-release --mutate-evidence: 8 passed, 0 failed
  negative control OBSERVED (gate unregistration, control deletion, forged stranger-run record; ledger both directions)
```

---

## 4. Dedicated Regression Guard (`test/gh568-releases-md-retired.sh --mutate-evidence`)

```
== test: GH-568 ==
  workdir: <tmp>
== GH-568 Mutate Evidence Mode ==
WITNESS_RED_CONTROL_1: PASS (correctly detected RELEASES.md presence)
WITNESS_RED_CONTROL_2: PASS (correctly detected RELEASES.generated.md presence)
WITNESS_RED_CONTROL_3: PASS (correctly detected write redirection to RELEASES.md)
WITNESS_RED_CONTROL_4: PASS (correctly detected Python write to RELEASES.generated.md)
WITNESS_RED_CONTROL_5: PASS (empty-input guard returned code 2 on empty search root)
WITNESS_RED_CONTROL_6: PASS (runtime probe correctly detected mutated/overwritten retired file)
WITNESS_RED_CONTROL_7: PASS (correctly detected JS/TS write to RELEASES.md)
== ALL 7 RED CONTROLS WITNESSED PASSING ==
```

