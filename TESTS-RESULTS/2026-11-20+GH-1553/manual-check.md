# Manual Check — GH-1553 (KS-06: Amendments Applied, Not Just Acknowledged)

Date: 2026-11-20
Scope: `skills/1-hourly/kickstart/scripts/run_record.py` and `skills/1-hourly/kickstart/SKILL.md` (`route=docs`; no new test suite per GH-831).

## Pre-Change Red Control (`outputs/pre-change-red.txt`)
- Evaluated pre-change `run_record.py` on a run record containing `OPERATOR_AMENDMENT: OA-1`, `PARENT_NOTE: PN-1`, and `INTERVENTION: INT-1`:
  - `pending_amendments` missed `INTERVENTION: INT-1` (only parsed `OPERATOR_AMENDMENT:` and `PARENT_NOTE:`), and there was no CLI command (`check-amendments`) to gate resume when unapplied directives existed.

## Changed Green Controls (`outputs/controls-green.txt`)
- **Control 1 (Unapplied `OPERATOR_AMENDMENT:` / `PARENT_NOTE:` / `INTERVENTION:` detection & exit-2 refusal):**
  - `run_record.py check-amendments <record>` returned exit `2` with all three unapplied directive IDs listed (`OA-1`, `PN-1`, `INT-1`) while preserving `interventions` list backward compatibility.
- **Control 2 (Applied directive clearing & non-mutating check):**
  - After recording `APPLIED: OA-1 -> ...`, `APPLIED: PN-1 -> ...`, and `APPLIED: INT-1 -> ...`, `run_record.py check-amendments <record>` returned exit `0` (`pending_amendments: []`) without mutating the run record (file SHA-256 unchanged).

## Route, Type Check & PDDA
- `utils/ci-route.sh pull_request` (piped changed files): `route=docs`, `tier=1` (`outputs/ci-route.txt`)
- `mypy --allow-untyped-defs --allow-incomplete-defs skills/1-hourly/kickstart/scripts/run_record.py`: 0 issues (`outputs/mypy.txt`)
- `./utils/pdda/pdda.sh run`: 0 errors (`outputs/pdda-run.log`)
