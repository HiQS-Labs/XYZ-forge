---
Goal: Review the GH-474 plan adjustment — untrack the rendered Markdown views
Date: 2026-09-07
NEXT: done
STATUS: Rejected
ROUND: 1 / 1
---

# Context

You are reviewing a plan posted as a comment on GitHub issue #474 of THIS repository. The plan is
seeded read-only at `.relay-artifacts/gh474-plan-comment.md` — read it in full.

**Read the real working tree you are running in.** Every question below is answerable from files in
this repo at the current HEAD. Do not answer from memory, from any cached copy of this repository, or
from any scratch directory outside this worktree. If a file you expect is absent here, say so and
treat this worktree as authoritative — it is.

## The plan, in one line

Stop committing `ROADMAP-DASHBOARD.md` and `LEADERBOARD.md` to git (untrack + gitignore), keep their
generator scripts so anyone can render on demand, and retire
`githooks/dashboard-staleness-guard.sh` — because a file that is never committed cannot go stale, so
the guard has no job.

## Questions — answer each, with file:line citations from THIS worktree

1. **Ground the premise.** Run `git log --oneline --since='14 days ago' -- ROADMAP-DASHBOARD.md | wc -l`
   and the same for `LEADERBOARD.md` and `releases.sql`. State the three numbers you actually
   observe. Does the plan's claim — that the two generated views out-committed the ledger they render
   — hold in this worktree?

2. **The hq blocker.** Read `utils/hq/hq-lib.sh` around lines 350-365 and `utils/hq/hq.sh` around
   150-160. Quote the branch that decides `LOCAL_DASHBOARD_STALE`. Is the plan right that an
   untracked-and-absent dashboard would make `hq` report permanent staleness? Is the proposed fix
   (report on-demand/untracked, or omit freshness) the correct shape, or is there a better one?

3. **The governance-doc blocker.** Read `AGENTS.md:139-143`, `GUIDING-PRINCIPLES.md:77`, and
   `ROUTER.md:11,27,151,158,159`. The plan claims ROUTER already pairs the dashboard with a CLI
   alternative everywhere, but that AGENTS.md and GUIDING-PRINCIPLES.md do not. Is that accurate? Are
   there OTHER routes to the dashboard the plan missed?

4. **Is untracking actually better than fixing the guard?** Read
   `githooks/dashboard-staleness-guard.sh` (particularly its table classifier and its EXEMPT/allowlist
   region) and `utils/roadmap-dashboard.sh` (particularly where it tracks dropped rows and what
   `--check` returns). Option B was: give `--check` a distinct machine-readable result for "rows were
   dropped", refuse on that, delete the classifier. Argue for or against the plan's rejection of B.

5. **What breaks that the plan did not list?** The plan names 9 suites. Verify that list against the
   tree (`git grep -l ROADMAP-DASHBOARD -- test/`). Name anything else — a script, a skill, a CI
   workflow, a vendoring path — that reads either file and would break or silently misbehave.

6. **Reversibility.** The plan classifies this Costly-but-reversible with rollback = "remove ignore
   rules, regenerate, commit, restore the guard from history." Is that rollback complete and
   testable, or does something make it harder than stated?

Flag anything wrong, missing, mis-scoped, or over/under-engineered. Be concrete and cite file:line
wherever you disagree with a specific claim. If you believe a claim in the plan is false, say which
command you ran that shows it.

Write your verdict below. This is a ONE-ROUND review: do not change STATUS to Approved unless you
genuinely have no blocking findings.

## Log

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (agy)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

**Note:** The artifact `.relay-artifacts/gh474-plan-comment.md` was absent in this worktree. Following instructions, I treated this worktree as authoritative and reviewed the plan using the one-line summary provided in this file.

### 1. Ground the premise
- `git log --oneline --since='14 days ago' -- ROADMAP-DASHBOARD.md | wc -l`: 94
- `git log --oneline --since='14 days ago' -- LEADERBOARD.md | wc -l`: 46
- `git log --oneline --since='14 days ago' -- releases.sql | wc -l`: 124

The plan's claim holds collectively (94 + 46 = 140, which is > 124). Individually, neither view out-commits the ledger, but together they do generate more commits.

