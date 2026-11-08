# Plan draft: #1110 CI audit - October 16: full suite ~64 min/merge; hosted reconcile is single-lane, parallel never qualified

> draft; preflight and independent plan QA outstanding

- Request: `gh-1110-3ad2a8fb4c27` (tick `slot_081`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: 3ad2a8fb4c27b9244fdc17201281d818204dd432bfa8503f50f5c5574df83130 (updated 2026-10-21T01:03:32Z)
- Dependencies: none

## Scope

_Source: codex-authored (codex-authored)_

Verify the current hosted reconciliation bottleneck, qualification rules, and status of the parallel-safety and stabilization work before planning changes.

_Source: codex-authored (codex-authored)_

Assess the existing parallel evidence and canary work as possible steps toward faster feedback and qualifying runs.

## Acceptance criteria

_missing_

## Open questions

_Source: codex-authored (codex-authored)_

What recommendations and constraints appear beyond the truncated issue body?

_Source: codex-authored (codex-authored)_

Are the reported timings, qualification rules, and statuses of #853 and #854 still current?

_Source: codex-authored (codex-authored)_

What evidence would establish that hosted parallel execution is safe to use as qualifying evidence?

## Write set

- `.github/workflows/wave-reconcile.yml` (issue#1110:L18)
- `test/gh436-merge-cleanup.sh` (issue#1110:L29)
- `test/gh549-work-events.sh` (issue#1110:L30)
- `test/gh365-tier-fail-closed.sh` (issue#1110:L31)
- `test/marathon-root-audit.sh` (issue#1110:L32)
- `test/gh251-validate-pytest-skip.sh` (issue#1110:L33)
- `test/gh280-jog-marathon-adapter.sh` (issue#1110:L34)
- `test/pdda-install-startup-docs.sh` (issue#1110:L36)
- `test/gh365-pdda-gov-scan.sh` (issue#1110:L37)
- `test/gh528-parallel-contention-retry.sh` (issue#1110:L38)
- `test/pdda-repo-contract.sh` (issue#1110:L39)
- `test/gh402-branch-enforcement.sh` (issue#1110:L41)
- `test/gh77-standup-triage.sh` (issue#1110:L42)
- `test/gh390-gate-guard.sh` (issue#1110:L43)
- `test/gh505-relay-attest.sh` (issue#1110:L45)
- `githooks/pre-push` (issue#1110:L51)
- `validate.sh` (issue#1110:L51)
- `utils/py/wave_reconcile.py` (issue#1110:L53)
- `utils/ci-route.sh` (issue#1110:L67)

## Unresolved file names

- `ci.yml` (issue#1110:L11; 2 tracked files share this name)
- `marathon-drive.sh` (issue#1110:L35; 2 tracked files share this name)
- `agy-turn.sh` (issue#1110:L40; 2 tracked files share this name)
- `consult.sh` (issue#1110:L44; 2 tracked files share this name)

## Contract probes

- none
