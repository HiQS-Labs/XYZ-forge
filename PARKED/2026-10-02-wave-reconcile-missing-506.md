# Hosted catch-up cannot resolve ledger issue GH-506

Observed after merging PR900 then PR902 into development: both hosted wave-reconcile runs fail closed before reconciliation, exit 6, because `gh issue view 506 --repo HiQS-Labs/XYZ-forge` reports that the issue cannot be resolved. The same read-only command reproduced the failure locally on October 2.

Evidence: [PR900 reconcile run](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36978963707), [PR902 reconcile run](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36979067253). The existing capture is `PROJECT/1-INBOX/GH-506-SKILLS-ARMY-HQ-REPLICATE.md`; its declared source is the unavailable issue URL.

Outside the requested merge scope: both PRs are merged and their independent QA, local gates and published-head CI passed. This finding concerns a prior ledger/capture reference encountered by hosted catch-up; no task-sync runtime change repairs that reference. Hosted doc/ledger reconciliation remains incomplete.

Next check: establish the canonical GitHub identity/state of the GH-506 capture, then triage the stale reference through existing PRS/PDDA procedures and rerun hosted catch-up. Do not invent an issue state or silently bypass the failed authoritative read.
