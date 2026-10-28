---
gh_issue: 1201
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1201
title: "Code audit: reduce operational complexity while preserving safety contracts"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-24
updated: 2026-10-24
owner: noelsaw
doc_type: feedback
effort: 2
complexity: 3
risk: 1
phases: 2
rating: "pri/sev/appeal/effort 75/70/85/70 · calc 300"
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1202
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1203
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1204
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1205
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1206
goal: Coordinate five evidence-backed maintainability plans without losing safety contracts or turning cleanup into a big-bang rewrite.
---

# GH-1201 — Code audit umbrella

## Quad Concepts

- Operational complexity obscures a sound kernel → five bounded follow-up plans with explicit preservation contracts.
- Cleanup can destroy evidence or safety semantics → read-only measurement, staged changes, and reversible verification.

## Revised findings

- `tick` has clear atomic publication, deterministic projection, claim locking, and epoch fencing.
- Documentation work must target duplicated active guidance and source commentary, not the much larger historical transcript/evidence corpus.
- Strict pure Python requires native containment, Bash retirement, and a compatible Python `tick`; deleting frozen twins alone is insufficient.
- SQLite integrity and foreign-key checks pass and storage compaction is unwarranted. Logical hygiene found three blank document paths, 49 nonexistent paths, and identity/lifecycle cases needing classification.
- `releases_app.py` has 6,928 lines and `marathon_drive.py` has 3,677 lines with a roughly 2,578-line `main()`. Existing #768/#769 decomposition audits should be executed behind stable facades.
- Package metadata still uses the predecessor name and a missing `index.js`; the dry-run package is 35.6 MB compressed / 150.4 MB unpacked because contents are not explicitly bounded.

## Follow-up plan

| Issue | Scope | PRS (`pri/sev/appeal/effort`) | Calc |
|---|---|---|---:|
| #1202 | Safe documentation/commentary compaction | 70/55/80/65 | 270 |
| #1203 | Pure-Python production runtime | 60/60/85/20 | 225 |
| #1204 | SQLite ledger hygiene | 80/75/75/70 | 300 |
| #1205 | Large core module decomposition | 80/75/85/35 | 275 |
| #1206 | Package identity and contents | 50/30/65/90 | 235 |

## Verification boundary

`npm run test:unit` passed 14/14. SQLite inspection and package dry-run were non-mutating. The full mutation-heavy gate was not run in the primary clone.

## Non-goals

- No blanket history deletion, big-bang rewrite, routine `VACUUM`, or automatic purge.
- No new test suites or gate machinery.
- No claim of full-gate health without a qualifying run.

## Merge evidence

- PR #1209 merged 2026-10-28 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
