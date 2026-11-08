# Plan draft: #1207 factory reconcile (#1200 P1): a mutating Jog verb leaves the primary dirty, so the next clean-primary wake refuses — publish the owned ledger paths inside the same wake

> draft; preflight and independent plan QA outstanding

- Request: `gh-1207-f2fa745a6ae9` (tick `slot_072`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: f2fa745a6ae99189085f2662c421f4e68994a50a374175d7e7e715e969bec398 (updated 2026-10-24T21:51:42Z)
- Dependencies: none

## Scope

_Source: codex-authored (codex-authored)_

Verify the reconciler's current behavior and plan publication of owned ledger paths within each mutating wake, including recovery from interrupted publication.

_Source: codex-authored (codex-authored)_

Preserve refusal of unrelated dirt and avoid changes to perform_write, Jog verbs, or Marathon.

## Acceptance criteria

_Source: issue#1207:L29 (Acceptance)_

- Two consecutive wakes that each perform a real mutation advance with no operator work; the primary is clean after each.
- An unrelated modified file in the primary still refuses the wake, with the file named in the heartbeat.
- A kill after the Jog verb and before the push, then a resume, publishes exactly once and issues no second verb (event count and queue rows unchanged).

Parent: #1200 (Revision 2, P1). Related: #1108, #1117, #1175.

_Source: codex-authored (codex-authored)_

Two consecutive mutating wakes complete without operator work and leave the primary clean after each.

_Source: codex-authored (codex-authored)_

An unrelated modified file causes refusal and is named in the heartbeat.

_Source: codex-authored (codex-authored)_

After interruption between the Jog verb and push, resume publishes exactly once without issuing a second verb; event counts and queue rows remain unchanged.

_Source: codex-authored (codex-authored)_

Use the three #1200 P1 entry controls recorded under TESTS-RESULTS for verification.

## Open questions

_Source: codex-authored (codex-authored)_

How does the current reconciler distinguish receipt-backed unpushed commits from modified owned paths without receipts across each interruption point?

_Source: codex-authored (codex-authored)_

How should bounded fast-forward retries handle conflicts or a changed remote while preserving the decision receipt?

## Write set

- `utils/py/releases_app.py` (issue#1207:L3)
- `releases.sql` (issue#1207:L7)
- `skills/2-daily/jog/SKILL.md` (issue#1207:L10)

## Unresolved file names

- none

## Contract probes

- none
