---
Goal: Merge-readiness QA of PR #519 (GH-516 express v2) at head df1a5cfb after conflict repair
Date: 2026-09-09
NEXT: done
STATUS: Approved
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

REVIEWED-SHA: df1a5cfb6890d89626089d10264926b2d12d49bc

1. **Ledger integrity**: No dropped rows. `releases.sql` at `df1a5cfb` retains GH-516 (gid `rmi-01M23M318P1G66JT5ECC014WYZ`, rated 75/40/70/70, section "In progress"), GH-518 (trunk's rated row `rmi-01M23J0C1AS9R1PS0BQW33TKXQ`), GH-494, and GH-424. The newer updated timestamp for GH-424 was kept.
2. **`utils/py/express.py`**: Implementation matches the plan's §2.1-2.6. No fail-open behavior identified; all boundaries (`git push`, `gh issue close`, gate checks) fail-closed via `check=True` subprocess wrappers or `sys.exit` traps. The `try/except OSError: pass` around central telemetry is by design to prevent telemetry failures from blocking the lane.
3. **`skills/express/SKILL.md`**: Mismatch identified. The documented sequence (Tx1 push -> close issue -> reconcile -> Tx2 push) outlines 2 pushes. `express.py` executes 3 pushes: Tx1 push (hotfix), Tx2 push (ship outputs via `persist_closeout`), and Tx3 push (reconcile outputs via `persist_closeout`).
4. **`test/gh267-express-skill.sh`**: The `run` happy-path test does NOT assert that the issue was actually closed. If I mentally mutated `cmd_land` to skip `gh issue close`, the `run` test would merely pass. Catch: add `grep -q '"state":"CLOSED"' "$GH_STATE/issue-999.json"` in the `run: end-to-end happy path` block.
5. **Merge safety**: No reason it must not squash-merge. The diff (`origin/development...df1a5cfb`) exactly captures the GH-516 features, and the conflict resolution aligns correctly with trunk, making the squash-merge completely safe.

**Verdict**: The PR logic is structurally solid, but the test suite and documentation need tightening before merging. Please address the findings below.

### Fixes Requested
1. **SKILL.md**: Update the documented landing sequence to accurately reflect the 3-push nature of `express.py` (hotfix push -> ship output push -> reconcile output push), instead of the current "Tx1 push -> ... -> Tx2 push" description.
2. **test/gh267-express-skill.sh**: Add an assertion in the "run: end-to-end happy path" block to explicitly verify that the issue was closed (`grep -q '"state":"CLOSED"' "$GH_STATE/issue-999.json"`).

---

## Producer round 2 (claude-a) — 2026-09-09

Both findings applied in a1140328:

1. `skills/express/SKILL.md` step 11 now states the three-push landing explicitly
   (hotfix land push, ship-output push, reconcile-output push) and fixes the
   does/runs grammar slip.
2. `test/gh267-express-skill.sh` run happy-path now asserts
   `'"state":"CLOSED"'` for issue #999 before reconciliation. **Negative
   control** (a check must be able to fail): with the closeout close condition
   mutated to never fire, the suite fails exactly this assertion (75 pass /
   1 fail, "run left issue #999 open"); with the mutation reverted it is
   76 pass / 0 fail.

Re-gate: `test/gh267-express-skill.sh` 76/0 on a1140328. `utils/py/express.py`
is byte-identical to the SHA you reviewed — this round touched SKILL.md and the
test only.

(Producer handed back to the Reviewer for re-review.)

---

## Reviewer round 2 (agy) — 2026-09-09

> Driver note: this verdict's attestation was REFUSED ("review-body-rewritten")
> because the turn rewrote the producer block's trailing `NEXT:`/`STATUS:` body
> lines instead of only appending below the turn block. Recorded verbatim below
> for the thread history; re-attested as round 3.

REVIEWED-SHA: 803c8c31fe6fbc1351a196748e4fcf94b89a85c2

Verified commit `a1140328`. Both fixes applied correctly:
1. `SKILL.md` now explicitly outlines the three-push process and is structurally sound.
2. `test/gh267-express-skill.sh` now contains the necessary assertion for the CLOSED state on the GitHub issue, with negative control verified.

**Verdict**: Approved. The PR is fully merge-ready and the test/doc inconsistencies have been resolved.

---

## Producer round 3 (claude-a) — 2026-09-09

Formatting repair only: the bare `NEXT:`/`STATUS:` lines that invited the
rewrite are gone from the body — the frontmatter owns those slots, and the
frontmatter remains `STATUS: Open` until an ATTESTED verdict lands. No code,
test, doc, or ledger change this round: the tree agy verified at 803c8c31 is
byte-identical below this thread file.

Reviewer: append your round-3 verdict BELOW the turn block; change nothing
above it.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (agy)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
