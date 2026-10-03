# GH-949 / GH-912 remediation evidence

Base: `3fbed72f781d1ad060e298b798a44c32edef393d`. Runtime candidate: `76ad7e4e1ec64afe4b63383b3dc4e80cd9549a2d`. Runs on macOS, offline/mock ATE, using the separate full `verify` clone. Manual scripts are retained witnesses, not registered suites or new gate machinery. Source SHA, UTC times, commands and observations are retained in each provenance file.

| Finding | Base witness | Candidate result | Evidence |
|---|---|---|---|
| F1 cancellation | TERM/INT children survive; active row absent | child gone, prior bytes retained, one interrupted row, 143/130 | manual-process before-final / after |
| F2 directory links | add/remove/retarget falsely pass | all rejected; targets unchanged; no-op passes | manual-state base / after |
| F3 linked Git config | common/worktree config missed | both detected; standalone and linked no-op controls pass | manual-state base / after |
| F4 empty grid | exits 0 and overwrites control | refuses before control/reset writes | manual-state base / after |
| F5 launch failure | traceback without row | one fail/spawn_error row, exit127 | manual-state base / after |
| F6 HOME absent | valid explicit override aborts with/without XDG | both resolve correctly | manual-state base / after |
| F7 timeout admission | sentinel executes before refusal | refuses with no launch | manual-process before-final / after |
| F8 oracle timeout | false pass or exception followed by late write | structured failed observation; no late write, including later repeats | manual-process before-final / after |
| F9 UTC | local time falsely suffixed Z | timestamp within observed UTC interval under America/Los_Angeles | manual-state base / after |
| K1 #912 selectors | find-harness48/2; roots40/1 | envelope:50/0 and41/0; explicit fixture selections and DB preserved | manual-environment |

State witness: 4/14 correct on base,14/14 on candidate. All process correct-property assertions pass on candidate, including normal exit, actual exit124 versus witnessed timeout. Compatibility witness covers repeated signals during CLI ACK cleanup, original SystemExit77 re-raised after group cleanup, and unchanged normal-success background-child policy. All owned groups independently cleaned up.

Existing focused suites: gh47843/0; ate-run-variations all checks; gh14230/0; telemetry schema PASS; domain-oracles17/0; metamorphic8/0; runner-envelope25/0; find-harness50/0; roots41/0. Each verification-clone identity snapshot remains unchanged. The retired domain suite was run directly for this change and was not re-registered.

Evidence limitations and dispositions: plan relay round1 PASS prose was rejected by the driver because the producer placed packet text after the final marker; corrected round2 is attested Approved, exit0. Both logs retained. The environment wrapper's final external-task-clone guard used a stale SHA and exited nonzero after passing suite/envelope checks; this orchestration failure is retained, not reported as a wrapper pass. The parent concurrently created this evidence directory in the task clone; all executed suites ran in verify and its identity stayed unchanged.

No claim of production loss. SIGKILL and deliberate process-session escape remain outside the cancellation contract. Library callers do not acquire global signal handlers; the ATE and proc_group CLI boundaries do. Final independent runtime QA and full qualifying gate are pending.

Additional contracts: eight checks passed for full failure-row consumer acceptance, threaded normal/timeout idempotence, missing host/config refusal and linked HEAD mutation detection (`manual-contracts`). A zero-minute invocation preserves prior rows and exits2 without a new row, but retains the existing initialization of control/baseline. The approved no-write rule applies to an empty grid, not to zero-minute initialization.

Final QA round1 found one existing false-pass in the touched idempotence oracle: the first rc/stdout was never compared to later runs because the consumer read a nonexistent `results` key. The actual-process witness (`manual-idempotence`) shows first-only exit/output differences passing on c93adc3d and failing on984b7f64; stable output stays passing. The repair compares the first observation with the existing exit_codes/stdout_hashes fields, with no new API or executor.
