# Plan draft: #1281 Track open-PR merge sequence and post-merge regression QA

> draft; preflight and independent plan QA outstanding

- Request: `gh-1281-36f94eb157a4` (tick `slot_046`)
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

## Acceptance criteria

_missing_

## Open questions

_missing_

## Write set

- `.github/workflows/wave-reconcile.yml` (issue#1281:L21)
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (issue#1281:L22)

## Unresolved file names

- none

## Contract probes

- none
