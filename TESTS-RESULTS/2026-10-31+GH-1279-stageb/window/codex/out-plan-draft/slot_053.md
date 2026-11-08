# Plan draft: #1200 Factory flywheel experiment (supersedes #1199): prove the decision layer, not the build layer — foreman reconcile loop with heartbeat, measured against a 48-hour unattended window

> draft; preflight and independent plan QA outstanding

- Request: `gh-1200-dedb13a01258` (tick `slot_053`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: dedb13a01258982993d1daf7d2891633354551ba9dc148fb690f0f99e6100793 (updated 2026-10-30T20:33:46Z)
- Dependencies: none

## Scope

_Source: issue#1200:L54 (Out of scope)_

Hosted/remote execution (#1175 Phase R), auto-merge, multi-repo, any change to Marathon or relay internals.

_Source: codex-authored (codex-authored)_

Verify the current reconcile, Jog, heartbeat, scheduler, and issue state before planning the 48-hour decision-layer experiment.

_Source: codex-authored (codex-authored)_

Plan a mixed, operator-approved queue and a 10-minute heartbeat with a STOP kill switch, using existing execution and landing mechanisms.

_Source: codex-authored (codex-authored)_

Plan an independent review and a day report measuring queue truth, throughput, interventions, liveness, and decisions.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

Each wake makes at most one Jog verb decision, reads before effects, and records the snapshot and decision; existing effects are no-ops.

_Source: codex-authored (codex-authored)_

Stale heartbeats or dead processes cause a reasoned park, and a dirty primary checkout or wrong branch prevents startup and is reported in the heartbeat.

_Source: codex-authored (codex-authored)_

Admission requires a contract and a live still-real probe; landing requires per-PR approval bound to the reviewed candidate SHA.

_Source: codex-authored (codex-authored)_

The report records false dispatches, PR-ready throughput, operator interventions, wake and heartbeat gaps, alerts, and model calls on unchanged wakes.

_Source: codex-authored (codex-authored)_

Verification uses existing gh-shim suites and the decision log without adding tests.

## Open questions

_Source: codex-authored (codex-authored)_

What are the remaining independent-review requirements in the truncated issue body, and what has already landed in the relevant dependencies?

_Source: codex-authored (codex-authored)_

Which current queue candidates satisfy the mixed seed requirements and are still real?

_Source: codex-authored (codex-authored)_

How will the hosted heartbeat alert and approval-bound landing be verified during the experiment?

## Write set

- `MACHINE-CONTRACTS.md` (issue#1200:L18)
- `releases.sql` (issue#1200:L66)
- `utils/py/jog_run.py` (issue#1200:L66)
- `utils/py/wave_reconcile.py` (issue#1200:L73)
- `test/gh280-jog-marathon-adapter.sh` (issue#1200:L112)

## Unresolved file names

- `marathon-closeout.sh` (issue#1200:L81; 2 tracked files share this name)

## Contract probes

- none
