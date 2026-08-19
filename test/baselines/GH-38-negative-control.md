# GH-38 negative control — agent2agent doorbell hardening

Recorded 2026-08-19. Per the standing rule: a check never observed failing is not evidence. Each
guard added for GH-38 was reverted in the working tree (mutate → run `bash test/agent2agent.sh` →
restore from a `cp` backup of `skills/agent2agent/scripts/agent2agent.py`), and the observed
failure counts are below.

Method note: mutations were applied through a `cp` backup-and-restore cycle, never
`git checkout -- <path>` (the GH-527 rail). Pristine tree before and after every mutation:
**105 passed, 0 failed**.

## Observed results

| Item | Guard reverted to | Failures observed |
|---|---|---|
| 2 — REARM interpreter | `os.path.abspath(sys.argv[0])` (pre-fix rendering) | **2** |
| 3 — silent timeout | `elif False:` (no `STILL-WAITING:` line) | **1** |
| 5 — `atomic_write` directory fsync | `pass` in place of `_fsync_dir(path.parent)` | **1** |
| 6 — doorbell liveness sidecar | `pass` in place of `touch_watch_sidecar(...)` | **2** |
| 6b — sidecar refreshed per poll | drop `heartbeat=` from the `wait_for_turn` call | **1** |

Item 1's guard is no longer revertible in that form and is controlled differently — see below.

## Item 1 after the agy QA review: flock, not pid liveness

The first implementation read the holder's pid, tested `os.kill(pid, 0)`, and stole the lock from a
dead holder. The agy QA review (`relay-system/2026-08-18/gh37-gh38-doorbell-hardening-qa.md`, r1)
returned it as a **[Blocker]** on two counts, both correct:

1. `os.kill` inspects only the LOCAL process table, so a holder on another host sharing the path
   reads as dead; pid reuse degrades the verdict even locally.
2. Steal-then-claim is not atomic. Two contenders can both observe the dead pid, both `unlink`, and
   both `create` — **the second unlink deletes the first contender's freshly created lock**, so both
   return believing they hold it exclusively. `O_EXCL` cannot detect this: the damage is done by the
   unlink, not the create.

The lock is now held by `fcntl.flock`, the idiom `DriveLock` already used fifteen lines away in the
same file. The kernel releases it when the holder dies, so there is no liveness test, no steal, and
no unlink race. The lock file is deliberately **never unlinked** — unlinking is precisely what
reintroduces the race.

Its control is therefore behavioral rather than a code revert: **six concurrent writers contend over
a lock file left by a process that no longer exists**, all sending as the seat that actually owns
`NEXT`.

**The discriminating assertion is the racers' EXIT CODES, not the file's structure.** The first
version of this control asserted only structural intactness — one `TURN:` header, one `NEXT:` header,
the `TURN:` field equal to the recorded block count — and the agy QA review (r2) demonstrated it was
vacuous by disabling the lock and watching it stay green. `atomic_write` uses `os.replace`, so six
unserialized racers each read the same state, each construct the same valid next state, and each
cleanly overwrite the file: the result is a structurally perfect ledger, because `os.replace`
prevents byte-tearing whether or not anything serialized the writers.

Exit codes separate *serialized* from *merely atomic*. Under `flock`, exactly one racer can hold the
turn — it commits and routes `NEXT` to the peer, so the remaining five are refused out-of-turn. The
assertion is therefore **exactly one of six exits 0**. Observed with the lock disabled
(`fcntl.flock` replaced by `pass`): `2 of 6 racers exited 0 — expected exactly 1`, plus 8 other lock
assertions red; restored, 108/0.

## Three of these tests were vacuous when first written

Recorded because "the suite is green" was not evidence in either case, and only reverting the guard
exposed it:

- **The sidecar-staleness assertion** first used a 1.2s wait against an `age <= 1` check. `int(1.2)`
  is `1`, so it passed whether or not the marker refreshed — removing the heartbeat left the suite
  fully green. Widened to a 3s wait, where a non-refreshing marker ages ~3s and a refreshing one ~0s.
- **The concurrency control** was vacuous *twice*. First, all six racers sent as `agent 1` and were
  refused on turn ownership before ever reaching the lock. Fixed to send as the seat owning `NEXT` —
  and it was *still* vacuous, because it asserted only on file structure, which `os.replace` keeps
  intact with no lock at all. Now asserted on exit codes (see above). Both rounds of this were found
  by the reviewer, not by me, and the second only because agy ran the control rather than reasoning
  about it.

The recurring shape is worth stating plainly, since it accounts for every defect in this change:
**a test that never fails proves nothing, and the only way to know it can fail is to break the thing
it guards and watch.** Reasoning about whether a control discriminates was wrong three times here.

A third ordering defect surfaced from the same check: the concurrency test left `NEXT` on whichever
racer won, so later probes expecting `take-turn` intermittently timed out (2 of 3 runs red, on tests
unrelated to the code under test). Each probe now declares the turn state it needs through the
`route_to` helper instead of inheriting one. Three consecutive clean runs at 107/0 after the fix.

Item 4 (interval/timeout round-trip) is a test-only strengthening with no product guard to revert:
its control is that the assertions compare the *rendered* values against the *invoking* values
(`--interval 7` / `--timeout 991`, deliberately not the defaults and not the values used by any
earlier probe in the file), so a renderer that dropped, defaulted, or reused a stale value fails.

## Why these mutations and not others

Each mutation reproduces the real-world failure the item was filed for, rather than breaking the
code in a way no operator would encounter:

- **Item 1** is the state a `SIGKILL`ed sender actually leaves: a lock file naming a pid that is no
  longer running. The fixture picks a genuinely dead pid by counting down from 999999 until
  `kill -0` fails, so it never races a real process. The paired assertion — a **live** holder's
  lock is refused and left intact — is what stops the fix from becoming "always steal."
- **Item 2** strips the executable bit from a *copy* of the CLI, which is what zip vendoring and
  some transfer paths do. Pre-fix this produced a 127/permission error from a command the tool
  itself printed as safe to run verbatim.
- **Item 3** lets a real 0.2s window expire while the turn is held elsewhere. The control also pins
  the *inverse*: the timeout path must **not** print `REARM:`, because re-arming by reflex after a
  window expires is the behavior the original in-code note deliberately prevented.
- **Item 5** counts `os.fsync` calls through a monkeypatched `os.fsync` during one `atomic_write`.
  One call means the bytes were persisted but the rename naming them was not.
- **Item 6** asserts both halves: the sidecar is written, **and** the relay file is byte-identical
  afterwards. The second half is why the marker is a sidecar rather than a relay-file field — the
  suite pins that `watch` never mutates the discussion, the same reasoning as GH-32's r4
  lock-audit finding.
