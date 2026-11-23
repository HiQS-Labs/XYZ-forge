# Plan draft: #1177 releases.db: 60 of 342 rated roadmap rows carry placeholder ratings (13 on the PDDA 1–5 scale, 47 at 50/50/50/50) that rank as real PRS scores

> draft; preflight and independent plan QA outstanding

- Request: `gh-1177-76aa8bd933b1` (tick `slot_075`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: 76aa8bd933b1de6e0dc250356da362811efb2ec7af3438a67509788fd93cc1ac (updated 2026-10-24T14:02:15Z)
- Dependencies: none

## Scope

_Source: codex-authored (codex-authored)_

Verify the reported placeholder rating shapes and current scan, rating, ranking, and check behavior before planning remediation.

_Source: codex-authored (codex-authored)_

Plan explicit placeholder classification and deliberate re-rating with a recorded reason; do not automatically convert PDDA ratings to PRS.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

The rater scan identifies ratings with all four axes at or below 5 and ratings exactly 50/50/50/50 as placeholders.

_Source: codex-authored (codex-authored)_

Re-rating a placeholder requires a deliberate force path and records the reason as placeholder; no silent re-score occurs.

_Source: codex-authored (codex-authored)_

releases check warns on both rating shapes.

## Open questions

_Source: codex-authored (codex-authored)_

Are the reported counts and affected rows still current?

_Source: codex-authored (codex-authored)_

How should legitimate ratings matching either placeholder shape be distinguished or handled?

_Source: codex-authored (codex-authored)_

What operator decision is needed before adopting the proposed classification and re-rating policy?

## Write set

- `utils/py/_marathon_plan.py` (issue#1177:L13)

## Unresolved file names

- none

## Contract probes

- none
