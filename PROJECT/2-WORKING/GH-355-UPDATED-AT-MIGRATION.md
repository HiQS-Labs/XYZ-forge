---
title: "GH-355: Migration 007 — updated_at across all releases.db tables, so consumers can detect what changed"
status: active
created: 2026-09-07
updated: 2026-09-07
owner: orchestrator (Claude Code)
goal: every releases.db table carries a maintained updated_at, so a reconciler can ask "what moved since I last looked"
gh_issue: 355
source: https://github.com/HiQS-Labs/XYZ-forge/issues/355
branch: feat/gh355-updated-at-migration
doc_type: feature
marathon: 497
lane: C
related: [GH-491, GH-492, GH-351, GH-349]
context_tags: [releases, schema, migration]
effort: 4
complexity: 3
risk: 3
---

## Status

| What was just completed | What's next |
|---|---|
| Confirmed the port source is intact: branch `fix/gh351-gh349-releases-ledger-fixes` at `b2f7947f`, all four named commits present | Lane C of marathon #497 — wave 1, the substrate the sweep is built on |

## Why this lane is in this marathon

From the issue: *"twelve of fourteen tables in `releases.db` have no modification timestamp, so no
consumer can detect what changed. A ranking tool, a dashboard, or **a reconciler** that wants 'what
moved since I last looked' has nothing to ask."*

That reconciler is lane B (#492). Without `updated_at` its sweep must re-read every row on every
run; with it, the sweep can skip rows that cannot have moved. The lane stands on its own merits —
it was already filed and already implemented — but it earns wave 1 here because it is what makes B
cheap rather than merely correct.

## This is a port, not a fresh build

PR #352 carried a working implementation. It was **unbundled, not rejected** — bundling an invasive
migration with a small verb meant a defect in either blocked both. Its round-trip tests are already
written, in that branch's changes to `test/gh32-releases-app.sh`.

Port from `fix/gh351-gh349-releases-ledger-fixes` (`b2f7947f`), in order — verified present in this
clone on 2026-09-07:

| Commit | What to take |
|---|---|
| `231d751b` | backfill & maintain `updated_at` across all tables |
| `aeba125d` | complete coverage across all write paths, full pre-migration fixture |
| `8897c84d` | backfill on old-dump loading, advance `settings.generation` `updated_at`, v6 untouched-rebuild test |
| `e56cb7cd` | separate `settings.generation` from the rebuild preservation snapshot, pin the rebuild clock |

The commits interleave GH-349 and GH-351 work, so this is a **content-level port, not a clean
`git cherry-pick`.**

### Do not take

That branch's `parse_roadmap_ledger` / `cmd_roadmap_sync` changes. Those are the rejected GH-349
half, superseded by #350, and they carry a **silent-wipe defect on a 0-byte `ROADMAP.md`**. Taking
them would reintroduce a data-loss path into the same subsystem this marathon exists to make
trustworthy.

## Scope

Roughly **144 write sites** across `utils/py/releases_app.py`, plus the migration, plus dump/rebuild
handling. Nine tables: `settings`, `repos`, `issue_refs`, `marathons`, `releases`, `manifest_items`,
`doc_lines`, `legacy_lines`, `grandfather_entries`.

## Acceptance

Verbatim from the issue:

- All nine tables carry non-NULL `updated_at` after `releases migrate`
- Every insert/update path maintains it; a mutation that skips it is caught by a test, not by review
- A pre-migration dump loads and backfills rather than producing NULLs
- Dump → rebuild → dump is a byte no-op for an untouched ledger
- `releases check` clean
- Full pre-push gate green

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "command", "expect_nonzero": true, "cmd": "[ $(sqlite3 releases.db \"SELECT count(*) FROM pragma_table_info('doc_lines') WHERE name='updated_at'\") = 1 ]" } ],
  "artifacts":     [ "utils/py/releases_app.py", "releases.sql", "releases.db", "test/gh32-releases-app.sh" ],
  "artifacts_new": [],
  "remediation":   { "source": "self#plan", "criteria": "all nine tables carry non-NULL updated_at after migrate; every write path maintains it under test; a pre-migration dump backfills rather than NULLs; dump->rebuild->dump is a byte no-op on an untouched ledger" },
  "lanes":         { "agy_safe": [ "utils/py/releases_app.py", "test/gh32-releases-app.sh" ], "orchestrator_only": [ "releases.sql", "releases.db", "validate.sh" ] }
}
```

`releases.sql` and `releases.db` are **orchestrator_only**: the repo's standing rule is that the
ledger and its dump are never hand-edited, and a migration is the one change that must go through
`releases migrate` rather than a text edit. `artifacts_new` is empty because this lane extends
`test/gh32-releases-app.sh` rather than adding a suite — the round-trip cases already exist on the
port branch.

The probe is a `command` rather than a grep because **grepping cannot discriminate here**:
`updated_at` already appears 152 times in `releases.sql`, since `roadmap_items` is one of the two
tables that has it. A file-level match is true before and after the migration and would prove
nothing. The probe asks the schema directly whether `doc_lines` — one of the twelve tables that
lack it — has the column, and with `expect_nonzero` it reads `unfixed` while the answer is no.
Verified against the live ledger: `rc=1` today.

## Risk

The highest-risk lane of the three: an invasive migration touching every write path in the ledger's
single write module. Mitigations are the reason it is wave 1 and alone in that wave — it lands with
nothing else in flight, its own gate run, and its own PR. The pre-existing implementation and tests
are what make the risk carryable at all; a fresh build of the same change would not belong in a
three-lane marathon.
