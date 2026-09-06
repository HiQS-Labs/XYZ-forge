---
title: "GH-452: Start publishing release tags (git tag + GitHub Release per shipped ledger release)"
status: Queued
created: 2026-09-05
updated: 2026-09-05
owner: orchestrator (Claude Code)
gh_issue: 452
source: https://github.com/HiQS-Labs/XYZ-forge/issues/452
doc_type: plan
effort: 2
complexity: 2
risk: 2
rating: "pri/sev/appeal/effort 60/30/80/70 · calc 240"
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/39
  - https://github.com/HiQS-Labs/XYZ-forge/issues/69
  - https://github.com/HiQS-Labs/XYZ-forge/issues/382
goal: >
  Every shipped ledger release gets an annotated v-tag on main and a GitHub Release built from the
  ledger manifest, with the tag SHA recorded back into the ledger row via CLI verb.
---

# GH-452: Release tags

## Why

Versions live in `releases.db` but nothing on GitHub marks a shipped release. The README now says so
plainly ("No release tags — two archival tags only"). Adopters cannot pin, diff, or roll back to a
known version, and vendored `.xyz/` installs cannot report which harness version they carry.

The two existing tags (`bash-final-2026-07-28`, `prereset/development-2026-09-02`) are archival, not
releases.

## Key Concepts

- Tag name derives from the ledger version (`v<major>.<minor>.<patch>`), cut on `main` at ship time.
- GitHub Release body is the ledger manifest — extend the #39 projection path, do not add a second one.
- Tag SHA is written back to the ledger row through `releases_app.py`; never hand-edit `releases.sql`.
- `xyz-vendor.sh` stamps tag/SHA into the vendored install so `hq` can report harness version per repo.
- Backfill already-shipped releases only where the landing commit is identifiable; otherwise start
  from the next release.

## Acceptance

- `git tag --list 'v*'` non-empty after the next ship.
- README "Release tags" row points at the Releases page.
- Ledger row carries the tag; `releases check` is clean.
- The tag step does not require the full suite (#382).

## Phases

- Phase 0 — decide tag/version mapping and backfill policy (operator decision).
- Phase 1 — `releases_app.py` ship verb cuts the tag and records the SHA.
- Phase 2 — GitHub Release publication from the ledger manifest.
- Phase 3 — vendor stamp + `hq` version report.
