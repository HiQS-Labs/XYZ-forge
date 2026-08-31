---
title: releases ledger roadmap layer never generalised to a vendored install
status: Active
created: 2026-08-31
updated: 2026-08-31
owner: Noel Saw
gh_issue: 349
source: https://github.com/HiQS-Labs/XYZ-forge/issues/349
doc_type: bugfix
complexity: 3
risk: 2
effort: 2
phases: 1
ratings_provisional: false
reported_from: LTVera-Pandas
harness_commit: 9d44be35
non_goals:
  - Fixing the reporting repo's own ROADMAP.md formatting or its undated releases — those are data
    problems in that repo, tracked in its own issue #322
  - Redesigning the rating system; item 4 asks only that the harness STATE which vocabulary wins
  - Adding a warning to `releases next` (recorded in the issue as out-of-scope, lower confidence)
related:
  - OPERATIONS.md in the reporting repo already records the sibling marathon-plan.sh parser bug as
    "flagged upstream, unresolved" — same root cause, different script
goal: >
  A vendored `.xyz/` install in any org can run `releases roadmap sync` against a link-style
  ROADMAP.md and get correct rows, with issue_url populated. A parse of zero entries from a
  non-empty ledger refuses instead of deleting. Canonical rating vocabulary is stated in
  RELEASES-DB-FAQS.md which ships with the vendored copy.
---

# GH-349 — releases ledger roadmap layer never generalised to a vendored install

## Status

| What was just completed | What's next |
|---|---|
| Phase 0 discovery completed; link-bullet parser, org-agnostic regex, empty-parse refusal guard, and RELEASES-DB-FAQS.md rating documentation implemented in `releases_app.py` | Run regression test suite `test/gh349-releases-roadmap-vendored.sh`, then drive Codex QA via `/relay-xyz` |

## Symptom

`releases roadmap sync` parses 0 of 51 entries from a vendored install's `ROADMAP.md`, deletes every
row in `roadmap_items`, and exits 0. Three related defects sit behind the same "written against this
repo's own conventions" root cause.

## Environment

- **Observed from:** `LTVera-Pandas` (vendored `.xyz/`)
- **Harness commit:** `9d44be35` (intake repo); vendored copy `c97f6176f53f`, vendored 2026-08-26
- **Worker/CLI:** n/a — `releases_app.py` invoked directly
- **Runtime:** Python (default; `XYZ_PYTHON` unset)
- **Sandbox:** off

## Reproduction

1. Vendor the harness into a repo whose `ROADMAP.md` uses `- [Title](path) — …` bullets rather than
   `- **Title**`.
2. Populate `roadmap_items` (any rows).
3. `python3 .xyz/utils/py/releases_app.py --root . roadmap sync --dry-run`

**Expected:** the parser reads the ledger's entries; or, failing that, the command refuses with a
non-zero exit rather than proposing to delete the table.
**Observed:** `roadmap sync: 0 in ROADMAP.md -> +0 added, ~0 updated, -4 removed, 0 unchanged`.
Without `--dry-run` the rows are deleted and the command exits 0.
**Frequency:** every time — deterministic.

## The four items & resolutions

1. **`parse_roadmap_ledger` now matches both `- **` and `- [Title](path)` bullets.** `cmd_roadmap_sync`
   now checks if `ROADMAP.md` has a non-empty ledger or if `roadmap_items` in the DB has existing rows,
   refusing with `rule=roadmap-empty-parse` rather than wiping the table.
2. **The issue-URL regex is un-hardcoded from this org.** Replaced with module-level `URL_EXTRACT_RE`
   matching any GitHub org/repo issue or PR URL (`https://github.com/[^/\s]+/[^/\s]+/(?:issues|pull)/[0-9]+`).
3. **Modification timestamps:** Clarified table timestamping model. Append-only tables (`op_receipts`,
   `manifest_state_events`, `schema_migrations`) carry immutable transaction timestamps (`at`, `applied_at`),
   while global and per-table state changes are tracked through generation counters and SHA-256 state digests.
4. **Canonical rating vocabulary documentation in vendored payload:** Added canonical rating grammar
   (`rated pri/sev/appeal/effort [ovr N]`) and axis definitions directly to `RELEASES-DB-FAQS.md`
   (which ships in vendored `.xyz/` for Tier 2) and updated citations in `releases_app.py`.

## Phase 1 — Implementation & QA

### Checklist
- [x] Fix `parse_roadmap_ledger` bullet extraction for `- [Title](path)`
- [x] Un-hardcode GitHub URL regex using org-agnostic `URL_EXTRACT_RE`
- [x] Add fail-safe refusal `rule=roadmap-empty-parse` in `cmd_roadmap_sync`
- [x] Add canonical rating documentation in `RELEASES-DB-FAQS.md`
- [ ] Add regression test suite `test/gh349-releases-roadmap-vendored.sh`
- [ ] Run Codex QA via `/relay-xyz`
