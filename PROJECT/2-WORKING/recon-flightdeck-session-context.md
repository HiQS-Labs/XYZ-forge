---
title: Flightdeck session context and Claude status — Recon Map
status: Research complete — existing producer verified; implementation not started
created: 2026-09-08
updated: 2026-09-08
owner: Codex
goal: Preserve useful session context and reuse existing Claude status producers without adding a parallel collector.
doc_type: research
roadmap_exempt: true
gh_issue: 494
source: https://github.com/HiQS-Labs/XYZ-forge/issues/494
---

# Recon Map — session context and Claude status

## Status

| What was just completed | What's next |
|---|---|
| Existing Rebalance reader returned all three screenshot sessions, connection and worker status; two exact local/cloud identity joins verified. Consumer context loss reproduced with synthetic records. | Design the bounded producer snapshot and consumer projection against these findings; no collector or hook has been installed or enabled. |

## Subject and change class

Cross-module read-contract extension: retain session identity/context separately
from latest prompt; consume existing Claude Remote Control status through the
incoming connector architecture. Existing producers remain authoritative. This is
research, not implementation approval or a new independent session authority.

Flightdeck HEAD: `b9cddc9cca4475236941212178728ffb748bf960`.
Rebalance reference HEAD: `0bffc4dab79da4a2a13ecd605af9798181a76bc9`.
Uncommitted breadcrumb CSS/HTML and unrelated harness DB changes were preserved.

Mode: Verify, graph leads plus direct source. XYZ graph generation
2026-09-01T15:54:30Z lacks this task clone's Flightdeck files. Rebalance graph
2026-09-02T03:54:57Z returned no claude_cloud symbols; path coverage metadata
matches its reader, with changed INSTALL metadata. Exact source reads supply the
material evidence. Local Claude metadata is outside those graphs. Parent covered
consumer flow, Rebalance producer, failure/operation and official contracts; one
read-only recon agent covered local metadata and installed hooks.

## Observed result

At **2026-09-08 23:38:24 UTC (4:38 PM PDT)**, one bounded page of 100 records from
Rebalance's existing session reader contained these exact screenshot titles:

| Session | Connection | Status bucket | Worker |
|---|---|---|---|
| Model-catalog v1.0.0 integration into XYZ-forge and AEGIS-Sleuth | connected | working | running |
| Unstuck command review | connected | working | running |
| Needle oracle training for XYZ Forge | connected | review_ready | idle |

All 100 rows in the initial read reported origin `claude_code_vscode`. This is
observed coverage of the screenshot's local/Remote Control sessions, not merely a
cloud-only assumption. Needle's state had changed since the screenshot; idle is
not a failed connection or proof that its project is complete.

[Retained bounded receipt](../../TESTS-RESULTS/2026-09-08+GH-494/session-status-research.json)
contains the three named records and freshness fields, not credentials or message
bodies. Three bounded read-only requests were used: status/coverage, identity-key
inspection, and connection-status verification. No PR enrichment, source refresh,
index write, enable flag, schedule, tunnel, installed hook, or application change
was invoked. Existing authentication stayed inside the existing reader.

## The seams

`FD:` paths are in this Flightdeck clone; `RB:` paths are in canonical RebalanceOS.
`CC:` means the existing machine-local Claude metadata root; it is a runtime
configuration location, not a path to bake into the application.

