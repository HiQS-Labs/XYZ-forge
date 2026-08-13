# GH-520 — recorded negative control: the CODEX_BIN probe trap

Per #419, a check never observed failing is not evidence. This records the control being **observed
in both directions**, on this machine, rather than asserted.

The condition under test is not a code change — it is an *environment*. `marathon_drive.py:334`
probes the reviewer binary (`CODEX_BIN`, default `codex`) before the guards, the preflight, or any
dispatch. A fixture that stubs only the builder therefore runs the probe instead of the code it was
written for. It passes on a developer machine, where a real `codex` is installed, and fails on
ubuntu CI, where none is.

## Reproducing the CI condition locally

No CI run needed. Strip the directory holding `codex` from `PATH`:

```bash
STRIPPED="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v '^/Users/<user>/.local/bin$' | paste -sd: -)"
PATH="$STRIPPED" bash test/gh402-branch-enforcement.sh
```

`command -v codex` must return nothing before the run — the control script asserts this and aborts
otherwise, so a control that silently ran under the *unstripped* PATH cannot be mistaken for a pass.

## Direction 1 — pre-fix, codex OFF PATH: all three RED

Test files stashed to their pre-fix state, same commit otherwise:

```
control condition OK: codex NOT on PATH

gh402-branch-enforcement    rc=1
    FAIL: GH-402: the refusal does not name the branch
          — got: marathon-drive: reviewer binary 'codex' not found on PATH (--reviewer agent 'codex')
gh514-write-set-trackable   rc=1
    FAIL: GH-514: the refusal does not identify itself
          — output was: marathon-drive: reviewer binary 'codex' not found on PATH (--reviewer agent 'codex')
gh388-run-log-durability    rc=1
    FAIL: part C did not reproduce: the phase never reached dispatch, so nothing was killed mid-run.
```

These are **byte-identical to the three failures on GitHub Actions run 31565898558** (`4baedb6d`,
branch `development`). The local control reproduces CI exactly, which is what makes it a control
rather than a similar-looking failure.

## Direction 2 — post-fix, codex OFF PATH: all three GREEN

```
control condition OK: codex NOT on PATH

gh402-branch-enforcement    rc=0   13 passed, 0 failed
gh514-write-set-trackable   rc=0   12 passed, 0 failed
gh388-run-log-durability    rc=0   24 passed, 0 failed
```

## Direction 3 — post-fix, codex ON PATH: still green

The half that is easy to skip. A "fix" that traded a CI failure for a local one would be no fix:

```
  gh402-branch-enforcement: 13 passed, 0 failed
  gh514-write-set-trackable: 12 passed, 0 failed
  gh388-run-log-durability: 24 passed, 0 failed
```

## Direction 4 — the release gate, under the CI condition

`gh388` and `gh514` are two of the five lifecycle cases `test/nightwatch-release.sh` **executes**, so
the Nightwatch RC claim depended on this environment:

```
PATH="$STRIPPED" bash test/nightwatch-release.sh --release-gate

manifest: 8 complete, 0 remaining, 0 false completion claim(s)
lifecycle: 5 passing, 0 failing, 0 NOT COVERED
GOALPOST MET — all 8 manifest entries complete and every lifecycle case executes green
```

Before the fix, that same command under the same condition would have reported two failing lifecycle
cases. The RC evidence was true on macOS and false on ubuntu; it is now true on both, and this is the
run that says so.

## The failure direction that is not covered, stated

`gh514` asserts on the **absence** of a Python traceback. A run that dies at the probe also produces
no traceback, so under a different arrangement that assertion could pass for entirely the wrong
reason — failing *open* rather than closed. All three instances here failed closed, and nothing in
the design guarantees the next one will. That is the general defect #520 is filed for, and it is
**not** fixed by the three stubs recorded above.
