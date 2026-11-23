# Plan draft: #1200 Factory flywheel experiment (supersedes #1199): prove the decision layer, not the build layer — foreman reconcile loop with heartbeat, measured against a 48-hour unattended window

> draft; preflight and independent plan QA outstanding

- Request: `gh-1200-dedb13a01258` (tick `slot_051`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: dedb13a01258982993d1daf7d2891633354551ba9dc148fb690f0f99e6100793 (updated 2026-10-30T20:33:46Z)
- Dependencies: none

## Scope

_Source: issue#1200:L54 (Out of scope)_

Hosted/remote execution (#1175 Phase R), auto-merge, multi-repo, any change to Marathon or relay internals.

## Acceptance criteria

_missing_

## Open questions

_missing_

## Write set

- `MACHINE-CONTRACTS.md` (issue#1200:L18)
- `releases.sql` (issue#1200:L66)
- `utils/py/jog_run.py` (issue#1200:L66)
- `utils/py/wave_reconcile.py` (issue#1200:L73)
- `test/gh280-jog-marathon-adapter.sh` (issue#1200:L112)

## Unresolved file names

- `marathon-closeout.sh` (issue#1200:L81; 2 tracked files share this name)

## Contract probes

- none
