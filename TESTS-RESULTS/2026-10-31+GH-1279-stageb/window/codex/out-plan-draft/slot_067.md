# Plan draft: #1224 Explore: move each project's operational work ledger outside the repo (factory flywheel, GH-1175)

> draft; preflight and independent plan QA outstanding

- Request: `gh-1224-eee37f84e2ff` (tick `slot_067`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: eee37f84e2ff0370056278d1791c95e99cc57421f9e2f454f7e022f8bf049f11 (updated 2026-10-26T02:47:06Z)
- Dependencies: none

## Scope

_Source: codex-authored (codex-authored)_

Explore the proposed split between an external operational ledger and decisions of record kept in git, including a diff-level assessment of current ledger churn.

_Source: codex-authored (codex-authored)_

Evaluate a local-first SQLite spike and the implications for leases, auditability, offline work, worktree isolation, and existing ledger integrations.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

The exploration identifies the governance and operational tradeoffs, the spike's decision criteria, and the evidence needed before considering a migration.

_Source: codex-authored (codex-authored)_

The plan remains exploratory and does not authorize implementation, migration, or changes to releases_app write paths.

## Open questions

_Source: codex-authored (codex-authored)_

What spike steps and decision gates appear beyond the truncated issue body?

_Source: codex-authored (codex-authored)_

Should PRS ratings be operational state or decisions of record?

_Source: codex-authored (codex-authored)_

Which ledger costs and integration assumptions remain current?

## Write set

- `releases.sql` (issue#1224:L9)
- `utils/py/marathon_drive.py` (issue#1224:L97)

## Unresolved file names

- none

## Contract probes

- none
