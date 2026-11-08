# Plan draft: #1204 Audit C: add logical SQLite ledger hygiene and safe maintenance

> draft; preflight and independent plan QA outstanding

- Request: `gh-1204-376b82298309` (tick `slot_002`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 80/75/75/70
- Capture doc: PROJECT/1-INBOX/GH-1204-LEDGER-HYGIENE.md (sha256 7b2483c7ea723a042318d73922b08be49787dc79c5acfd413e42093b26c5949d)
- Issue sha256: 376b822983097b2a378c202365629990e524d2c74873f1d1a1ad4bd443085e72 (updated 2026-10-24T21:37:38Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-1204-LEDGER-HYGIENE.md:L18 (frontmatter goal)_

Keep PRS pointers, lifecycle, and derived views clean through read-only reporting and receipted preview-first repairs, with storage maintenance driven by evidence.

_Source: codex-authored (codex-authored)_

Extend the existing PRS CLI with read-only ledger hygiene reporting, including pointer, identity, lifecycle, rating, derived-view, and native-state checks.

_Source: codex-authored (codex-authored)_

Review stale and blank document pointers through existing receipted repair verbs, recording explicit exemptions and classifying the shared #111 identity.

_Source: codex-authored (codex-authored)_

Integrate reporting into existing reconciliation and document-hygiene workflows while preserving preview-first lifecycle changes.

_Source: codex-authored (codex-authored)_

Define measurement-based storage maintenance and an operator-invoked reporting and repair cadence; avoid routine compaction, automatic purges, and a separate cleanup service.

## Acceptance criteria

_Source: issue#1204:L29 (Acceptance criteria)_

- The report reproduces the baseline classes above and distinguishes defects from legitimate multi-doc/multi-issue relationships.
- Every current stale pointer is repaired or has a documented exemption; no row is silently deleted or merged.
- Read-only reporting leaves DB, dump, and derived files byte-unchanged.
- Existing receipt-chain, dump consistency, lifecycle, and reconciliation suites pass, with negative controls witnessed on existing suites.
- Any storage operation has a measured trigger, rollback copy, and post-operation integrity/dump checks.

_Source: PROJECT/1-INBOX/GH-1204-LEDGER-HYGIENE.md:L42 (Acceptance)_

- The report reproduces baseline classes and distinguishes legitimate relationships from defects.
- Every stale pointer is repaired or exempted without silent merge/deletion.
- Read-only reporting leaves DB, dump, and derived files byte-unchanged.
- Existing receipt, dump, lifecycle, and reconciliation checks pass with negative controls.
- Storage operations have measured triggers, rollback copies, and integrity/dump verification.

_Source: codex-authored (codex-authored)_

Report baseline finding classes, distinguish legitimate relationships from defects, and never report clean after empty or failed extraction.

_Source: codex-authored (codex-authored)_

Repair or document an exemption for every stale pointer without silently deleting or merging rows.

_Source: codex-authored (codex-authored)_

Read-only reporting leaves the database, dump, and derived files byte-unchanged.

_Source: codex-authored (codex-authored)_

Existing receipt-chain, dump consistency, lifecycle, and reconciliation suites pass with witnessed negative controls.

_Source: codex-authored (codex-authored)_

Any storage operation has a measured trigger, backup, exclusive write boundary, and post-operation integrity and dump checks.

## Open questions

_Source: codex-authored (codex-authored)_

Which existing canonical documents or exemptions apply to each stale or blank pointer?

_Source: codex-authored (codex-authored)_

What measured threshold would justify a storage maintenance operation?

## Write set

- `utils/py/releases_app.py` (issue#1204:L24)

## Unresolved file names

- none

## Contract probes

- none
