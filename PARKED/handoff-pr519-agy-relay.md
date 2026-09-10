# Handoff prompt — PR #519 (GH-516 express v2): conflict repair, Agy relay QA, merge

Paste everything below the line into a fresh agent session.

---

You are taking over PR **#519** in the `XYZ-forge` repo (`HiQS-Labs/XYZ-forge`), branch
`feat/gh516-express-v2`, title "feat(express): v2 hotfix fast lane upgrade (GH-516)".
It is currently `mergeable: CONFLICTING` / `mergeStateStatus: DIRTY` against `development`.

Your job, in order: repair the conflict, run a `/relay-xyz` QA loop with **agy** as reviewer,
and merge only on the reviewer's approval. Do not merge on your own judgment.

## Startup

1. Read `ROUTER.md`, then `AGENTS.md`, then `PROJECT/2-WORKING/GH-516-EXPRESS-TRUE-DIRECT-PUSH-PLAN.md`.
2. Work in a **disposable full clone**, not in the primary checkout at
   `~/Documents/GH Repos/XYZ-forge`, and not in `~/Documents/GH Repos/XYZ-forge-gh516-express-v2`
   (that clone is the PR's source of record — leave it alone).
   Clone fresh into `~/marathon-clones/pr519-repair` and check out `feat/gh516-express-v2`.
   Reason this is mandatory: gate runs in the primary go RED because the Antigravity language
   server holds `.git` handles that the Gen4 oracle calls leak. A throwaway clone is the only
   place the gate result is trustworthy.

## Conflict repair — ledger data, not text

PR #519 touches these files:

```
LEADERBOARD.md
PROJECT/2-WORKING/GH-516-EXPRESS-TRUE-DIRECT-PUSH-PLAN.md
ROADMAP-DASHBOARD.md
TESTS-RESULTS/2026-09-08+GH-516/provenance.jsonl
relay-system/2026-09-08/gh516-express-plan-qa-agy.md
releases.db
releases.sql
skills/express/SKILL.md
test/gh267-express-skill.sh
utils/py/express.py
```

The conflicts are in the generated/ledger set: `releases.db`, `releases.sql`,
`ROADMAP-DASHBOARD.md`, `LEADERBOARD.md`.

**Never resolve these by taking one side.** In this repo the SQLite DB is roadmap truth;
`releases.sql` is its text dump and the two dashboards are rendered from it. Taking `--ours`
or `--theirs` on `releases.db` silently drops whatever roadmap rows the other side added.

Correct procedure:

1. `git fetch origin`, then rebase or merge onto `origin/development` — match whatever this
   branch's recent history already does.
2. On any `releases.db` / `releases.sql` conflict: take `origin/development`'s version of the
   ledger as the base, then **re-apply this branch's intended rows through the CLI**, not by
   editing SQL — `python3 utils/py/releases_app.py roadmap ...` / `add` / `update` as
   appropriate for the GH-516 entries.
3. Regenerate derived files rather than merging them by hand:
   `python3 utils/py/releases_app.py gen`, then `python3 utils/py/releases_app.py check`.
   `check` must pass clean — it verifies DB↔dump↔generated consistency, FK pragma, stale WAL,
   and receipt-vs-change bypass.
4. Renumber CHANGELOG entries only if this branch adds unpublished ones that now collide with
   entries landed on `development` since the fork. Never renumber published ones.
5. Run the gate in your disposable clone: `validate.sh`, plus the express skill test this PR
   modifies. Both must be green before you hand off to review.
6. Push the repaired head to `feat/gh516-express-v2`.

If a conflict is genuinely ambiguous — two sides assert different values for the same ledger
field and neither is derivable — stop and escalate that specific field to the operator. Do not
escalate merely because the PR says `CONFLICTING`, and do not retry the same failed repair
more than twice.

## Relay QA with agy

Once the branch is repaired, gated green, and pushed, run a `/relay-xyz` loop with **agy** as
the reviewer against the PR head:

- Invoke the `relay-xyz` skill. The harness lives in `relay-automation/` — `relay-drive.sh`
  is the supervisor and `agy-turn.sh` is the reviewer turn-taker.
- You are the Producer. agy is the Reviewer. The thread file lands under
  `relay-system/<date>/<slug>.md`.
- Note the frozen-Bash warning at the top of `relay-drive.sh`: Python is authoritative
  (`utils/py/relay_drive.py`, reachable via `XYZ_PYTHON=1`). Prefer the Python path.
- Scope the review to: the conflict resolution itself (did any ledger row get dropped?),
  `utils/py/express.py`, `skills/express/SKILL.md`, and whether the express skill test actually
  covers the new direct-push mode rather than just passing.
- Apply agy's fixes yourself as the Producer, re-gate, and take another round. Respect the
  harness's round cap; if it exhausts without approval, stop and report — do not merge.

**Known integrity caveat, relevant to exactly this task:** GH-505 / GH-509 record that a
builder can currently approve and close its own relay, and that merge is not bound to the
reviewed head SHA. So before merging, verify by hand that the thread's `STATUS: Approved`
block was written by the **agy** turn and not by your own, and that the SHA you merge is the
SHA agy reviewed. Say so explicitly in your report.

## Merge

Only after agy has approved and you have verified the two integrity checks above:

```
gh pr merge 519 --squash --delete-branch
```

Then, in the primary checkout:

```
git fetch origin && git merge --ff-only origin/development
python3 utils/py/wave_reconcile.py --pr 519
python3 utils/py/releases_app.py gen && python3 utils/py/releases_app.py check
bash utils/pdda/pdda.sh issue-doc-sync
```

Commit any ledger/dashboard regeneration that reconciliation produces.

**Known trap, do not report success without checking:** GH-510 records that the jog merge path
discards the `gh pr merge` result and reports `completed` even on a refused merge. Whatever path
you use, re-query `gh pr view 519 --json state,mergedAt` afterwards and confirm it actually says
`MERGED`. A merge you did not verify is not a merge.

## Out of scope

- PR **#495** (`marathon/gh-490-prep`) is being handled separately and last. It collides with
  #519 on `ROADMAP-DASHBOARD.md`. Do not touch it, do not rebase it, do not merge it.
- PR **#520** is landing ahead of you. If it has already landed when you start, your rebase
  picks it up normally; no action needed either way.
- Do not delete or tear down any clone. Eight clones currently hold unpushed work; teardown is
  a separate pass.

## Report back

One paragraph: what the conflict actually was, which ledger rows you re-applied and how you
verified none were lost, the gate result, agy's verdict plus the two integrity checks, and the
verified post-merge state of #519.
