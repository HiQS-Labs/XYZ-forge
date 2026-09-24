---
title: "Recon Map — GH-767 architecture diagrams"
status: Complete
created: 2026-09-23
updated: 2026-09-23
owner: Codex
goal: establish the current code-backed component and relationship set for every generated diagram under ARCHITECTURE
roadmap_exempt: true
---

# Recon Map — GH-767 architecture diagrams

Commit: `a47c212b3ce2cee400853386a3e7213182f7827d` · Mode: graph+read · Lanes: A/B/C/D

## Subject and change class

Subject: all generated JSON/HTML diagram pairs under `ARCHITECTURE/`.

Change class: cross-module documentation regeneration. The specs describe shared runtime authority,
state, trust boundaries, external effects, and deployment projections, but do not change those systems.

## The seams — where stale diagrams escape the file

| Seam | Location | Crosses | Breaks if |
|---|---|---|---|
| Python-default Tier-A routing | `relay-automation/relay-drive.sh:2`, `relay-automation/marathon-drive.sh:2` | shell entry points → authoritative Python implementations | diagrams keep naming frozen Bash twins as runtime owners |
| Marathon actor dispatch | `relay-automation/marathon-agent.sh:12` | phase driver → selected turn adapter | diagrams connect the relay driver directly to an incomplete adapter list |
| Relay containment | `utils/py/rtl.py:882`, `relay-automation/relay-turn-lib.sh` | Python adapters → shared enforcement/worktree core | one layer is presented as the whole containment contract |
| Approval authority | `utils/py/relay_attest.py:1` | reviewer turn → driver-authored attestation | thread `STATUS` is shown as sufficient proof of approval |
| Coordination authority | `bin/tick`, `src/events.js`, `src/project.js` | CLI verbs → append-only events → projected state | the event log and its projection are collapsed or bypassed |
| Roadmap authority | `ROUTER.md:143`, `utils/py/releases_app.py:4044` | releases-mode CLI → `roadmap_items` in `releases.db` | retired `ROADMAP.md`/dashboard flows are shown as live |
| Ledger write boundary | `utils/py/releases_app.py:1616` | verbs → lock/journal/receipts → DB + SQL dump | ordinary writes and merge recovery are conflated |
| Work-state projection | `utils/py/releases_app.py:1537`, `utils/py/work_connectors/__init__.py:127` | ledger transaction → append-only events → bounded connectors | remote projections appear authoritative or coupled to ledger success |
| Derived ledger views | `utils/py/releases_app.py:1332`, `utils/releases-merge-resolve.sh:154` | DB → presence gate → three optional root views | retired dashboard and deleted staleness guard remain visible |
| Hosted reconciliation | `.github/workflows/wave-reconcile.yml:3`, `utils/py/wave_reconcile.py:1579` | merged PR/schedule → ledger/docs/views → declared publisher | post-merge lifecycle ownership is absent |
| Verification boundary | `githooks/pre-push:206`, `utils/ci-route.sh:17`, `AGENTS.md:319` | changed paths → routed local gate; main push → macOS attestation | a deleted artifact guard is shown, or linked worktrees are shown as suite isolation |
| Flightdeck read boundary | `src/flightdeck/server.py:37`, `src/flightdeck/connectors.py:57` | local producers → passive loopback snapshot/UI | the current operational read surface is omitted or shown as a writer |
| Skills Army distribution | `skills/3-weekly/skills-army-hq/SKILL.md:40` | owning repos → one Pulse collection/device → app symlinks | the superseded GH-508 extra-projection design is retained |
| Git history generation | `utils/swe-diagram/scripts/git-history-to-json.js:49` | cached refs → bounded lane snapshot | deleted branches or un-fetched remote state are invented |

## Call paths in

```text
operator skills / HQ
  -> GitHub issue + PROJECT capture
  -> releases_app roadmap and release verbs
  -> planner / preflight
  -> Jog or Marathon
  -> relay supervisor -> actor router -> turn adapter
  -> RelayTurnLib + relay-turn-lib.sh containment
  -> model CLI in a throwaway working tree
  -> tick events + relay thread + driver attestation
  -> gate -> landing -> hosted reconciliation
```

```text
owning skill repository
  -> Skills Army intake/update on publisher Pulse checkout
  -> reviewed Git commit/push -> private Pulse remote
  -> clean pull on another device -> in-place adoption
  -> device-local receipts/targets -> app-directory symlinks
```

## State

- `tick` owns turn/claim state through `.tick/events`; `STATE.md` is a projection.
- `releases.db` owns runtime release, roadmap, Jog, receipt, and work-event state; `releases.sql`
  is the Git merge surface and recovery input.
- Relay Markdown holds review content; driver-authored attestation holds approval evidence.
- Skills payloads travel in each device's Pulse checkout. Targets, receipts, locks, catalog/history,
  backups, and staging remain ignored device-local state.
- Flightdeck is a passive aggregator over typed local sources and established-work reads.

## Contracts

- `marathon-invocation@1` and `marathon-drive/result@1` connect planning to execution.
- `perform_write` is the single ledger business-write protocol; connector dispatch occurs only after
  its durable commit and cannot change the host verb's result.
- Root ledger views are opt-in by presence; Pages roadmap generation is a separate deploy-time path.
- A throwaway linked worktree isolates working files, not shared `.git`; mutation-heavy suites require
  a separate full clone.
- Skills Army deployments refuse canonical Forge drift unless an explicit loud override is selected.

## Build, failure and rollback today

Diagram JSON is validated by `utils/swe-diagram/scripts/validate-spec.js` and rendered by
`utils/swe-diagram/assets/build-diagram.sh`. The Git-history spec is generated directly from cached
local and remote-tracking refs. Every HTML file is disposable and rebuildable from its paired JSON.
Rollback is the prior JSON specs followed by a full HTML rebuild.

## Unknowns

| Unknown | Why it matters | What would settle it |
|---|---|---|
| Flightdeck is implemented and used but not yet a top-level core dependency | It should be visible without implying the execution path depends on it | Treat it as passive/experimental until README/ROUTER promotes it |
| The repository's GH-672 Skills Army contract differs from this machine's observed external Git Pulse writer/configuration | A diagram must not claim an unverified scheduled publication path | Depict the repo contract and label Git commit/push/pull as an explicit external workflow |

## Current-state radius, one line

Operator skills and HQ, GitHub intake, PROJECT/PDDA docs, releases and work-event state, Jog/Marathon
planning, relay execution and containment, model CLIs/providers, local/hosted gates, reconciliation,
Flightdeck reads, and cross-device Skills Army projection all depend on the concepts these diagrams expose.

