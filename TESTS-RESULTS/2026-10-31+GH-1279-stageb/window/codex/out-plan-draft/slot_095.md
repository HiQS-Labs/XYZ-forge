# Plan draft: #1160 docs: AGENTS.md:66 still says wave-reconcile.yml reconciles automatically after merge (contradicts #1131 dispatch-only)

> draft; preflight and independent plan QA outstanding

- Request: `gh-1160-f4379a38dcca` (tick `slot_095`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: f4379a38dccadc16b76327e23c135aca313881c405029748cc1a3952ffc1169f (updated 2026-10-18T21:05:46Z)
- Dependencies: none

## Scope

_Source: codex-authored (codex-authored)_

Verify the current reconciliation workflow and documentation, including whether the reported contradiction has already been fixed.

_Source: codex-authored (codex-authored)_

Update the startup guidance in AGENTS.md to describe local reconciliation after a merge and hosted dispatch before promotion.

## Acceptance criteria

_Source: issue#1160:L22 (Acceptance)_

- [ ] No startup or router text describes automatic hosted reconciliation after a development merge.
- [ ] `pdda.sh run` is clean.

Refs #1127, #1131, #1155.

_Source: codex-authored (codex-authored)_

No startup or router text describes hosted reconciliation as automatic after a development merge.

_Source: codex-authored (codex-authored)_

The documentation gate passes without code or test changes.

## Open questions

_Source: codex-authored (codex-authored)_

Does the current workflow still match the dispatch-only and local-default behavior described in the issue?

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
