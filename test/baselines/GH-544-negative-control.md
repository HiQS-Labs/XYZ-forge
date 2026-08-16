# GH-544 negative control — `test/gh544-parallel-default.sh`

Recorded 2026-08-14. Per #419: a check never observed failing is not evidence.

Fixed tree: **29 pass, 0 fail.**

## What had to be falsifiable

The flip to parallel-by-default does not create a "parallel might be wrong" risk — GH-528 already
measured the pass/fail set as byte-identical. It creates a **legibility** risk: the gate now *chooses*
a mode, so a run believed to be 8-wide might have been sequential, or a promotion boundary might
silently inherit a default it was never meant to have. The controls therefore attack the announcement
and the precedence, not the suite outcomes.

## Controls, each run against the real tree and restored from a copy afterwards

### A — the promotion boundary stops pinning its mode

`.github/workflows/ci.yml`: `run: ./validate.sh --sequential` → `run: ./validate.sh`

```
FAIL: ci.yml's macOS boundary pins --sequential explicitly
FAIL:   and no CI step invokes a bare ./validate.sh
27 pass, 2 fail
```

This is the control that matters most. Reverting one flag is exactly what a future edit would look
like, and without these two assertions the boundary would quietly begin promoting on parallel
evidence — the precise circularity GH-509 exists to prevent, arriving through a default rather than
through a decision.

### B — the mode is chosen but not announced

`validate.sh`: the `SEQUENTIAL mode — $PARALLEL_WHY` line replaced with `:`

```
FAIL: XYZ_VALIDATE_PARALLEL=0 selects sequential
FAIL:   and names the env var as the reason (never a silent downgrade)
FAIL: --sequential selects sequential
FAIL:   and names the flag as the reason
25 pass, 4 fail
```

A silent fallback is the failure mode this whole design is built against: the operator believes they
ran an 8-wide gate, the host declined, and nothing said so.

### C — precedence inverted so the environment beats an explicit flag

`validate.sh`: the env block's guard `[ "$FORCE_SEQUENTIAL" -eq 0 ] && [ -z "$PARALLEL_JOBS" ]`
replaced with `true`, so `XYZ_VALIDATE_PARALLEL` is consulted even when a flag was passed.

```
FAIL: an explicit flag OVERRIDES XYZ_VALIDATE_PARALLEL
28 pass, 1 fail
```

**Exactly one assertion, which is the point of recording it separately.** A blunt suite would have
reddened half a dozen lines here; this one names the single property that broke. A stale
`XYZ_VALIDATE_PARALLEL=0` in a shell profile silently overriding `--parallel 8` is a real shape, and
it is invisible without this.

## Restored

Both files restored from copies; re-run clean at **29 pass, 0 fail** in the same session, so the
controls are not an always-red detector passing for a precise one.

## Honest limit

These controls prove the suite detects a **mis-declared or unannounced mode**. They do not prove
8-wide execution is *stable* — that is GH-528 Phase 2 (multi-width repeats at ~N=50 under CPU load,
leak and clean-tree checks), which remains **unmet**. The flip was an operator decision (GH-544)
taken with that evidence still owed, and the mitigations are the announced fallback, the untouched
sequential path in `ci-local.sh`, and the pinned `--sequential` on the promotion boundary. None of
those is a substitute for the stress evidence, and this file should not be read as if it were.
