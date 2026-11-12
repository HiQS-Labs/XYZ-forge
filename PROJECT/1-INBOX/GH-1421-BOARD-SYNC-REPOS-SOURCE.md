---
gh_issue: 1421
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1421
title: "board_sync repos_source: opt-in read of Rebalance agent_session_activity (T3 work signal)"
status: Proposed (1-INBOX — not yet active)
created: 2026-11-11
owner: unassigned
doc_type: feedback
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - no Rebalance DB writes
  - no github_activity semantics change
  - no new board columns
related:
  - HiQS-Labs/rebalanceOS#375
  - #1000
  - #899
goal: >
  TODO: one-paragraph statement of what "done" looks like for this idea.
---

## Key concepts

- TODO: 2-4 bullets on what this idea concretely is and why it matters.

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# board_sync repos_source: opt-in read of Rebalance agent_session_activity (T3 work signal)

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

Follow-on to HiQS-Labs/rebalanceOS#375. That issue adds per-device T3 Code agent activity to Rebalance in a new table, `agent_session_activity`. The operator decided on 2026-11-11 that existing readers get the data through **opt-in reads of the new table**, not by writing into `github_activity`. This issue is the XYZ-forge reader: `board_sync`'s Rebalance `repos_source`.

## Observed

- `utils/py/board_sync.py:133-163` `_rebalance_active_repos` ranks repos only from `github_activity`: commits + PRs + issues + comments + reviews over `since_days`, with no login filter. Repos worked only through T3 agents, with no push yet, never reach the project board.
- On this Mac, the plain `?mode=ro` open of `~/Library/Application Support/rebalance-os/rebalance.db` failed with "unable to open database file", while `immutable=1` worked. The suspected cause, unconfirmed, is that the WAL `-wal`/`-shm` sidecars are absent and a read-only connection cannot create them. Related: #899 (stale default DB path).

## Plan

1. Add an opt-in policy key to the `github_board_selection_policy` `repos_source` block (env `XYZ_GITHUB_BOARD_POLICY_*`), default off: `include_agent_sessions: true`.
2. When the key is on, `_rebalance_active_repos` also reads `agent_session_activity` (schema from rebalanceOS#375 migration 0010) over the same `since_days`, and merges repos by a documented score. Proposed: the GitHub score plus `runs`, with agent-only repos ranked after GitHub-active ones.
3. If the table is missing (an older Rebalance), warn once and fall back to `github_activity` only. This is the same warn-and-continue path as today (`board_sync.py:155-158`).
4. Confirm or fix the `mode=ro` open failure before relying on the reader on this device. Record the cause.

## Acceptance

- [ ] With `include_agent_sessions` off, `policy-preview` output is byte-identical to today's. Red control: turning the key on with a fixture DB changes the repo list.
- [ ] With the key on and a fixture DB holding a repo present only in `agent_session_activity`, that repo appears in the preview's repo set. Red control: the same fixture with the key off omits it.
- [ ] A Rebalance DB without `agent_session_activity` warns and falls back with no exception. Red control: a DB with the table yields agent repos.
- [ ] The read-only open of the live Rebalance DB succeeds on this Mac, or the failure cause is documented with a working open mode. Red control: the current `?mode=ro` failure is reproduced first.

## Verification

Manual checks under `TESTS-RESULTS/<date>+GH-<n>/` (XYZ-forge: no new tests, GH-831), using `board_sync.py policy-preview` against fixture and live DBs.

## Dependencies

Blocked by HiQS-Labs/rebalanceOS#375 (table schema and writer). Related: #1000 (project 9 board), #899.

## Non-goals

No writes to the Rebalance DB. No change to `github_activity` semantics. No new board columns.

## Why

Repos worked only through T3 agents never reach the project board because board_sync's repos_source reads github_activity only; operator chose opt-in reads of rebalanceOS#375's new agent_session_activity table.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
