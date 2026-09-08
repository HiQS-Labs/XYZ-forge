---
gh_issue: 494
source: https://github.com/HiQS-Labs/XYZ-forge/issues/494
title: Flight dashboard — HTML design review
status: Design in progress — awaiting operator visual approval
created: 2026-09-08
updated: 2026-09-08
owner: Codex
goal: Help the operator remember and advance concurrent repository lanes each hour.
doc_type: design
branch: feat/flight-dashboard-mockup
effort: 2
complexity: 2
risk: 1
phases: 1
---

# Flight dashboard — design brief

## Status

| What was just completed | What's next |
|---|---|
| Fresh clone, related-work recon and user design preferences recorded. | Build and visually review initial HTML, then request operator design approval. |

## Scope and checkpoint

Local interactive HTML mockup only. The operator explicitly holds the Swift app
plan until visual approval; future telemetry cadence is 2–3 minutes. No scanner,
background service, external publication, agent messaging or merge execution.
Easy to reverse: this is an isolated design artifact and mock UI state only.

## Grounding

Base: `661308219e9a02478ba6bf94888ce832d8f73d98` from origin/development.
The installed Daily skill describes prompt intent, Git/PR evidence and two-hour
trajectory synthesis. Shutdown's existing recon and design were read locally in
rebalanceOS: `PROJECT/4-MISC/recon-gh196-shutdown.md` and
`PROJECT/2-WORKING/GH-196-SHUTDOWN-HANDOFF.md`. Those documents distinguish physical
full clones, shared-common-dir worktrees, canonical remote grouping, observation
time from event time, unknown from inactivity, and deliberate deferrals.
This is document-level recon, not a fresh audit of the telemetry implementation.
No private logs, live repo inventories, or source payloads enter the public artifact.

## Agreed design

Dark mission control with restrained color. Seven repo cards fit a full-screen second-monitor view. The next action opens
a detail panel with agent context and a copyable handoff prompt. Each carries project intent, agent lanes, issue association and its basis,
PR state, count and names of full-clone folders and linked worktrees, latest
meaningful progress, and an actionable next step. A recent event in one lane must
not hide another lane's overdue handoff. Fixture data is visibly labeled.

Meaningful progress is a commit, a substantive PR state change, or completed
agent milestone. Red at >=120 minutes, amber at >=60 minutes, green below 60.
Unknown/stale data is gray; activity is not evidence of current process liveness.
Manual check-in or snooze does not reset the progress timestamp.

The 6 PM local-time countdown means wrap up: QA ready work, merge reviewed work,
preserve unfinished lanes. At and after 6 PM show wrap-up due, never silently roll
the deadline to tomorrow. Mock clock supports before/after deadline exploration.
Distinct sample QA/merge/carry-forward items are associated with repo lanes.

## Mockup construction and review

1. Build one self-contained HTML file under `docs/mockups/flight-dashboard/`,
   with inline CSS, fixture data and small plain JavaScript; no packages, remote
   assets or telemetry fetches. Use desktop grid with responsive fallback.
2. Implement repo/filter search, details with checkout names and agent context,
   copyable handoff, and simulated time controls. Controls affect mock state only.
3. Render and inspect desktop and narrow widths; exercise filters, details, keyboard
   close, copy fallback, missing-data and 6 PM states. Check totals against fixture
   records and ensure an empty search has an explicit empty state.
4. Present HTML for operator design approval. Only after that approval write the
   Swift app plan; no claim that mock observations reflect current real work.

## Review questions

Does the design cover the operator's requested hourly recall, repo/checkout names
and counts, inferred issues, PR QA/merge queue and meaningful two-hour idle signal?
Are mocked data, source uncertainty and action boundaries clear? Are countdown
and attention states coherent? Does scope remain a design artifact, preserving the
future Swift planning checkpoint and existing Daily/Shutdown source ownership?

## Rating rationale — 2026-09-08

Proposed RELEASES rating 65/45/50/80: user-requested current work; observed lost
continuity across 6–7 repos, no reported data loss; neutral appeal; inexpensive
standalone design. Related closeout #124 and rebalanceOS#196 reflect similar pain,
not independently counted incidents. Last-14-day versus preceding-14-day incident
trend is unknown; no recurrence multiplier. No operator rank override.
