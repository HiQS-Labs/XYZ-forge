# PARKED

Items deliberately dropped from an active scope, kept so they stop resurfacing as "new" findings.

## 2026-08-31 — dropped from GH-351 (`manifest unship`)

- **Migration 007: `updated_at` across all tables.** PR #352 carried a timestamp migration adding and
  backfilling non-NULL `updated_at` on `settings`, `repos`, `issue_refs`, `marathons`, `releases`,
  `manifest_items`, `doc_lines`, `legacy_lines` and `grandfather_entries`, maintained across every
  insert/update path and preserved through dump/rebuild. It is a **real fix for
  BinoidCBD/LTVera-Pandas#322 finding 7** (twelve of fourteen tables have no modification timestamp,
  so no consumer can detect what changed) and the work looked sound.

  Parked, not rejected. It is a separate scope from GH-351 — ~144 write sites across the file — and
  bundling it would make this branch's review the same "two PRs wearing one hat" problem that sank
  #352. It should land as its own PR against its own issue, ported from
  `origin/fix/gh351-gh349-releases-ledger-fixes`, with the dump/rebuild round-trip tests that branch
  already wrote (`test/gh32-releases-app.sh` changes).

  `cmd_manifest_unship` is written to be indifferent to it: the `updated_at` write is guarded by
  `_has_column`, so GH-351 lands cleanly before or after.

- **PR #352's "ROADMAP.md without a `## Ledger` header" support** (commit `b2f7947f`). Rejected, not
  parked — it leaks document preamble into the ledger and breaks the repo-wide invariant that
  `## Ledger` separates ledger rows from narrative prose. Recorded here so it is not re-proposed as
  an unexamined idea.
