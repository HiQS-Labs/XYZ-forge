---
title: 'GH-1080: Express docs admission recon'
status: Active
created: 2026-10-15
updated: 2026-10-15
owner: Codex
goal: Map express verification and receipt consumers before extending admission
roadmap_exempt: true
---

# Recon Map — express documentation admission

Commit: 05f693d5d5b2c0f4fb510d3682396ad966106506 · Mode: graph lead + exact source reads · Lanes: A–D in one bounded main-context trace.

## Status

| What was just completed | What's next |
|---|---|
| Source and receipt consumers traced | Verify implementation against this map |

## Subject and change class

Extend admission in the existing express driver, not a new landing path. Costly until qualified: admission controls direct development writes. Rollback is reverting the admission/skill/SOP changes; no schema or new receipt format is needed.

## Seams and call paths

- `skills/2-daily/express/SKILL.md` directs users to `utils/py/express.py`; SOP section 4 permits only explicit express requests.
- `express.py:1203` parser → `cmd_run:1189` → `cmd_check:426` → `cmd_docs:565` → `cmd_ledger:694` → `cmd_land:742`. Standalone steps use the same functions.
- `cmd_check:536` requires a registered suite for every change. It does not distinguish documentation from code. `insertions:405` can count binary data as text for new images.
- `test/pdda-repo-contract.sh:1` already runs the actual deterministic docs gate (`utils/pdda/pdda.sh run`); it is registered at `validate.sh:557`. Reuse this suite for documentation mode rather than inventing a runner, suite or receipt format.
- `cmd_land:767` runs the selected suite, verifies gate wiring and qualified content after the run, then stages exact paths and pushes fast-forward. `closeout:845` persists the exact suite/commit/rc receipt before gated reconciliation.
- `valid_express_receipt:210` and `cmd_resume:1109` match commit, issue, exact suite command and success from committed receipts. Selecting the existing docs suite keeps this contract intact; resume must resolve the same default suite in documentation mode.
- `test/gh267-express-skill.sh` is the existing hermetic behavior suite, including hotfix refusals, real write surfaces, TOCTOU, interrupted closeout and resume controls.

## State and downstream checks

No new durable state. The explicit mode selects the existing docs suite; its receipt command is `bash test/pdda-repo-contract.sh`. Existing closeout selects and advances that exact commit/issue receipt to reconciliation and completion. A docs receipt must not be described as runtime behavior coverage. Retry remains explicit resume with the original commit and suite; no new background retries. Parameter role: mode restricts eligible paths and selects a fixed verifier, never generates work. Old readers can already match this suite command, so no mixed-version schema migration is needed.

## Scope and unknowns

Ordinary README/docs/project text and image assets qualify; extension alone must not admit executable files, symlinks, runtime/config, generated outputs or policy/skill instructions. Filename enumeration must include the source of a rename so code cannot disappear behind a documentation destination. Manual rendering/link/content checks remain agent obligations, not proof from the structural PDDA suite. Unknown: final gate runtime and hosted check outcome until executed.
