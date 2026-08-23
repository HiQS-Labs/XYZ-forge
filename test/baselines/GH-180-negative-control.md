# GH-180 negative control (pre-fix, recorded 2026-08-23)

Soak evidence: #177 §3.1 (probe A10). Any telemetry record with `exit_code: null`
(the shape `run_harness` emits on timeout — the fuzzer's most common record class)
crashed the builder instead of producing a reproducer:

    TypeError: int() argument must be a string, a bytes-like object or a real
    number, not 'NoneType' — at utils/py/repro_builder.py:68 in parse_failure_telemetry

Post-fix expectation: null exit coalesces to the 124 timeout signature; a
reproducer is emitted only when the timeout shape actually reproduces (a command
exiting 0 cannot fabricate one). Verified by test/gh180-repro-timeout-crash.sh.
