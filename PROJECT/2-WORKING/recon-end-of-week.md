---
title: End of Week recon map
status: In progress
created: 2026-09-13
updated: 2026-09-13
owner: Codex
goal: Ground the End of Week skill in existing readers and canonical writers.
roadmap_exempt: true
---

# Recon Map — End of Week

## Status

| What was just completed | What's next |
|---|---|
| Bounded source recon completed. | Use the map in GH-606 plan QA. |

Base: `38507a23303bebab6184607b15e3099cc2dd88e3` (fresh origin clone, 2026-09-13).
Mode: Verify, graph leads + current source reads. Lanes: local XYZ integration trace;
independent read-only Rebalance reader/config trace. No live weekly sweep performed.
XYZ graph generation 2026-09-01T15:54:30Z missed board_sync; `.xyz` excluded.
Rebalance generation 2026-09-02T03:54:57Z had changed/excluded reader paths;
current source fallback superseded those leads. No completeness claim from either graph.

## Subject and change class

An instructions-only skill coordinating existing readers and writers. No runtime,
schema, configuration authority or writer change. Consumer metadata remains canonical;
kanban remains its projection. Rebalance is evidence, not lifecycle authority.

## Seams and current call paths

| Seam | Current source | Consequence for skill |
|---|---|---|
| Branch selection | `.github/workflows/wave-reconcile.yml:7`, `utils/py/wave_reconcile.py:248`, `:1117`, `:1899` | Workflow and local reconciler assume development. Discover GitHub default first; a different default is an unsupported-reconciler gap, never permission to silently switch targets or bypass guards. |
| Reconciliation ownership | `utils/py/wave_reconcile.py:75`, `:148`, `:1837` | Hosted in-flight guard, local journal/rollback and branch checks exist. Use supported reconciliation, no parallel writer or force override. |
| Consumer root | `utils/py/board_sync.py:43`, `utils/py/releases_app.py:5028` | Explicit consumer root avoids projecting harness state in a vendored install. |
| Board configuration | `utils/py/device_config.py:32`, `utils/py/board_sync.py:94`, `:297` | Resolver uses XYZ_DEVICE_CONFIG_PATH or user .xyz/device_config.json and feature env overrides. Board identity has no defaults. Repo-local settings are effective only when routed through that resolver. |
| Lifecycle projection | `utils/py/releases_app.py:4760`, `:4848`, `:5021` → `utils/py/work_connectors/__init__.py:387` → `utils/py/work_connectors/github_board.py:97` → `utils/py/board_sync.py:528` | Canonical RELEASES write → work events → connector cursor → shared board writer. Reuse this path, not raw GitHub mutations. |
| Work-start projection | `utils/py/board_sync.py:447`, `:653` | reconcile/touch mean In progress; they are not full lifecycle refresh. Do not run them indiscriminately after terminal-state reconciliation. |
| Release cards | `utils/py/releases_app.py:3072` | project sync projects release cards, distinct from issue lifecycle kanban. Do not substitute it. |
| HiQS reader | rebalanceOS `src/rebalance/mcp/tools/index.py:247` → `src/rebalance/ingest/next_actions.py:1566`, `:1613` | get_next_actions reads cached ranked actions and metadata. Standalone HiQS/hiqs search package is a different feature. |
| HiQS coverage | rebalanceOS `src/rebalance/mcp/tools/index.py:11`, `:118`, `:272`; `src/rebalance/ingest/querier.py:522` | Ingest timestamps, watched repos and time/repo-filtered retrieval support the seven-day evidence window. Latest ranking is a snapshot, not a seven-day historical ranking. |
| HiQS configuration | rebalanceOS `src/rebalance/paths.py:221` | Existing DB resolver: explicit → REBALANCE_DB → app-data → configured database_path → root walk-up. Verify configured path; no new DB or copied settings. |

## State and failure paths

PDDA docs and RELEASES domain rows are authoritative. RELEASES perform_write owns
receipt-backed domain/event writes; the connector dispatcher owns connector_cursors.
Board identity/options and snapshots are cached locally by board_sync. GitHub issue/card
identities must be qualified by repository; issue number alone collides across repos.

Connector failures deliberately preserve a successful host exit (`work_connectors/__init__.py:387`).
A zero exit is therefore insufficient: inspect FAILED/skipped diagnostics, cursor movement,
pending events and a fresh board read-back. Dispatch reads at most 500 events per batch
(`:127`); drain finite pending batches with progress checks. A reset replays history, so
use it only for evidenced projection drift and never as an unconditional weekly reset.
Board reads are paginated (`board_sync.py:381`). Missing columns fail; no automatic
board creation or column invention. Known kill switches remain respected.

Rebalance ranking may be empty on read failure (`querier.py:124`); missing/stale data
is unknown coverage, never proof of inactivity. Use exact repo identities and source
links, not semantic similarity alone, to justify corrections. Read-only reader fallback
may use configured installed Python runtime; no recomputation/ingestion is required.

## Unknowns

| Unknown | Effect | Resolution |
|---|---|---|
| Current user's effective board connector config | board_sync config resolved no board identity during recon; repo .xyz listing supplied no board config | At invocation inspect documented local config wiring and effective connector block; ask for missing identity only if unresolved. Do not commit machine settings. |
| Downstream version/capabilities | Some vendors lack work events, HiQS connection or non-development reconciliation | Inspect installed help/source; report unsupported capability and continue independent checks. No implicit migration or install. |
| Real live weekly correctness | This task authors a skill; live business data has not been swept | Exercise on authorized invocation; documentation QA cannot claim a live board update. |

## Current-state radius

Consumer PDDA docs, RELEASES rows/events/cursors, GitHub issues and configured project
cards; read-only Rebalance context and local/origin activity. Public reporting must not
export private source text or machine configuration.
