---
gh_issue: 1485
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1485
title: "feat(whack-a-mole): sharpen for cross-repo topology, multi-domain failure taxonomy, and phased umbrellas"
status: Active — Plan authoring
created: 2026-11-14
updated: 2026-11-14
owner: start-task lane
goal: Sharpen whack-a-mole to detect cross-repo upstream/downstream boundaries, decompose compound multi-domain failure modes, and structure multi-domain umbrella remediation plans into phased delivery lanes.
doc_type: enhancement
effort: 2
complexity: 2
risk: 1
phases: 1
related:
  - GH-1383 (optimize merge sequences umbrella)
  - GH-1475 (merge-cleanup 3-phase remediation plan)
  - GH-781 (radar reports seeding)
  - GH-860 (CI churn SOP)
context_tags: [whack-a-mole, skills, multi-domain, cross-repo, diagnosis]
---

# GH-1485 — Sharpen Whack-a-Mole: Cross-Repo, Multi-Domain Taxonomy & Phased Umbrellas

## Status
| What was just completed | What's next |
|---|---|
| Fresh full clone provisioned, issue #1485 created, capture registered | Author surgical implementation plan, run Codex plan QA |

## Background & Motivation
In recent weeks, complex batch execution tools (such as `merge-cleanup` and `wave_reconcile`) suffered from severe bug churn spanning both upstream (`HiQS-Labs/XYZ-forge`) and downstream consumer repositories (`BinoidCBD/LTVera-Pandas`).
The failures manifested across four distinct operational planes:
1. **Resource / Storage**: clone workdir leaks filling disk.
2. **Platform / Harness**: temp directory deletion and 600s subshell timeouts.
3. **Concurrency / State**: git ref locking races during concurrent fetch/pull.
4. **Merge Protocol / Domain**: GitHub squash merge failing to pair renames with reconcile appends.

When run in a downstream repo, standard `whack-a-mole` currently only scans `gh repo view` (missing upstream code churn), treats complex failures as a single invariant, and produces a single linear task list (`Repro -> Guard -> Fix -> Sweep -> Verify`) that cannot adequately capture multi-plane remediation.

## Proposed Enhancements
1. **Cross-Repo Topology Discovery (§2 Scan)**:
   - Recognize shared tool / engine dependencies (via `.merge-cleanup.json`, `.tick`, `PROJECT/`, or Skills Army roots).
   - Ingest symptoms from consumer repos while linking code churn from producer repos.
   - Proactively resolve external cross-repo issue mentions (`owner/repo#N`).
2. **Multi-Domain Invariant Taxonomy (§5 Isolate Invariant)**:
   - Decompose clusters across four planes: Platform/Harness, Resource/OS, Concurrency/State, and Domain Logic.
   - Distinguish primary root cause invariant violations from environmental catalysts and secondary casualties.
3. **Phased Umbrella Remediation Plans (§6 Draft Umbrella)**:
   - For multi-domain clusters, format the remediation plan into phased lanes: Phase 1 (Defensive Guards/Pre-flights), Phase 2 (Core Invariant Repairs), Phase 3 (Architectural Decoupling).
4. **Runtime Telemetry & Transcript Harvesting (§2 Scan)**:
   - Inspect local execution logs, test results, and issue comment addendums where crash/timeout telemetry resides.
