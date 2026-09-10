# GH-549 — implementation QA brief (PR #559)

This is the **implementation** review. The plan for this change already passed a five-round
plan QA (`relay-system/2026-09-10/gh549-work-events-plan-qa.md`). Do not re-review the plan's
design choices that were settled there unless the committed code **departs** from them.

Review the code that is actually on this branch.

## What to review

- Branch: `feat/gh549-work-events-connectors` · head `c737cbd3` · base `52938679` (PR #559).
- The full diff: `git diff 52938679..HEAD` in the worktree you are running in.
- Read the changed files **in full**, not just the hunks (GH-268 whole-file sweep).

## Files changed (implementation, in review priority order)

| File | What changed |
|---|---|
| `utils/py/releases_app.py` | migration 008 (`work_events`, `connector_cursors`, append-only triggers); `dump_text`/`load_dump` placement; the extractor registry (`NON_EVENT_OPS`, `WORK_EVENT_EXTRACTORS`, `extractor_for`); `_record_work_event`; `perform_write`'s new `work_event=` parameter and the single dispatch seam; `_dispatch_work_connectors`; `cmd_work_emit`; `cmd_work_reconcile`; the `work {emit,reconcile}` CLI |
| `utils/py/work_connectors/__init__.py` | new — bounded concurrent connector dispatch, cursor persistence |
| `utils/py/device_config.py` | `load_device_config_diagnostic`, `resolve_device_block` |
| `utils/py/board_sync.py` | baked-in board identity removed; `require_board_identity`; scope-error detection on both `_gql` failure paths; `resolve_settings` reduced onto `resolve_device_block` |
| `utils/py/mock_gh_board.py` | sticky `insufficient_scopes` fault |
| `skills/merge-cleanup/scripts/merge_cleanup.py` | `CLOSES_RE`, `linked_issues`, `emit_pr_merged` |
| `test/gh549-work-events.sh` | new suite, 42 assertions |
| `test/gh402-board-sync.sh`, `test/gh405-mock-board-harness.sh` | assertions for the board-identity and scope changes |
| `validate.sh`, `utils/ci-route.sh`, `test/ci-route.sh` | suite registration |

## Supporting context (read; do not take these documents' word for the code)

- `PROJECT/2-WORKING/GH-549-WORK-STATE-EVENT-STREAM.md` — the approved plan and its acceptance criteria.
- `PROJECT/1-INBOX/recon-gh549-work-events.md` — the recon map the plan was written against.
- `relay-system/2026-09-10/gh549-work-events-plan-qa.md` — the five plan-QA rounds and their dispositions.
  Rounds 1, 3 and 5 each killed a design defect; the reasoning there is the record of **why** the code
  looks the way it does. In particular: `connector_cursors` is deliberately absent from `dump_text`
  entirely, because `cmd_check` byte-compares the committed dump against `dump_text(conn, db_gen)`
  (`utils/py/releases_app.py:4627`, rule `dump-divergence`) — a cursor row mutating after the dump was
  written would make `releases check` fail on every healthy repo after the first connector run.
- `TESTS-RESULTS/2026-09-10+GH-549/SUMMARY.md` — the gate evidence and its provenance.
- Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/549

## Definition of Done — answer each of these explicitly

1. **Is issue #549 satisfied?** Map each acceptance criterion on the issue to the code that
   satisfies it, at `file:line`. Name any criterion that is unmet or only partially met.
2. **Do the actual codepaths match the plan?** Where the code departs from
   `PROJECT/2-WORKING/GH-549-WORK-STATE-EVENT-STREAM.md`, say so and say whether the departure is
   an improvement, a regression, or an undocumented scope change.
3. **Did a duplicate subsystem or a second write path slip in?** The contract is that every work
   event is emitted inside the one existing ledger write seam, `perform_write`
   (`utils/py/releases_app.py:1317`), and that no caller emits or dispatches on its own.
   Verify that against the 29 call sites, not against the plan's claim.
4. **Do the checks substantiate the claims?** `test/gh549-work-events.sh` asserts 42 things.
   For each red control in it, is the mutation actually isolating the condition it names, and would
   the assertion genuinely fail without the fix (AGENTS.md §6)? Name any assertion that is vacuous —
   one that would pass against an empty table, an absent anchor, or a no-op.
5. **Correctness and safety of the new code**, specifically:
   - the writer-lock hold time and ordering in `_record_work_event` / `perform_write`;
   - what happens if a connector subprocess hangs, crashes, or writes garbage;
   - cursor persistence under concurrency — is the parent genuinely the sole cursor writer;
   - the append-only triggers versus every path that writes `work_events`;
   - migration 008 against an existing populated ledger, and the rebuild round-trip;
   - `XYZ_WORK_CONNECTORS=0` and the `XYZ_WORK_CONNECTORS_REGISTRY` test overlay — can the overlay
     be abused to run something it should not?
6. **Pre-existing defects** in the files this change touches are IN SCOPE (GH-268). If you find
   none, say so explicitly.

## Known and already disclosed — do not report these as new findings

- PR #559 currently conflicts with `development` on `releases.db` / `releases.sql` only (the
  generated ledger artifacts). That is resolved with the repo's `releases-merge-resolve.sh` at
  merge time, and is not an implementation defect.
- Issue #558: `test/gh32-releases-app.sh` section J fails ~24% of the time on `development` itself
  (6/25), independent of this branch (2/19 here). It is filed, it is pre-existing, and the
  attribution correction is recorded in `TESTS-RESULTS/2026-09-10+GH-549/SUMMARY.md`.
