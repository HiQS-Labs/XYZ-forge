# GH-520 — recorded negative control

Change: `test/_setup.sh` exports a default `CODEX_BIN` stub.
Suite: `test/gh520-default-reviewer-stub.sh` (11 pass / 0 fail)
Recorded: 2026-08-14, macOS, branch `fix/critical-2026-08-14`

## The problem this control had to solve

The obvious control does not work, and that is worth stating because it looks like the change is
unfalsifiable until you find the right lever.

`marathon_drive.py` probes the reviewer binary before anything else, and `--reviewer codex` is the
default in essentially every marathon fixture. GH-520's evidence is three suites — `gh402`,
`gh514`, `gh388` — that read the probe's message instead of their subject on a machine with no
`codex`. But **all three were individually stubbed by commit `6ae068b8`**, which repaired the
instances and not the class. So with `codex` stripped from PATH they pass identically with and
without the new default: their own stubs carry them.

Two other unstubbed fixtures (`gh384-crash-recovery`, and `gh402` with its stub intact) were also
observed passing both ways. **A default that protects only future fixtures cannot be observed on
today's suites**, which under #419 would make it not-evidence.

## The control that does work

Remove `gh402`'s **own** stub, so it depends on the shared default, and reproduce the CI condition
by excluding only the directory containing `codex` from PATH (excluding more removes `node` and
produces an unrelated failure).

**A — own stub removed, shared default present, `codex` absent:**

```
gh402-branch-enforcement: 13 passed, 0 failed
```

**B — own stub removed AND the shared default removed (the pre-fix world):**

```
FAIL: GH-402: the refusal does not name the branch
      — got: marathon-drive: reviewer binary 'codex' not found on PATH (--reviewer agent 'codex')
```

That failure is **character-for-character** the one GH-520 records from the 2026-08-11/12 CI runs:
a plausible, on-topic, completely false assertion failure, produced by a run that died at the probe
and never reached the code under test.

Both files restored after the run; `grep -c 'export CODEX_BIN'` returns 1 for each.

## Why the shape is a default and not another comment

GH-232 recorded this exact trap in a `ci.yml` comment. It recurred three times anyway. The finding
in GH-520 is not "stub the binary" — it is that a written warning did not prevent its own
recurrence, so the fix has to be a default in the one file every fixture already sources.

## Honest limits

- This proves the default is **load-bearing for a fixture that lacks its own stub**. It does not
  prove any *currently shipping* suite depends on it — by construction, the three known instances
  no longer do. Its value is for the next fixture, and that is why the control had to be
  constructed by removing an existing stub rather than found.
- The companion assertions in the suite (`missing reviewer binary exits 2`, and that
  `_probe_agent_bin` is still wired) exist because a default stub is otherwise indistinguishable
  from deleting the GH-117 protection. Those are grep-level assertions over `test/marathon-drive.sh`
  and `utils/py/marathon_drive.py`, not executions.
