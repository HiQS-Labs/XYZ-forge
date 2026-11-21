# GH-772 manual verification

Actual Python function extracted with AST and executed with Darwin subprocess responses for 1024 compressor pages, 2048MB free swap. Runtime page sizes 4096/16384 yield 4/16MB. Unavailable sysconf preserves soft failure (compressor unknown, swap still2048). Baseline 16K case returned4MB, a witnessed failure. No production telemetry stage or test suite added. Full gate pending parent host slot.

Existing gh382-marathon-memory-telemetry suite passed (exit0, 3.532s) in disposable full clone at a8ef441b9dce8a9b3e9db5bdddef88836d4bc859; HEAD/origin/bare/local identity unchanged. Normal hooks installed.

Superseding runtime repair: sysconf failed a controlled Rosetta-like4K-process/16K-header input. Parse vm_stat header instead; controls in header-controls.json. Existing memory telemetry suite passed again after this material change; independent changed-runtime QA PASS. Earlier evidence retained as history, not final behavior.
