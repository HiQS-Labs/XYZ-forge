---
Goal: Merge-readiness QA of PR #519 (GH-516 express v2) at head df1a5cfb after conflict repair
Date: 2026-09-09
NEXT: Reviewer
STATUS: Open
---

# Context

PR #519 (`feat/gh516-express-v2`, "feat(express): v2 hotfix fast lane upgrade (GH-516)") was
CONFLICTING against `development`. The Producer repaired it in this disposable clone and pushed
head **df1a5cfb6890d89626089d10264926b2d12d49bc** (PR now MERGEABLE/CLEAN). You are the Reviewer;
the Producer (claude-a) will apply any fixes you request.

Repair summary you are adjudicating:

- Round 1 merged `origin/development` (b4966580, PR #520). Conflicts: `releases.db`, `releases.sql`,
  `LEADERBOARD.md` (`ROADMAP-DASHBOARD.md` auto-merged, then regenerated). Resolution: took
  development's `releases.sql` as base, rebuilt the DB via
  `utils/releases-merge-resolve.sh`, then re-applied the branch's GH-516 roadmap row through the CLI
  (`releases roadmap add` + `roadmap update --section "In progress"`). GH-424 differed only in
  `updated_at` (branch 03:22:31Z vs development 03:47:30Z); development's newer timestamp kept.
  Byte-level proof: all 151 development rows byte-present in the merged dump; the only branch rows
  not byte-present were GH-424 (timestamp-only) and GH-516 (re-applied, ratings 75/40/70/70 intact).
- Gate repair: the resolver's `releases.db.bak` was removed (it trips gh32's "a gate must never
  repair" assertion), and GH-518's capture doc — landed unparked by #520 — was parked via CLI
  (556076b6). A parallel session then landed 3b758c30 on development doing the same park (rated,
  via hq) — round 2 merged it, keeping **trunk's** rated GH-518 row and superseding the branch's
  transient unrated duplicate; the resolver's rewind guard set the base generation header 512->515.
  Final ledger: 153 rows, generation 518, `releases check` clean (0 failures, 8 pre-existing
  migration warnings).
- Gates: full `validate.sh` 359/359 on 556076b6 (one disclosed GH-528 parallel-flake, passed alone);
  `test/gh267-express-skill.sh` 75/0; pre-push gates GREEN on both pushes. Express code
  (`utils/py/express.py`, `skills/express/SKILL.md`, `test/gh267-express-skill.sh`) is byte-identical
  to the pre-repair PR head 30de5449 — the repair touched only the ledger/dashboards/PARKED docs.

Read, at minimum:
- `utils/py/express.py`
- `skills/express/SKILL.md`
- `test/gh267-express-skill.sh`
- `PROJECT/2-WORKING/GH-516-EXPRESS-TRUE-DIRECT-PUSH-PLAN.md` (the plan this implements)
- `releases.sql` (roadmap rows for GH-516 / GH-518 / GH-494 / GH-424) and
  `git log --oneline 30de5449..df1a5cfb` (the repair commits)

Questions:

1. Ledger integrity: does `git show df1a5cfb:releases.sql` contain any DROPPED row relative to its
   two merge parents (30de5449's GH-516 row content; b4966580/3b758c30's rows)? Check specifically
   that GH-516 carries ratings 75/40/70/70 with section "In progress", and that GH-518 is trunk's
   rated row (gid rmi-01M23J0C1AS9R1PS0BQW33TKXQ). Cite evidence.
2. `utils/py/express.py`: does the v2 implementation match the plan's §2.1–2.6 (cumulative diff,
   <=2 branch commits, `resume`, `--allow-multi-subsystem` + <=30-line/<=2-file micro-diff
   auto-allow, `--dry-run`, central telemetry mirroring in a try/except OSError)? Flag any
   fail-open behavior: a refusal that can be bypassed, or a push/merge path that can report success
   without verification (compare GH-510's discarded-result trap).
3. `skills/express/SKILL.md`: is the documented landing sequence (Tx1 push -> close issue ->
   reconcile -> Tx2 push) consistent with what `express.py` actually does? Cite mismatches.
4. `test/gh267-express-skill.sh`: do its assertions actually COVER the new direct-push mode (would
   they fail if `cmd_land` pushed to a non-development ref, skipped issue closure, or skipped
   reconciliation), or do they merely pass? Name one assertion you mutated mentally and say what
   would catch it.
5. Merge safety: any reason this PR must NOT squash-merge into `development` as-is? (Out of scope:
   PR #495, teardown of any clone.)

Record at the top of your verdict block: `REVIEWED-SHA: <output of git rev-parse HEAD>` — the merge
will only proceed if this equals df1a5cfb6890d89626089d10264926b2d12d49bc.

Write your verdict below and change the STATUS to Approved if it passes; otherwise list concrete
fixes and set STATUS: Changes Requested.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (agy)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
