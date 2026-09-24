---
gh_issue: 757
source: https://github.com/HiQS-Labs/XYZ-forge/issues/757
title: Next-action evaluation redesign
status: In progress
owner: XYZ Forge
created: 2026-09-23
updated: 2026-09-23
goal: Evaluate recorded-action prediction and useful next-step advice on fresh, independently grouped evidence
branch: feat/gh757-next-action-evaluation
effort: 4
complexity: 4
risk: 2
phases: 4
---

# GH-757 — next-action evaluation

## Status

| What was just completed | What's next |
|---|---|
| Task isolated and registered; development-data probe recorded in `TESTS-RESULTS/2026-09-23+GH-757/` | Finish Phase 0 feasibility receipt in [#757](https://github.com/HiQS-Labs/XYZ-forge/issues/757) |

## Table of contents

- [Phase 0: feasibility](#phase-0-feasibility)
- [Phase 1: frozen contracts](#phase-1-frozen-contracts)
- [Phase 2: comparison](#phase-2-comparison)
- [Phase 3: decision](#phase-3-decision)

The [XYZ issue #757](https://github.com/HiQS-Labs/XYZ-forge/issues/757) owns the full experiment plan, protocol amendments and all substantive results. [#758](https://github.com/HiQS-Labs/XYZ-forge/issues/758) is the historical results register. This document is the repository's resumable PDDA pointer and records source seams/validation; it does not define a second protocol.

**Task rating, 2026-09-23:** read back from RELEASES as `rated 70/40/50/25` (priority/severity/appeal/cheapness). Priority reflects the operator's direct request and the need to stop reusing the weak two-trajectory sample. Severity is moderate because this is research, not a demonstrated production defect. Appeal is neutral by policy. Cheapness is 25 because grouped data, multiple harnesses and human adjudication make a full comparison substantial. The September 9–23 campaign history contains several tests of one research question, not independent recurring incidents; the August 26–September 8 period has earlier Oracle work but no comparable reported failure-rate series. Trend is unknown; no user override is recorded.

## Phase 0: feasibility

- [ ] Complete the bounded audit and roster/annotation feasibility in the owning issue; publish a go/no-go receipt there before scored inference.
- [ ] Record repository and dataset revision, existing source/consumer seams and uncertainty here without storing source text.

### Phase 0 QA

- [ ] Verify all evidence in the issue receipt against pinned source and data; incomplete items remain explicit.

## Phase 1: frozen contracts

- [ ] Register the observed-action and independently judged advice contracts, numerical gates, manifest hashes and model identities in #757 before final-test access.

### Phase 1 QA

- [ ] Independent relay reviews the frozen manifest and confirms no test-set-derived choices.

## Phase 2: comparison

- [ ] Execute only admitted arms on frozen rows, verify metrics independently and publish full or incomplete receipts in #757.

### Phase 2 QA

- [ ] Focused controls and appropriate repository tests pass; provenance and failed calls remain accounted for.

## Phase 3: decision

- [ ] Apply registered gates, publish separate A/B decisions and consumer handoff constraints in #757.

### Phase 3 QA

- [ ] Final relay approves claims against receipts and diff; local qualifying gate and hosted checks validate any ready PR.

## Initial recon and source ownership

- The future consumer is an advisory next-step view tracked by [#467](https://github.com/HiQS-Labs/XYZ-forge/issues/467); current XYZ code has no production six-action prediction endpoint. Consumer integration recon belongs only after an advice candidate passes.
- The existing data serializer/label mapper is `Needle-fork/spike/coding_core/prepare_openhands.py` at pinned dataset revision `35455389ab51bf5e2306bfd436ef72d0f98bf882`. It reads one trajectory at a time, converts preceding actions/results to q3 state and maps next tool calls to six broad labels.
- The existing simple comparators are `Needle-fork/spike/coding_core/baselines.py`; work-purpose classification in XYZ is a distinct task. `utils/py/jev_triage.py` is an existing Jev client for ATE, not a general next-action scorer. No runtime write path is being changed by this research phase.
- The operator volunteered to judge a 20-case, three-choice pilot, now posted in [#757](https://github.com/HiQS-Labs/XYZ-forge/issues/757#issuecomment-5789038344). Contract B remains unscored until those answers are received and frozen; this small pilot alone does not authorize an advisory handoff.
- Unknowns: actual advice consumer seam, OSS model/runtime choice, and final held-out repository/sample counts. Resolve them in Phase 0 or stop that arm.
