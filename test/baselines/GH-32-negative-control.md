# GH-32 negative control — releases-app consistency gates (Phase 0+1)

Recorded 2026-08-18. Per the standing rule: a check never observed failing is not evidence.
Every guard the PRD names for `releases check` and the writer protocol was reverted in the
working tree (mutate → run `bash test/gh32-releases-app.sh` → restore from a `cp` backup), and
the failing assertions below are the observed transcripts. Pristine tree before and after every
mutation: **81 passed, 0 failed**.

Method note: mutations were applied to a `cp` backup-and-restore cycle of
`utils/py/releases_app.py` (never `git checkout -- <path>` — the GH-527 rail), and the restored
file was `cmp`-verified identical before the next mutation ran.

## Mutation 1 — exact-shape GID checks relaxed to prefix-only (the r2 "theater" regression)

`_gid_check()` rewritten to `GLOB '<prefix>*'` — the exact shape the r2 review finding rejected:
a prefix-only GLOB accepts any length and any alphabet, so the "26-character ULID" claim was
convention, not schema.

```
== gh32-releases-app: 78 passed, 3 failed ==
  FAIL: migration carries the exact-shape GID check written out in full (26 Crockford classes)
  FAIL: schema refuses a too-short global_id
  FAIL: schema refuses a wrong-alphabet global_id (Crockford excludes I/L/O/U)
```

All three GID-shape assertions go red: the schema accepts `rel-SHORT` and `rel-01IIII…` (I is
outside the Crockford alphabet), and the migration no longer contains the 26 written-out
character classes.

## Mutation 2 — receipt-chain verification disabled

The final digest comparison in `cmd_check` (`latest after != business digest`) short-circuited
with `if False and …` — i.e. the r3 bypass detector turned off.

```
== gh32-releases-app: 79 passed, 2 failed ==
  FAIL: coupling detected
  FAIL: (3) receipt-less write
```

Both digest-chain controls go red: a receipt-less direct write (dump refreshed so
dump-divergence cannot fire first — the control is isolated to the chain) and the
state/event-coupling control (a direct `UPDATE manifest_items` without an event) are no longer
detectable. The append-only triggers still physically block in-DB receipt edits — the chain is
what catches the writer who bypasses the DB's own conventions.

## Mutation 3 — stale `-wal`/`-journal` detection removed

The `if stale and not journal_live` guard in `cmd_check` short-circuited.

```
== gh32-releases-app: 80 passed, 1 failed ==
  FAIL: (2) stale -wal
```

A leftover `releases.db-wal` with no live intent journal no longer fails check — exactly the
"write proceeds over a dirty state" condition PRD Git story 5 forbids.

## Mutation 4 — writer lock neutered (`acquire` returns immediately)

The r4 control: a refused writer must change NO committed artifact. With no exclusion at all,
the simulated concurrent-writer case loses the refusal AND the evidence.

```
== gh32-releases-app: 78 passed, 3 failed ==
  FAIL: lock refusal rc4
  FAIL: refused changed nothing
  FAIL: sidecar
```

The write under a held lock proceeds (no exit 4), the DB/dump hashes move, and no
`retried`/`refused` lines reach the lock-audit sidecar. This is the mutation whose clean run
would have silently invalidated the Phase-0 sole-writer dogfood.

## Mutation 5 — `gen` writes the real ledger (Phase-0 boundary breach)

A second `_atomic_write(paths["ledger"], …)` added to `cmd_gen` — the one code path the task
forbids outright.

```
== gh32-releases-app: 80 passed, 1 failed ==
  FAIL: drift hand-edit
```

The clobbered fixture ledger erases the hand-added block before the drift report reads it, so
the report stops naming it. **Recorded honestly: the FIRST run of this mutation passed 81/81**
because the drift assertion grepped for the literal `hand-edit`, which also occurs in the
report's boilerplate summary line — a vacuous control. The assertion was tightened to require
the actual finding line (`[hand-edit] blocks in RELEASES.md with no DB counterpart: 9.9.9`) in
the same commit as this record, and the mutation replay above is the tightened assertion's
observed red. The vacuous-pass transcript is itself the #419 lesson: an always-green detector
is indistinguishable from a working one until you try to break it.

## Not mutated, but covered by construction

- The five crash boundaries (pre-commit / post-commit / post-stage / mid-rename / post-rename)
  are each injected via `RELEASES_APP_CRASH_AT` in the suite itself; the recovery branch
  selection depends on the journal-vs-DB generation comparison, which the boundary assertions
  (discarded vs preserved) exercise directly.
- The divergent-dump merge control asserts BOTH sides' grandfather history after
  `check --rebuild`; losing the table would fail the two import-run assertions.
- The four PRD-named check-failure cases are the suite's section I; mutations 2 and 3 above are
  the revert-and-replay evidence for two of them, and mutations 1/4/5 cover the remaining named
  guards (GID shape across DBs, lock refusal, the RELEASES.md write boundary).
