---
title: Lane brief — GH-168: scope wave_reconcile's trailing drift check to the reconciled PR
status: Active (2-WORKING)
created: 2026-08-24
updated: 2026-08-24
owner: noel
branch: development
doc_type: project
roadmap_exempt: true
goal: >
  Lane brief for marathon phase gh168-wave-reconcile-scope.
---

# Lane brief — GH-168: scope wave_reconcile's trailing drift check to the reconciled PR

## Status

| What was just completed | What's next |
|---|---|
| Brief authored. | Phase execution. |

Execution surface of record: `PROJECT/2-WORKING/GH-168-WAVE-RECONCILE-SCOPE.md`
(issue: https://github.com/HiQS-Labs/XYZ-forge/issues/168)

## Task

`utils/py/wave_reconcile.py` chains a trailing `marathon-plan.sh --dry-run` after its
PR-specific reconciliation. Today the runner already tolerates blanket exit 4/5 (see the
`marathon-plan` branch in the step loop, added under GH-202) — but the issue's contract is
finer than blanket tolerance and is NOT yet implemented:

1. Split the trailing check by attribution: drift attributable to the **reconciled PR's own
   items** stays fatal (rollback via RollbackJournal, unchanged); **pre-existing unrelated
   drift** downgrades to a warning block naming each held item, with no rollback.
2. Idempotence: the promotion writer moves a ROADMAP bullet between lifecycle sections, never
   adds — running reconcile twice on the same PR is a no-op (retires the #163 duplicate shape
   at the writer).
3. `test/gh168-wave-reconcile-scope.sh` (new): fixture ledger with pre-existing unrelated
   drift — reconcile of an unrelated PR succeeds with a warning; drift on the reconciled PR's
   own item still fails and rolls back; double-run is a no-op. Register in validate.sh TESTS.

Do not regress the GH-202 tolerances (exit 5 items-held logged and tolerated; see
`test/gh202-wave-reconcile-issue-state.sh`).

## Definition of done

- Both real repro shapes (`--pr 162`, `--pr 160`) succeed with a warning on pre-existing
  unrelated drift instead of rolling back.
- Drift attributable to the reconciled PR's own items still fails and rolls back, unchanged.
- Running reconcile twice on the same PR is a no-op (idempotence).
- `test/gh168-wave-reconcile-scope.sh` green and registered in validate.sh.
- `bash validate.sh` green.
