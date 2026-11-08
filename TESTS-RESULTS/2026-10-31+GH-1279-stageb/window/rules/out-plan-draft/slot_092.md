# Plan draft: #1160 docs: AGENTS.md:66 still says wave-reconcile.yml reconciles automatically after merge (contradicts #1131 dispatch-only)

> draft; preflight and independent plan QA outstanding

- Request: `gh-1160-f4379a38dcca` (tick `slot_092`)
- Draft status: **missing-scope** (held: no sourced scope)
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: f4379a38dccadc16b76327e23c135aca313881c405029748cc1a3952ffc1169f (updated 2026-10-18T21:05:46Z)
- Dependencies: none

## Scope

_missing_

## Acceptance criteria

_Source: issue#1160:L22 (Acceptance)_

- [ ] No startup or router text describes automatic hosted reconciliation after a development merge.
- [ ] `pdda.sh run` is clean.

Refs #1127, #1131, #1155.

## Open questions

_missing_

## Write set

- `AGENTS.md` (issue#1160:L3)
- `.github/workflows/wave-reconcile.yml` (issue#1160:L3)
- `utils/py/wave_reconcile.py` (issue#1160:L3)
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (issue#1160:L7)
- `ROUTER.md` (issue#1160:L8)
- `utils/pdda/pdda.sh` (issue#1160:L20)

## Unresolved file names

- none

## Contract probes

- none
