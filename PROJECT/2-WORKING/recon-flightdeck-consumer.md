---
title: Flightdeck consumer — Recon Map
status: Complete — bounded source recon
created: 2026-09-08
updated: 2026-09-08
owner: Codex
doc_type: research
roadmap_exempt: true
gh_issue: 494
source: https://github.com/HiQS-Labs/XYZ-forge/issues/494
---

# Recon Map — Flightdeck consumer

## Status

| What was just completed | What's next |
|---|---|
| Existing Rebalance, Git Pulse, CLIO, continuity and Swift consumer seams traced read-only. | Use this map to review the canonical Flightdeck implementation plan. |

## Subject and change class

Add a read-only HTML consumer of existing work signals, with tokenized presentation
and a later Swift client. Cross-module read contract and UI addition; source authority
stays with existing writers. No new source of truth or collection pipeline is proposed.

Rebalance reference commit: `0bffc4dab79da4a2a13ecd605af9798181a76bc9`.
Rebalance had unrelated dirty documentation, including CLIO install notes; the
planning-evidence source hashes pin inspected working-tree bytes, not a claim that
every deployed/configuration file equals the base commit.
XYZ mockup reference commit: `c7e4bce88ec60599b876e2b28de6c1d542482a1f`.
`RB:` below means a path relative to the inspected Rebalance checkout; `XYZ:` means
this repo. Machine-local locations are configuration inputs, not deployment literals.

Mode: graph leads plus exact source. Parent Verify graph generation was
`2026-09-02T03:54:57Z`, fast. Positive search results were narrowed; broad search
pagination was not exhausted, so no exhaustive symbol claim is made. Coverage
reported changed/untracked metadata for registry, queries, index_ops, pulse, config,
next_actions, github_knowledge and shutdown scanner. Scripts/MCP tool subtrees were
excluded. All material paths were source-read by the parent or read-only recon lanes;
no graph-only edge is relied on. Three independent lanes covered Git Pulse state,
Rebalance entry/contracts, and runtime/Swift operations; parent covered mockup and CSS.
CLIO received a bounded follow-up. No source refresh, sync, collector, Git scan or
launchd mutation was invoked. No private prompt/message bodies were copied.

## The seams

| Seam | Source evidence | Contract and consequence |
|---|---|---|
| Existing local HTTP host | `RB:scripts/pulse_server.py:76,126,575` | Shares selected web handlers, binds loopback port 8767. Reuse the host; it does not automatically inherit every web.py route. |
| Cached SQLite reads | `RB:src/rebalance/ingest/db/connection.py:91` | Existing `db_connection_readonly` uses SQLite URI `mode=ro`; normal factory at line 20 creates directories/sets write-oriented pragmas. |
| Project/repo identity | `RB:src/rebalance/ingest/registry.py:14,375`; `db/queries.py:60,188` | Canonical projects and mirror-alias resolution exist. Pass a read-only connection; standalone registry lookup assures schema. |
| Issue/PR/check corpus | `RB:src/rebalance/ingest/db/schema.py:433,479,503,522,543,654,706` | GitHub items, reviews/comments, commits, checks, links and coverage are already stored. Preserve event time, fetched time, full SHA and coverage separately. |
| Cached PR queries | `RB:src/rebalance/ingest/db/queries.py:776,1217` | Correct newest-mirror-before-open selection exists. Output currently omits some freshness/SHA fields; default PR limit 10 is not a fleet total. |
| Commit queries | `RB:src/rebalance/ingest/db/queries.py:389` | Arbitrary time window supported despite `fetch_day_commits` name; canonical repo/SHA dedup exists, but output abbreviates SHA and author scope matters. |
| Next actions | `RB:src/rebalance/ingest/next_actions.py:271,303,1566` | Persisted result includes computed_at and evidence. Existing loader needs supplied read-only connection support rather than ordinary factory. |
| Local signals cache | `RB:src/rebalance/ingest/focus5_scan.py:68` | RepoSignals includes device/path/remote/branch/dirty/recency/probed_at. Cached signals are reusable; ranked top-five roster cannot represent all physical checkouts. |
| Git Pulse writer | `RB:experimental/git-pulse/collect.sh:146,371,400,418,438,492` | Per-device TSV-in-Markdown commit feed plus YAML heartbeat. Basename and branch-at-scan-time are not canonical repository/checkout identity. |
| Git Pulse health/parser | `RB:src/rebalance/ingest/pulse_health.py:88,138,167`; `experimental/git-pulse/sqlite_spike.py:165,213,253` | Supported pure health/config reads exist. Narrow TSV parser exists in an experimental nonautomatic spike; promote/reuse parsing only if no supported equivalent fits. |
| CLIO writer | installed `~/.claude/hooks/clio-capture.sh:21,47,74,85,137`; `RB:utils/CLIO/INSTALL.md:38` | Existing hook appends timestamp/repo/branch/machine/agent/session_id/prompt. Repo is basename; prompts under 20 chars and system/relay inputs may be omitted. |
| CLIO tailers and projection | `RB:utils/CLIO/clio-codex-tail.sh:138,213`; `clio-agy-tail.sh:133,138`; `src/rebalance/ingest/clio.py:21,44,73,147` | Existing tailers capture user input. DB projection already exists but drops branch/machine. Prompt intent is not completed work or process liveness. |
| CLIO orchestrator | `RB:src/rebalance/ingest/index_ops.py:602,1958,2210` | Existing source registration/ingest and freshness concepts; app must not invoke ingestion to serve a read. |
| Existing topology scanner | `RB:.agents/skills/daily/scripts/scan_unclosed_loops.py:400,829,852`; `.agents/skills/shutdown/SKILL.md:37,92` | Existing scanner serializes canonical remote, common Git dir, branches, worktrees, commits, clone counts and limits. It prints results; skill asks invoking agent to persist them. Existing recurring output is not established. |
| Swift consumer precedent | `RB:macOS/Apps/Focus5Float/Sources/Focus5Float/Focus5Client.swift:49,59,196`; `Focus5Model.swift:198,211`; `Focus5FloatApp.swift:75,120` | Loopback JSON client, timeout, last-known cache and offline behavior already exist. Reuse the pattern; ranking/Git/DB remain server-owned. |
| Current HTML | `XYZ:docs/mockups/flight-dashboard/index.html:7,46`; `focus-cards.js:1,7,23,69,89`; `focus-cards.css:1` | A working entry and B/C shared renderer use illustrative arrays, navigation/spotlight and sample clock. No live consumer exists. |

