# Plan draft: #1121 Merge batch 2026-10-17 — HiQS-Labs/XYZ-forge — #1062, #1089, #1097, #1120

> draft; preflight and independent plan QA outstanding

- Request: `gh-1121-7adc31d0dcb8` (tick `slot_091`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: 7adc31d0dcb8806a862c8f4f04aa9ebe7fe724a4152b184fc0a5776f31050b2b (updated 2026-10-18T21:56:47Z)
- Dependencies: none

## Scope

_Source: codex-authored (codex-authored)_

Verify the current status of the four merged PRs, integration PR #1122, hosted qualification, and batch follow-ups against current evidence.

_Source: codex-authored (codex-authored)_

Reconcile the batch record’s pending qualification and sweep inputs with its recorded clean verdict and hosted run evidence.

_Source: codex-authored (codex-authored)_

Review the deferred PR #1089 findings and post-deployment carry-overs, including details beyond the truncated issue body.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

The batch record accurately identifies the landed commits and the evidence supporting its sweep verdict.

_Source: codex-authored (codex-authored)_

Outstanding review findings and deployment carry-overs have evidence-backed current dispositions.

## Open questions

_Source: codex-authored (codex-authored)_

Does the hosted qualification cover all four landed changes, and has the pending reconcile status since been updated?

_Source: codex-authored (codex-authored)_

What post-deployment carry-overs appear beyond the truncated issue body, and which remain outstanding?

_Source: codex-authored (codex-authored)_

Have the three deferred PR #1089 findings been resolved?

## Write set

- `validate.sh` (issue#1121:L20)
- `skills/3-weekly/skills-army-hq/scripts/intake.py` (issue#1121:L48)
- `skills/3-weekly/skills-army-hq/scripts/sync.py` (issue#1121:L48)
- `TESTS-RESULTS/2026-10-17+GH-1121/review-r3-attestation.json` (issue#1121:L71)
- `ARCHITECTURE.md` (issue#1121:L76)
- `sentinel-overlay/lib/config.sh` (issue#1121:L89)

## Unresolved file names

- none

## Contract probes

- none
