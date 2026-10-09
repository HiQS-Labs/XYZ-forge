---
gh_issue: 1006
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1006
title: "Marathon: bounded progress and safe repair handoff"
status: "Proposed (1-INBOX — not yet active)"
created: 2026-10-09
doc_type: feature
effort: 3
complexity: 3
risk: 3
phases: 3
---

The operator wants evidence of useful work after several unattended hours: opt-in scheduled
progress reports, a bounded path for genuinely minor machinery repairs, and a reviewed repair PR
that can support an explicitly authorized continuation. Completion is not guaranteed. A live
heartbeat and repeated attempts are not accepted progress. Keep one executor, existing locks,
containment, gates and attempt/review caps; reuse consult/start-task/relay rather than a new daemon.

Original observation default: 600 seconds × 6 checks; report terminal outcomes immediately and
end the monitoring window explicitly without killing an authorized run. Recovery must be
separately opted into and budgeted. A three-seat consult is advisory, never proof or authority to
bypass deterministic constraints. Preserve all prior failure receipts and attempts.

2026-10-09 rating rationale: priority 80 (explicit operator scheduling, blocks unattended usefulness),
severity 65 (observed recoverable stalls and wasted operator time; no data loss claimed), appeal 80
(interpretation of the user's explicit desirability, retaining the issue's provisional value),
cheapness 45 (observation is modest; safe continuation is constrained by existing contracts).
No operator rank override. The 2026-09-25–2026-10-09 versus 2026-09-11–2026-09-25 search found
relevant examples #1001/#1002 (one consumer episode), #976 (receipt churn), and #752 (multi-phase
resume refusal). This is examples-based recurrence evidence; distinct incident counts and trend
are unknown, because issue updates/reconciliation are not incident timestamps.
