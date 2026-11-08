# Plan draft: #1276 Guard: no shipped script reads ROADMAP.md for current state in releases mode (split from #418)

> draft; preflight and independent plan QA outstanding

- Request: `gh-1276-312da3d1611f` (tick `slot_053`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: 312da3d1611fdbd5b2edefa33faa868d0908a4a460da4596c29131490cbe4b44 (updated 2026-10-30T18:44:27Z)
- Dependencies: none

## Scope

_Source: issue#1276:L15 (Scope)_

Classify each reference as either legacy-mode-only or writer/generator (allowed), or a current-state read in releases mode (a defect). Fix the defects. Add the smallest deterministic guard, preferably inside an existing check (GH-831: no new suite), that fails when a new current-state read appears.

## Acceptance criteria

_Source: issue#1276:L19 (Acceptance)_

- Every listed reference is classified, with its file and line.
- The defects are fixed or have their own issues.
- The guard fails on a seeded current-state read and passes on the classified tree.

## Open questions

_missing_

## Write set

- `utils/leaderboard.sh` (issue#1276:L10)
- `utils/marathon-plan.sh` (issue#1276:L11)

## Unresolved file names

- `ROADMAP.md` (issue#1276:L5; 72 tracked files share this name)

## Contract probes

- none
