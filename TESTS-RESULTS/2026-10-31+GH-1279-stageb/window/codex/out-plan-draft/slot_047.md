# Plan draft: #1285 Merge batch 2026-10-30 — HiQS-Labs-XYZ-forge — #1245, #1259, #1277, #1278

> draft; preflight and independent plan QA outstanding

- Request: `gh-1285-d276db381d6f` (tick `slot_047`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: d276db381d6f0cb69a6fbeedc4c7fafc96b4211707d85891ccd40611dad19e33 (updated 2026-10-31T06:41:59Z)
- Dependencies: none

## Scope

_Source: codex-authored (codex-authored)_

Verify the current batch and PR states against issue #1285 and its tracker before identifying outstanding work.

_Source: codex-authored (codex-authored)_

Reconcile the recorded landed range, held PRs, regression sweep evidence, and post-deployment carry-overs with the batch record.

_Source: codex-authored (codex-authored)_

Track the full hosted registry sweep required before promotion and preserve the deferred verdict until its receipt exists.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

The batch record accurately identifies landed PRs, their merge commits, reconciliation results, and held candidates.

_Source: codex-authored (codex-authored)_

The regression verdict cites evidence for the landed range and does not claim full qualification without the hosted sweep receipt.

_Source: codex-authored (codex-authored)_

Any applicable post-deployment carry-overs are recorded with their source.

## Open questions

_Source: codex-authored (codex-authored)_

Have PR #1278 or the held candidates changed state since the recorded batch verdict?

_Source: codex-authored (codex-authored)_

Has the hosted full-registry sweep run, and is its receipt applicable to the relevant development revision?

## Write set

- `LEADERBOARD.md` (issue#1285:L18)
- `CHANGELOG.md` (issue#1285:L19)
- `releases.sql` (issue#1285:L19)
- `validate.sh` (issue#1285:L26)
- `.github/workflows/wave-reconcile.yml` (issue#1285:L27)
- `relay-automation/new-relay.sh` (issue#1285:L62)

## Unresolved file names

- none

## Contract probes

- none
