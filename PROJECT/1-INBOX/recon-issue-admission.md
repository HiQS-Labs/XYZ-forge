---
title: "Recon — issue admission"
status: Recorded
created: 2026-09-08
doc_type: report
roadmap_exempt: true
source: https://github.com/HiQS-Labs/XYZ-forge/issues/522
---

# Recon Map — GitHub issue admission
Commit inspected: 507286b333bc95caf7021edfc82d7f7add259c32 (primary); capture workspace based on 9135d2f7a8a68c0603790090649a8cf438718d7b.
Mode: graph + direct source; Verify tier. Graph XYZ-forge generation 2026-09-01T15:54:30Z reports metadata_changed on all material Python paths; source reads supersede stale graph line numbers. Lanes: parent state/contracts/operations; read-only explorer planner/preflight. Bounded feasibility recon, not exhaustive implementation audit.

## Subject and change class
Add an admission contract and monitor upstream of current queue/planner. No new execution authority approved.

## Seams and paths
- skills/10days/scan-issues.sh:63-65 -> gh issue list: open updated-window issue discovery, capped at200; not a durable cursor.
- utils/py/_marathon_plan.py:760-826 -> read-only releases.db roadmap_items -> doc enrichment847-850 -> readiness951-1007 -> score1038-1050 -> waves1083-1124.
- utils/py/swarm_preflight.py:101-147 validates local contract;1318-1373 probes target ref;1430-1445 checks local remediation;1460-1534 reads issue and acceptance. Issue-body remediation content is not the hard gate.
- swarm_preflight.py:1084-1139 -> marathon-invocation@1 -> jog_run.py:85-124 loader -> Marathon executor. MACHINE-CONTRACTS.md declares ownership and version policy.
- releases_app.py:3876-3935 cmd_jog_add -> perform_write:1283. Duplicate pending/running rows refused; existing terminal rows reset pending and attempt_count=0. Automatic replay must not call this blindly.
- releases_app.py:4150-4165 jog to-marathon prints IDs; it is not a complete reviewed wave-plan adapter.
- releases_app.py:3366-3440 roadmap rate -> parse_rating -> perform_write. Rating changes update generic updated_at, not a dedicated reviewed-plan identity.

## State and ownership
GitHub owns live issue discussion/state; PROJECT owns local execution docs; RELEASES owns roadmap/ratings/jog membership through CLI + perform_write. Marathon owns execution/result facts; Jog owns leases and projections. Proposed cursor and decision receipt must not copy execution truth.

## Failure and rollback today
Planner dry-run skips final plan write (marathon_plan.py:201-207). Preflight dry-run skips packet output but uses fetch/temp worktree (swarm_preflight.py:1341-1367,1688-1694). Source-only concerns: deep preflight unmapped rc985-1007; missing deps advisory1010-1027; no-progress packing1114-1119; exact declared paths657-671 differ from preflight expanded tests/helpers1259. These need reproduction before fixes are specified. No runtime gates run in this recon.

## Unknowns
- Review attestation authority and issue-body/comment selection schema: settle during contract design with trusted maintainer policy.
- Full scheduler inventory/platform choice: inspect existing local scheduling integrations before adding one; not audited here.
- Atomic admission across independent clones: existing DB locking is insufficient evidence for global single-marathon policy; design against marathon ledger and current claim/lock ownership.
- Which planner guard gaps reproduce: fixture tests in disposable full clone, with negative evidence committed under test/baselines/ plus provenance.jsonl.
- Whole-repo absence is not claimed. ROUTER:177 points at a proposed steward section absent from current PROJECT/PDDA.md.

## Live issue reconciliation
2026-09-08: #443,#492,#418,#423 OPEN. #505,#509,#510 CLOSED. Current source already supports RELEASES DB despite #418 historical report. These statuses do not independently prove fixes.

## Radius
Current roadmap/rating writers, Jog queue mutations, planner/preflight contract, Marathon committed membership, and operator prioritization; new monitor adds persistent external-input consumption and autonomous admission policy.
