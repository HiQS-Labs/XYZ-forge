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
| both branches made the **same number** of writes | merges **cleanly** — one generation header, both sides' rows present. The header is identical text on both sides (`-- generation: 2`), so there is nothing to conflict. |
| branches made **different numbers** of writes | **two** generation headers, silently, with no conflict markers |
| either case | the single-row `settings` table is **duplicated** |

That last row is the real defect. `check --rebuild` on such a dump dies with an unhandled
`sqlite3.IntegrityError: UNIQUE constraint failed: settings.key` — a raw Python traceback rather than
a clean refusal. It does fail closed (the DB is left untouched), but it fails ugly.

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
- [#52](https://github.com/HiQS-Suite/XYZ-forge/issues/52), [#53](https://github.com/HiQS-Suite/XYZ-forge/issues/53), [#54](https://github.com/HiQS-Suite/XYZ-forge/issues/54) — the open gaps above
