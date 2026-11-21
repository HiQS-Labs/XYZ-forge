# Plan draft: #1188 Factory liveness: foreman dead-man's switch + Jog lease reads driver heartbeat (GH-1175)

> draft; preflight and independent plan QA outstanding

- Request: `gh-1188-7289048fa2a6` (tick `slot_065`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: 7289048fa2a62226b36f02d22e1f2b64d5315fbbe19166665de3bcef9678af61 (updated 2026-10-27T14:16:32Z)
- Dependencies: #1175

## Scope

_Source: issue#1188:L1 (Outcome)_

Every layer of the factory (#1175) has the liveness signal it needs, and none of them uses a heartbeat to decide an outcome. The most important missing signal is a **dead-man's switch for the foreman itself**: a scheduled job's normal failure mode is silence (launchd didn't fire, the Mac slept, `gh` auth expired), and nothing today would notice.

This issue records design only. Creating it does not authorize implementation, scheduling, ledger writes, or paid execution.

_Source: codex-authored (codex-authored)_

Verify the current foreman, driver heartbeat, Jog lease reconciliation, and hosted attention mechanisms before designing the liveness signals.

_Source: codex-authored (codex-authored)_

Design a local last-run record and best-effort remote visibility with an independent hosted dead-man's switch.

_Source: codex-authored (codex-authored)_

Design single-host lease reconciliation using corroborated heartbeat, process, and lease evidence; leave cross-host TTL leases to a separately gated issue.

## Acceptance criteria

_Source: issue#1188:L58 (Acceptance (when implemented))_

- L1: stop the scheduler (or sleep the Mac) past the threshold → exactly one attention signal from the hosted workflow. Resume → the signal clears on the next successful pass. An idle pass still refreshes the record.
- L2: (a) kill the driver → the item parks; (b) a hung driver with a live pid and stale heartbeat → the item parks; (c) a lease pid reused by an unrelated process → the item parks, not `running`; (d) a healthy run → the lease is untouched. Evidence as manual red/green receipts under `TESTS-RESULTS/`. No new suites (GH-831).

_Source: codex-authored (codex-authored)_

The design keeps heartbeats separate from wake-up, progress, and completion decisions; completion requires a receipt and reviewer attestation.

_Source: codex-authored (codex-authored)_

The local last-run record precedes the best-effort remote update, and reporting failures do not alter the pass exit code.

_Source: codex-authored (codex-authored)_

A stale or mismatched heartbeat produces uncertainty and corroborated reconciliation that parks work without automatic refire.

_Source: codex-authored (codex-authored)_

The design identifies how the hosted check detects missed runs and uses the existing attention pattern.

## Open questions

_Source: codex-authored (codex-authored)_

What acceptance criteria appear beyond the truncated issue body?

_Source: codex-authored (codex-authored)_

How should stale heartbeat evidence be corroborated with process and lease state before parking, especially when the process still exists?

_Source: codex-authored (codex-authored)_

Which current foreman and hosted attention mechanisms are available, and what wake interval and alert threshold should apply?

## Write set

- `utils/py/marathon_drive.py` (issue#1188:L12)
- `relay-automation/relay-turn-lib.sh` (issue#1188:L12)
- `utils/telemetry/write-xyz-heartbeat.sh` (issue#1188:L13)
- `utils/py/releases_app.py` (issue#1188:L14)

## Unresolved file names

- none

## Contract probes

- none
