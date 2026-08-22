---
gh_issue: 144
source: https://github.com/HiQS-Suite/XYZ-forge/issues/144
title: "Agent2Agent 3+ participant onboarding and read-only status quick wins"
status: Active
created: 2026-08-21
updated: 2026-08-21
owner: Codex
goal: Make the existing agentN protocol practical to onboard and inspect with no protocol expansion.
branch: feat/gh-144-agent2agent-3plus-ux
doc_type: feedback
effort: 1
complexity: 2
risk: 1
phases: 1
---

# GH-144: Agent2Agent 3+ participant UX quick wins

## Status

| What was just completed | What's next |
|---|---|
| Both additive changes implemented; pre-fix red control recorded; focused Agent2Agent suite passes 129/129 assertions in a standalone full clone. | Run the final projection/doc gates, push the branch, and open the PR to `development`. |

## Problem

Agent2Agent already supports a fixed `agent1` through `agentN` roster, but `start --agents 4` prints
only agent 2's invitation. Later seats can safely join early, wait, and arm a doorbell, yet the
operator must hand-author those invitations or onboard the roster sequentially. There is also no
seat-agnostic read-only command for inspecting the roster, current turn owner, and doorbell state.

## Scope

- Print paste-ready invitations for every non-initiator seat at startup while preserving the
  existing agent 2 invitation and single `NEXT: agent2` owner.
- Add `status --id` as a strictly read-only overview of the discussion metadata, roster, timed-watch
  mode, and advisory per-seat doorbell state.
- Document the 3+ startup flow in the skill and README.

No protocol/wire-format migration, parallel turns, broadcasts, dynamic roster mutation, agent
aliases, automatic routing, or automatic watcher/model startup.

## Acceptance criteria

- [x] A four-seat start prints invitations for agents 2, 3, and 4; agents 3 and 4 may join early and
  receive `DECISION: wait` without changing the relay file.
- [x] `status --id` reports the compact operator overview without requiring a seat number.
- [x] Byte fingerprints prove `status` creates or changes no relay, lock, or sidecar state.
- [x] Existing two-agent behavior remains compatible and `bash test/agent2agent.sh` passes in a
  disposable full clone with a recorded negative control.

## Verification

- `bash test/agent2agent.sh`
- `utils/pdda/pdda.sh frontmatter`
- `utils/pdda/pdda.sh status-table`
- `utils/pdda/pdda.sh roadmap`
- `utils/pdda/pdda.sh roadmap-coverage`
- `bash utils/roadmap-dashboard.sh --check`
- `python3 utils/py/releases_app.py check`

## Source

Live discussion and implementation review captured in [issue #144](https://github.com/HiQS-Suite/XYZ-forge/issues/144).
