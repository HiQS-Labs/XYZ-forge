---
gh_issue: 1360
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1360
title: "Task-agnostic supervisor with LTVera monitor pilot"
status: "Proposed (1-INBOX — not yet active)"
created: 2026-11-07
doc_type: feedback
effort: 3
complexity: 3
risk: 3
phases: 5
---

## Objective
Plan a small task-agnostic supervisor script that can replace selected paid Grok Bot scheduled jobs. **Operator-selected first pilot: LTVera app Health Check API endpoint monitor.** Research and plan only; no schedule activated, monitor invoked, notification sent, credential accessed, or Grok task disabled.

## Medium-depth recon (2026-11-07)
Forge source inspected at `3bf02f73ce0cb11a82f970357209980f808ccb3c`, using rg/direct reads. No new source-of-truth decision is made here.

| Confirmed seam | Source | Consequence |
|---|---|---|
| ONE shared local scheduler already has an owner | #1168, live OPEN | Coordinate with that contract, not another scheduler. Per-job opt-in, lock, receipt, missed-run policy; current scope excludes existing-job migration |
| Primitive tool list hard-coded | utils/py/harness.py:29,317-360 | note/summarize/probe/idle/plan-draft are not arbitrary jobs; probe is local-no-network |
| Rules adapter separates judgment from scheduling | harness.py:186-221 | Deterministic jobs need no LLM every wake |
| Intent, receipt, consumption and quarantine | harness.py:41-78,131-149,1263-1288,1420-1458,1511-1525 | Missing receipt does not justify replay of external effects |
| Prototype sandbox permits output/temp writes only | harness.py:1384-1402 | Do not loosen it to make generic maintenance work |
| Bounded process-group runner exists | utils/py/proc_group.py:3-18,108 onward | Reuse for subprocess jobs if needed |
| Deterministic hourly scan already exists | utils/hq/hourly-global-scan.sh:21-41; install-hourly-scan.sh:21-59 | Timing/reporting alone is not new capability |
| Some tasks require native app tools and one writer | skills/3-weekly/task-sync/SKILL.md:298-325 | Not every Grok/native task can migrate to a local script |

#1248 remains a prototype whose timed soak driver explicitly is not a scheduler install (TESTS-RESULTS/2026-10-29+GH-1248/driver.py:1-5). #1200/#1175 own factory decisions; this issue owns generic-job requirements and selective migration, not another factory queue.

Read-only filtered LaunchAgents metadata showed existing Git Pulse/RebalanceOS schedules, no matching XYZ/HQ/Grok/supervisor job. Current-project T3 scheduled-task list returned empty. Neither proves external Grok tasks absent. No arguments, secrets or payloads published.

## LTVera pilot grounding
Read a local LTVera-Pandas clone at `dd76b53d9de611bc067280ff4357a87ac02f5668`, not a deployed version claim:
- app/api/routes/health.py:159-179 defines /health (module describes /api/health), reports status/app/environment/checks; returns 503 if required checks fail.
- :132-155 can POST a RAG query as part of health evaluation; a poll can have downstream work/cost. Some unconfigured probes return true rather than proving those services healthy.
- scripts/check_buffer_server_health.py is a broader existing CLI covering buffer/BQ/GCP/WP; it is not automatically equivalent to the requested app endpoint monitor.

**Unresolved before pilot:** exact existing Grok task and URL, route mount/deployed version, cadence/timezone, authentication reference, body/field expectations, allowed downstream probe cost, timeout, failure/recovery thresholds, alert channel and current notification policy. No secret should be copied into issue/config. Actual Grok usage and bills unknown; zero savings claimed.

## Triangulate research card
CELL: irreversible × crossing when schedule/effect ownership moves; full lenses, bounded medium recon.
GROUND: #1168 scheduler → named job → bounded execution → observation/intent → receipt → next wake/alert.
FALSIFY: greenfield scheduler premise disproved by #1168; arbitrary executor premise disproved by primitive tool/sandbox limits; safe blind retry disproved by quarantine semantics; every-wake LLM requirement disproved for deterministic checks.
SMALLEST: HTTP monitor under existing scheduling ownership, optional model only for separately justified diagnosis.
UNKNOWN: live #1168 implementation readiness and deployed LTVera/Grok contract.

## Alternatives and decision
1. Existing scheduler plus an existing equivalent HTTP monitor command, if verified: smallest.
2. Minimal Python task runner under #1168 exposing named job, timeout, lock and receipt: only shared behavior actually needed by pilot.
3. Bounded optional model diagnosis on a confirmed incident: defer until deterministic alerting demonstrably insufficient.
4. Keep Grok job if connector/availability or maintenance costs outweigh savings.
5. Generalize whole factory primitive into arbitrary plugins: reject for pilot.

