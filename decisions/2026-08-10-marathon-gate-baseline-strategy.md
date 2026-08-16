# 2026-08-10 Marathon Pre-Advance Gate Baseline Strategy (GH-378)

## Context

A marathon's pre-advance gate (`--pre-advance-cmd`) executes at each phase boundary. Previously, any non-zero exit code immediately escalated with `pre-advance-failed` and halted the chain. This prevented marathons from running against target repositories that had pre-existing suite failures before phase 1 began, even when the phase's own changes introduced no regressions.

## Decision

We adopt **Option 1c (Baseline allowance via exit-code bound `--pre-advance-baseline` / `MARATHON_GATE_BASELINE`)** combined with **Option 4 (Documentation disclosure)**.

1. **Invocation & Scope:**
   The baseline allowance is configured via `--pre-advance-baseline <rc>` or the `MARATHON_GATE_BASELINE` environment variable. The single `--pre-advance-cmd` interface remains untouched.
   
2. **Evaluation & Gating:**
   - If the pre-advance gate returns a non-zero exit code `rc <= baseline_rc` (and not killed by resource guards), the phase recognizes the pre-existing baseline failure and advances.
   - If the gate encounters a new regression resulting in `rc > baseline_rc` or a guard kill (`GATE_GUARD_KILL_EXIT`), the phase halts and escalates with `pre-advance-failed` or `gate-killed`.

3. **Explicit Disclosure of Guarantees:**
   An exit-code baseline allows runs against repos with known pre-existing failure codes (e.g. `exit 1`). A passing gate proves that the overall failure exit code has not worsened beyond the accepted baseline. It **does not prove** test-identity equivalence: it cannot distinguish "the same tests failing" from "a different set of tests failing with the same exit code". Target repos requiring granular test-identity verification should run dedicated scoped gates or repair their suites before full marathon dispatch.

**Status:** Accepted
