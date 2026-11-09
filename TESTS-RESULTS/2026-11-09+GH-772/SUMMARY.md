# GH-772 manual verification

Actual Python function extracted with AST and executed with Darwin subprocess responses for 1024 compressor pages, 2048MB free swap. Runtime page sizes 4096/16384 yield 4/16MB. Unavailable sysconf preserves soft failure (compressor unknown, swap still2048). Baseline 16K case returned4MB, a witnessed failure. No production telemetry stage or test suite added. Full gate pending parent host slot.
