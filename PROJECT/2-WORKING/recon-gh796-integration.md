---
title: GH-796 integration recon map
status: Reference
created: 2026-09-24
updated: 2026-09-24
owner: noel
goal: Record the source and state seams behind the integration sequence.
roadmap_exempt: true
---

## Status

| What was just completed | What's next |
|---|---|
| Bounded pinned-source review and pairwise merge inspection | Apply findings in GH-796 plan; refresh on head changes |

## Subject and change class

Integration of #794/#795/#765; assessment and hold of #759. Cross-module governance/test changes and shared ledger writes. Base337813e0; pinned heads in the owning GH-796 plan. Graph+source mode; graph generation2026-09-01 stale, new symbols missing, exact direct-source fallback. Lanes: governance entry/contracts, cleanup/build/failure, evaluation/state.

## Seams and call paths

| Seam | Location at reviewed PR head | Crosses / failure |
|---|---|---|
| Wave readiness | #765 start-marathon SKILL292 → check_marathon_qa.py102/289 | Per-wave PR opening invokes all-wave completion; deadlock with #777 plan72 |
| Aggregate PDDA | #765 pdda.sh1568 → check_marathon_qa.py299 | Existing active/completed docs scanned; full-mode new errors block aggregate |
| Receipt identity/root | #765 checker25/201/278; pdda-lib6 | Harness-root defaults and link parsing can reject valid consumer receipt; empty file passes |
| Inventory | development checker_inventory_ratchet.py55/122 | New utils checker adds frozen production script; exact baseline required |
| Python launch | #795 test/lib/pystub.py22; fuzz_engine/repro_synth/gen4_campaign diff | Shell quoting preserves spaced executable; existing shlex parser consumes target |
| Landing | #794 merge_cleanup.py wait/poll/reconcile diff | Six bounded UNKNOWN waits; only PR/merge-SHA hosted success accepted; local fallback writer follows |
| Evaluation | #759 phase0-development-probe.py7/41 | Remote unpinned rows labeled with module revision; provenance boundary incomplete |
| Shared DB | all four releases.db/sql | Writer receipts/generation shared; old schema8 branches must preserve schema9 base |

## State and writers

RELEASES CLI is canonical DB/dump writer; views are generated. Merge-cleanup existing B1 classifies/replays disjoint roadmap changes through that writer; wave_reconcile owns post-merge doc/ledger transitions with hosted/local exclusion. No new writer is planned. Tick relay uses existing event API and claims; Agy writes only its relay thread. Evaluation JSON is research evidence, not admitted scoring or authoritative action state.

## Failure and rollback today

Git detects ledger/changelog/view text conflicts; green textual source merges do not detect semantic contract conflicts. Existing focused suites and full macOS gate verify final code, while hosted exact-SHA checks/reconciliation attest remote events. Repair slots persist per PR at primary; two attempts cap. Failed checks stop sequence. Reviewed revert plus canonical ledger reconciliation is recovery; primary resets/DB replacement are not.

## Unknowns

| Unknown | Why it matters | Settlement |
|---|---|---|
| Final cumulative remediated tree | Pairwise merge trees are not final integration proof | Real current-base merges, writer replay, focused and full gates after fixes |
| Consumer-root executable fixture | Source trace proves wrong default; integration variants not exercised here | Distinct harness/consumer fixture in GH-784 suite |
| Receipt verdict semantics | Existence is weaker than approved QA | Reuse existing verdict owner; test empty/rejected/approved documents |
| New heads or in-flight #789/#786 | May touch cleanup implementation after this snapshot | Refresh allowlist/head matrix before execution |
| #759 original remote revision | Current script does not bind acquisition | #757 provenance repair; no retrospective data-correctness assertion |

Current-state radius: merge-cleanup callers and primary ledger; test/fuzz Python launchers; marathon preparation and consumer PDDA; held research provenance. No whole-repository correctness claim.
