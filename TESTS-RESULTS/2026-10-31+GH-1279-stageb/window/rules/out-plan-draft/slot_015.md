# Plan draft: #1202 Audit A: safely compact active documentation and source commentary

> draft; preflight and independent plan QA outstanding

- Request: `gh-1202-6c7ab41a3c8c` (tick `slot_015`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 70/55/80/65
- Capture doc: PROJECT/1-INBOX/GH-1202-DOC-COMPACTION.md (sha256 cf804ae5f1dc3702dcdf36b765f8f5bcf33533162264209849be8107533c838b)
- Issue sha256: 6c7ab41a3c8c0c9fdf398fcda4619bdd27b624cc969340d2137a3520b2095006 (updated 2026-10-24T21:37:36Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-1202-DOC-COMPACTION.md:L17 (frontmatter goal)_

Reduce duplicated active documentation and commentary while preserving canonical contracts, safety rationale, links, and historical evidence.

## Acceptance criteria

_Source: issue#1202:L32 (Acceptance criteria)_

- A repeatable inventory identifies which Markdown/commentary is eligible and which is protected.
- Each changed file has a specific duplication or readability rationale.
- No generated file, raw transcript, evidence receipt, or historical changelog is rewritten merely to reduce size.
- All canonical links, commands, safety semantics, and incident references in changed content survive.
- Existing covering checks pass in the appropriate isolated full clone; any sampled meaning preservation is reviewed independently.

_Source: PROJECT/1-INBOX/GH-1202-DOC-COMPACTION.md:L44 (Acceptance)_

- Eligible and protected content are distinguishable in the inventory.
- Every changed file has a specific readability/duplication rationale.
- No generated file, transcript, receipt, or changelog is rewritten only for size.
- Links, commands, safety semantics, and incident references survive.
- Existing covering checks pass in an isolated clone.

## Open questions

_missing_

## Write set

- `src/project.js` (issue#1202:L7)
- `utils/py/marathon_drive.py` (issue#1202:L7)
- `utils/py/rtl.py` (issue#1202:L7)
- `CHANGELOG.md` (issue#1202:L11)

## Unresolved file names

- none

## Contract probes

- none