An always-on existing host may suit monitoring better than a sleeping Mac. Select host from required coverage and available infrastructure; do not create remote hosting/network exposure by implication.

## Ordered plan — apply ground → falsify → shrink in every phase
1. **Inventory and contract.** Capture current Grok job configuration safely, exact endpoint/body schema/cadence, notification effects, authentication references and actual cost baseline. Falsify HTTP-200-only success with malformed/degraded responses and optional checks. Select one real monitor, not all scheduled tasks.
2. **Ownership and mechanism.** Confirm #1168 implementation and explicit ownership for schedule, observations and notifications. Falsify scheduler-alone sufficiency against overlap, sleep/missed ticks and alert-after-effect crash. Use native timing and smallest named HTTP handler; no arbitrary model-generated shell, new backlog, ledger or plugin framework. Agree host/interval based on required coverage.
3. **Report-only shadow.** Compare equivalent observations with current monitor; suppress all replacement external alerts. Ground expected health/degraded/unknown states. Falsify with timeout/DNS/TLS failure, 503, malformed/empty body, wrong app/environment, missing checks, duplicate/overlap, stale output and restart. HTTP read retry may be bounded; notification retry requires dedup/reconciliation, never blindly duplicate. Choose enough opportunities plus restart/control coverage, not an arbitrary multi-day soak.
4. **Single-owner cutover.** Read back that exact old notification-producing task is disabled before enabling new alerts. Falsify dual-writer risk across a scheduled boundary. Explicit activation approval per job; no inherited broad send authority. Rollback disables new owner, reconciles uncertain sends, then re-enables old owner. Keep original job configuration recoverable.
5. **Evaluate and extend only on evidence.** Compare detection/recovery latency, missed checks, false positives, duplicate alerts, operator minutes and actual usage including downstream endpoint work. Falsify claimed savings with maintenance burden. Only generalize shared execution contracts after a second real job needs them. Clone cleanup #1359 remains separate authority; report-only clone census could later be another handler, never automatic deletion by this pilot.

## Plan triangulate card
GROUND: scheduler and runner responsibilities separated; existing ownership respected.
FALSIFY: generic script does not imply connector parity or uptime while host asleep; endpoint polling is not proven free/read-only in downstream behavior.
SMALLEST: one deterministic LTVera monitor with typed observation and durable alert transition state.
SKIPPED WITH TRIGGER: semantic diagnosis when rules demonstrably insufficient; generic job adapters when a second inventoried task needs them; cleanup effects only after #1359 safety/ownership plan.

## Acceptance and planned red controls
- [ ] Nonempty pilot contract matches actual Grok job and deployed endpoint; no guessed cadence/URL/auth/cost.
- [ ] Valid healthy/degraded/unknown observations distinguished; 200 HTML, empty body, missing expected checks or stale response cannot pass.
- [ ] Declared timing coverage met and missed checks reported; sleeping-host limitation explicit.
- [ ] Duplicate wake/overlap yields at most one intended observation/alert effect; no claim of exactly-once external delivery without destination support.
- [ ] Timeout bounded; subprocess cancellation affects owned group only if subprocess used.
- [ ] Consecutive-failure/recovery thresholds and alert dedup match approved policy; missing send receipt becomes uncertain rather than blindly retried.
- [ ] Shadow emits no external notifications; cutover proves one effect owner; rollback rehearsed without duplicates.
- [ ] Deterministic routine checks make zero model calls; cost comparison includes actual old usage and new host/endpoint/intervention costs or explicitly UNKNOWN.
- [ ] Existing checks or manual red controls plus provenance under TESTS-RESULTS/<date>+GH-1360/; no new suite/gate. This plan specifies controls; none claimed executed.
- [ ] Independent review verifies contract, ownership and results before broader migration.

## Investment rubric (#1358)
Gain: replace paid model-driven polling with equivalent bounded deterministic monitoring. Discriminating test: actual LTVera semantics plus interruption/alert controls. Value: measured savings and operator effort, not genericity; no runtime build commitment until task inventory and #1168 readiness justify it.

## Bounds and rollback
Planning reversible; scheduling/effect ownership migration is Costly and crossing. No changes to existing scheduler, sandbox, secrets, messages or application during recon. #1328 repair ceiling applies to implementation; predeclare numeric time/usage budgets and escalation before activation. Do not silently change #1168's no-auto-retry/missed-run contract.

## PRS proposal
- pri 65: concrete recurring paid monitor selected by operator.
- sev 30: efficiency/reliability opportunity; no current incident established.
- appeal 50: neutral.
- effort 45: single pilot plus safe cutover; actual inventory may reduce scope.
Unstarted implementation intake; no ledger row. Related #1168, #1248, #1200, #1175, #1188, #1358, #1359.


