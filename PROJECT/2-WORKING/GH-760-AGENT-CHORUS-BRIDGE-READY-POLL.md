---
title: "agent-chorus-bridge.sh flakes on hosted wave-reconcile: remote send misses turn 2 after sleep 1"
status: Active
created: 2026-09-23
updated: 2026-09-23
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
  test/agent-chorus-bridge.sh waits for GET / HTTP 200 instead of sleep 1.0 so hosted
  wave-reconcile --qualify no longer fails closed on a startup race; next hosted
  wave-reconcile.yml run does not list this suite in failed:.
---

# GH-760 — agent-chorus-bridge.sh flakes on hosted wave-reconcile

## Status

| What was just completed | What's next |
|---|---|
| Ready-poll landed. Disposable clone: **48 passed, 0 failed**; mutation (helper always ready) went red on the closed-port control. | PR against `development`. Post-merge: hosted `wave-reconcile.yml` must not list `agent-chorus-bridge.sh` in `failed:` (cite run URL + SHA). |

## Symptom

Hosted `wave-reconcile.yml` run [35767844928](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/35767844928) failed `--qualify` because `test/agent-chorus-bridge.sh` was the one red suite (`34 passed, 10 failed`). First miss: `remote agent2 send succeeds` (no `"turn": 2`); the rest of the 10 are the same conversation never advancing. `wave_reconcile.py` exited 6 with no receipt.

## Distinct from #625

#625 was a hang at bind (`socket.getfqdn()`). This run got past health; the send path missed turn 2. Same suite, different defect.

## Flake

Later scheduled reconcile [35786932826](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/35786932826) at the same SHA `44e96b77` went green. Recurrence still burns ~70 minutes of hosted qualify.

## Phase 1 — ready poll instead of sleep 1

`test/agent-chorus-bridge.sh`: `wait_bridge_ready` polls `GET /` until the expected HTTP code (200 on the open bridge, 401 on the CF-auth bridge) or 8s. Timeout fails with the bridge log. `expect_contains` / `expect_not_contains` dump the actual body and log on fail.

### QA checklist — Phase 1

- [x] Closed-port red control: `wait_bridge_ready http://127.0.0.1:1` fails; a helper that returns 0 unconditionally makes that check go red.
- [x] `bash test/agent-chorus-bridge.sh` green in a disposable full clone (no previously passing checks skipped).
- [x] No remaining `sleep 1.0` after a bridge start.
- [ ] Post-merge: a hosted `wave-reconcile.yml` run does not list `agent-chorus-bridge.sh` in `failed:` (cite run URL + SHA).
