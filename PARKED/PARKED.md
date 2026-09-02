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

## 2026-09-02 — dropped from the #386 bridge-hardening scope

Everything below is real but not worth holding the merge for. Recorded so it stops resurfacing as
a new finding.

- **The AgentChorus bridge's max-lifetime cap is decorative.** The 2-hour limit bounds one session
  object, not participation: reattaching to a non-closed discussion mints fresh tokens, so a client
  can stay resident forever. Left as-is because behind the authentication guard added in #386 the
  worst case is an *authenticated* peer overstaying; the false claim in the plan doc was corrected
  instead of implementing enforcement.

- **No cap on discussion creation.** Each `POST /sessions` without an id writes a new discussion to
  disk with no rate limit. This was only dangerous while the bridge was open to anyone; with
  authentication required it is a rate-limit policy question, not a security hole.

- **A local CLI close leaves bridge tokens alive.** `revoke_all` runs only on the HTTP close path,
  so closing a discussion from the command line leaves any issued tokens valid until the lease
  lapses. Verified harmless today — the zombie token cannot write, because the on-disk state
  rejects it — but it breaks the "closing revokes access" expectation.

- **`token_to_seat` is maintained and never read.** Dead reverse-lookup map in the bridge. Finish
  it or delete it; it currently just suggests an unfinished design to the next reader.

- **The Fast Gate step in `ci.yml` cannot run.** It requires a pull-request event but sits in a job
  that only accepts pushes to `development`, orphaned when #347 moved the canary. Dead code that
  reads as coverage.

- **`--parallel 6` on the Ubuntu canary is a guess.** The 5.1x speedup it is based on was measured
  on a 10-core Mac; nothing has been timed on the actual runner, and the pool plus the serialized
  lane peaks at seven processes on eight cores. The A/B to settle it is named in `ci.yml`; it needs
  a few logged runs first.
