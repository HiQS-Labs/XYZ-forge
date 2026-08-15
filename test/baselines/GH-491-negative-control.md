# GH-491 — recorded negative control (#419)

Test:     `test/gh491-gate-only-refire.sh`
Baseline: `commit c9ed895b17c49f3710d51e260d53b5cef99cd7bc` — `utils/py/marathon_drive.py`
Date:     2026-08-15

## Defect Summary

Before GH-491, re-firing an already-satisfied phase with `--retry` silently triggered an expensive rebuild (builder + reviewer turn) instead of notifying the operator that re-firing plainly without `--retry` would have re-run only the pre-advance gate. Furthermore, `--retry`'s help text did not explain when not to use it.

## Verification & Controls

`test/gh491-gate-only-refire.sh` verifies that:
1. `marathon.sh --help` explicitly describes when `--retry` is the wrong choice and that plain re-fire re-runs only the gate.
2. The driver emits an informational advisory when `--retry` is passed for a phase whose relay is already terminal (`STATUS: Approved`) and whose recorded token is `done`.
3. The advisory does NOT alter `--retry`'s behavior (the lane still rebuilds).
4. **Negative Controls:**
   - When the recorded token is not `done`, no advisory is emitted (the rebuild is genuinely required).
   - When the relay status is non-terminal (`Open`), no advisory is emitted.
5. Plain re-fire without `--retry` continues to hit the `already-satisfied` gate-only path and dispatches no turns.
