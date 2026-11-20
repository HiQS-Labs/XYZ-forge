---
gh_issue: 1552
title: "kickstart(KS-08): safe self-recovery of a killed landing (stopped-ownership + remote PR state)"
status: Complete
roadmap_id: rmi-01M7WG8KCX34HV9TGT31N0Z79C
parent_arc: 1541
milestone: KS-08
owner: antigravity
goal: "Codify fail-closed child self-recovery for killed landings in skills/1-hourly/kickstart/SKILL.md using exact supported attempt_record.py and merge_cleanup.py CLI contracts."
created: 2026-11-20
updated: 2026-11-20
---

# GH-1552 (KS-08) — Safe Self-Recovery of a Killed Landing

## Status

| What was just completed | What's next |
|---|---|
| Implemented KS-08 killed-landing self-recovery rule in `skills/1-hourly/kickstart/SKILL.md` and passed disposable-clone Controls A/B/C + PDDA (0 errors). | Complete Codex Final QA, open PR, and land. |

## Objective
Codify in `skills/1-hourly/kickstart/SKILL.md` the child's deterministic, fail-closed self-recovery protocol for a killed or interrupted landing before touching any stale `merge-cleanup` attempt record, reusing existing `attempt_record.py` and `merge_cleanup.py` mechanisms (no new runner or schema).

