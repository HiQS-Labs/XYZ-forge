---
title: Optional Paperclip dashboard — Recon Map
status: Complete — bounded source recon
created: 2026-10-06
updated: 2026-10-06
owner: Codex
goal: Establish the existing read boundary and the smallest optional UI extension.
doc_type: research
roadmap_exempt: true
gh_issue: 981
source: https://github.com/HiQS-Labs/XYZ-forge/issues/981
---

# Recon Map — optional Paperclip dashboard

## Status

| What was just completed | What's next |
|---|---|
| Source boundary and candidate UI borrowing traced. | Review the GH-981 spike plan before implementation. |

Commit: `85556455a3e734708235ef23869818a0dc743ba5`.
Mode: source reads and rg; graph tools unavailable. One bounded read-side lane
in the parent context, combining entry, state, contract and failure inspection.
No shared implementation will change. Existing broader producer maps remain
references, not a claim this spike re-audited those producers.

## Subject and change class

Optional presentation addition over Flightdeck's existing projection; no source
authority, persistence, schema, coordination or execution-control change.
Paperclip reference: `noelsaw1/paperclip-fork` at
`90182b4f8b40d6ee217937ba61199b4abc31dee7`, clean observed working tree.

## The seams

| Seam | Location | Contract and consequence |
|---|---|---|
| Passive HTTP snapshot | `src/flightdeck/server.py:37` | GET `/flightdeck.json` invokes existing aggregator, returns 503 on failure; host and response-security policy are established. |
| Projection | `src/flightdeck/aggregate.py:47` | `snapshot()` reads bounded connectors and emits schema 1, repos, sources, timestamps, coverage and truncation. PR classification deliberately requires QA. |
| Connector ownership | `src/flightdeck/connectors.py:439` | Static registry retains reader ownership; `read_xyz_work` uses existing releases work-status helper rather than a new SQL reader. |
| Explicit source configuration | `src/flightdeck/contract.py:69` | `ConnectorConfig.from_environment` owns FLIGHTDECK paths and enabled connectors; optional add-on must not configure producers or install connectors. |
| Honest issue status | `web/flightdeck/issue-context.mjs:13` | `issueStatus` and `issueCards` distinguish native/established evidence, unknown/conflict and stale reads. Reuse these selectors. |
| Freshness and progress | `web/flightdeck/presentation.mjs:2` | `snapshotFresh` expires at five minutes; `progressTone` returns unknown because producers lack a complete progress window. Reuse, do not infer liveness. |
| Current UI | `web/flightdeck/app.js:94` | Repo cards, lanes, cached PRs and handoff already consume this projection; default server/renderer can remain byte-identical. |
| Paperclip small components | `ui/src/components/MetricCard.tsx:14`, `FilterBar.tsx:17`, `SidebarShell.tsx:91` in reference repo | Presentation patterns are reusable, but JSX, Tailwind, router and utility imports are not native to this repo. Adapt to dependency-free markup/CSS. |
| Paperclip large components | `ui/src/pages/Dashboard.tsx:1`, `ActiveAgentsPanel.tsx:1` in reference repo | Company contexts, heartbeat API, shared polling and transcripts prevent a drop-in page import. Do not port the execution plane. |

## Call paths in

Existing explicit launcher -> FlightdeckHandler GET -> FlightdeckAggregator.snapshot
-> read_connectors -> configured passive readers -> schema-1 JSON -> existing
browser selectors -> observed UI. The new add-on can reuse that path through a
small handler subclass, with its own finite asset map and opt-in launch.

## State

Readers stay where they are. Existing producers own source DBs, prompt JSONL,
Git Pulse and optional feeds. No producer refresh is invoked. New writes are UI
preferences in browser storage only; synthetic demo data has no source authority.
No new backend canonical writer is needed.

## Build, failure and rollback today

Python standard library serves static assets; existing UI uses native modules,
with no npm build. Existing manual harness is opt-in and absent from CI.
Snapshot failures and stale values must be visible; last-good data is context,
not readiness. Stop the optional server to roll back; no current reader changes.

## Unknowns

| Unknown | Why it matters | What settles it |
|---|---|---|
| Whether the denser shell improves this operator's scanning | This is the actual spike hypothesis. | Desktop/mobile preview and operator review before merge. |
| Which local connectors have available data | Live preview may be sparse or partial. | Opt-in live GET; keep coverage visible and retain synthetic demo for layout review. |
| Producer execution/progress completeness | A polished UI cannot establish it. | Existing producer work, outside this spike; keep unknown/verification-needed labels. |

Current-state radius: Flightdeck read contract and selectors, existing producer
ownership, current browser operator; new radius adds only an explicitly launched
add-on HTTP handler and presentation files. Cut off at producer internals and
Paperclip unrelated features; neither changes nor is relied on for new authority.
