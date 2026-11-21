# Plan draft: #1243 consult: blind A/B payloads leak the CLI transcript, and the no-citation stamp misfires on cited answers

> draft; preflight and independent plan QA outstanding

- Request: `gh-1243-21430d20aff4` (tick `slot_018`)
- Draft status: **missing-scope** (held: no sourced scope)
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: 21430d20aff4e215167c680e8db246cf58606019cbe05784aadce149df97d17f (updated 2026-10-28T02:30:14Z)
- Dependencies: none

## Scope

_missing_

## Acceptance criteria

_Source: issue#1243:L18 (Done when)_

- [ ] Re-running a small Codex + agy consult gives neutral payloads of comparable shape and size: answer text only, with no exec logs, prompt echo or token footer.
- [ ] A Codex answer that cites file:line next to its `[Pass]` lines is not stamped. An answer with an uncited `[Pass]` still is.
- [ ] Verified per GH-831 with existing suites (`test/consult.sh`) plus a manual TESTS-RESULTS receipt. No new suites.

Related: #1214 (umbrella), #1219 (blind A/B).

## Open questions

_missing_

## Write set

- `utils/py/consult.py` (issue#1243:L8)
- `relay-automation/relay-turn-lib.sh` (issue#1243:L13)
- `relay-automation/consult.sh` (issue#1243:L14)
- `test/consult.sh` (issue#1243:L22)

## Unresolved file names

- `codex-turn.sh` (issue#1243:L7; 2 tracked files share this name)
