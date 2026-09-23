---
gh_issue: 764
source: https://github.com/HiQS-Labs/XYZ-forge/issues/764
title: "Baseline macOS gate failures in ATE, work state, and work events suites"
status: In progress
created: 2026-09-23
updated: 2026-09-23
owner: Codex
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 2
ratings_provisional: false
non_goals:
  - No change to ATE issue filing behavior
  - No RELEASES schema or work-event contract change
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/764
goal: >
  Restore the baseline macOS gate by fixing the connector subprocess failure and making the ATE
  and WAL-header tests construct the intended preconditions on this device.
---

## Key concepts

- Reproduce each reported failure in a disposable full clone before changing it.
- Preserve the ATE exit contract and WAL-header safety check.
- Keep the connector launch parallel and the deadline shared.

# Baseline macOS gate failures

## Status

| What was just completed | What's next |
|---|---|
| All three focused failures reproduced on untouched `development`; the first two have direct environment/fixture disproofs, and GH-549 has an isolated subprocess repro. | Review the plan, implement the bounded fixes, and run focused plus full gate checks in a separate full clone. |

## Why

The macOS gate is red on baseline `development`, blocking qualification of unrelated PRs including
#765. One gate run is the known incident; repeated runs of that same incident are not a recurrence
trend. The last 14 days versus the prior 14 days are not established from issue history, so trend
is unknown. The effect is a work-blocking qualification failure, not observed user-data loss.

## Rating rationale (2026-09-23)

`rated 85/80/50/70` (priority/severity/appeal/cheapness). Priority and severity reflect the
blocked macOS promotion gate; appeal stays neutral by policy; effort is moderately cheap because
the failures have focused repros, though full-gate qualification remains long. No operator override.

## Phase 0 — Recon and failure ledger

Base: `origin/development` at `a47c212b3ce2cee400853386a3e7213182f7827d`.

| Probe | Observation | Meaning |
|---|---|---|
| `bash test/gh142-ate-exit-contract.sh` with system Python | Fails at “no child-failure line”; `bash -x` reveals `ModuleNotFoundError: requests` in `run_variations.py` before filing. | The exit code assertion passed vacuously on an import failure. |
| Same suite with temporary venv containing requests, PyYAML and pytest | 30 passed, 0 failed. | No ATE behavior fix is supported. The test needs an explicit dependency preflight, and gate setup needs a documented toolchain. |
| `bash test/gh605-work-state.sh` | 27 passed, 1 failed before `load_work_evidence()`: `-wal`/`-shm` still exist after fixture close. | macOS SQLite leaves sidecars even after `wal_checkpoint(TRUNCATE)` and close. |
| Standalone WAL probe | Header stays WAL after closed sidecars are removed; the exact header-without-sidecars state can be constructed. | Fix the fixture setup, preserve the production refusal. |
| `bash test/gh549-work-events.sh` | Connector runs report `communicate failed: ValueError('I/O operation on closed file.')`; dependent cursor/card assertions fail. | `_launch` closes `proc.stdin`, `_collect` then invokes `proc.communicate()`. |
| Isolated `Popen` probe | Closed stdin + `communicate()` raises; assigning `proc.stdin = None` after close collects `('3\\n', '')`. | Fix the handoff at the launcher, preserving concurrent launch and shared deadline. |

### Recon Map

- **ATE:** `test/gh142-ate-exit-contract.sh` starts `run_variations.py`, which imports `requests` and `yaml` before it can call `compile_issue.py`. The test's expected `rc=1` alone cannot distinguish import failure from filing failure. `utils/ate/install.sh` already names `requests` and PyYAML as dependencies; `validate.sh` calls the suite without a dependency preflight.
- **Work state:** `test/test_gh605_work_state.py` constructs a WAL-mode copy, checkpoints and closes, then expects no sidecars before invoking `releases_app.load_work_evidence()`. The reader first checks the WAL header and sidecar presence and returns before opening the DB. The failure is in the fixture's precondition, not that reader.
- **Work connectors:** `work reconcile` resolves configured connectors, `_launch` starts all child processes and writes each payload, `_collect` reads results under one deadline, validates `advanced_to`, and persists cursors. The closed stdin handle causes `communicate()` to fail before result parsing; cursor and board failures are downstream. This touches a shared connector path and is **Costly** until focused and full gate checks show preservation. Rollback: revert the connector handoff change; no data migration is involved.

Root cause: missing ATE runtime dependency + WAL fixture assumption + closed subprocess stdin handle;
fix sites: ATE test preflight/toolchain docs, WAL test setup, and connector launcher respectively;
why there: the production ATE and WAL readers satisfy their contracts, while the connector error
originates where the closed handle is passed to the collector.

## Phase 1 — Ordered implementation and QA

1. Make GH-142 distinguish import/setup failure from the expected filing failure and document the local gate Python packages; rerun with and without `requests` -> expect a named dependency failure and a 30/0 result in the pinned venv.
2. Have GH-605's fixture remove closed WAL sidecars before asserting their absence; witness the old assertion fail and the updated test pass while the reader still refuses the WAL header.
3. Clear the closed `stdin` handle after the GH-549 payload is sent; run its focused suite, including the parallel-window and cursor red controls -> expect no `communicate failed` and all checks green.
4. Run the complete macOS gate once on the final approved commit in a separate disposable full clone; record result and provenance, and verify clone identity before/after. Keep #764 open and PR draft if any gate remains red.

Non-scope: no new dependency manager, connector runner abstraction, SQLite reader relaxation, or
synthetic testing framework. The three causes are separate, but they form one existing gate incident
and one bounded #764 PR. Plan QA and final QA use independent Codex relay turns.
