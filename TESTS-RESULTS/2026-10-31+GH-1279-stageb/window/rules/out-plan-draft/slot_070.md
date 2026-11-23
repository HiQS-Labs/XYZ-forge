# Plan draft: #1207 factory reconcile (#1200 P1): a mutating Jog verb leaves the primary dirty, so the next clean-primary wake refuses — publish the owned ledger paths inside the same wake

> draft; preflight and independent plan QA outstanding

- Request: `gh-1207-f2fa745a6ae9` (tick `slot_070`)
- Draft status: **missing-scope** (held: no sourced scope)
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: f2fa745a6ae99189085f2662c421f4e68994a50a374175d7e7e715e969bec398 (updated 2026-10-24T21:51:42Z)
- Dependencies: none

## Scope

_missing_

## Acceptance criteria

_Source: issue#1207:L29 (Acceptance)_

- Two consecutive wakes that each perform a real mutation advance with no operator work; the primary is clean after each.
- An unrelated modified file in the primary still refuses the wake, with the file named in the heartbeat.
- A kill after the Jog verb and before the push, then a resume, publishes exactly once and issues no second verb (event count and queue rows unchanged).

Parent: #1200 (Revision 2, P1). Related: #1108, #1117, #1175.

## Open questions

_missing_

## Write set

- `utils/py/releases_app.py` (issue#1207:L3)
- `releases.sql` (issue#1207:L7)
- `skills/2-daily/jog/SKILL.md` (issue#1207:L10)

## Unresolved file names

- none

## Contract probes

- none
