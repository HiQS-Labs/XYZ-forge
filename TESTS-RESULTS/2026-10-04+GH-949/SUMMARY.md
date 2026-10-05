# PR953 resumed cancellation verification

Original base: `3fbed72f781d1ad060e298b798a44c32edef393d`.
Reviewed PR checkpoint: `0b892acd81c6549eac3a356d73105e185c765624`.
Development integration: `6beac5bfb4e90bb8d6695372b12b8deaab9ee23e` (PR948 merged).
Only the two oracle CLI entry points change in this repair; both reuse
`proc_group.Cancelled` and `cancellation_signals`. Library calls retain their API
and do not install signal handlers. No new suite, registry entry or gate stage.

## Observations and falsification

The same manual process controls ran in a separate full clone, with source files
extracted at the exact original base for the base comparison. Every case waits for
a nonempty PID/PGID artifact before cancellation, checks the recorded child's
actual process state, and independently cleans up any survivor.

| Source | Direct SIGTERM, both CLIs | Outer process-group timeout, both CLIs |
|---|---|---|
| Original base | children survive (inherited gap) | children gone, status124 |
| PR before repair | children survive | children survive (session-isolation regression) |
| Repaired CLI boundaries | children gone, status143 | children gone, status124 |

Repaired SIGINT returns130 with no surviving child for both CLIs. Direct SIGTERM
against a TERM-resistant command also returns143 and removes the child for both.
All eight repaired cancellation properties pass. The pre-repair controls are the
red witness for the exact two omitted entry-point guards, rather than assertions
over an empty or unlaunched command. `replay.py`, results, UTC provenance and
source hashes are retained alongside this summary. Historical base failures and
their cleanup remain evidence, not passing validation.

Root cause: default CLI SIGTERM termination bypasses the shared runner's
BaseException cleanup after session-isolated launch. Fix site: each CLI's
`__main__` boundary. The library runner already cleans up on catchable cancellation;
installing process-global handlers inside it would break threaded library use.

Existing focused suites pass: domain-oracles17/0, metamorphic8/0 and process-group
guard43/0. Verification clone identity and tracked diff are unchanged after the
completed run; snapshots, raw logs and provenance are retained.

## Scope and limits

Normal successful background-child policy is unchanged. Deliberate session escape
and SIGKILL remain outside the cancellation contract. Concurrent idempotence workers
remain bounded by their own command timeouts; no new global thread cancellation
policy is introduced. This is local macOS CLI verification, not promotion evidence.

Fable B1 is Implemented. Nonblocking S1 is retained in
`PARKED/2026-10-04-metamorphic-worktree-config.md`; it is not claimed repaired.
Fresh independent QA and the final required gate remain pending.
