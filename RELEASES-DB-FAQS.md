---
title: RELEASES DB FAQs — why a committed SQLite ledger still merges, and what triggers what
status: Reference
created: 2026-08-19
updated: 2026-08-19
owner: noelsaw
doc_type: architecture
summary: Answers the recurring questions about the GH-32 SQLite RELEASES ledger — why git can merge it without a SQLite-diffing library, which artifact is authoritative where, what fires each transform (and what does not), and how the git-boundary gaps (#52/#53/#54) were closed.
verified_against:
  - utils/py/releases_app.py
  - test/gh32-releases-app.sh
  - test/gh32-releases-artifacts.sh
  - test/gh53-releases-merge-resolve.sh
  - test/gh54-merged-dump-refusals.sh
  - utils/releases-merge-resolve.sh
  - releases.sql
  - .gitattributes
  - validate.sh
  - .git/hooks/
---

# RELEASES DB FAQs

Written 2026-08-19 after answering these from scratch. Everything below was checked against the code
rather than taken from the PRD, and the citations are there so the next reader can re-check rather
than re-derive. Where this file and
[PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md](PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md) disagree,
**the PRD wins** — that is the rule `releases_app.py` states about itself, and it applies here too.

---

## Q: Git can't merge binary SQLite files. Do we need `git-sqlite` or something like it to compute the transitions?

**No.** The DB was never meant to be the merge artifact.

The authority is split deliberately
([releases_app.py:8-13](utils/py/releases_app.py#L8-L13)):

| Artifact | Authoritative for |
|---|---|
| `releases.db` | reads and writes **at runtime** |
| `releases.sql` | **git merge boundaries only** |

Every CLI write regenerates the dump inside the same transaction as the DB write, so the two never
drift outside a crash. At a merge you resolve the **text**, then rebuild the binary from it:
`releases check --rebuild` does dump → DB atomically, keeping a `.bak` of the displaced DB.

`--rebuild` is for **merge resolution only, never crash recovery.** Crash recovery is a different
mechanism (see below) and conflating them will destroy evidence.

## Q: Why does a plain text merge work? Concurrent inserts usually collide on primary keys.

Because the schema was designed so they can't. The dump says so in its own header:

```
-- releases-app canonical dump (GH-32 grammar: GID-keyed rows, natural keys elsewhere,
-- no integer PKs/FKs as values; rebuild renumbers deterministically)
```

Two properties do the work:

1. **Rows are keyed by ULID global IDs**, not by a shared autoincrement counter. Two branches
   inserting at the same moment generate non-colliding keys with no coordination.
2. **No integer primary or foreign key ever appears as a value.** Relationships are carried by GID or
   natural key, so nothing in the text refers to a rowid that rebuild is free to reassign.

Together those make the union of two dumps a semantically valid merge — no renumbering, no diffing,
no transaction replay. Rebuild assigns fresh integer rowids deterministically on the way in.

That is exactly the property SQLite-diffing tools have to synthesize after the fact. Here it was
designed in from the start, which is why this is a text-merge problem and not a database problem.

## Q: What's the actual merge procedure?

It is tested end-to-end in section J of
[test/gh32-releases-app.sh:300-322](test/gh32-releases-app.sh#L300-L322) — two divergent clones each
import a different 2-release ledger, the dumps are merged, and the test asserts all four releases
survive with both import runs intact.

The resolution step:

```bash
{ grep '^-- generation' "$A/releases.sql"
  grep -vh '^-- generation' "$A/releases.sql" "$B/releases.sql" | awk '!seen[$0]++'
} > merged.sql
```

Keep **one** generation header, union the remaining lines, dedupe. Then:

```bash
python3 utils/py/releases_app.py check --rebuild   # dump -> DB, atomic, .bak of the old DB
python3 utils/py/releases_app.py check             # must print "check: clean"
```

Or, since 2026-08-19, one command that does all of it and refuses what it cannot settle:

```bash
utils/releases-merge-resolve.sh
```

### Do not use `merge=union` — and not for the reason you'd guess

Git ships a built-in `union` merge driver that keeps both sides' lines. It looks like precisely the
right tool. **Measured 2026-08-19 against real two-branch merges**, here is what it actually does:

| Case | Result |
|---|---|
| both branches made the **same number** of writes | merges **cleanly**. One generation header, both sides' rows present, and the `settings` table **not** duplicated — 3 rows, the same as a single-side dump. Both sides emit byte-identical `-- generation: 2` and `settings` lines, so there is nothing to conflict and nothing to double. |
| branches made **different numbers** of writes | **two** generation headers **and** a duplicated `settings` row (4 rows) — silently, with no conflict markers |

Unequal write counts are the whole problem, and both symptoms share one cause: the two sides'
generation values differ, so the lines carrying them are no longer identical. `check --rebuild` on
such a dump used to die with an unhandled `sqlite3.IntegrityError: UNIQUE constraint failed:
settings.key` — a raw Python traceback rather than a clean refusal. It failed closed (the DB was left
untouched), but it failed ugly. `validate_merged_dump()` now names it instead.

The equal-write case being genuinely clean is what makes this dangerous: union *looks* fine right up
until the day two branches write a different number of times.

So the earlier claim in this file — that the header "conflicts by construction on every concurrent
write" and that `check` catches it — was **wrong on both counts**, and is corrected here. The header
often does not conflict at all, and when it duplicates, nothing catches it until the rebuild throws.
`utils/releases-merge-resolve.sh` now refuses a multi-header dump up front, naming the fix. Tracked
as [#54](https://github.com/HiQS-Suite/XYZ-forge/issues/54).

### The derived artifacts conflict on purpose

`releases.db` conflicts on every concurrent ledger write. That is
deliberate, and `.gitattributes` records the measurement behind it: `merge=ours` does nothing (`ours`
is a merge *strategy*, not a built-in *driver*), and the only thing that auto-merges it is a driver
defined in `.git/config` — which is not committed, so it would be absent on fresh clones (#4).

More to the point, auto-resolving is the **wrong outcome**: it lets the merge complete while the DB
still holds only one side's rows, leaving the rebuild easy to forget. The conflict is what stops you
at the moment the decision has to be made. Resolution is `utils/releases-merge-resolve.sh`.

---

## Q: What triggers the transforms before, during, and after a git operation?

**Git triggers nothing.** Every transform is fired by the CLI process. Git is entirely passive — it
sees two files and merges them naively.

Verified: the only installed hook is `pre-push`, and it contains zero references to releases. There is
no `post-merge`, `post-checkout`, or `post-rewrite` hook. `.gitattributes` exists as of 2026-08-19 but
defines **no merge driver** — it only marks `releases.db` as a derived file, deliberately (see above).

| Transform | Triggered by | Automatic? |
|---|---|---|
| DB write + dump + generated view | a CLI write command | yes, same transaction |
| Crash recovery from the intent journal | `releases check` | **no** — human runs it |
| Merge resolution (dump → DB) | `releases check --rebuild` | **no** — human runs it |
| Anything at all during `git merge` / `checkout` / `rebase` | — | **nothing fires** |

### The write protocol

[`perform_write()`](utils/py/releases_app.py#L780), triggered by a write command (`add`, `update`,
`ship`, `manifest`, `marathon`, `import`, `reconcile`). One transaction, three phases:

- **Before the DB commit** — write the intent journal: `txn_id`, the **next** generation number, and
  the list of planned output files. It is written first precisely so a crash is recoverable; the
  journal records what was *about* to happen.
- **During** — `BEGIN IMMEDIATE` → mutate → stamp the new generation into `settings` → append an
  `op_receipt` carrying the business-state digest before and after → `COMMIT`.
- **After** — stage the dump and the generated view (each carrying that same generation),
  atomic-rename them into place, clear the journal.

The **generation number** is the thread tying the artifacts together: stamped into the DB and into
each file's header, so `check` can distinguish a consistent set from a torn one. Five named crash
boundaries are injectable via `RELEASES_APP_CRASH_AT` for testing.

### Crash recovery is fail-closed

[`recover_from_journal()`](utils/py/releases_app.py#L867) is called from exactly one place:
`cmd_check` ([line 1969](utils/py/releases_app.py#L1969)).

It is **not** automatic and **not** run on the next write. A live journal makes the next write
**refuse** ([lines 796-799](utils/py/releases_app.py#L796-L799)) and tell you to run `check`. That is
deliberate: the tool will not quietly write on top of an interrupted transaction.

## Q: Should we add a git hook that runs before merging?

**No.** Asked and answered 2026-08-19; the reasoning is recorded here so it doesn't get re-litigated.

1. **A local hook cannot fire on the merge path this repo actually uses.** Merges here happen through
   `gh pr merge` — server-side on GitHub. No local hook runs at all.
2. **Hooks don't travel with clones.** `.git/hooks/` is not committed. That exact problem is already
   tracked as [#4](https://github.com/HiQS-Suite/XYZ-forge/issues/4). A safety check that is silently
   absent on a fresh clone is worse than no check, because people assume it is running. (Same caveat
   applies to #54's merge driver, since `.git/config` isn't committed either.)
3. **The obvious hook doesn't fire where the risk is.** `pre-merge-commit` is skipped exactly when the
   merge conflicts — the only case that matters here. Per git's documentation, when the merge cannot
   be carried out automatically that hook is not executed; you resolve and commit, and `pre-commit`
   runs instead. Full coverage would need `post-merge` *and* `pre-commit`, and the latter fires on
   every commit.
4. **`--no-verify` bypasses it**, and this repo has a documented instance of that being used to get
   past a spuriously red gate.

**Use CI + the gate instead.** `.github/workflows/ci.yml` runs `./validate.sh --sequential` on `push`
and `pull_request` for `main` and `development`. So [#52](https://github.com/HiQS-Suite/XYZ-forge/issues/52)
— wiring `releases check` into `validate.sh` — buys enforcement on four surfaces from one committed
change: every PR before merge, every push to `development` after merge, local `pre-push`, and any
local `validate.sh` run. It travels with the clone and catches divergence regardless of how the merge
happened.

**Why this is less urgent than it sounds:** the server-side path already fails closed. If two branches
both wrote to the ledger, GitHub hits the binary conflict on `releases.db` and **refuses to
auto-merge** rather than producing a divergent state silently. The genuinely risky path is a human
resolving locally and pushing — which `pre-push` and CI both cover.

An advisory `post-merge` hook that prints "the ledger changed, run `releases check`" is cheap if you
want a nudge, but it is a convenience, not a safety mechanism, and it still won't exist on a fresh
clone.

---

## Q: What does the rebuild do if the merged dump is mangled?

It refuses, by name, before writing anything. The live DB is never touched. Three rules, each
matching damage a real text merge produces:

| Rule | Means | Fix |
|---|---|---|
| `dump-multi-generation` | two or more `-- generation:` headers — a union across branches with unequal write counts | keep the **highest** header, delete the rest |
| `dump-duplicate-setting` | a `settings` key appears twice — same cause; only shows when the generation values differ | keep the row that should win (for `generation`, the higher) |
| `dump-duplicate-gid` | one `global_id` in a table twice — **both branches edited the same record** | a real content conflict; decide which row wins. No union rule can settle this. |
| `dump-load` | backstop for damage not yet named above | read the message; the live DB is untouched |

`utils/releases-merge-resolve.sh` checks the first of these up front, so the common case is caught
before a rebuild is even attempted.

## Q: So what's missing?

Three gaps, all at the git boundary, all filed:

| # | Gap | Consequence |
|---|---|---|
| [#52](https://github.com/HiQS-Suite/XYZ-forge/issues/52) — **closed** | Nothing ran `releases check` against the repo's real artifacts — `validate.sh` only exercised the CLI in fixtures | A mis-resolved merge shipped a DB that disagrees with the dump, silently. Now gated by `test/gh32-releases-artifacts.sh` (read-only, never `--rebuild`, runs against a copy so it cannot write to the clone it checks). |
| [#53](https://github.com/HiQS-Suite/XYZ-forge/issues/53) — **closed** | `releases.db` is a committed derived artifact that conflicts on every concurrent write | Now marked `-diff linguist-generated` and given a one-command resolution (`utils/releases-merge-resolve.sh`). The conflict itself is kept **on purpose** — see above. `RELEASES-PREVIEW.md` was a second such artifact and was **deleted** 2026-08-19 rather than managed. |
| [#54](https://github.com/HiQS-Suite/XYZ-forge/issues/54) — **closed** | A naive `merge=union` duplicates the single-row `settings` table, and `check --rebuild` died with an unhandled `IntegrityError` instead of refusing | `validate_merged_dump()` now names each case before anything is written (see below). No merge driver was added: the resolver plus these refusals cover it, and a driver would have to live in uncommitted `.git/config`. |

**Do #52 first.** It makes a mis-resolved merge *visible*; the other two make merges *easier*. #52 is
worth having even if the merge tooling is never improved, because it catches the mistake regardless of
how the merge was performed. It must be **read-only — never `--rebuild`** — a gate that silently
repairs destroys the evidence that a merge went wrong.

### The structural alternative on the record

The cheapest fix for both #53 and #54 is to **stop committing `releases.db`** and gitignore it, since
it is fully reconstructible from `releases.sql` via the already-tested rebuild path. No binary in git,
nothing to conflict.

That is **PRD Decision 2**, so reversing it is an owner call, not a cleanup. Noted here so the option
stays on the record: if Decision 2 is revisited for other reasons, it also closes two open issues.

### The hazard worth remembering

Binding the transforms to the *write* rather than to git is the right design — the dump stays
current with no one remembering a step. But a git operation can swap both `releases.db` and
`releases.sql` underneath you (merge, checkout, rebase) and **nothing revalidates afterward**. The
writer lock lives in the git common-dir and guards concurrent CLI writers; it has no opinion about git
itself moving the files. The one place a human step exists is exactly the place with no safety net.

---

## Q: What does a REAL merge actually look like, and what goes wrong?

Answered by measurement on 2026-08-19, not by reading the code. Everything below is pinned in
[`test/gh57-live-merge-resolve.sh`](test/gh57-live-merge-resolve.sh) (30 assertions), which drives an
actual `git merge` rather than hand-building a union with `awk`.

**Why this needed its own suite.** `gh53`, `gh54` and `gh57-releases-fuzz` all construct their merged
dump themselves and hand it to the app. That proves what the app does with a mangled dump. It never
puts the resolver in front of a real conflicted index. And the repo's own traffic had never produced
one — as of 2026-08-19, **no PR had touched `releases.sql` concurrently with `development`**, so the
live path had zero coverage from real merges and zero from tests. A suite was the only way it would
be exercised before an operator met it.

### What git leaves behind

A concurrent ledger write conflicts **both** artifacts, not just the dump:

```
$ git diff --name-only --diff-filter=U
releases.db
releases.sql
```

`releases.sql` gets ordinary conflict markers and ends up carrying **both** sides' `-- generation:`
headers. `releases.db` is binary, so git leaves the *ours* copy in the working tree and marks the path
unmerged. That two-file shape is what `utils/releases-merge-resolve.sh` branches on.

### Four things that were broken, and now are not

| What | Was | Now |
|---|---|---|
| A **failed** resolve | Staged `releases.db` *before* attempting the rebuild, so a run that then failed had already marked half the merge resolved — while its own error text said "nothing was staged over it". `git commit` at that point would have committed the stale *ours* DB against a dump it does not match. | The derived artifact is replaced in the working tree but **resolved in the index only after** the rebuild *and* the verify both pass. A failed run genuinely leaves the merge open. |
| Keeping the **lower** generation header | Returned `rc=0`, and `releases check` then said **clean**, with the counter silently rewound below a merge parent's. The advice to "keep the HIGHEST" lived only inside another refusal's prose and was enforced nowhere — so the one resolution that loses information was the one nothing complained about. | Refused, naming both parents' generations and the value to set. Enforced during the merge, while `HEAD` and `MERGE_HEAD` are both still reachable. |
| `releases.db.bak` | Created by every rebuild, described by the resolver as "untracked and safe to delete" — but **not gitignored**. A `git add -A` before `git merge --continue` would commit a stale ~200 KB binary copy of the ledger: the one artifact guaranteed to disagree with the dump. | Gitignored. |
| `--root ""` | Fell through to `git rev-parse --show-toplevel`, i.e. **whatever repo you happen to be standing in**. This is not hypothetical: it fired while writing the suite above, when a fixture builder aborted and returned an empty string, and it rebuilt **this repo's production ledger** (generation 6 → 12; recovered byte-for-byte from `HEAD`). | Refused. "No `--root`" and "`--root` with an empty value" are different statements and no longer share a code path. |

### The operator path, in full

```bash
git merge <branch>                      # conflicts releases.sql AND releases.db
# resolve releases.sql BY HAND: union both sides' rows, keep ONE settings block,
# and keep the HIGHEST '-- generation:' header
git add releases.sql
utils/releases-merge-resolve.sh         # takes either side of the .db, rebuilds, verifies, stages
git commit                              # the resolver deliberately does not commit for you
```

The resolver refuses, without touching the live DB, if `releases.sql` is still unmerged, still
carries conflict markers, has zero or multiple `-- generation:` headers, keeps a header below the
highest parent, or rebuilds into something `check` will not pass.

### A trap for anyone writing fixtures here

macOS ships **bash 3.2**, where `local a="$1" b="$WORK/$a"` does **not** see `a` — every name in the
statement is localized before any assignment runs, so `$a` is unset. Under `set -u` that aborts the
function mid-build and it returns an empty string. One name per `local`. That single quirk is what
produced the `--root ""` escape above.

---

## Q: What ELSE lives in this DB? (the ROADMAP shadow, GH-69)

Since 2026-08-19 the DB holds a **second subsystem**: `roadmap_items`, a one-way mirror of
`ROADMAP.md`'s ledger. Same Phase-0 pattern as releases:

| | releases (GH-32) | roadmap shadow (GH-69) |
|---|---|---|
| Human file | `RELEASES.md` (until the strict flip) | `ROADMAP.md` — **always**; the shadow never writes it |
| Write path | `releases add/update/ship/manifest` | `releases roadmap sync` (parse + mirror; `--dry-run` previews) |
| Keys | `rel-`/`mfi-`/… GIDs | `rmi-` GIDs, stable across edits; entries keyed by GH number |
| Captured | typed release fields | gh_number, title, section, position, status marker, cx/risk/eff, doc link, issue URL — **plus the entry text verbatim** (lossless) |
| Merge story | this whole document | identical — the rows ride the same dump, the same `check --rebuild`, the same resolver, and `validate_merged_dump`'s per-table GID sweep covers them generically |

Two properties worth knowing before you touch it:

1. **A no-change sync is a true no-op** — no write, no generation bump, no dump churn. Syncing
   after every ledger edit is therefore free, and is the expected habit.
2. **The shadow mirrors the FILE, not the planner.** Sections the marathon planner skips
   (`Ad-hoc detours`) are still captured; its job is what `ROADMAP.md` says, not what
   `_marathon_plan.py` chooses to read.

All pinned by `test/gh69-roadmap-shadow.sh` (24 assertions). Design history and the staged flip
plan: [#69](https://github.com/HiQS-Suite/XYZ-forge/issues/69).

---

## Q: The ledger says one thing and GitHub says another. What keeps them honest?

**Right now: nothing automatic.** Both subsystems are internally consistent by construction — the
generation trio, the receipt chain, and `check --rebuild` guarantee the DB, the dump, and the
generated Markdown agree with each other. None of that says a word about whether they agree with
*reality*. Three surfaces drift silently, all of them observed on 2026-08-19:

| Surface | How it drifts | Detected by |
|---|---|---|
| A release whose exit criterion is met but never shipped | `ship` is a deliberate human verb (it requires evidence, by design — `rule=ship-needs-evidence`). Nothing notices that the criterion has been met. 0.7.1 sat `active` for a day after its own merge landed. | **`check`, since 2026-08-19** — `rule=release-overdue` (active, past target) and `rule=release-target-passed` (draft, past target). Warn-only; see below. |
| Manifest item open/closed state | Stored when the item is added, never refreshed. `reconcile` only maps placeholder IDs → real URLs; it does not re-read GitHub. All three of Bulwark's items showed `[open]` while closed. | nothing |
| ROADMAP status markers vs. issue state | The shadow faithfully mirrors whatever the file says, including a `🚧 active` marker on an issue GitHub closed a day earlier. Four entries were stale. | nothing |

The shadow is not the problem here — it mirrors the file correctly, which is exactly its contract.
The gap is that **no reader ever compares either ledger to GitHub**, and no surface makes a
discrepancy visible without someone deciding to audit by hand.

**The first row is now covered.** `check` emits two warn-only advisories off the stored target date
— no network call, no GitHub read, so `check` stays offline and fast:

- `rule=release-overdue` — an `active` release is past its target. *"if the exit criterion is met,
  `releases ship` it; if not, `releases update` the target."*
- `rule=release-target-passed` — a `draft` is past its target. The plan has drifted from the
  calendar.

Both **warn and never refuse**, deliberately: a gate that turns red on a calendar date is a gate
people disable. Pinned by `test/gh32-release-target-advisory.sh` (17 assertions), including the
falsifiable half — a release whose target has *not* passed produces no warning at all. Mock the
clock with `RELEASES_APP_NOW`.

The remaining two rows close in this order:

1. **[#75](https://github.com/HiQS-Suite/XYZ-forge/issues/75) — the dashboard.** A read-only page
   showing both ledgers side by side makes "shipped release still marked active" and "closed issue
   still marked active" *visible on sight*. Detection before enforcement.
2. **A GitHub-reading refresh** — manifest item state, and roadmap markers vs. real issue state.
   Both need `check` (or a separate verb) to make a network call, which it has never done. That is
   a design decision, not a patch; #75 defers it by showing stored state *with its age*.

Until those land, the honest habit after closing issues or merging a release PR is: `releases next`,
`releases show --version <v>`, `releases roadmap sync` — and read the output.

---

## Quick reference

```bash
R="python3 utils/py/releases_app.py"

$R check                 # read-only health: generation trio, receipt chain, digests
$R check --rebuild       # MERGE RESOLUTION ONLY: dump -> DB, atomic, .bak of displaced DB
$R list                  # releases
$R show --version 0.7.0  # or --gid <ULID>
$R next                  # next unshipped release by target date
$R gen                   # side-by-side view; NEVER writes RELEASES.md

utils/releases-merge-resolve.sh   # finish a ledger merge: rebuild, verify, stage (never commits)
```

A healthy repo prints:

```
OK: generation trio consistent at <N> (DB <-> dump)
OK: RELEASES.generated.md generation marker matches (<N>)
OK: receipt chain intact (<n> receipt(s), business-state digest matches)
check: clean (0 failures, 0 warning(s))
```

## Artifact inventory

| Path | What it is | Committed? |
|---|---|---|
| `releases.db` | the SQLite DB — runtime truth | yes (PRD Decision 2) |
| `releases.sql` | canonical GID-keyed logical dump — merge-boundary truth | yes |
| `RELEASES.md` | the human ledger; **Phase 0 hard boundary — the tool never writes it** | yes |
| `RELEASES.generated.md` | side-by-side generated view (`gen` only) | no — gitignored |
| `RELEASES.generated.md.drift` | drift report: generated view vs the real `RELEASES.md` | no — gitignored |
| `releases.db.bak` | DB displaced by `check --rebuild` | no |
| `releases-app.lock` | repo-scoped writer lock, in the **git common-dir** (GH-448 idiom) | no |
| `releases-app-journal.json` | intent journal; exists only mid-write | no |

`RELEASES-PREVIEW.md` was **removed 2026-08-19**. It existed to give a human a readable view of the
DB without SQL; a desktop SQLite viewer and the GitHub Projects cards from `releases project sync`
(GH-39) both do that better. Deleting it removed a tracked generated file that conflicted on every
concurrent write, one staged output from every write transaction, one crash-recovery surface, and
the whole `preview-stale` rule. For a whole-ledger view use `releases list`, a SQLite viewer, or the
Project cards.

## Related

- [PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md](PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md) — the PRD; wins on any disagreement
- [skills/releases/SKILL.md](skills/releases/SKILL.md) — the operator workflow
- [test/gh32-releases-app.sh](test/gh32-releases-app.sh) — the suite; section J is the merge procedure
- [#52](https://github.com/HiQS-Suite/XYZ-forge/issues/52), [#53](https://github.com/HiQS-Suite/XYZ-forge/issues/53), [#54](https://github.com/HiQS-Suite/XYZ-forge/issues/54) — the gaps above, all closed
- [#57](https://github.com/HiQS-Suite/XYZ-forge/issues/57) — the canonical fuzzing issue; [test/gh57-releases-fuzz.sh](test/gh57-releases-fuzz.sh) (42/0) and [test/gh57-live-merge-resolve.sh](test/gh57-live-merge-resolve.sh) (30/0) are its two suites
