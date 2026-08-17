# GH-14 — recorded negative control

Test:     `test/gh14-atomic-append.sh` (TEST_SOFT_FAIL=1)
Baseline: `54052c52325015bd5eff13128734240d1c208bf9` — `src/events.js` at pre-fix content
Date:     2026-08-17

The deterministic discriminator is the mechanism pin (Part 2): `fs.writeFileSync`/`fs.renameSync`
are traced and the ONLY write must go to a non-`.jsonl` name followed by exactly one rename onto
the final path. Pre-fix, `appendEvent` wrote directly to the `.jsonl` path with no rename, so the
pin fails with `no direct write to a .jsonl path (1 !== 0)`.

The stress run (Part 4) is the behavioural proof, and it is honestly probabilistic: the pre-fix
torn-read window is the gap between `writeFileSync` creating the file and the bytes landing, which
a concurrent `readAllEvents` only observes if it lands in that window. In the recorded pre-fix run
it did NOT fire (300/300 events, zero torn reads) — a green stress run pre-fix is a missed race,
not an all-clear, which is exactly why the mechanism pin exists as the deterministic half. The five
assertions that PASS pre-fix are the point: they prove the fix is byte-preserving (Part 1 passes
both sides) and that the reader's `.jsonl` filter (Part 3) already existed — the defect was purely
in the write path, so a blanket-failing suite would not have been discriminating.

## PRE-FIX — the control is OBSERVED failing

```
== test: gh14-atomic-append ==
  workdir: <tmp>
  PASS: healthy-path event bytes and filename preserved byte-for-byte
  FAIL: atomic-publish mechanism violated: AssertionError: no direct write to a .jsonl path (1 !== 0)
  PASS: readers never see a torn in-flight .tmp document and still read real events
  PASS: concurrent readers never observed a torn file under cross-process load (reader ok: 12 iterations, 300/300 stress events, zero torn reads)
  PASS: no .tmp residue in the events directory after the stress run
  PASS: final event count exact (303)

  gh14-atomic-append: 5 pass, 1 fail (exit 1)
```

## POST-FIX — same file, same assertions, green

```
== test: gh14-atomic-append ==
  workdir: <tmp>
  PASS: healthy-path event bytes and filename preserved byte-for-byte
  PASS: appendEvent writes via a temp name and one atomic rename onto the .jsonl path
  PASS: readers never see a torn in-flight .tmp document and still read real events
  PASS: concurrent readers never observed a torn file under cross-process load (reader ok: 31 iterations, 300/300 stress events, zero torn reads)
  PASS: no .tmp residue in the events directory after the stress run
  PASS: final event count exact (303)

  gh14-atomic-append: 6 pass, 0 fail (exit 0)
```
