---
gh_issue: 280
source: https://github.com/HiQS-Labs/XYZ-forge/issues/280
title: "Recalibrate Jog as a serial supervisor over Marathon execution"
status: "Proposed (1-INBOX — not yet active)"
created: 2026-08-27
owner: noel
doc_type: feedback
effort: 4
complexity: 4
risk: 3
phases: 4
ratings_provisional: false
related:
  - GH-279
  - GH-259
  - PROJECT/1-INBOX/recon-jog-marathon-recalibration.md
fix_probes:
  - bash test/jog-queue.sh
  - bash test/marathon-drive.sh
goal: >
  Keep Jog's serial queue authority while delegating per-task execution to Marathon's reviewed,
  gated, retry-safe, branch-safe one-phase driver through additive structured contracts.
---

# GH-280 · Jog ↔ Marathon recalibration

## Why

The first real unattended Jog queue run in GH-279 landed all four tasks but required six manual
unblocks. Recon found that Jog reused `relay-drive`, not Marathon's one-phase driver, and independently
rebuilt Tick seeding, agent environment, terminal interpretation, retry handling, branch creation,
and PR discovery.

## Authority boundary

- Jog owns serial ordering, leases, intake/promotion, landing policy, and receipt-backed queue status.
- Swarm Preflight owns the resolved readiness contract.
- Marathon owns reviewed execution, attempts, Tick history, acceptance, gates, branch/commit state,
  and PR creation.
- `wave_reconcile.py` owns post-merge issue/doc/roadmap lifecycle.

Jog's execution status becomes a projection of Marathon's durable result, never a second execution
authority.

## Work requested

1. Pin a real root-and-vendored Jog integration test; simulation is insufficient.
2. Add additive structured invocation/result contracts to Swarm Preflight and Marathon without
   changing existing defaults or exits.
3. Add an opt-in Jog adapter that invokes one reviewed Marathon phase and consumes its result receipt.
4. Separate resume, gate-only retry, and artifact rebuild; preserve queue position and append-only
   Tick history.
5. Add idempotent `jog land/reconcile` verification and delegate lifecycle closeout to
   `wave_reconcile.py`.
6. Dogfood root and `.xyz` runs before flipping the Jog default; retain a bounded legacy rollback.

## Decisions before implementation

- Reviewer selection and cost policy.
- Branch naming versus receipt-only branch identity.
- Existing-PR adoption checks.
- Queue attempt-count meaning.
- Replay order across GitHub merge, queue update, and PDDA reconciliation.

## Evidence and acceptance

- GH-279 is the production reproduction and is cross-linked to this issue.
- `bash test/jog-queue.sh` currently passes 34/0 but runs only simulated execution.
- `bash test/marathon-drive.sh` passes 152/0 and covers the mechanics Jog duplicated.
- Existing Marathon callers remain compatible when new structured outputs are unused.
- No builder-only Marathon shortcut, Tick-history deletion, shared-branch commits, or log parsing API.

Full trace: [Recon Map — Jog ↔ Marathon recalibration](recon-jog-marathon-recalibration.md).