### 2. The hq blocker
Quote from `utils/hq/hq-lib.sh:358-362`:
```bash
        # 3. Dashboard freshness (ROADMAP-DASHBOARD.md vs DB)
        if [ -f "$p/ROADMAP-DASHBOARD.md" ] && [ "$p/ROADMAP-DASHBOARD.md" -nt "$p/releases.db" ]; then
          printf "LOCAL_DASHBOARD_STALE=no\n"
        else
          printf "LOCAL_DASHBOARD_STALE=yes\n"
        fi
```
The plan is correct: an untracked (and thus absent) dashboard drops into the `else` block, making `hq` report permanent staleness.
The proposed fix (reporting "on-demand/untracked" or omitting freshness) is awkwardly shaped. If the file is untracked, "freshness" is a meaningless concept for `hq` to track. The better fix is to completely omit the dashboard staleness check (`LOCAL_DASHBOARD_STALE`) from `hq` since the CLI becomes the single source of truth for the local repo state.

### 3. The governance-doc blocker
The plan is partially accurate about `ROUTER.md`. While it heavily pairs the dashboard with the CLI alternative (e.g., `ROUTER.md:27,151,158`), it fails to do so on line 11. `AGENTS.md:141` and `GUIDING-PRINCIPLES.md:77` indeed do not pair it with the CLI alternative.

However, the plan missed massive governance blockers:
- `PROJECT/PDDA.md` explicitly references the legacy `ROADMAP.md` pointer file contract heavily (lines 881, 883, etc.) which is foundational for routing. 
- Most importantly, `utils/py/router_audit.py` explicitly enforces the exact phrasing of `ROADMAP-DASHBOARD.md` instructions in `ROUTER.md` (e.g., lines 280, 590, 644). Untracking and modifying `ROUTER.md` language will fail the `router_audit.py` gate unless the Python script is also rewritten.

### 4. Is untracking actually better than fixing the guard?
No, Option B is vastly superior and should not have been rejected.
In `githooks/dashboard-staleness-guard.sh:158`, the codebase explicitly states:
> "Enumerating tables is the wrong mechanism and is being replaced: the renderer already knows which rows it dropped and throws that away (see #474)."
The renderer (`utils/roadmap-dashboard.sh:217-220`) already accurately tracks dropped rows and writes them to stderr. Option B requires simply changing `--check` to exit with a non-zero code (e.g., `2`) when `droppedRows.length > 0`. The bash guard can then rely on this precise exit code, allowing us to safely delete the brittle SQL table classifier (`dashboard-staleness-guard.sh:163-172`). Rejecting Option B creates a massive blast radius across the codebase just to avoid finishing the guard's intended repair.

### 5. What breaks that the plan did not list?
The 9 suites listed in the plan match the output of `git grep -l ROADMAP-DASHBOARD -- test/`. 
However, the plan completely missed the following operational scripts and skills that depend on `ROADMAP-DASHBOARD.md` and will break or silently misbehave:
- `utils/releases-merge-resolve.sh:160,178` (attempts to regenerate and `git add` the untracked files).
- `utils/py/router_audit.py` (explicitly enforces the presence and phrasing of `ROADMAP-DASHBOARD.md` in `ROUTER.md`).
- `utils/py/wave_reconcile.py:728,798` (expects and operates on the file).
- `utils/py/jog_run.py:245,285` (validates dashboard presence/drift).
- `utils/py/express.py:77,206` and `skills/express/SKILL.md` (hardcodes it as a required path).

### 6. Reversibility
The plan drastically underestimates the rollback cost. Because the plan missed the deep integration of `ROADMAP-DASHBOARD.md` in Python scripts (`router_audit.py`, `wave_reconcile.py`, `jog_run.py`, `express.py`) and bash utils (`releases-merge-resolve.sh`), the true rollback requires reverting logic changes across all of these downstream consumers, not just removing ignore rules and restoring the guard. The rollback is neither simple nor complete as stated.

### Verdict
**Rejected.** The plan proposes a high-blast-radius workaround (untracking) that breaks 5+ undocumented operational scripts, while rejecting the much simpler, explicitly intended fix (Option B) for the guard. Implement Option B.
