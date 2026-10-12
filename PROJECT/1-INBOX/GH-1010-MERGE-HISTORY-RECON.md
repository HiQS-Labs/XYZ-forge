---
title: "GH-1010 — Merge history recon"
status: Reference
created: 2026-10-09
updated: 2026-10-09
owner: Codex
roadmap_exempt: true
goal: Ground the merge policy implementation.
---

# Recon Map — merge history policy
Commit: ecec5561 · Mode: graph attempted + file reads (graph has no cleanup symbols) · Lanes: local A/D; read-only agent B/C.

## Subject and change class
Per-project merge strategy constraint in the existing cleanup orchestrator; local configuration contract.

## Seams and call paths
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:1182` CLI defaults strategy to squash; `main:1198` resolves explicit primary. `land_prs:854` calls the writer at :1098 and forwards method to `execute_pr_merge:150`, the single GitHub merge writer. This is the enforcement seam. `_gh` already bounds subprocess failures.
- `merge_cleanup.py:1081` dry-run preview formats method independently; it must use the same resolver. The skill caller can park docs before executing Phase 0, so its instructions must check policy first. The Python command should also resolve policy before Phase 0.
- `scan_clones.py` existing ancestry and merged-PR/content checks authorize disposal; no policy change should weaken them. Deep skill consumes scanner JSON and its agent template, assesses content versus ancestry, then hands teardown back to cleanup.
- `skills/4-occasional/vendor-stack/SKILL.md:30` owns interactive adoption choices. `relay-automation/xyz-vendor.sh:59` requires an existing directory, mirrors harness into `.xyz/`; it never creates a repository. Runtime allowlist at :236 survives upgrades; target-root files are outside that mirror.
- `utils/py/device_config.py:29` uses a machine/user config, not shared project policy. PRS settings only exist with Tier 2. Neither is a universal project policy mechanism to reuse.
- `test/gh436-merge-cleanup.sh` registers the existing Python suite and GH-534 modules. Retain this coverage; manual policy probes follow the current no-new-tests rail.

## State and contracts
Proposed target-root tracked `.merge-cleanup.json` is maintainer-owned input, read only by the existing orchestrator; deep audit calls its policy-report mode. No new database, global preference, independent parser or vendoring writer. Existing `--strategy` remains available subject to opted-in policy. Missing policy preserves existing squash default.

## Failure and rollback today
`_gh` failure returns false, `land_prs` stops before teardown; merged state re-query is retained. Configuration errors should enter that refusal path. Remove/disable the policy to restore future default behavior; do not rewrite history. Historical squash/content fallback remains necessary.

## Unknowns
Hosting rulesets/merge queues can further restrict merge commits even when the repository capability says enabled. Let GitHub refuse; never switch methods. No end-to-end live merge is authorized by this implementation task.

## Current-state radius
Cleanup landing and preview, deep audit instructions, vendor-stack adoption guidance; not the coordination kernel, ledger schema, GitHub settings, or teardown eligibility algorithm.
