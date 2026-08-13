# GH-388 — recorded negative control (#419)

Test:     `test/gh388-run-log-durability.sh` (TEST_SOFT_FAIL=1, so one run enumerates every gap)
Baseline: `a75cafd24eebcc5225c5f868dc6b1a339b6b24d3` — `marathon.sh`, `relay-turn-lib.sh`, `rtl.py` and `marathon_drive.py` at
          their pre-fix content, and the two new shared files (`durable-log-lib.sh`,
          `non-durable-log-roots.conf`) absent, since the fix introduces them.
Date:     2026-08-11

**A green suite proves nothing on this issue** — everything already worked on the success
path, and the defect is defined by what is MISSING after a failure. So the pre-fix run below
is the finding, not a formality: the chain announced no run log, and the phase killed
mid-run left nothing behind at all.

## PRE-FIX — the control is OBSERVED failing

```
== test: gh388-run-log-durability ==
  workdir: <tmp>
-- A: one registry, two readers, same verdict
  FAIL: GH-388 criterion 5: no single place states the non-durable locations
test/gh388-run-log-durability.sh: line 36: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/durable-log-lib.sh: No such file or directory
test/gh388-run-log-durability.sh: line 43: xyz_non_durable_reason: command not found
Traceback (most recent call last):
  File "<string>", line 3, in <module>
    print(rtl.non_durable_reason('/tmp/x.log'))
          ^^^^^^^^^^^^^^^^^^^^^^
AttributeError: module 'rtl' has no attribute 'non_durable_reason'
test/gh388-run-log-durability.sh: line 43: xyz_non_durable_reason: command not found
Traceback (most recent call last):
  File "<string>", line 3, in <module>
    print(rtl.non_durable_reason('/private/tmp/x'))
          ^^^^^^^^^^^^^^^^^^^^^^
AttributeError: module 'rtl' has no attribute 'non_durable_reason'
test/gh388-run-log-durability.sh: line 43: xyz_non_durable_reason: command not found
Traceback (most recent call last):
  File "<string>", line 3, in <module>
    print(rtl.non_durable_reason('/var/tmp/y'))
          ^^^^^^^^^^^^^^^^^^^^^^
AttributeError: module 'rtl' has no attribute 'non_durable_reason'
test/gh388-run-log-durability.sh: line 43: xyz_non_durable_reason: command not found
Traceback (most recent call last):
  File "<string>", line 3, in <module>
    print(rtl.non_durable_reason('/dev/shm/z'))
          ^^^^^^^^^^^^^^^^^^^^^^
AttributeError: module 'rtl' has no attribute 'non_durable_reason'
test/gh388-run-log-durability.sh: line 43: xyz_non_durable_reason: command not found
Traceback (most recent call last):
  File "<string>", line 3, in <module>
    print(rtl.non_durable_reason('/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/logs/a.log'))
          ^^^^^^^^^^^^^^^^^^^^^^
AttributeError: module 'rtl' has no attribute 'non_durable_reason'
test/gh388-run-log-durability.sh: line 43: xyz_non_durable_reason: command not found
Traceback (most recent call last):
  File "<string>", line 3, in <module>
    print(rtl.non_durable_reason('/usr/local/share/keepme'))
          ^^^^^^^^^^^^^^^^^^^^^^
AttributeError: module 'rtl' has no attribute 'non_durable_reason'
  PASS: the Bash and Python readers agree on every probe path
test/gh388-run-log-durability.sh: line 55: xyz_path_is_durable: command not found
  FAIL: the repo's own transcript root was classified non-durable
test/gh388-run-log-durability.sh: line 58: xyz_path_is_durable: command not found
  PASS: /tmp is classified non-durable
cp: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/durable-log-lib.sh: No such file or directory
bash: relay-automation/durable-log-lib.sh: No such file or directory
bash: xyz_non_durable_reason: command not found
  FAIL: adding an entry to the registry changed nothing — the real list is hardcoded somewhere (got: '')
-- B: a misconfigured archive root refuses, rather than quietly writing to volatile storage
  FAIL: GH-388: python lane returned a path instead of refusing — got: <tmp>
  FAIL: GH-388: the returned transcript path is in volatile storage: <tmp>
  FAIL: the refusal did not explain the cause — got: <tmp>
  FAIL: GH-388: bash lane returned '<tmp>' instead of refusing — the lanes disagree
  PASS: a healthy default (no XYZ_ARCHIVE_ROOT) still resolves: relay-system/logs/2026-08-11/agy-turn-T-1-90869.log
  PASS: and it resolves under the repo's own relay-system, unchanged
-- C: kill a phase mid-run; assert what survives
  FAIL: part C did not reproduce: the phase never reached dispatch, so nothing was killed mid-run.
--- driver output ---
claude-turn: worktree isolation ON (<tmp>)
claude-turn: WARNING: workspace '<tmp>' is not trusted; Claude may ignore project permissions. Run Claude Code interactively in this directory and accept the trust dialog, or set projects['<tmp>']["hasTrustDialogAccepted"] to true in /Users/noelsaw/.claude.json.
--- phases tree ---
<tmp>
<tmp>
<tmp>
-- D: the chain run log survives a chain that never finishes
  FAIL: part D did not reproduce: the chain never announced a run log.
--- chain output ---
marathon: plan: <tmp> — 1 phase(s) in execution order
marathon: ── phase 1/1: neverends (reviewer=codex, round-cap=3) ──
marathon-drive: reclaiming stale relay-driver.lock (holder pid 90973 not running).
claude-turn: worktree isolation ON (<tmp>)
claude-turn: WARNING: workspace '<tmp>' is not trusted; Claude may ignore project permissions. Run Claude Code interactively in this directory and accept the trust dialog, or set projects['<tmp>']["hasTrustDialogAccepted"] to true in /Users/noelsaw/.claude.json.
  PASS: --dry-run leaves no run log (nothing ran, so nothing is narrated)

  gh388-run-log-durability: 5 passed, 9 failed
```

