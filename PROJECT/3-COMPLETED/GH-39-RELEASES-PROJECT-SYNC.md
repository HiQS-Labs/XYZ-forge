---
title: "GH-39: Project RELEASES.DB into GitHub release cards"
gh_issue: 39
source: "https://github.com/HiQS-Labs/XYZ-forge/issues/39"
status: active
created: 2026-08-18
updated: 2026-08-19
owner: unassigned
goal: "Project the RELEASES SQLite ledger into GitHub release cards so release state is visible outside the repo."
doc_type: bugfix
---

# GH-39 — GitHub Project release-card projection

## Status

| What was just completed | What's next |
|---|---|
| Added an explicit, one-way `releases project sync` writer, Project-schema refusal, and a mocked regression suite. | Apply it to the private XYZ Forge Releases Project, obtain review, and merge through PR review. |

## Goal

Make the SQLite release ledger the sole writer of a human-readable GitHub Project view. The
projection uses the immutable Release ID as its remote idempotency key, so reruns update cards
instead of creating duplicates.

## Design

- `releases project sync --owner ORG --number N` is dry-run by default; `--apply` is required to
  write GitHub.
- The writer refuses if the target Project lacks any required field or select option, rather than
  silently creating a divergent schema.
- Project card text is intentionally one-way: editing a card in GitHub never writes to
  `releases.db`.
- The Project’s view includes its target-date field for release-order planning.

## Verification

- `test/gh39-releases-project-sync.sh`: dry-run non-mutation, initial create, idempotent repeat
  update, and missing-schema refusal.
- Live sync is scoped only to HiQS-Labs Project #2 and uses the existing eight release cards.
