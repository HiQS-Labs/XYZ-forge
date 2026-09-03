# GH-411 — recorded negative control (#419)

The control this repo requires is not a sentence asserting it happened. Both runs are below,
same test file, same machine, differing only in whether the bin/tick fix is present.

Test:     `test/gh411-tick-log-foreign-cwd.sh` (TEST_SOFT_FAIL=1, so one run enumerates every gap)
Site:     `bin/tick` (`assertResolvedRoot` / `shouldGuard` for non-cost `tick log` types)

## PRE-FIX — the control is OBSERVED failing

```
== test: gh411-tick-log-foreign-cwd ==
  workdir: /tmp/tick-gh411-tick-log-foreign-cwd.XXXXXX.Hd0mLWxFMQ
  FAIL: unpinned foreign-git tick log task.created succeeded (rc=0): .tick/events/2026-09-03T19-49-46.921Z-s-created-T1.jsonl
  FAIL: error did not explain missing .tick/events: .tick/events/2026-09-03T19-49-46.921Z-s-created-T1.jsonl
  FAIL: task.created auto-created .tick/ in foreign git repo
  FAIL: unpinned foreign-nongit tick log task.created succeeded (rc=0): fatal: not a git repository (or any of the parent directories): .git
.tick/events/2026-09-03T19-49-46.991Z-s-created-T2.jsonl
  FAIL: error did not explain missing .tick/events for non-git cwd: fatal: not a git repository (or any of the parent directories): .git
.tick/events/2026-09-03T19-49-46.991Z-s-created-T2.jsonl
  FAIL: task.created auto-created .tick/ in foreign non-git dir
  FAIL: unpinned foreign-git tick log marathon.complete succeeded (rc=0): .tick/events/2026-09-03T19-49-47.049Z-s-marathon.complete-M1.jsonl
  FAIL: marathon.complete error did not explain missing .tick/events: .tick/events/2026-09-03T19-49-47.049Z-s-marathon.complete-M1.jsonl
  FAIL: marathon.complete auto-created .tick/ in foreign git repo
  PASS: unpinned foreign tick log cost.tokens succeeds (rc=0)
  PASS: unpinned foreign tick cost verb succeeds (rc=0)
  PASS: pinned TICK_REPO_ROOT tick log task.created succeeds (rc=0)
  FAIL: pinned log created .tick/ in foreign git repo
  PASS: pinned log wrote to intended root /tmp/tick-gh411-tick-log-foreign-cwd.XXXXXX.Hd0mLWxFMQ/agent-a
  PASS: inferred root WITH .tick/ still logs task.created (rc=0)
  FAIL: resolved root was not echoed to stderr: .tick/events/2026-09-03T19-49-47.307Z-s-created-T6.jsonl
  gh411-tick-log-foreign-cwd: 5 pass, 11 fail
```

## POST-FIX — same file, same assertions, green

```
== test: gh411-tick-log-foreign-cwd ==
  workdir: /tmp/tick-gh411-tick-log-foreign-cwd.XXXXXX.oHlO8L1Ow2
  PASS: unpinned foreign-git tick log task.created refused (rc=1)
  PASS: error names missing .tick/events
  PASS: no .tick/ auto-created in foreign git repo by task.created
  PASS: unpinned foreign-nongit tick log task.created refused (rc=1)
  PASS: error names missing .tick/events for non-git cwd
  PASS: no .tick/ auto-created in foreign non-git dir by task.created
  PASS: unpinned foreign-git tick log marathon.complete refused (rc=1)
  PASS: marathon.complete error names missing .tick/events
  PASS: no .tick/ auto-created in foreign git repo by marathon.complete
  PASS: unpinned foreign tick log cost.tokens succeeds (rc=0)
  PASS: unpinned foreign tick cost verb succeeds (rc=0)
  PASS: pinned TICK_REPO_ROOT tick log task.created succeeds (rc=0)
  PASS: foreign git repo still has no .tick/ after pinned log
  PASS: pinned log wrote to intended root /tmp/tick-gh411-tick-log-foreign-cwd.XXXXXX.oHlO8L1Ow2/agent-a
  PASS: inferred root WITH .tick/ still logs task.created (rc=0)
  PASS: resolved root echoed to stderr when inferred
  gh411-tick-log-foreign-cwd: 16 pass, 0 fail
```

---

## SECOND CONTROL — the `drift` exemption, added in review

The first control proves the *fix* works. It says nothing about the invariant the fix came closest
to breaking: `drift` is a separate verb sitting next to `cost`/`log` in the same comment
(`bin/tick:35`), exempt under GH-68's warn-only contract
(`decisions/2026-07-01-cross-agent-dep-conflict.md`). The original suite asserted nothing about it.

A `drift` case was added — and the first version of it **could not fail**, for a reason worth
recording. It reused `FOREIGN_COST`, where an earlier case had already run `tick log cost.tokens`
and thereby created `.tick/events`. The guard only refuses where `.tick/events` is *absent*, so the
assertion passed even under a refactor that captured `drift`. The same latent flaw applied to the
pre-existing `tick cost` verb case. Both now use a **fresh** foreign directory.

Simulated refactor (`verb !== 'cost' && !(eventType || '').startsWith('cost.')`) — the exact
generalisation a later reader might reach for:

```
  PASS: unpinned foreign tick cost verb succeeds (rc=0)
  FAIL: GH-68 REGRESSION: drift was guarded and hard-failed a turn (rc=1): tick: resolved repo root
  .../foreign-drift via git rev-parse (set TICK_REPO_ROOT to pin it)
  tick: error: no .tick/events at .../foreign-drift (resolved via git rev-parse). Refusing to
  create a coordination log here ...
```

Restored, the full suite is **19 pass, 0 fail**. Reverting `bin/tick` to base `322eeead`
reproduces the original defect (`unpinned foreign-git tick log task.created succeeded (rc=0)`),
so both controls are witnessed against this suite.
