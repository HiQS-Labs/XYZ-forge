---
title: "agent-chorus-bridge.sh flakes on hosted wave-reconcile: remote send misses turn 2 after sleep 1"
status: Active
created: 2026-09-23
updated: 2026-09-24
owner: Bryan Reyes
gh_issue: 760
source: https://github.com/HiQS-Labs/XYZ-forge/issues/760
doc_type: bugfix
complexity: 1
risk: 2
effort: 1
phases: 1
ratings_provisional: true
branch: fix/gh760-agent-chorus-bridge-ready-poll
harness_commit: a47c212b
non_goals:
  - Weakening or skipping --qualify (#591)
  - Re-reconciling run 35767844928 (later green at the same SHA)
  - Revisiting the #625 getfqdn bind hang
related:
  - GH-625 (prior runner-only hang, closed)
  - GH-591 (qualify must stay fail-closed)
  - GH-384 (bridge)
  - GH-293 (radar class)
goal: >
  PR #761 adds a GET / ready poll and dumps the send body plus bridge log on a failed
  assertion. It does not fix the run 35767844928 send miss (health already passed).
  #760 stays open until a failing run shows that body.
---

# GH-760 — agent-chorus-bridge.sh flakes on hosted wave-reconcile

## Status

| What was just completed | What's next |
|---|---|
| Review on PR #761: the ready-poll does not explain run 35767844928 (GET / 200 and both joins passed before the send miss). Diagnostics stay. Claim corrected so the PR refs #760 and does not close it. | Merge `origin/development` and resolve the ledger. #760 stays open until a failing run prints the send body. |

## Symptom

Hosted `wave-reconcile.yml` run [35767844928](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/35767844928) failed `--qualify` because `test/agent-chorus-bridge.sh` was the one red suite (`34 passed, 10 failed`). First miss: `remote agent2 send succeeds` (no `"turn": 2`); the rest of the 10 are the same conversation never advancing. `wave_reconcile.py` exited 6 with no receipt.

## Distinct from #625

#625 was a hang at bind (`socket.getfqdn()`). This run got past health; the send path missed turn 2. Same suite, different defect.

## Flake

Later scheduled reconcile [35786932826](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/35786932826) at the same SHA `44e96b77` went green. Recurrence still burns ~70 minutes of hosted qualify.

## Phase 1 — diagnostics, not a claimed fix

Run 35767844928 passed bridge start, `GET /` 200, session create, and both joins before `remote agent2 send` missed `"turn": 2`. A later idempotent send in the same suite committed turn 2. The `runtime/agent2.watch` traceback is from `agent-chorus.sh`. `wait_bridge_ready` remains as readiness hardening. `dump_diag` prints the client body and the last 50 log lines on a failed assertion so the next red names the send-path cause.

### QA checklist — Phase 1

- [x] Closed-port red control: `wait_bridge_ready http://127.0.0.1:1` fails; a helper that returns 0 unconditionally makes that check go red.
- [x] `bash test/agent-chorus-bridge.sh` green in a disposable full clone (no previously passing checks skipped).
- [x] No remaining `sleep 1.0` after a bridge start.
- [x] PR text refs #760 and does not claim the poll fixed the send miss.
- [ ] A later failing hosted run shows the send body (or a verified cause). #760 stays open until then.

## Merge evidence

- PR #761 merged 2026-09-24 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
