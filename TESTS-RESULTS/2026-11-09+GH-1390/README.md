# GH-1390 publication safety repair

After #1389 produced no reconciliation writes, an up-to-date push invoked the hook's empty-ref fallback and started the full registry in primary. The owned gate was stopped; the separate #1384 gate was preserved. See incident-caller.log, owned-gate-stop.json and integrity-check.md. No full-pass or blanket no-data-loss claim is made for that interrupted run.

The existing publication helper now fetches first and requires nonempty commit IDs. Already-published state needs no push. Unpublished commits retain the normal gate, post-push fetch and final clean/equality checks. No hook bypass, new suite or deployed-payload edit.

Existing gh436 controls: baseline 3 failed/1 passed; repaired suite 227/227 passed. Independent source QA passed. Normal full qualification remains pending. This is the second and final #1384 repair slot; earlier repair history is preserved. Nonempty per-landing push coalescing remains unmet in open #1383.

First normal gate at df30f08ce failed405/408 and refused the push: GH123 failed both pooled and serial; PDDA/sentinel exposed a missing mandatory `goal` field in this repair's new working doc. Added that required field within the existing repair slot. An unchanged quiet GH123 run passed6/0; this does not establish a harmless flake or qualify the registry. Prior failures are retained. That later retry was aborted (reported task history; no retry receipt supplied here). Current B01 composition remains unqualified; no gate was removed or bypassed.

The original two GH-1384 repair slots remain exhausted. The new issue-specific bounded window and parent qualification limits are recorded in the existing GH-1390 plan. These are retained source artifacts, not fresh B01 gate evidence.