## Call paths and state authority

```text
Existing Git Pulse launchd -> installed git-pulse writer -> configured sync folder
  -> pulse-<device>.md + devices/<device>.yaml
Existing GitHub job -> refresh_index github/focus5 -> existing SQLite corpus/cache
Existing CLIO prompt hook / 60s tailers -> prompt-log.jsonl
  -> existing CLIO ingest adapter -> clio_prompts
  -> existing Markdown export -> operator prompt log (separate presentation)
Existing Daily/Shutdown invocation -> existing scanner -> stdout
  -> invoking agent's saved JSON/Markdown, when present
Existing Pulse host -> existing cached read helpers -> existing clients
Proposed Flightdeck -> new passive read projection on that same host -> HTML/Swift
```

The first four producer paths remain owners. Flightdeck may write local UI preferences
and a disposable display cache only; it must not write the corpus, sync repo, prompt
log, watched checkouts, source schedules or Git refs. A topology export extension,
if required, belongs to the already-existing scanner/writer path.

## Current feed contents and observed limits

Read-only sync-folder enumeration found 57 non-Git files: 37 Markdown, 9 JSON, 6 TSV,
3 YAML and 2 extensionless. Three pulse files contained 2,698 six-field observations
(epoch, UTC time, repo basename, branch, short SHA, subject). Nine JSON files were
calendar/email snapshots/pointers and a Sleuth reminders export—not a Git topology
snapshot. PDDA/XYZ TSVs are installation registries, not active clone counts.
Twelve narrative snapshots were historical, newest August 10. The CLIO directory
contained only a README about optional daily synthesis, not the raw prompt stream.

Git Pulse's `.git` directory check (`collect.sh:373`) skips linked worktrees whose
`.git` is a file. Its reflog filter collects commit/initial/amend, not every merge,
rebase or checkout. Installed script differs bytewise from source; inspected relevant
coverage/filter logic matches, but broad deployment parity was not established.

| Device | Latest observed heartbeat UTC | Configured / scanned / missing | Latest pulse commit UTC |
|---|---|---|---|
| Studio | 2026-09-08T05:33:04Z | 49 / 3 / 46 | 2026-08-16T14:58:56Z |
| Laptop 14 | 2026-09-08T05:15:51Z | 62 / 56 / 6 | 2026-09-04T19:28:32Z |
| Laptop 16 | 2026-07-20T21:41:05Z | 1 / 1 / 0 | 2026-07-19T16:54:10Z |

All three records said scan_status=ok. Only explicit scan failures degrade that
producer status; skipped missing paths do not. This proves coverage insufficiency,
not why each path is absent. A fresh heartbeat cannot justify zero activity or red
inactivity for uncovered repos. Pure health reader currently omits these counts;
exposing them is a reader extension, not a new health collector.

CLIO JSONL at inspection: 1,472 valid rows, 0 malformed, 2,111,212 bytes; latest
record 2026-09-08T06:22:53Z; 976 rows had a repo. Agent values included agy, zcode,
claude-code and codex. Markdown export existed, timestamp 06:19:17Z. Raw JSONL is
local; Markdown cross-device sync health was not verified. No separately named
CLIO skill folder appeared in the three searched installed roots, but hooks/tailers
are concretely installed and deployed Daily explicitly references them. This is an
implementation-location clarification, not an absent-capability claim.