| Seam | Evidence | Current contract / consequence |
|---|---|---|
| CLIO projection | FD:src/flightdeck/connectors.py:73–130 | Groups by repo/session; overwrites task with every latest prompt (240 chars). Issue references survive nearby follow-ups, but initial context/title does not. |
| Read window | FD:src/flightdeck/contract.py:13–14,51 | Last 4 MiB and 5,000 records are bounded input. Earliest available prompt must not be mislabeled the original prompt if history fell outside coverage. |
| Snapshot aggregation | FD:src/flightdeck/aggregate.py:119–129,155–173 | Source lane IDs remain distinct; 30 lanes per repo cap. No cloud/local identity mapping currently joins them. |
| Card and handoff | FD:web/flightdeck/app.js:94–118,234–249 | Repo cards count prompts from the last hour; latest task drives next action and handoff. A quiet long-running session can disappear from this count. |
| Refresh/cache | FD:web/flightdeck/app.js:256–272,315 | Passive HTTP read every 150 seconds, last-good sessionStorage fallback. Must retain source observation time and status uncertainty separately. |
| Existing Claude reader | RB:src/rebalance/ingest/claude_cloud.py:77–139 | Already fetches and normalizes title, status, status_bucket, worker_status, last_event_at, repo and branch. Raw connection_status exists but normalize currently drops it. |
| Existing date filter | RB:src/rebalance/ingest/claude_cloud.py:197–222 | sessions_for_day selects CREATED on the requested day. It would exclude the still-active September 6 integration and September 7 Needle sessions from a September 8 read. |
| Registry / persistence gap | RB:src/rebalance/ingest/index_ops.py:2130–2154,2233–2248 | Registered derived_scan, excluded from all; refresh returns grade, not persisted session rows. Ranking is separately opt-in. Calling it on each dashboard request would violate the passive-consumer goal. |
| Existing exports | RB:utils/claude_cloud_daily_grade.py:76–108,115–139; RB:scripts/cc_cloud_jobs.py:370–401 | Daily-note report exists; older standalone POC can save JSON manually. Neither is a verified current periodic, versioned session snapshot. Do not add a third fetch implementation. |
| Duplicate implementation warning | RB:PROJECT/1-INBOX/GH-150-ACTIVITY-SIGNAL-CONSOLIDATION.md:62–74 | Already records duplicate POC/production fetch implementations. Extend the canonical reader; do not base a new collector on the POC. |
| Compact native session registry | CC:sessions/*.json, six inspected records | sessionId, pid/process-start, name, entrypoint, version 2.1.263. Startup metadata, not heartbeat; no observed worker-state field. Derived name differs from screenshot title. |
| Native title records | CC:projects/.../integration-session.jsonl:15483–15485 | custom-title and ai-title records already exist. Exact screenshot integration title is aiTitle. Local customTitle differs; title precedence cannot be inferred solely from field names. |
| Native identity records | CC:projects/.../integration-session.jsonl:15575; unstuck-session.jsonl:3128 | bridge-session records explicitly pair local sessionId and cloud bridgeSessionId. Exact integration and Unstuck joins confirmed. |
| Existing start/end hooks | CC:hooks/session-start-sync.sh:10–18; session-end-sync.sh:14–18 | Config/skill Git synchronization, not a live-state producer. No need to repurpose or execute these hooks. |

## Call paths and state

Existing Claude prompt hook -> CLIO append log -> read_clio -> aggregate.snapshot
-> /flightdeck.json -> card / drawer / copyable handoff.

Existing Claude Remote Control -> existing session API -> Rebalance _fetch_raw
-> normalize -> sessions_for_day -> grade / optional ranking or daily-note report.
The live API already owns title, connection and worker status. Missing today is a
producer-owned reusable snapshot between that reader and a passive consumer.

Claude also writes non-message title/bridge metadata into local transcripts.
An existing producer can project those records; Flightdeck should not acquire a
second full-transcript scanner. Two local UUID -> remote session joins were
verified without matching prompt text or guessing from a repo name. No exact Needle
join was found in 146 top-level local transcript metadata files. Keep its remote
identity distinct until an explicit mapping is available; do not merge all sessions
in one repo or fabricate a local match.

## Consumer context finding

A temporary two-record fixture through the current read_clio produced one lane:
initial issue #440 request -> “Yes go with your plan”. The output retained issue
440 but only the acknowledgment as task; no initial_intent/session_title field.
Input was nonempty and unchanged. This confirms consumer loss even when upstream
capture is complete; it is independent of the earlier first-prompt capture defect.

The smallest context change is additive: retain the source session title when
available, earliest available intent with timestamp/coverage, latest prompt with
its own timestamp, and existing current issue/PR context as separate facts. Keep
legacy task meaning compatible during transition. A short acknowledgment must not
erase the task label; an old mission must not masquerade as the latest instruction.
No model summarizer, keyword-heavy classifier or new context database is required.

## Implications for the next change

- **Reuse, not new collection:** extend canonical Rebalance Claude-session reading
  to publish a bounded versioned snapshot; add a passive Flightdeck incoming adapter.
  Include raw connection_status, authoritative title and worker/status fields.
- Include old-but-active sessions rather than filtering only on creation date.
  Retain fetched_at, last_event_at, coverage/truncation and source errors. Empty,
  failed and expired are different states; a previous running observation must not
  remain asserted live after refresh failures.
- Project existing bridge metadata through a producer for exact CLIO joins where
  available. Retain both IDs and mapping provenance. Missing Needle mapping is
  explicit uncertainty, not a reason to suppress the remote session.
- Separate session identity/context, latest instruction, last-hour activity and
  verified progress in the UI. A process existing, connection up, worker running,
  and completed milestone are four different observations.
- No new hook/status collector is justified by this research. Claude's documented
  hooks are a fallback only if the existing verified status feed later proves
  insufficient. Do not start another scheduler, transcript crawler or LLM service.
- Current client polling is 150 seconds. A separate 150-second producer schedule
  could make end-to-end freshness approach five minutes. If the implementation
  promises 2–3 minutes, budget producer cadence plus client cadence plus fetch time;
  e.g. 120-second production and 30-second passive reads. No cadence was changed.

## Failure, verification and rollback

Existing reader catches fetch/auth errors and returns an empty list; an exporter
must not call that empty list proof of zero sessions. Pagination is capped and
underlying subscription endpoint compatibility is not guaranteed by this probe.
Use the existing auth path, redact payloads, retain last-success status separately,
and mark stale/unknown explicitly. No source ownership moves to Flightdeck.

Future manual checks belong in the existing experimental harness: initial context
plus acknowledgment, topic change, old active session, disconnected/idle distinction,
failed/expired snapshot, exact bridge join and unmatched remote session, and a
negative control for current latest-prompt overwrite. No CI/CD integration requested.
Research changed only this map and a sanitized receipt; implementation rollback is
not yet applicable. A future adapter must remain independently disableable.

## Official contracts checked

- [Remote Control documentation](https://code.claude.com/docs/en/remote-control):
  local execution and remote presentation are distinct from cloud execution;
  session names and connection status already belong to Claude. Local and remote
  names need not be reconstructed from our latest captured prompt.
- [Hook reference](https://code.claude.com/docs/en/hooks): lifecycle/turn/permission
  notifications are available, but turn completion is not session end and idle
  notifications may be delayed. This is a possible fallback contract, not evidence
  an existing installed status export emits those events.

## Unknowns

| Unknown | Why it matters | What would settle it |
|---|---|---|
| Exact local bridge identity for Needle | Avoid duplicate counts or a false merge | An explicit bridge mapping from its actual device/session producer |
| Durable API/enum compatibility and disconnect behavior | Live sample is not an offline/reconnect contract | Bounded producer fixture tests and a controlled disconnect/reconnect observation |
| Complete export coverage and scheduling policy | First-page sample found the targets, not every session on every device | Implement bounded pagination/coverage receipts in the existing producer and review its schedule |
| Native bridge alias changes across resume/reconnect | Prevent mixing historical and current remote identities | Trace successive bridge metadata records and retain mapping provenance |

Current-state radius: Flightdeck CLIO lanes/cards/handoffs, Rebalance's existing
Claude-session reader/registry/report consumers, and native Claude metadata. No
runtime modifications, hook deployment, source mutation, or new collector.
