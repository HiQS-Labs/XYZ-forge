# Plan draft: #1206 Audit E: correct package identity entrypoint and contents

> draft; preflight and independent plan QA outstanding

- Request: `gh-1206-57443808869c` (tick `slot_022`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 50/30/65/90
- Capture doc: PROJECT/1-INBOX/GH-1206-PACKAGING-DRIFT.md (sha256 ed9dab9e1a820c402c23c8c1ce00d5887365396935d1d3d9ddf9d262680bcb3a)
- Issue sha256: 57443808869ceccd071b3f11ac85498b103f0e2012764905b54beed94fee96bb (updated 2026-10-24T21:37:40Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-1206-PACKAGING-DRIFT.md:L17 (frontmatter goal)_

Align npm metadata with XYZ Forge and explicitly bound package contents without publishing or changing the release version.

## Acceptance criteria

_Source: issue#1206:L19 (Acceptance criteria)_

- No stale predecessor package name remains in package/lock metadata.
- No `main` entry references a missing file.
- Metadata declares the same Node baseline as the README.
- The dry-run package contains only intentional assets and excludes evidence, runtime state, ledgers, and transcripts.
- The 14 kernel unit tests still pass, and any declared CLI works from the packed artifact.
- No npm publish, version bump, or release-tag change occurs.

_Source: PROJECT/1-INBOX/GH-1206-PACKAGING-DRIFT.md:L38 (Acceptance)_

- No predecessor package name remains in package/lock metadata and no missing `main` target remains.
- Node engine matches the README.
- Dry-run contents exclude evidence, state, ledgers, and transcripts.
- All 14 kernel unit tests pass; any declared CLI works from the packed artifact.
- No publish, version bump, or release-tag change occurs.

## Open questions

_missing_

## Write set

- `bin/tick` (issue#1206:L16)

## Unresolved file names

- `package.json` (issue#1206:L5; 3 tracked files share this name)
- `index.js` (issue#1206:L6; 3 tracked files share this name)
- `package-lock.json` (issue#1206:L15; 2 tracked files share this name)

## Contract probes

- none
