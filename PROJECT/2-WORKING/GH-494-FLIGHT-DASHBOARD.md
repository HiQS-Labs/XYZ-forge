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
| Initial HTML and browser checks complete; brief and final HTML relay reviews approved. | Operator visual approval, then Swift app planning with 2–3 minute telemetry cadence. |

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
Each lane has a progress age and explicit fixture observation state. A failed poll
or observation older than 6 minutes is unknown/gray and retains last-known age.
For the simulation, successful fixture observations repeat at the simulated time;
progress timestamps stay fixed. Unknown progress never becomes green.
Repo summary uses the worst fresh known lane (red before amber), then unknown
before green. Mixed red/gray shows red with an additional missing-data label.
Attention filtering includes red, amber and unknown repos. Activity is not evidence
of current process liveness.
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

## Design checks (planned, not yet evidence)

| Case | Expected result |
|---|---|
| 1920 × 1080 | All seven repo cards and the 6 PM queue visible without page scrolling. |
| 390 × 844 | One card column, readable controls, no horizontal overflow; vertical scrolling allowed. |
| 59 / 60 / 119 / 120 minutes | Green / amber / amber / red respectively. |
| Fresh 5-minute + fresh 130-minute + unknown lane | Red repo; overdue lane and unknown label both remain visible. |
| Missing or >6-minute-old observation | Gray lane; last-known age labeled, never inferred fresh/green. |
| Fixed mock day, 17:59 / 18:00 / 18:01 | 1 minute remaining / wrap-up due / wrap-up due; no tomorrow reset. |
| Copy permission denied | Handoff text stays visible and selectable, with a manual-copy instruction. |
| Nonempty named checkout fixtures | Counts equal list lengths; deliberately adding one to expected total fails the check. |
| Search with no matches | Explicit empty state; clearing search restores all seven cards. |

Retain screenshots and interaction/check output under local `temp/` for visual
review. Committed verification summaries may reference artifact hashes; no private
telemetry is used. Relay approval here authorizes HTML construction only, not
operator visual approval, production readiness, or starting the Swift plan.

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

## Initial HTML review artifact

Open `docs/mockups/flight-dashboard/index.html` directly in a browser. It has no
external assets or network requests. Seven example repositories represent twelve
agent lanes, sixteen full clones, seven linked worktrees and ten known open PRs;
one repo has unknown PR inventory. These are synthetic states, not live inventory.

`docs/mockups/flight-dashboard/verification.json` records the artifact hash and
local browser design checks. Desktop 1920 × 1080 fits all cards; mobile 390 × 844
uses vertical scrolling. Copy denial preserves selectable text. Countdown boundary
and progress/freshness cases were exercised. The first desktop render overflowed
and was tightened before the passing check. A deliberately wrong folder count was
rejected. Full repository runtime/promotion gates have not been run for this
design checkpoint; no ready PR or shipping claim is made.

Swift planning remains explicitly held for operator visual approval.

Final HTML review: `relay-system/2026-09-08/gh494-html-review.md`, round 2 Approved, driver exit 0. Three first-round context defects were reproduced and corrected; current artifact hashes are retained in provenance. The task remains at the operator visual-approval checkpoint.

## Layout B — focused carousel design checkpoint

The operator approved the first visual direction and explicitly requested that it
be saved to disk, committed and pushed as **Layout A**, without losing it. The exact
approved HTML is now `docs/mockups/flight-dashboard/layout-a.html`; its SHA-256 is in
`layout-a.sha256`. Treat that file as frozen. New iterations use separate files.

User choices: one repo per card, three fully visible tall cards on a second monitor,
neighboring cards peeking at both edges, horizontal swipe, a fade limited to the edge
peeks, and X at top right returning to Layout A. Quiet/stalled repos stay visible.
The only persistent UI is the cards and X. The last-hour view shows meaningful
activity, agent names, issues associated with those events and clone/worktree counts
with names. Historical/unconfirmed issues must not masquerade as last-hour activity.
Existing two-hour warning semantics and unknown-vs-quiet distinctions carry forward.

Reversibility: Easy. Preserve the exact A snapshot, build B separately, keep the
previous entry view. Existing synthetic repo/lane/PR definitions and progressEvents
are the single source for the working views. No new collector or store. Extract the
already-read fixture/icon definitions from index.html to a small local demo-data.js
used by current index and B; the frozen A remains self-contained as explicitly
requested. B uses those events, not a second invented activity stream.

1. Verify the frozen A byte hash and push its preservation commit through the normal
   hook from a disposable full clone; verify remote branch SHA and remote A bytes.
2. Build layout-b.html with native horizontal overflow, scroll snap, touch pan and
   pinch-zoom permitted, overscroll containment, keyboard arrows/Home/End and mouse
   dragging. Native touch/trackpad scrolling supplies multi-touch gestures; do not
   claim a physical Mac trackpad test from synthetic browser events.
3. Size three tall full cards at 1920×1080; start one card into the collection so both
   edge peeks are visible. Fade ends before the fully visible cards. Narrow views
   show one readable card plus peeks; no page-wide horizontal overflow. Keep rows
   and any longer content scrollable inside each card.
4. Filter progressEvents to 0 <= age < 60 minutes on the fixed sample clock. Join
   each event to its explicit lane for issue/agent attribution; deduplicate issue
   references per repo. Repos without events show a quiet state; unavailable data
   shows unknown. Show old waiting lanes separately from last-hour events. At the
   60-minute boundary remove that event and its issue from last-hour activity.
5. Browser-check three full cards and two peeks, first/last carousel boundaries,
   mouse, horizontal wheel, touch input and keyboard navigation, native zoom policy,
   X destination, last-hour event/issue boundary, quiet/unknown states, responsive
   overflow, and unchanged frozen A hash. Retain evidence with artifact hashes.
6. Run final independent review, then commit/push B to the same task branch and
   present the separate layouts for operator comparison. Swift planning stays at
   the later design checkpoint while the operator explores B.

Existing task rating retained (65/45/50/80), no operator rank override. This is an
extension of the same inexpensive design task, no new incident/recurrence claim.

Review questions: Does this match the requested cards-only presentation and exact
A preservation? Is the shared-fixture extraction bounded? Are last-hour issues
correctly scoped, quiet/unknown honest, and gestures/fades/edge behavior specified
without claiming untested hardware support? Does the plan preserve the Swift hold?
