# #52 negative control — the committed RELEASES artifact pair

Recorded 2026-08-19. Per the standing rule: a check never observed failing is not evidence.

`test/gh32-releases-artifacts.sh` asserts that this repo's committed `releases.db` and
`releases.sql` agree. On a healthy repo that assertion passes trivially — and would keep passing if
the check were broken, absent, or structurally incapable of failing. The control below is what makes
it mean something.

Pristine tree before and after: **10 passed, 0 failed.**

## The control is inside the suite, not a manual step

Unlike the other baselines here, this control does not require reverting a guard by hand. The suite
carries its own falsifiability half: it seeds a **second** fixture from the same artifacts, appends
one comment line to that fixture's `releases.sql`, and asserts the check goes red there.

That design is deliberate. The thing being guarded is the *committed state of this repo*, which is
healthy by definition most of the time — so a control that lives outside the suite would be run once,
recorded here, and never exercised again. Carrying it inside means every gate run re-proves that the
check can still fail.

## Observed

| Case | Fixture | `releases check` | Rule named |
|---|---|---|---|
| the real committed pair | copy of `releases.db` + `releases.sql` + `RELEASES-PREVIEW.md` | **rc=0**, `check: clean` | — |
| dump perturbed by one appended comment line | same, plus `\n-- deliberate divergence…` | **rc=1** | `dump-divergence` |

Full text of the failure the control observes:

```
FAIL: rule=dump-divergence: releases.sql does not equal the canonical dump of the DB;
      recovery is `releases check --rebuild` (merge resolution ONLY — never crash recovery)
```

A comment line is enough because `dump_text()` is compared byte-for-byte, and a comment cannot be
mistaken for a real content edit — it isolates "the check notices divergence" from "the check
notices a particular kind of row change".

## Containment control

The suite also asserts what it must *not* do. Both checks run against copies in `$WORK`, never
against the clone, because plain `check` is only almost read-only: with a live intent journal it
calls `recover_from_journal()`, which writes.

| Assertion | Method |
|---|---|
| the clone's artifacts are unchanged after the clean check | SHA-256 of `releases.db`, `releases.sql`, `RELEASES-PREVIEW.md` compared before/after |
| the clone's artifacts are unchanged after the negative control | same digest re-compared |
| no `releases.db.bak` appeared | existence check — a `.bak` would mean something ran `--rebuild` |

That last one is the load-bearing one for the "never repair" rule: `--rebuild` is the only path that
produces a `.bak`, so its absence is positive evidence the gate stayed read-only.

## What this control does NOT cover

- It does not prove the *merge procedure* works — that is section J of `test/gh32-releases-app.sh`.
- It does not prove `--rebuild` produces a correct DB — same place.
- It cannot detect a dump and DB that agree with each other but are both wrong (e.g. a merge
  resolved by dropping one side's releases entirely, then rebuilt). Agreement is the invariant here;
  completeness is not, and no artifact-level check can recover a row nobody kept.

## Related

- [#52](https://github.com/HiQS-Suite/XYZ-forge/issues/52) — the issue this closes
- [RELEASES-DB-FAQS.md](../../RELEASES-DB-FAQS.md) — the merge model and why this gate exists
- `test/baselines/GH-32-negative-control.md` — the CLI-level controls this one sits on top of
