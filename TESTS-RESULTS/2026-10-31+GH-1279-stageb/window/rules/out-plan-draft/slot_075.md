# Plan draft: #1168 scheduler: shared local scheduler (launchd) for XYZ jobs — first job #1184, then daily weekly-prepare + Friday start-marathon hookup (child of #1022)

> draft; preflight and independent plan QA outstanding

- Request: `gh-1168-2cba856d87cc` (tick `slot_075`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: 2cba856d87cc647ab75e25825da3be24aef4aa2c84ad951f96adba092bd45ea2 (updated 2026-10-23T05:35:20Z)
- Dependencies: none

## Scope

_Source: issue#1168:L8 (Scope)_

- A daily trigger (launchd or the repo's scheduled-task mechanism) that runs `weekly-prepare --apply` against a fresh full clone, HELD / dispatch false, and records its receipt.
- A `start-marathon` entry point that accepts an `auto-<date>` predecessor root as its intake source, so Friday's computation starts from the accumulated ledger rather than re-discovering.
- Explicit operator approval remains the gate for any fire; this issue adds no dispatch authority.

## Acceptance criteria

_missing_

## Open questions

_missing_

## Write set

- `utils/hq/hourly-global-scan.sh` (issue#1168:L37)

## Unresolved file names

- none

## Contract probes

- none
