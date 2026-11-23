# Plan draft: #1201 Code audit: reduce operational complexity while preserving safety contracts

> draft; preflight and independent plan QA outstanding

- Request: `gh-1201-794fcf69ac2c` (tick `slot_001`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 75/70/85/70
- Capture doc: PROJECT/1-INBOX/GH-1201-CODE-AUDIT.md (sha256 4b4c1f5d13749dbba9a4a13a49fc82c96e28292510fd84f7f677b157a0c56b78)
- Issue sha256: 794fcf69ac2cce9563572befee956b1863ebb46a0814fd06f487ec67bbf8ed13 (updated 2026-10-24T21:38:30Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-1201-CODE-AUDIT.md:L21 (frontmatter goal)_

Coordinate five evidence-backed maintainability plans without losing safety contracts or turning cleanup into a big-bang rewrite.

## Acceptance criteria

_missing_

## Open questions

_missing_

## Write set

- `bin/tick` (issue#1201:L9)
- `src/events.js` (issue#1201:L9)
- `src/project.js` (issue#1201:L9)
- `src/claim.js` (issue#1201:L9)
- `src/lock.js` (issue#1201:L9)
- `src/paths.js` (issue#1201:L9)
- `utils/py/relay_drive.py` (issue#1201:L10)
- `utils/py/rtl.py` (issue#1201:L10)
- `ARCHITECTURE.md` (issue#1201:L10)
- `ROUTER.md` (issue#1201:L10)
- `GUIDING-PRINCIPLES.md` (issue#1201:L10)
- `relay-automation/relay-turn-lib.sh` (issue#1201:L19)
- `utils/py/releases_app.py` (issue#1201:L21)
- `utils/py/marathon_drive.py` (issue#1201:L21)

## Unresolved file names

- `README.md` (issue#1201:L10; 56 tracked files share this name)
- `index.js` (issue#1201:L22; 3 tracked files share this name)

## Contract probes

- none
