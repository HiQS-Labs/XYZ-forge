---
title: Closeout evidence recon map
status: Active
created: 2026-09-16
updated: 2026-09-16
owner: noel
goal: Ground GH-656 and GH-657 in their existing evidence seams.
roadmap_exempt: true
quad_exempt: true
---

# Recon Map — closeout evidence

Commit: a605f5d40a178611a0f64a8dc9d0ae87caaa04ab · grep-only · one local bounded lane.
This preserves the intake trace originally embedded in the shared plan before its execution steps.

## Status

| What was just completed | What's next |
|---|---|
| Existing producer/consumer and receipt failure paths traced | Apply the shared GH-656 repair plan and its recorded verification gates |

## Subject and change class

Existing offline merge evidence and pre-merge outcome validation; cross-module contract repair,
no new authority or writer.

## Seams and call paths

| Seam | Location at intake | Crosses | Breaks if |
|---|---|---|---|
| Verified PR → offline manifest | utils/py/jog_run.py:950,1001,1023 | Jog land/reconcile → real wave reconciler | Verified merge proof is omitted |
| Offline PR → manifest ship | utils/py/wave_reconcile.py:328,1106 | PR object → owned release membership | Full mergeCommit.oid is absent |
| Committed receipt → pre-merge decision | utils/py/wave_reconcile.py:695,779 | Git tree JSONL → run_pre_merge | One positive field masks explicit failure |

## State and contracts

Jog persists its existing landing projection before reconciliation, then stores reconciled evidence.
Release-member shipping uses the existing CLI/transaction/event writer; repeat lookup excludes shipped
members. Receipt validation reads committed JSONL at HEAD, checks identity and source staleness.
Supported legacy result/status-only and integer-zero-only success formats remain; present malformed
fields are not absent fields. Post-merge attribution-only check_provenance_receipts stays separate.

## Build, failure and rollback

Existing GH-280 landing/replay and GH-496 receipt suites are the extension seams. Reconciliation
already refuses missing full proof and can replay a recorded landing; no inferred proof is allowed.
Add nonempty shipping and contradictory-outcome regressions with witnessed red controls.
Easy rollback: focused revert before deployment; preserve all original review/evidence history.

## Unknowns

Full registered-suite behavior on the final candidate is unknown until disposable macOS qualification.
The issue/PR metadata fixtures use deterministic GitHub stubs; they do not prove live remote landing.

## Current-state radius

Jog task closeout, wave pre-merge validation, release-member shipping and their existing test consumers.