## POST-FIX — same file, same assertions, green

```
== test: gh388-run-log-durability ==
  workdir: <tmp>
-- A: one registry, two readers, same verdict
  PASS: the registry file exists (non-durable-log-roots.conf)
  PASS: the Bash and Python readers agree on every probe path
  PASS: a path inside the repo's own relay-system is durable
  PASS: /tmp is classified non-durable
  PASS: the registry is genuinely read at runtime (an invented entry changes the verdict)
-- B: a misconfigured archive root refuses, rather than quietly writing to volatile storage
  PASS: python lane REFUSES on an unusable archive root (exit 5)
  PASS: the refusal names WHY the root did not resolve (the resolver's stderr is no longer swallowed)
  PASS: bash lane REFUSES on the same input (exit 5)
  PASS: a healthy default (no XYZ_ARCHIVE_ROOT) still resolves: relay-system/logs/2026-08-11/agy-turn-T-1-34296.log
  PASS: and it resolves under the repo's own relay-system, unchanged
-- C: kill a phase mid-run; assert what survives
  PASS: the phase reached dispatch, so the kill below lands mid-run
  PASS: the killed phase left a record (PHASE-INTERRUPTED.md)
  PASS: the record names the phase id
  PASS: the record carries the relay state at interruption
  PASS: the record names a reason
  PASS: the record is non-empty
  PASS: the record was written after the phase began (not pre-created)
-- D: the chain run log survives a chain that never finishes
  PASS: the chain announced its run log at start (acceptance: the operator must know where to look)
  PASS: the announced path is parseable: relay-system/run-logs/2026-08-11/marathon-PLAN_-163639-37828.log
  PASS: the run log lives under the same transcript root as the per-phase transcripts
  PASS: the run log still exists after the chain was killed
  PASS: the run log is non-empty
  PASS: the run log carries the chain narrative (the phase heading), not just a header
  PASS: --dry-run leaves no run log (nothing ran, so nothing is narrated)

  gh388-run-log-durability: 24 passed, 0 failed
```
