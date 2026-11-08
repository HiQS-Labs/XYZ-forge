# Plan draft: #1145 relay harness reverts substantive PASS verdicts on block format (VERDICT:/Basis: line shape, system-note placement), burning round caps

> draft; preflight and independent plan QA outstanding

- Request: `gh-1145-105a0168b1d1` (tick `slot_056`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: 105a0168b1d198f22588a99b5b1b2f6e217b29eaf5730ce8b08a178ee0e217d0 (updated 2026-10-30T17:44:20Z)
- Dependencies: none

## Scope

_Source: codex-authored (codex-authored)_

Verify the reported verdict validation, system-note placement, and round accounting behavior before planning changes.

_Source: codex-authored (codex-authored)_

Plan clearer scaffolded verdict instructions and a fix for system-note placement or rewrite validation.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

Scaffolded reviewer instructions show the required line-start verdict block.

_Source: codex-authored (codex-authored)_

A valid reviewer block placed immediately above the next-turn marker is not rejected because of a harness-generated system note.

_Source: codex-authored (codex-authored)_

Verification uses existing checks; do not add tests without operator approval.

## Open questions

_Source: codex-authored (codex-authored)_

Is the reported behavior still reproducible, and which existing checks cover these paths?

_Source: codex-authored (codex-authored)_

Should validation-only reverts affect round accounting, or should the cap message identify format reverts?

_Source: codex-authored (codex-authored)_

How should a completed tick token be handled after a validation-only revert?

## Write set

- `relay-system/2026-10-18/gh1126-idle-race-final.md` (issue#1145:L7)
- `relay-system/2026-10-18/gh1136-b1-accepted-start-final.md` (issue#1145:L9)

## Unresolved file names

- `new-relay.sh` (issue#1145:L20; 2 tracked files share this name)

## Contract probes

- none
