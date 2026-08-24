# GH-181 negative control (pre-fix, recorded 2026-08-23)

Soak evidence: #177 §3.2 (probe B2). A real GH-141 failure record — `command`
recorded as a joined string whose absolute path contains a space, with no `env`
and no `argv` — produced an emitted reproducer whose command line was
mis-tokenized AND unquoted. Executing it:

    rc 127 — "FAIL: Expected exit code 2, got 127"
    stderr: /Users/noelsaw/Documents/GH: line 1: 1: command not found

The builder manufactured a non-reproducing reproducer from real telemetry, and
rc-only matching could not tell it failed for the wrong reason.

2026-08-23 amendment: the GH-141 record's underlying defect is historical
(`agy-turn.sh --help` exits 0 on current development — GH-156/PR #157), so the
record is the TOKENIZATION fixture; reproduction is proven on a synthetic
still-live record; wrong-cause rc coincidence is rejected by signature matching.
Verified by test/gh181-repro-adapter-fidelity.sh.
