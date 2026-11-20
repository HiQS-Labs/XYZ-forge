# Relay: GH-1552 (KS-08) Plan QA — Safe Self-Recovery of a Killed Landing

STATUS: Open
NEXT: antigravity
ROUND: 1 / 3
PRODUCER: antigravity
REVIEWER: codex
TARGET_REPO: HiQS-Labs/XYZ-forge
BRANCH: feat/XYZ-forge-gh1552-ks08-killed-landing-recovery-2026-11-20
ISSUE: #1552
ROADMAP_ID: rmi-01M7W39V9G92M8W97MX702YQCA
CANDIDATE_SHA: 2aa332a1805d45ac88aebc8a9054bb727137863b

## Producer Round 1 — Plan QA Submission

Please review `PROJECT/2-WORKING/GH-1552-KS08-KILLED-LANDING-RECOVERY.md` against issue #1541 (KS-08), `skills/1-hourly/kickstart/SKILL.md`, and `skills/2-daily/merge-cleanup/scripts/attempt_record.py`.

Key points:
- Zero new runner/wrapper; reuses `attempt_record.py` (`MERGE_CLEANUP_RECORD`, `finish --outcome aborted-*`, `MAX_REPAIRS=2`) and `merge_cleanup.py` (`--reconcile-pr N --execute`, `--resume --execute`).
- Fail-closed two-step precondition: (1) full stopped-ownership proof (owner, lock, builders/checks/push/sessions) + exact record & index lookup preserving repair count; (2) remote PR state check (`MERGED` -> `--reconcile-pr`, `OPEN` unchanged head -> `finish aborted-*` + `--resume`, changed/unknown -> hold).
- Disposable-clone paired red/green checks against real `attempt_record.py`.

If the plan is sound, set `STATUS: Approved` and `NEXT: Done`.

## Reviewer Round 1 — codex — Needs changes

Verdict: two blocking command-contract errors prevent the proposed recovery path from running. Keep STATUS Open; return to producer. Review is plan-only; no implementation or runtime qualification is claimed.

1. **[Must] Remove unsupported `finish --reason`.** Grounded Recon and Plan step 1 prescribe `attempt_record.py finish --index <idx> --outcome aborted-<cause> --reason "..."`. The CLI parser at `skills/2-daily/merge-cleanup/scripts/attempt_record.py:188-190` accepts only `--index` and `--outcome`; the Python `finish(..., **fields)` API does not expose `reason` through this CLI. The documented command therefore fails argument parsing before settling the stale attempt. Use the existing supported finish invocation and retain the reason through an existing supported record/note channel, or otherwise explicitly revise scope; do not assume API keywords are CLI options. Source check: `sed -n '120,205p' skills/2-daily/merge-cleanup/scripts/attempt_record.py` (exit 0), decisive output: `f.add_argument("--index", type=int, required=True)` and `f.add_argument("--outcome", required=True)`, followed immediately by the `note` parser. Make Control B exercise the exact published command.

2. **[Must] Preserve the vetted full-SHA PR selection in the resume invocation.** Plan step 1's `merge_cleanup.py --primary <LANDING_CLONE> --resume --execute` cannot execute: `merge_cleanup.py:2533-2538` refuses a merging run without `--prs`. Specify resuming the original authorized selection with its approved full-SHA pins and applicable original landing-policy arguments; unchanged remote head must match that approved pin as well as the interrupted attempt. Do not widen the selection during recovery. Source check: `sed -n '2525,2605p' skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (exit 0), decisive output: `if merging and not args.prs:` -> `REFUSING to execute: a merging run needs --prs N[,N...]` -> `return 2`. Control B must verify the actual supported resume command/selection, not infer success solely from repair_count remaining 1.

The stopped-ownership boundary, MERGED/reconcile versus OPEN/resume split, and repair-budget preservation otherwise match KS-08 in issue #1541 (read with `gh issue view 1541 --json body,title`, exit 0). Source-only/manual checks of instruction decisions must be labeled as such: attempt_record.py alone cannot prove detached check/session liveness or command selection. Planned disposable-clone controls remain unexecuted here: **[Unverified — needs clone run]**. No phase gate was configured in this relay, and none was run.

Graph limitation: list_projects returned no index for this relay worktree; nearest Forge index generation 2026-11-18T19:39:07Z is another checkout. Coverage reported no recorded gaps for the two Python paths, but current local source reads above are the authority for these findings.
