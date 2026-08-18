# GH-23 kernel path-overlap enforcement negative control — `test/gh23-path-overlap-enforcement.sh`

Recorded 2026-08-17. Per the standing rule: a check never observed failing is not evidence.
Flagged as missing by an Agy-driven code review (`relay-system/2026-08-17/gh-23-kernel-overlap-enforcement-code-review.md`) before this record was written.

## What had to be falsifiable

GH-23's fix adds a path-overlap check under `withClaimLock` to both `src/claim.js` (direct
`tick claim`) and `src/scope.js` (`tick scope`), rejecting a request whose paths overlap another
agent's active claim unless `--force` is passed. The control mutates each check off and shows the
regression test catching the reintroduced defect: a collision the kernel is supposed to prevent
goes through silently.

## Controls (mutation pair)

Mutation performed in a disposable scratch copy (`~/xyz-disposable/gh23-negcontrol`, never `/tmp`,
never the primary clone): `src/claim.js:64` and `src/scope.js:57` each had their overlap-check
guard changed from `if (!force) {` to `if (false && !force) {`, disabling the check entirely
regardless of `--force`.

### PRE-FIX (mutated) — the control is OBSERVED failing

```
== test: gh23-path-overlap-enforcement ==
  workdir: <tmp>
  PASS: alice successfully claimed TASK-101
  FAIL: direct claim on overlapping task was not rejected! status=0 out=won: TASK-102 claimed by bob
```

Bob's claim on `TASK-102` (`src/auth/login.js`) — which overlaps Alice's active claim on
`TASK-101` (`src/auth/**`) — succeeds instead of being rejected. This is exactly the collision the
kernel exists to prevent (README's "two agents never edit the same thing" promise). The test's
`fail()` exits on first failure (this suite's established shape — see the other 12 assertions in
the file for what a full pass covers), so the mutation is caught at the first point it diverges
from the fix's contract.

### POST-FIX (unmutated) — same file, same assertions, green

```
== test: gh23-path-overlap-enforcement ==
  workdir: <tmp>
  PASS: alice successfully claimed TASK-101
  PASS: direct claim on overlapping task TASK-102 rejected (exit 1): lost: TASK-102 paths overlap active claim (TASK-101) held by alice — use --force to override
  PASS: rejected claim was non-mutating: TASK-102 remains open
  PASS: direct claim with --force succeeded: won: TASK-102 claimed by bob
  PASS: force provenance recorded in event log for forced claim
  PASS: bob claimed non-overlapping TASK-103
  PASS: scope expansion into overlapping paths rejected (exit 1): tick scope: scope rejected: paths overlap active claim (TASK-101) held by alice (use --force to override)
  PASS: rejected scope expansion was non-mutating: TASK-103 paths unchanged (src/billing/**)
  PASS: scope expansion with --force succeeded: scoped: TASK-103
  PASS: force provenance recorded in event log for forced scope change
  PASS: release unblocking verified: charlie claimed TASK-104 after alice completed TASK-101
  PASS: third-party claim rejected against Bob's forced active scope: lost: TASK-106 paths overlap active claim (TASK-103) held by bob — use --force to override
  PASS: idempotent re-claim by current holder succeeded without self-overlap rejection
  gh23-path-overlap-enforcement: 13 pass, 0 fail
```
