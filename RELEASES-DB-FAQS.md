---
title: RELEASES DB FAQs — why a committed SQLite ledger still merges, and what triggers what
status: Reference
created: 2026-08-19
updated: 2026-08-19
owner: noelsaw
doc_type: architecture
summary: Answers the recurring questions about the GH-32 SQLite RELEASES ledger — why git can merge it without a SQLite-diffing library, which artifact is authoritative where, what fires each transform (and what does not), and the three known gaps around the git boundary.
verified_against:
  - utils/py/releases_app.py
  - test/gh32-releases-app.sh
  - releases.sql
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

### Do not use `merge=union`

Git ships a built-in `union` merge driver that keeps both sides' lines. It looks like precisely the
right tool and it is **wrong**: it keeps *both* generation headers, and `check` then fails the
generation trio. The header needs the special-case handling above. Tracked as
[#54](https://github.com/HiQS-Suite/XYZ-forge/issues/54).

---

## Q: What triggers the transforms before, during, and after a git operation?

**Git triggers nothing.** Every transform is fired by the CLI process. Git is entirely passive — it
sees two files and merges them naively.

Verified: the only installed hook is `pre-push`, and it contains zero references to releases. There is
no `post-merge`, `post-checkout`, or `post-rewrite` hook, and no `.gitattributes`, so no merge driver.

| Transform | Triggered by | Automatic? |
|---|---|---|
| DB write + dump + preview + generated view | a CLI write command | yes, same transaction |
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
- **After** — stage the dump, the preview, and the generated view (each carrying that same
  generation), atomic-rename them into place, clear the journal.

The **generation number** is the thread tying the artifacts together: stamped into the DB and into
each file's header, so `check` can distinguish a consistent set from a torn one. Five named crash
boundaries are injectable via `RELEASES_APP_CRASH_AT` for testing.

### Crash recovery is fail-closed

[`recover_from_journal()`](utils/py/releases_app.py#L867) is called from exactly one place:
`cmd_check` ([line 1969](utils/py/releases_app.py#L1969)).

It is **not** automatic and **not** run on the next write. A live journal makes the next write
**refuse** ([lines 796-799](utils/py/releases_app.py#L796-L799)) and tell you to run `check`. That is
deliberate: the tool will not quietly write on top of an interrupted transaction.

---

## Q: So what's missing?

Three gaps, all at the git boundary, all filed:

| # | Gap | Consequence |
|---|---|---|
| [#52](https://github.com/HiQS-Suite/XYZ-forge/issues/52) | Nothing runs `releases check` against the repo's real artifacts — `validate.sh` only exercises the CLI in fixtures | A mis-resolved merge ships a DB that disagrees with the dump, silently. The DB is what every reader trusts at runtime. |
| [#53](https://github.com/HiQS-Suite/XYZ-forge/issues/53) | `releases.db` is a committed derived binary with no `.gitattributes` | Every concurrent ledger write produces an unmergeable binary conflict on a file that is fully derivable from the dump beside it |
| [#54](https://github.com/HiQS-Suite/XYZ-forge/issues/54) | No merge driver for `releases.sql`; its `-- generation:` header conflicts **by construction** on every concurrent write | Every merge conflicts on that line even when no release rows overlap |

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

Binding the transforms to the *write* rather than to git is the right design — the dump and preview
stay current with no one remembering a step. But a git operation can swap both `releases.db` and
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
```

A healthy repo prints:

```
OK: generation trio consistent at <N> (DB <-> dump)
OK: RELEASES.generated.md generation marker matches (<N>)
OK: RELEASES-PREVIEW.md generation marker matches (<N>)
OK: receipt chain intact (<n> receipt(s), business-state digest matches)
check: clean (0 failures, 0 warning(s))
```

## Artifact inventory

| Path | What it is | Committed? |
|---|---|---|
| `releases.db` | the SQLite DB — runtime truth | yes (PRD Decision 2) |
| `releases.sql` | canonical GID-keyed logical dump — merge-boundary truth | yes |
| `RELEASES.md` | the human ledger; **Phase 0 hard boundary — the tool never writes it** | yes |
| `RELEASES-PREVIEW.md` | disclaimer-headed preview, regenerated in every write transaction | yes |
| `RELEASES.generated.md` | side-by-side generated view (`gen` only) | no — gitignored |
| `RELEASES.generated.md.drift` | drift report: generated view vs the real `RELEASES.md` | no — gitignored |
| `releases.db.bak` | DB displaced by `check --rebuild` | no |
| `releases-app.lock` | repo-scoped writer lock, in the **git common-dir** (GH-448 idiom) | no |
| `releases-app-journal.json` | intent journal; exists only mid-write | no |

`RELEASES-PREVIEW.md` is a preview of the DB, never the ledger. Do not edit it, cite it as shipped
history, or resolve conflicts in it — regenerate it.

## Related

- [PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md](PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md) — the PRD; wins on any disagreement
- [skills/releases/SKILL.md](skills/releases/SKILL.md) — the operator workflow
- [test/gh32-releases-app.sh](test/gh32-releases-app.sh) — the suite; section J is the merge procedure
- [#52](https://github.com/HiQS-Suite/XYZ-forge/issues/52), [#53](https://github.com/HiQS-Suite/XYZ-forge/issues/53), [#54](https://github.com/HiQS-Suite/XYZ-forge/issues/54) — the open gaps above
