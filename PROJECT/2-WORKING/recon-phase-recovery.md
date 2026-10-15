---
title: Recon — phase recovery
roadmap_exempt: true
status: In progress
created: 2026-10-13
updated: 2026-10-13
owner: Codex
goal: Trace historical phase recovery and approval boundaries.
---

## Status

| What was just completed | What's next |
|---|---|
| Entry, state and consumer trace confirmed. | Verify implementation against the shared repair plan. |

# Recon Map — phase completion recovery
Commit: b9f07ea5b8d95bac62a3ed9f886770fee883030f · Mode: graph + exact source · Lanes: parent entry/failure plus independent read-only state/contract trace.

## Subject and change class
Existing marathon phase satisfaction; optional derived completion metadata under existing attestation authority.

## Call paths and seams
| Seam | Location | Crosses | Breaks if |
|---|---|---|---|
| Sequential traversal | relay-automation/marathon.sh:583–625 | visits all phases, explicit token only on retry target | skipping prior phases hides validation |
| Force allocation | utils/py/marathon_drive.py:487–532,1416–1423 | changes token identity before satisfaction | completed record becomes unrelated |
| Startup satisfaction | utils/py/marathon_drive.py:2770–2864 | nested completed/task/status/attested checks | terminal words mistaken for trusted completion |
| Initial/final success | utils/py/marathon_drive.py:2668–2760 | probes→gate→candidate→postapprove→result/receipts | recovery startup fix alone still fails final bind |
| Trust reader/writer | utils/py/relay_attest.py:197–355 | git-common-dir atomic record, byte-range/trailer/reviewer checks | workspace artifacts become approval authority |
| Merge consumer | utils/py/jog_run.py:414–424 | result reviewed_candidate checked against PR revision | current HEAD falsely reported peer-reviewed |

## State and contracts
relay-drive is sole approval writer; marathon reads approval. Approval record includes task, target/relay, reviewer, exact reviewed head, isolated flag, review range/digest and trailer. Tick token must read done. RELAY directive is builder-writable hint limited to same family. Current result@1 and gate receipts are workspace artifacts; no historical authority. candidate_ok demands reviewed ancestor and transcript-only endpoint delta. Preserve it for Jog merge and initial/postapprove completion.

## Failure and rollback today
No matching repair PR. Missing/malformed attestation or candidate drift halts4; gate red halts5; explicit retry rebuilds. Attempt caps and driver lock unchanged. Bash twins frozen, edit Python only. Gate suites run separate full clones.

## Unknowns and evidence limits
Graph generation2026-10-13T06:40:42Z lacks nested helper edges, resolved with exact source. Shell partial416/694 ranges read along with traversal. Foreign GH750 artifacts were not supplied; live issue reports plus local shipped-function replay are evidence, no claimed full provider replay. Legacy completed runs cannot obtain protected completion proof from existing untrusted artifacts. Trusted completion extension intentionally has no automatic migration.

## Current-state radius
Marathon retries/force and terminal result/receipt consumers, including Jog merge qualification; no remote network service or event kernel change.
