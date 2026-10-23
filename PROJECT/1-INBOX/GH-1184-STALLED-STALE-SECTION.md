---
title: "daily-planner: read-only Stalled & stale section, one dated comment per device on the weekly issue"
status: "Proposed (1-INBOX - not yet active)"
created: 2026-10-22
owner: agent-b
gh_issue: 1184
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1184
doc_type: feature
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - An `arc` skill, 3-day cycles, tracking-issue creation/closing, or cross-device writes to a shared body (#1183, retired)
  - Dispatch, merging, re-rating, ledger writes, or closing member issues/PRs
  - A new collection daemon or the launchd scheduler itself (#1168 owns it; enabling any job is a separate approval)
  - A new SQLite connection to releases.db (GH-777 ratchet, #1182) or any new test suite (GH-831)
related:
  - GH-1183
  - GH-1168
  - GH-1182
goal: >
  `/daily-planner` gains a read-only "Stalled & stale" section (GitHub items idle N days
  plus this device's unpushed/uncommitted/orphaned branches and open session notes),
  with Held items listed separately, written into the existing daily pivot files and,
  with --team-issue, posted as one dated comment per device per day on the weekly issue
  (a same-day re-run edits its own comment). A headless mode runs only that scan and
  comment so the shared scheduler (#1168) can call it later.
---

# GH-1184 - daily-planner: read-only Stalled & stale section (slim successor to #1183)

> 1-INBOX capture, not the active-work doc. On promotion to `PROJECT/2-WORKING/`, add the status
> table and per-phase QA gates (`PROJECT/PDDA.md`).

## Key concepts

- **Read-only report, append-only comments.** No shared body edits, no tracking issue; each Mac posts
  its own dated comment on the weekly issue and edits only that comment on a same-day re-run (found by
  a hidden marker). Removes the whole concurrency class that sank #1183.
- **Extends the existing engine.** `/daily-planner` already requires the weekly baseline and runs
  `planner_core.py --mode daily`; the section is a new step after the merge sequence, using the GitHub
  data the engine already pulls plus a local read-only git scan.
- **Held is never Stalled.** Phase 5 held drafts and evidence carriers, hold-labelled items, and
  explicit owner holds are listed under **Held**.
- **Gaps are visible.** A failed or truncated `gh` lookup is a coverage gap, never "nothing stalled";
  a device that did not run today shows as "no report from <device> since <date>" from prior comments.

## Asks / acceptance criteria (transcribed)

1. `/daily-planner` output includes a Stalled & stale section with dated evidence per row and a
   next-action suggestion (resume / rebase / close / retire clone / route to issue #…).
2. Phase 5 held drafts, hold-labelled items and owner-held decisions appear under Held, never Stalled.
3. Two Macs running the same day produce two separate comments; a same-day re-run edits its own comment only.
4. A failed or truncated `gh` lookup is shown as a coverage gap, never as "nothing stalled".
5. Local scan is read-only: no fetch/prune/delete; no raw file contents or secrets posted (branch names,
   counts and paths only).
6. No new SQLite connection to `releases.db`; ledger reads only via the engine's loaded data or
   `releases_app.connect(path, readonly=True)`; never writes the ledger.
7. Covered by an extension to the existing daily-planner/planner_core tests; no new suite.
8. Headless, non-interactive entry point that runs only the scan and the per-device comment (for the
   #1168 scheduler; not scheduled here). A missed morning is recorded as skipped and the next report
   notes the gap per device.

## Defaults (tunable flags)

`--stale-days 3` (PRs, in-progress issues), `--draft-stale-days 7`, `--local-roots` = the target
checkout plus `~/marathon-clones/*` for the same repo; the comment is posted only with `--team-issue`.

## Why

Work started in one session or on one Mac gets forgotten and PRs go stale. #1183 solved it with a
cross-device, self-rolling issue body that four Codex plan rounds could not make race-safe; a read-only
report with per-device append-only comments has none of that.
