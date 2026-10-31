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

_Source: codex-authored (codex-authored)_

Verify what PR #1209 delivered and identify remaining work while issue #1202 remains open.

_Source: codex-authored (codex-authored)_

Inventory and classify active documentation and source commentary separately from protected generated files, completed plans, transcripts, and evidence.

_Source: codex-authored (codex-authored)_

Pilot selective compaction with per-file rationale and independent meaning-preservation review, then consolidate repeated guidance into canonical owners and retain pointers.

_Source: codex-authored (codex-authored)_

Measure changes to selected files and run existing PDDA and affected source checks in an isolated full clone.

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

_Source: codex-authored (codex-authored)_

A repeatable inventory distinguishes eligible content from protected content.

_Source: codex-authored (codex-authored)_

Each changed file has a specific duplication or readability rationale.

_Source: codex-authored (codex-authored)_

Current commands, ownership, canonical routing, safety rationale, incident references, evidence links, and machine-readable contracts survive.

_Source: codex-authored (codex-authored)_

Generated files, transcripts, evidence receipts, and historical changelogs are not rewritten merely to reduce size.

_Source: codex-authored (codex-authored)_

Existing covering checks pass and sampled meaning preservation is independently reviewed; no new gates or test suites are introduced.

## Open questions

_Source: codex-authored (codex-authored)_

What did merged PR #1209 complete, and what remains open under issue #1202?

_Source: codex-authored (codex-authored)_

Which active documents and comments are suitable for the initial low-risk pilot?

## Write set

- `src/project.js` (issue#1202:L7)
- `utils/py/marathon_drive.py` (issue#1202:L7)
- `utils/py/rtl.py` (issue#1202:L7)
- `CHANGELOG.md` (issue#1202:L11)

## Unresolved file names

- none

## Contract probes

- none
