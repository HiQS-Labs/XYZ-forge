# Plan draft: #1281 Track open-PR merge sequence and post-merge regression QA

> draft; preflight and independent plan QA outstanding

- Request: `gh-1281-36f94eb157a4` (tick `slot_048`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: 36f94eb157a4be7fc27d89b3f33160a55c9b1b1d04591a371a00152dfaad5b7b (updated 2026-10-31T06:41:57Z)
- Dependencies: none

## Scope

_Source: issue#1281:L3 (Authorized scope and readiness)_

Candidate PRs: #1245, #1259, #1268, #1277, #1278. #1024 is a draft and excluded until its owner makes it ready.

Primary readiness currently blocked: development has uncommitted releases.db/releases.sql and untracked peer intake/review artifacts. Preserve these; no stash/reset or readiness override authorized. No local-only integration commits observed against the cached remote.

_Source: codex-authored (codex-authored)_

Verify the current primary checkout and candidate PR states before planning any landing.

_Source: codex-authored (codex-authored)_

Plan the merge-cleanup dry run, independent strategy review, driver-owned batch record, ordered landings, and governance reconciliation.

_Source: codex-authored (codex-authored)_

Plan cross-PR regression analysis, the applicable sweep, carry-over recording, and safe checkout retirement.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

Primary readiness is established without losing peer work or overriding readiness checks.

_Source: codex-authored (codex-authored)_

The batch record captures pinned PR heads, reviewed merge order, landing results, and rollback boundaries; draft PR #1024 remains excluded until ready.

_Source: codex-authored (codex-authored)_

The regression verdict cites the merged range and exact evidence, and remains deferred for full qualification until the required hosted sweep receipt exists.

_Source: codex-authored (codex-authored)_

Post-deployment carry-overs are copied verbatim and unchecked, and only verified idle, recoverable checkouts are retired.

## Open questions

_Source: codex-authored (codex-authored)_

What are the current states of the primary checkout and candidate PRs, and has the provisional merge order changed?

_Source: codex-authored (codex-authored)_

What evidence resolves the primary readiness blocker while preserving the ledger and peer artifacts?

## Write set

- `.github/workflows/wave-reconcile.yml` (issue#1281:L21)
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (issue#1281:L22)

## Unresolved file names

- none

## Contract probes

- none
