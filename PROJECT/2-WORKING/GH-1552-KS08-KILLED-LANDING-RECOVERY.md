---
issue: 1552
title: "kickstart(KS-08): safe self-recovery of a killed landing (stopped-ownership + remote PR state)"
status: active
roadmap_id: rmi-01M7W39V9G92M8W97MX702YQCA
parent_arc: 1541
milestone: KS-08
created: 2026-11-20
---

# GH-1552 (KS-08) — Safe Self-Recovery of a Killed Landing

## Objective
Codify in `skills/1-hourly/kickstart/SKILL.md` the child's deterministic, fail-closed self-recovery protocol for a killed or interrupted landing before touching any stale `merge-cleanup` attempt record, reusing existing `attempt_record.py` and `merge_cleanup.py` mechanisms (no new runner or schema).

## Grounded Recon
- `skills/1-hourly/kickstart/SKILL.md` Section 4 (Transition 4) defines parent-level stopped-ownership proof and recovery ladder, but does not define the child's exact killed-landing recovery sequence for `merge-cleanup` attempt records.
- `skills/2-daily/merge-cleanup/scripts/attempt_record.py` stores per-PR records at `<LANDING_CLONE>/.tick/merge-cleanup/<repo_slug>/pr-<N>.json` with exclusive `RecordLock` (`<record>.lock`), `MAX_REPAIRS = 2`, and `repair_count(rec) = len(rec["attempts"])`.
  - `MERGE_CLEANUP_RECORD=<abs-path> python3 skills/2-daily/merge-cleanup/scripts/attempt_record.py finish --index <idx> --outcome aborted-<reason> --reason "..."` closes an `in_progress` attempt while preserving the attempt entry and repair count.
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` supports `--reconcile-pr <N> --execute` (for a PR already `MERGED` remotely but unreconciled locally) and `--resume --execute` (for an `OPEN` PR after settling an aborted attempt).
- `utils/ci-route.sh` classifies edits to `skills/1-hourly/kickstart/SKILL.md`, `PROJECT/**`, `TESTS-RESULTS/**`, `CHANGELOG.md`, and `releases.db`/`releases.sql` as `route=docs`.

## Plan
1. Add a concise **Killed-Landing Self-Recovery Protocol (KS-08)** subsection under Section 4 (Transition 4) of `skills/1-hourly/kickstart/SKILL.md`:
   - **Precondition 1 — Stopped-Ownership Proof (mandatory before touching any attempt record):**
     - Verify the prior landing owner, its lock owner (`<record>.lock` and any repo/driver lock), and every associated builder, check, or push subprocess or detached session are truly stopped.
     - Live, paused, or unknown ownership MUST hold immediately without modifying any attempt record or redispatching.
     - Identify the exact coordinator record under the pinned `LANDING_CLONE/.tick/merge-cleanup/<repo_slug>/pr-<N>.json` and the exact `in_progress` attempt index before any `finish` call; never create or switch to a second landing clone, and never reset or delete attempt entries (preserving the 2-repair ceiling).
   - **Precondition 2 — Remote PR State Verification (`gh pr view <N> --json state,headRefOid,mergeCommit`):**
     - **`MERGED` (unreconciled locally):** run `merge_cleanup.py --primary <LANDING_CLONE> --reconcile-pr <N> --execute` (backgrounded); NEVER run `--resume` or re-merge.
     - **`OPEN` with `headRefOid` unchanged** (matching the `in_progress` attempt's `head_sha`): settle the interrupted attempt via `MERGE_CLEANUP_RECORD=<abs-record-path> python3 skills/2-daily/merge-cleanup/scripts/attempt_record.py finish --index <idx> --outcome aborted-<cause> --reason "..."`, verify `repair_count` is preserved, then launch `merge_cleanup.py --primary <LANDING_CLONE> --resume --execute` (backgrounded).
     - **`OPEN` with `headRefOid` changed, `CLOSED`, or remote state/outcome unknown:** HOLD (never retry an unknown outcome).
   - **Budget Preservation:** Preserve original wall deadline, global task budget, and the 2-repair ceiling across recovery.
2. Update `CHANGELOG.md` with a concise GH-1552 (KS-08) entry.
3. Retain disposable-clone paired red/green checks under `TESTS-RESULTS/2026-11-20+GH-1552/` (no new test suite, GH-831; real `attempt_record.py` entry point in a disposable repo):
   - **Control A (Live check/lock session -> HOLD):** While a lock/check subprocess is live (holding `RecordLock` / live PID), recovery refuses to touch the attempt record; `attempt_record.py` preserves `in_progress` untouched and lock contention refuses mutation.
   - **Control B (Stopped owner + OPEN unchanged head -> `finish aborted-timeout` + `--resume`, repair count preserved):** Pre-change (run-1 #1539 shape) required manual parent intervention; changed path proves stopped ownership + unchanged head, runs real `attempt_record.py finish --index 0 --outcome aborted-timeout`, confirms `outcome == "aborted-timeout"` and `repair_count == 1` (NOT reset to 0), and confirms remaining budget is `1/2` for `--resume`.
   - **Control C (Post-merge interruption / remote `MERGED` -> `--reconcile-pr`, NOT `--resume`):** Controlled decision replay where remote PR state is `MERGED` with an `in_progress` attempt: verifies the protocol selects `--reconcile-pr N --execute` and refuses `--resume`, and verifies changed-head `OPEN` holds.
   - Run `./utils/pdda/pdda.sh run` and generate `provenance.jsonl`.

## Acceptance Criteria
- `skills/1-hourly/kickstart/SKILL.md` specifies exact stopped-ownership proof (owner + lock + builders/checks/push/sessions), exact coordinator record + index lookup, remote PR state branching (`MERGED` -> `--reconcile-pr`, unchanged `OPEN` -> `finish aborted-*` + `--resume`, changed/unknown -> hold), and budget/repair-count preservation.
- All three disposable-clone paired red/green controls executed against real `attempt_record.py` and recorded with `provenance.jsonl`.
- `./utils/pdda/pdda.sh run` passes with 0 errors.
