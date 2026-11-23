# Plan draft: #216 marathon-plan.sh ledger parser rejects link-style ROADMAP.md bullets — reconciler never completes

> draft; preflight and independent plan QA outstanding

- Request: `gh-216-d38e278f7736` (tick `slot_004`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 75/65/70/70
- Capture doc: PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md (sha256 7828a204d6491b4c520e5fdf88b524264731acd7bae5031aae166717b8f24c9a)
- Issue sha256: d38e278f77364d7ce8663a9bafb6dd99168233e69759eec4d438b696c6467bb8 (updated 2026-08-24T19:15:28Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md:L65 (Phase 0 — Diagnose & scope)_

> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [ ] Decide: widen `_parse_ledger()`'s bullet regex (accept `^- \[.+\]\(.+\)` in addition to `^- \*\*`) and `SECTIONS` list (accept bare `Deferred` in addition to `Deferred · vision`), OR document the bold-bullet/`Deferred · vision` format as a hard requirement for `ROADMAP.md` in consuming repos
- [ ] If widening the parser: also fix the exit-3 message, which currently blames a missing `## Ledger` heading when the real cause can be bullet/heading-name mismatch under a heading that IS present
- [ ] Set/correct triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [ ] The repro is confirmed from the report, not assumed
- [ ] A regression fixture (link-style `ROADMAP.md`) covers the failure path before the fix lands
- [ ] The fix composes with the existing harness rather than adding a parallel path

_Source: PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md:L21 (frontmatter goal)_

marathon-plan.sh's ledger parser either accepts link-style ROADMAP.md bullets (this repo's actual format) or the required bold-bullet / "Deferred · vision" format is documented as a hard constraint on consuming repos before they rely on the reconciler.

## Acceptance criteria

_missing_

## Open questions

_missing_

## Write set

- `utils/py/wave_reconcile.py` (issue#216:L3)
- `utils/py/_marathon_plan.py` (issue#216:L5)
- `utils/marathon-plan.sh` (PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md:L40)
- `PROJECT/PDDA.md` (PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md:L67)

## Unresolved file names

- `marathon-plan.sh` (issue#216:L3; 2 tracked files share this name)
- `ROADMAP.md` (issue#216:L5; 72 tracked files share this name)

## Contract probes

- none
