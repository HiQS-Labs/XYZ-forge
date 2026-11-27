# /merge-cleanup without the XYZ-forge overlay (standalone mode and a prose runbook)

This page is linked from [`SKILL.md`](SKILL.md). It is for a repository that has **not** installed the XYZ-forge harness overlay (no `githooks/install.sh`, no RELEASES ledger, no `utils/py/wave_reconcile.py`, no `pdda.sh`). It has three parts, in priority order:

1. **Sequencing** works with only `git` and `gh`: the merge order and the landing forecast for a large queue.
2. **Landing** works in an explicit standalone mode (`--standalone`).
3. **A prose runbook** for an agent when the scripts cannot run at all (no Python, or the scripts are not installed): the same ordering rules and a safe landing loop, done by hand.

The default mode (no `--standalone`) is the Forge-overlay mode and is unchanged. Read [what each mode needs](#what-each-mode-needs) first.

## What each mode needs

| | Default (Forge overlay) mode | `--standalone` |
|---|---|---|
| Declared how | nothing | the flag, every run. It is **never inferred** from a missing file (GH-1576): without it, a landing clone with no `githooks/install.sh` still refuses. |
| Repo must have | `githooks/install.sh` (the pre-push gate), the RELEASES ledger (`releases.sql` at HEAD, `utils/py/releases_app.py`), `utils/py/wave_reconcile.py`, `utils/pdda/pdda.sh` | none of those. The flag is **refused** if the primary carries any overlay marker (`releases.sql`, `releases.db`, `utils/py/releases_app.py`, `.xyz/utils/py/releases_app.py`, `utils/py/wave_reconcile.py`): use the default mode for a partial overlay. |
| Integration branch | `development` only. `wave_reconcile.py` (post-merge) defaults to `development`, filters its PR flows on a literal `development`, and merge-cleanup forwards no branch to it, so `--integration-branch main` merges and then stops at reconcile. | any branch (`--integration-branch main`). |
| Pre-merge ledger gate, post-merge `wave_reconcile`, `releases_app check`, `pdda.sh`, Jog | run | skipped, and logged as skipped |
| A conflicting landing | B1 may repair a disjoint ledger/changelog conflict, then pushes the repaired head through the clone's gate hook | **hands off**: the PR is named with its conflicting paths, the queue continues, the run exits 3. There is no automatic repair. |
| `.tick/` records (`selection-*.json`, batch records) | written under `<primary>/.tick/`, which the Forge `.gitignore` hides | the primary's own `.git/info/exclude` gets `/.tick/` once (local, untracked) so the primary stays clean; nothing is written if `.tick/` is already ignored |
| Default scan roots (teardown candidates) | four fixed roots, not origin-filtered, plus the primary's parent folder (origin-filtered) | the primary's parent folder only, origin-filtered. The fixed roots are not scanned. `--root` is still the operator's explicit choice; `--prefix` still narrows by name. |
| Pushes | gated by the clone's pre-push hook; refused without a proven hook | the same code: **refused without a proven hook**. A clean standalone queue makes no push. Never `--no-verify`. |

## Prerequisites

- Python 3.9 or newer, `git` 2.38 or newer (`git merge-tree --write-tree`), `gh` 2.18 or newer and authenticated for the repository, an `origin` remote, and `lsof` (the teardown scan; without it checkouts are preserved, not removed).
- A **gate hook** matters only if a push is to be made. Standalone landing makes none on a clean queue. If the repo ships its own `githooks/install.sh`, merge-cleanup runs it in each landing clone as in the default mode.
- The `--standalone` dry run prints a **STANDALONE PREREQUISITES** block first, before the primary is inspected and before any clone is made (the forecast clone and the landing clones come later). Each unmet item is named there, for example `[UNMET] git >= 2.38: git version 2.30.0 is below the required 2.38.0 minimum ...`. `--execute` refuses (exit 2) on an unmet Python, `gh` or `origin`; an old `git` only withholds the forecast.

## Part 1 and 2: the scripts, standalone

```bash
S=<installed skill>/scripts/merge_cleanup.py     # copied skill folder; the scripts are standard-library only
python3 $S --primary "$PRIMARY" --integration-branch main --standalone --prs-only    # sequence only: no clone
python3 $S --primary "$PRIMARY" --integration-branch main --standalone --prs 12,14,15,19   # dry run: pins heads, forecast for 3+
python3 $S --primary "$PRIMARY" --integration-branch main --standalone --prs 12@<sha>,14@<sha> \
    --landing-plan direct --landing-reason "<why>" --execute                         # lands them, in order
```

- `--prs-only` lists **every** open PR in order and makes no clone. A dry run with `--prs` also simulates each listed landing in disposable clones (each **alone** against the current base: it merges nothing, so two PRs that conflict only with each other both read "Would merge"; the forecast's pair and fold lines show those), prints the **Landing forecast** for 3 or more, and pins the heads. `--execute` lands only the pinned PRs, at those heads, and exits 5 for 3 or more PRs until `--landing-plan direct|group` and a reason are given. The exit codes are the default mode's: 2 a stop, 3 something did not land (read the list), 4 landed with the sweep verdict pending (record it with `--record-sweep`), 5 a landing decision is required.
- Declare the repo's sweep cadence in a committed `.merge-cleanup.json` (`qualification`: `none`, `per_batch` with a `sweep_command`, or `promotion`) as in SKILL.md; without it a batch of 2 or more PRs exits 4 until a verdict is recorded.
- The batch issue (2 or more PRs) is opened in **your** repository through `gh`; say so if that is not wanted.
- `--teardown-only` and Phase 6 work as in SKILL.md. Review the Phase 1-3 table before an `--execute`; pass `--prefix <name>` (a substring unique to the clones you mean) to keep removal to those.

### How to read the output

| You see | Meaning |
|---|---|
| table row `Draft yes` and, with `--execute`/dry run, `SKIPPED (draft)` then `Skipped draft PR(s)` | not landed; hard dependents wait. A draft in `--prs` is refused at pin time (rc 2): drop it. |
| `carries hold label` / `Skipped held PR(s)` | a label containing `hold`, `do not merge`, `do-not-merge`, `blocked` or `wip`, or such a word in the title |
| `Checks FAIL` in the table; `[DRY RUN] ... required checks failing` | the dry run only reports it; `--execute` does not merge it and its hard dependents are `NOT attempted` |
| `NOT attempted — depends on #N (...)` | a hard dependency did not land (or is pending in a cycle) |
| `Cycle or unresolved dependency detected among PRs: [...]` under Ordering Notes | those PRs are appended in numeric order; each is then `NOT attempted` because its dependency is not landed. Break the cycle by editing a `Depends on` line. |
| `landing merge conflicts ... HANDOFF` with the conflict set | standalone has no repair; resolve it on the PR branch (see the runbook, conflict handling), then re-run the dry run to re-pin |
| `N PR(s) did not land (...)` and exit 3 | the closing summary of everything not landed, with each reason |

## Part 3: the prose runbook (an agent, no scripts)

Use this when Python or the scripts are unavailable. It does by hand what the scripts do; the order it produces is the same. Do not invent rules: where the script and this page differ, the script wins and this page is wrong.

**Ground rules (every step).** Never force-push, never delete a branch, never `--no-verify`, never edit someone else's PR branch unless the operator authorized that PR. Work in your own disposable clones, not in the operator's primary. Re-read a PR's live state immediately before acting on it. Stop and report at the first state you cannot establish; unknown is not a pass.

### 0. Preconditions

1. The primary checkout is on the integration branch (`<B>`), clean (`git status --porcelain` empty), and not behind or ahead of `origin/<B>` (`git fetch origin <B>` then `git merge-base --is-ancestor HEAD origin/<B>` and no local-only commits). If not, stop and report.
2. Get the PR list the operator authorized. Anything else open is listed, never landed.

### 1. Inventory

```bash
gh pr list --state open --limit 1000 --json number,title,headRefName,headRefOid,baseRefName,isDraft,labels,mergeable,statusCheckRollup,body,files,createdAt,url > prs.json
```

A listing that fails is an error, not an empty queue. `files` can be cut off for a very large PR (the listing returns a bounded number of files): for any PR showing exactly 100, read `gh api repos/{owner}/{repo}/pulls/<N>/files --paginate --jq '.[].filename'`. Record, per PR: number, head SHA, base branch, draft, labels, checks, mergeable, created time, files, body.

### 2. Classify each PR (nothing is dropped; each gets a reason)

| Class | Test | Treatment |
|---|---|---|
| draft | `isDraft` | skipped; hard dependents wait |
| held | a label whose lowercase name contains `hold`, `do not merge`, `do-not-merge`, `blocked` or `wip`; or a title word `hold`, `wip`, `dnm`, `blocked`, `do not merge`, `no merge` | skipped; hard dependents wait |
| wrong base | `baseRefName` is neither `<B>` nor another open PR's head branch | stop: it does not land on the branch you verified |
| conflicting | `mergeable` is `CONFLICTING` | not landed; hand off (step 8) |
| checks | `gh pr checks <N> --required --json name,bucket`: `fail`/`cancel` is failing, `pending` is pending, `pass`/`skipping` is ok, and `no required checks reported` is none | failing: not landed, dependents wait. pending: wait (bounded), then defer. unreadable: defer |
| mergeable unknown | `UNKNOWN` | re-read every 15 s up to 6 times; still unknown: stop, never guess |

### 3. Dependencies (edges that decide eligibility)

A **hard edge** `A -> B` means B waits for A and is never attempted if A did not land:

- the PR title or body says `depends on`, `blocked by`, `after`, `requires` or `prerequisite` followed by `#N` or a pull-request URL (case-insensitive), or `part of wave after #N`, and #N is an **open** PR in this inventory (a merged, closed or external number is ignored);
- **stacked base:** B's `baseRefName` equals A's `headRefName` for another open PR A. B cannot land on `<B>` until A has, because it targets A's branch.

### 4. File-overlap matrix (edges that decide sequence only)

Build each PR's file set. For every pair that shares a file and has **no** hard edge between them, add a **soft edge**: the older PR (`createdAt`) lands first. Skip a soft edge that would close a cycle with the edges already present, and say so. A soft edge never blocks: if the older PR did not land, the newer one is still attempted and its own landing check decides.

How to read the matrix: a PR with many overlaps is a candidate **conflict hub**; two PRs that overlap on the same lines will conflict when the second lands; overlap on the same file in different regions usually merges cleanly. Overlap is a prediction; step 6 measures it.

### 5. The order

1. Take every PR that has no unmet incoming edge (hard or soft). Among those, take the **lowest number** first.
2. Repeat after removing it, until none remain.
3. If PRs remain, they are in a **cycle** (or wait on one). Append them in ascending number order, report the cycle by number, and treat each as `NOT attempted` until its hard dependency lands. Never break a cycle by guessing; ask the author or the operator to edit a `Depends on` line.

Present the result as a table: sequence, PR, title, head SHA, base, draft/hold/checks/mergeable, files, and the reason for every edge ("hard: depends on #109", "stacked on #106", "soft: both touch src/core.py, #102 older"). List the skipped and blocked PRs with their reason. A table that omits a PR is wrong.

### 6. Forecast the landings (needs `git` 2.38+, no checkout, no push)

```bash
git clone --quiet --no-checkout "$ORIGIN" f && cd f
git fetch --quiet origin <B> && BASE=$(git rev-parse origin/<B>)
for N in <listed>; do git fetch --quiet origin +pull/$N/head:refs/forecast/$N; done   # each head must equal the SHA you recorded
git merge-tree --write-tree --name-only --no-messages $BASE refs/forecast/<N>          # alone: exit 0 clean, 1 conflict (paths follow the tree id), other = did not run
git merge-tree --write-tree --name-only --no-messages refs/forecast/<A> refs/forecast/<B>   # every pair
```

- **Cumulative fold** in the step 5 order: start at `$BASE`; for each PR run `git merge-tree --write-tree --name-only --no-messages <CUR> <PR>`; on exit 0 advance with `CUR=$(git -c user.name=fold -c user.email=fold@local commit-tree <tree> -p <CUR> -p <PR> -m fold)`; at the first exit 1 stop and mark every later PR "not simulated after #X".
- **Conflict hubs.** Set aside every PR that conflicts alone with `$BASE`. Then, while any two remaining PRs conflict with each other, set aside the one with the most pairwise conflicts (ties: the later one in the order). Anything that hard-depends on a set-aside PR is set aside too. The rest is the **clean set**; fold it again. The greedy choice is a heuristic, not a proven minimum.
- **Recommendation (the script's rule).** No conflicts: `direct`, one by one. Any conflict on a path the tool cannot repair (in standalone mode that is **every** path, there being no B1): `group`, one reviewed combined resolution (GH-1066). If any step could not run: **no** recommendation, never a guess. The script's `direct in passes` needs repairable paths, so it does not arise here.
- **A reasoned alternative you may state.** When the hubs are few (at most half the queue) and the clean set folds clean, you may land the clean set first and hand each hub to its author, giving that as your own landing reason. It is your decision and your reason, not the script's recommendation.
- **Blind spots to state:** merge-tree is text-level; reconcile commits and later pushes move the base; a stacked child can read `CONFLICTING` after its base was squash-merged even though merge-tree is clean (merge `<B>` into the child branch: that is a new head and fresh checks).

Without git 2.38, `merge-tree --write-tree` does not exist: use `git merge --no-commit --no-ff` in a throwaway clone per PR (then `git merge --abort`) and say that the pair and fold simulations were not run.

### 7. The landing loop (one PR at a time; re-check after each)

For each PR in order, **re-read it live first** (`gh pr view <N> --json state,isDraft,mergeable,headRefOid,baseRefName,labels,mergeCommit,title`):

1. Not `OPEN`, now a draft, now held, or `baseRefName != <B>`: skip it, record why, and treat it as not landed for its hard dependents. (A stacked child's base becomes `<B>` once the operator or you retarget it with `gh pr edit <N> --base <B>`; retarget a child **before** merging its base PR, never after, and only for PRs in the authorized queue.)
2. Head moved from the SHA you recorded: do not merge it; re-do the forecast for the queue and re-confirm.
3. Re-simulate against the base **now** (`git fetch origin <B>`, then step 6's "alone" command at the new tip). Conflict: hand off (step 8) and continue with the PRs that do not depend on it.
4. Checks per step 2. Then `gh pr merge <N> --squash --match-head-commit <recorded sha>` (use `--merge` or `--rebase` if the project's policy file says so; never choose by guess).
5. Verify the **remote** says `MERGED` with a merge commit (`gh pr view <N> --json state,mergeCommit`); a zero exit is not a landing.
6. In the primary: `git fetch origin <B>` then `git merge --ff-only origin/<B>`; confirm `git status --porcelain` is empty and `HEAD == origin/<B>`. If the fast-forward fails, stop and report: the PR is merged remotely but the primary did not advance.
7. **Re-check the rest of the queue:** the base moved, so every remaining PR's mergeable state and its overlaps may have changed. Re-read the next PR's live state (it can read `UNKNOWN` for a few seconds), and if a landing touched a file another queued PR touches, re-run that pair's forecast before proceeding.

### 8. Conflicts and failing PRs: no force-push, no branch deletion

- **Report and hand off by default.** Name the PR, the conflicting paths (from the merge-tree output), the PRs it conflicts with, and who could resolve it. Continue with the PRs that do not depend on it.
- Resolve a conflict yourself **only if the operator authorized that PR**. Do it in a disposable full clone: `git checkout --detach <pr head>`, `git merge origin/<B>`, resolve, commit, and push the result to the PR branch with a plain `git push` through the project's pre-push hook, never `--force` and never `--no-verify`. If the clone has no installed gate hook, the push is **refused**: report that instead of pushing. A new head needs fresh checks and a fresh forecast; treat it as a new PR in the queue.
- Never delete a PR branch, a stacked parent's branch, or an unmerged clone; never rewrite history on the integration branch. A failing-checks PR is not merged and not "fixed" by you unless the operator asks.

### 9. Stop conditions

Stop (and report) when: the primary is not ready; a listing or a live read fails and is not a clear network blip; a PR's mergeable state stays `UNKNOWN`; a PR targets a branch you did not verify; the fast-forward fails; two runs of the same landing disagree; the operator's authorized list is exhausted; or any step needs an override the operator did not give. A network blip may be retried twice with a short wait; anything else is a stop.

### 10. What to report

One table: every PR in the inventory with its final state: **landed** (merge commit), **not landed** with the reason (draft, held, failing checks, conflict with paths, blocked by #N, cycle, head moved, deferred), and what you did not attempt. Then: the order you used and why (edges), the forecast and its blind spots, the primary's final state (`HEAD == origin/<B>`, clean), and what the operator must decide (a hub to resolve, a cycle to break, a stack to retarget).

### What only the scripts do

The scripts add what a hand run cannot do reliably: the `--prs` pin file that refuses a moved head (GH-1226), the durable per-PR repair record and its two-repair ceiling, the lock around those records, the batch issue and its sweep record, polling and bounded retry with defer, `gh pr merge --match-head-commit` on the pinned SHA, the safe-teardown inspection (dirty, stash, unlanded refs, live sessions, open handles) and Trash-only removal, and the forecast's cumulative fold and hub selection done for every pair. **Do not tear down or delete clones by hand**; report them for the scripts or the operator. Where you cannot run them, say plainly which of these you skipped.