At inspected locations, checkout daily output was last modified September 7 around
12:00 PDT; no shutdown output directory, runtime daily-log or generic telemetry
folder was present. These are bounded path checks, not a device-wide absence claim.
The generic Swift telemetry shape (`TelemetryModels.swift:7`) lacks a reliable
repo/issue/agent/milestone join. Completed agent milestones remain unverified.

## Installed cadence, not a promised refresh SLA

| Existing mechanism | Observed installed schedule |
|---|---|
| Git Pulse collection | 3,600 seconds + RunAtLoad |
| GitHub ingest / Focus5 | Hourly at :45, 06:00–23:00 |
| Pulse Markdown publication | Hourly at :00, 06:00–23:00; reads existing ingested data |
| Pulse HTML publication | :08 and :38, 06:00–23:00 |
| CLIO Claude hook | User prompt event |
| CLIO Codex/Agy tailers | 60 seconds |
| CLIO Markdown export | 300 seconds installed; docs currently say 60 |
| Rebalance daily synthesis job | 18:20 daily |
| Installed Daily conversational skill | Intended 15-minute workflow; not the same job |
| Pulse server | Persistent KeepAlive, loopback 8767 |
| Existing Focus5Float UI | 90-second client polling |

Relevant installed launchd jobs were loaded; inspected completed jobs returned exit
0 and server was running. No job was triggered. Schedule evidence comes from
installed plists, not inference from templates. A 150-second consumer refresh cannot
make an hourly producer current within 150 seconds.

## Consumer traps and failure paths

- `/focus-5.json` is not passive cached-only: `web.py:957` calls summarize defaults;
  `focus5_scan.py:1023,1055` probes Git activity/health and enriches only one PR.
- `/focus-5` on missing roster/refresh (`web.py:793`) calls sync; `/whats-next` on
  missing cache/refresh (`web.py:1571`) calls ranking/network/persistence.
- `pulse_server.py:307` POST refresh invokes helper/write/render operations.
- `collect_pulse_snapshot` can search live assigned GitHub issues (`pulse.py:451`);
  publish path (`pulse.py:949`) commits/pushes. Neither is a consumer read adapter.
- `get_index_status` (`index_ops.py:508`) calls ensure_semantic_schema despite its
  read-only description. Use existing read-only gateway plus bounded safe queries.
- `sync_snapshot.py:317` pointer reader returns None on failure and lacks strict
  pointer/schema containment. If used, validate confined target and distinguish
  error from empty. No need to read unrelated calendar/email contents for v1.
- `github_coverage.py:120` remote_tip uses ls-remote. Read stored coverage instead.
- Do not inherit or revive 3-Eyes; repo policy explicitly defers it.

## Current styling and future reuse

Measured literal occurrences: working A entry has 71 hexadecimal colors and 102
font-size declarations; shared B/C CSS has 53 colors and 49 font-size declarations.
Some CSS variables exist, but this is not full tokenization. Frozen A has SHA-256
`f6a71e98692acaf81a1e3cbdd4b58ad7cd6b2ec844bf3a6bb5e8f83695446607`.
Plan tokenization on production assets only, preserving every current mockup byte.

## Unknowns and the smallest way to settle them

| Unknown | Why it matters | Bounded next check / disposition |
|---|---|---|
| Rebalance CLIO cache lag on active runtime DB | Prompt capture cadence differs from ingest | Compare count/max timestamp/synced_at via existing read-only gateway; no ingest invocation. |
| Complete current topology output elsewhere | Current sync folder lacks it; scanner exists | Verify configured existing Shutdown output locations; if absent, add persistence to that source-owned writer. No new scan engine. |
| Why 46 Studio configured repos were skipped | Coverage blocks exact totals/inactivity claims | Existing Git Pulse owner checks configured paths and deployed version; do not repair from dashboard. |
| Complete issue-linked agent milestones | Prompt requests are not completions | Inspect an existing structured completion record with stable repo/issue/event ID; otherwise display unknown. |
| CLIO branch/machine in cached projection | Raw writer has them, DB drops them | Additive existing CLIO projection migration/backfill, only when those fields are needed. |
| Cross-device CLIO coverage | Local writer does not prove sync | Verify existing notes/sync owner; local-only coverage until then. |
| Full per-repo GitHub coverage and state-transition history | Zero and ready claims need more than one fresh row | Expose stored corpus coverage and exact-head check evidence; absent transition history stays unknown. |
| Target source revision at execution | Other agents own active checkouts | Re-anchor against source HEAD and re-read changed seams before implementation. |

## Current-state radius

Existing Rebalance corpus and loopback clients, Git Pulse sync consumers, CLIO hooks,
Daily/Shutdown callers, and the three local Flightdeck mockups. Proposed work adds
one cached projection/API contract and a production UI consumer; upstream exporters
change only for named gaps, in their own owner lanes. No primary checkout edits or
running producer modifications were made during recon.