## Grounded Recon
- `skills/1-hourly/kickstart/SKILL.md` Section 4 (Transition 4) defines parent-level stopped-ownership proof and recovery ladder, but does not define the child's exact killed-landing recovery sequence for `merge-cleanup` attempt records.
- `skills/2-daily/merge-cleanup/scripts/attempt_record.py` stores per-PR records at `<LANDING_CLONE>/.tick/merge-cleanup/<repo_slug>/pr-<N>.json` with exclusive `RecordLock` (`<record>.lock`), `MAX_REPAIRS = 2`, and `repair_count(rec) = len(rec["attempts"])`.
  - Exact CLI (`attempt_record.py:188-195`):
    - Attach diagnostic cause (consumes no budget): `MERGE_CLEANUP_RECORD=<abs-path> python3 skills/2-daily/merge-cleanup/scripts/attempt_record.py note --kind diagnosis --text "<cause>"`
    - Close the `in_progress` attempt: `MERGE_CLEANUP_RECORD=<abs-path> python3 skills/2-daily/merge-cleanup/scripts/attempt_record.py finish --index <idx> --outcome aborted-<cause>` (no `--reason` CLI flag exists).
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`:
  - `--reconcile-pr <N> --execute` reconciles a PR that is already `MERGED` remotely.
  - `--resume --execute` (`merge_cleanup.py:2533-2538`) STILL requires the original authorized `--prs <N>@<approved-full-sha>[,...]` selection (and applicable original landing-policy arguments); never widen the selection during recovery.
- `PROJECT/PDDA.md:462-465`: honor configured `CHANGELOG_WRITES` mode (no task-branch `CHANGELOG.md` edit under default `off`/`landing`).
- `utils/ci-route.sh` classifies edits to `skills/1-hourly/kickstart/SKILL.md`, `PROJECT/**`, `TESTS-RESULTS/**`, and `releases.db`/`releases.sql` as `route=docs`.

## Plan
1. Add a concise **Killed-Landing Self-Recovery Protocol (KS-08)** subsection under Section 4 (Transition 4) of `skills/1-hourly/kickstart/SKILL.md`:
   - **Precondition 1 — Stopped-Ownership Proof (mandatory before touching any attempt record):**
     - Verify the prior landing owner, its lock owner (`<record>.lock` and any repo/driver lock), and every associated builder, check, or push subprocess or detached session are truly stopped.
     - Live, paused, or unknown ownership MUST hold immediately without modifying any attempt record or redispatching.
     - Identify the exact coordinator record under the pinned `LANDING_CLONE/.tick/merge-cleanup/<repo_slug>/pr-<N>.json` and the exact `in_progress` attempt index before any `finish` call; never create or switch to a second landing clone, and never reset or delete attempt entries (preserving the 2-repair ceiling).
   - **Precondition 2 — Remote PR State Verification (`gh pr view <N> --json state,headRefOid,mergeCommit`):**
     - **`MERGED` (unreconciled locally):** run `merge_cleanup.py --primary <LANDING_CLONE> --reconcile-pr <N> --execute` (backgrounded); NEVER run `--resume` or re-merge.
     - **`OPEN` with `headRefOid` unchanged** (matching BOTH the original authorized full-SHA pin AND the interrupted `in_progress` attempt's `head_sha`):
       1. Record the diagnostic cause via `MERGE_CLEANUP_RECORD=<abs-record-path> python3 skills/2-daily/merge-cleanup/scripts/attempt_record.py note --kind diagnosis --text "<cause>"`.
       2. Close the interrupted attempt via `MERGE_CLEANUP_RECORD=<abs-record-path> python3 skills/2-daily/merge-cleanup/scripts/attempt_record.py finish --index <idx> --outcome aborted-<cause>`.
       3. Verify `repair_count` is preserved (never reset), then launch `merge_cleanup.py --primary <LANDING_CLONE> --root <ROOT> --prs <original-authorized-N@full-sha-list> [<original-landing-policy-flags>] --resume --execute` (backgrounded), never widening the PR selection.
     - **`OPEN` with `headRefOid` changed, `CLOSED`, or remote state/outcome unknown:** HOLD (never retry an unknown outcome).
   - **Budget Preservation:** Preserve original wall deadline, global task budget, and the 2-repair ceiling across recovery.
2. Honor configured `CHANGELOG_WRITES` mode (no task-branch `CHANGELOG.md` edit under default `off`/`landing`).
3. Retain disposable-clone paired red/green checks under `TESTS-RESULTS/2026-11-20+GH-1552/` (no new test suite, GH-831), clearly distinguishing real CLI execution checks from source-only instruction walkthroughs:
   - **Control A (Live lock / check subprocess -> HOLD, real `attempt_record.py` CLI):** While a live child holds `RecordLock` (simulating an active check/landing session), `attempt_record.py finish` with `MERGE_CLEANUP_LOCK_TIMEOUT_S=0.3` fails with `lock-timeout` and leaves `in_progress` untouched; instruction walkthrough confirms live/unknown ownership holds before touching any record.
   - **Control B (Stopped owner + OPEN unchanged head -> exact published `note` + `finish --index 0 --outcome aborted-timeout` + `merge_cleanup.py` CLI validation):**
     - Runs the EXACT published `attempt_record.py note --kind diagnosis ...` and `attempt_record.py finish --index 0 --outcome aborted-timeout` commands in a disposable clone, verifying `outcome == "aborted-timeout"`, `diagnosis` note recorded, and `repair_count == 1` (NOT reset to 0).
     - Runs real `merge_cleanup.py --primary <disposable-clone> --resume --execute` WITHOUT `--prs` (red: refused exit 2 with `a merging run needs --prs`) vs WITH `--prs N@<full-sha>` (green: passes CLI selection validation in dry-run/preflight without hitting the missing-`--prs` refusal).
   - **Control C (Post-merge interruption / remote `MERGED` -> `--reconcile-pr`, NOT `--resume`, plus changed-head HOLD):** Source-only instruction walkthrough + real `merge_cleanup.py --help` / argument validation confirming `--reconcile-pr N` accepts the post-merge reconcile mode distinct from `--resume --prs ...`, and changed-head `OPEN` maps to HOLD.
   - Run `./utils/pdda/pdda.sh run` (0 errors) and generate `provenance.jsonl`.

## Acceptance Criteria
- `skills/1-hourly/kickstart/SKILL.md` specifies exact stopped-ownership proof, exact coordinator record + index lookup, exact supported `attempt_record.py note`/`finish` CLI flags, exact `merge_cleanup.py --reconcile-pr` vs `--prs <original-pins> --resume --execute` branching, and budget/repair-count preservation.
- Controls A, B, and C executed and accurately labeled (real CLI checks vs instruction walkthrough) under `TESTS-RESULTS/2026-11-20+GH-1552/` with `provenance.jsonl`.
- `./utils/pdda/pdda.sh run` passes with 0 errors and `CHANGELOG_WRITES` policy is respected.
