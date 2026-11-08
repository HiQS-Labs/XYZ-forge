---
title: merge-cleanup deployed copy never finds tick, so published retirement preserves every checkout
status: Active (shared plan GH-1247)
created: 2026-11-07
updated: 2026-11-07
owner: noelsaw1
gh_issue: 1362
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1362
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: false
reported_from: LTVera-Pandas
harness_commit: f5fe2379
non_goals:
  - Using the audited checkout's own tick (GH-744 forbids it).
  - Changing what counts as a live claim, or the fail-closed rule when no harness resolves.
  - The origin-held tag false positive (GH-1247).
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1247
goal: >
  merge_cleanup.py run from the Skills Army deployed copy resolves the maintained harness's
  bin/tick through the existing harness locator chain, so --retire-published-pr can verify
  claims; with no resolvable harness it still preserves as PRESERVE_UNVERIFIED_SESSION.
---

# GH-1362 — merge-cleanup deployed copy never finds tick

Canonical active shared plan: [GH-1247](../2-WORKING/GH-1247-RETIRE-REMOTE-TAGS.md). The original incident details below are retained; plan, ratings, QA and verification are maintained in the shared plan. PR #1364 implements this issue; installed deployment remains post-merge.

## Symptom

From `<Deployed Skills>/merge-cleanup/scripts/`, `--retire-published-pr` reports "tick binary not found" and preserves every checkout as `PRESERVE_UNVERIFIED_SESSION`.

## Environment

- **Observed from:** `LTVera-Pandas` (vendored `.xyz/`; driver run from the Skills Army deployed copy)
- **Harness commit:** `f5fe2379`
- **Worker/CLI:** n/a (`merge_cleanup.py` → `scan_clones.py`)
- **Runtime:** Python
- **Sandbox:** off

## Reproduction

1. `python3 "<Deployed Skills>/merge-cleanup/scripts/merge_cleanup.py" --primary <primary> --retire-published-pr <n> --checkout <clone>`, with no `tick` on PATH and `MERGE_CLEANUP_TICK_BIN` unset.

**Expected:** the maintained harness's `bin/tick` is resolved (`XYZ_HARNESS`, then `~/.config/xyz/harness`, as the relay-xyz locator does); fail closed only if none resolves.
**Observed:** `PRESERVE_UNVERIFIED_SESSION | Cannot verify tick claims: tick binary not found`.
**Frequency:** every time from the deployed copy.

## Cause

`skills/2-daily/merge-cleanup/scripts/scan_clones.py::_tick_binary` tries `MERGE_CLEANUP_TICK_BIN`, then `bin/tick` among the script's own parents (only true inside an XYZ-forge checkout), then PATH.

## Impact

start-task Step 9 published retirement cannot complete from the deployed copy. Workaround: run the driver from an XYZ-forge checkout, or set `MERGE_CLEANUP_TICK_BIN`.

## Phase 0 — Diagnose & scope
> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [x] Reproduce it in the intake repo (not just in the reporting repo)
- [x] Locate the responsible script/path — name the concrete write-set
- [x] Decide fix vs. guard-and-document; reuse an existing code path before adding one (`/ponytail`)
- [x] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [x] The repro is confirmed from the report, not assumed
- [x] An existing suite, or a recorded manual check, covers the failure path before the fix lands (no new test suites: `AGENTS.md` *No new tests*, GH-831)
- [x] The fix composes with the existing harness rather than adding a parallel path
