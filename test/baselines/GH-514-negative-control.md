# GH-514 — recorded negative control (#419)

Test:     `test/gh514-write-set-trackable.sh` (TEST_SOFT_FAIL=1)
Baseline: `55f1c626d5a3608f2aff7260cc8d39051fb14949` — `utils/py/marathon_drive.py` without `preflight_write_set_trackable`
Date:     2026-08-11

**Read the exit codes, not the pass count.** The pre-fix tree ALSO fails on a hostile target —
that is the whole problem — so an exit-code assertion would pass against the defect and prove
nothing. What changed is WHEN the refusal happens, so the assertion that moves is the one
counting builder dispatches. In the pre-fix run below a turn is dispatched and paid for
before the run falls over; after the fix, zero.

## PRE-FIX — the control is OBSERVED failing

```
== test: gh514-write-set-trackable ==
  workdir: <tmp>
-- case 1: the target gitignores marathon-system/
  PASS: the hostile target is refused (exit 1)
  PASS: guard: no builder turn was dispatched before the refusal
  FAIL: GH-514: the run died with an unhandled Python traceback instead of a refusal — the driver knows what is wrong and is not saying it. Output: The following paths are ignored by one of your .gitignore files:
marathon-system
hint: Use -f if you really want to add them.
hint: Disable this message with "git config set advice.addIgnoredFile false"
Traceback (most recent call last):
  File "~/Documents/GH Repos/xyz-3-agents-swarm/utils/py/marathon_drive.py", line 2262, in <module>
    main()
    ~~~~^^
  File "~/Documents/GH Repos/xyz-3-agents-swarm/utils/py/marathon_drive.py", line 1955, in main
    subprocess.run(["git", "-C", root, "add", "--", relay_file], check=True)
    ~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.6/Frameworks/Python.framework/Versions/3.14/lib/python3.14/subprocess.py", line 578, in run
    raise CalledProcessError(retcode, process.args,
                             output=stdout, stderr=stderr)
subprocess.CalledProcessError: Command '['git', '-C', '<tmp>', 'add', '--', '<tmp>']' returned non-zero exit status 1.
  FAIL: GH-514: the refusal does not identify itself — output was: The following paths are ignored by one of your .gitignore files:
marathon-system
hint: Use -f if you really want to add them.
hint: Disable this message with "git config set advice.addIgnoredFile false"
Traceback (most recent call last):
  File "~/Documents/GH Repos/xyz-3-agents-swarm/utils/py/marathon_drive.py", line 2262, in <module>
    main()
    ~~~~^^
  File "~/Documents/GH Repos/xyz-3-agents-swarm/utils/py/marathon_drive.py", line 1955, in main
    subprocess.run(["git", "-C", root, "add", "--", relay_file], check=True)
    ~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.6/Frameworks/Python.framework/Versions/3.14/lib/python3.14/subprocess.py", line 578, in run
    raise CalledProcessError(retcode, process.args,
                             output=stdout, stderr=stderr)
subprocess.CalledProcessError: Command '['git', '-C', '<tmp>', 'add', '--', '<tmp>']' returned non-zero exit status 1.
  PASS: the refusal names the path that cannot be tracked
  FAIL: GH-514: the refusal does not name WHICH rule matched — an operator cannot act on it
  FAIL: GH-514: the refusal gives no remedy
  PASS: the target's .gitignore was left alone (non-goal: no silent auto-repair)
-- case 2: the same fixture WITHOUT the hostile rule still dispatches
  PASS: a trackable target still dispatches its builder turn (2)
  PASS: the healthy target is not reported as blocked
-- case 3: a rule in .git/info/exclude is honoured too
  FAIL: GH-514: a .git/info/exclude rule was missed — the check is reading .gitignore itself instead of asking git. dispatches=0
  FAIL: GH-514: the refusal did not name .git/info/exclude as the source

  gh514-write-set-trackable: 6 passed, 6 failed
```

## POST-FIX — refused before any turn is dispatched

```
== test: gh514-write-set-trackable ==
  workdir: <tmp>
-- case 1: the target gitignores marathon-system/
  PASS: the hostile target is refused (exit 2)
  PASS: guard: no builder turn was dispatched before the refusal
  PASS: the run refuses cleanly — no unhandled traceback
  PASS: the refusal says it happened before dispatch
  PASS: the refusal names the path that cannot be tracked
  PASS: the refusal names the ignore rule (file:line:pattern) that matched
  PASS: the refusal names the remedy
  PASS: the target's .gitignore was left alone (non-goal: no silent auto-repair)
-- case 2: the same fixture WITHOUT the hostile rule still dispatches
  PASS: a trackable target still dispatches its builder turn (2)
  PASS: the healthy target is not reported as blocked
-- case 3: a rule in .git/info/exclude is honoured too
  PASS: an exclude-file rule is caught too (git check-ignore is the authority, not a .gitignore parser)
  PASS: and it names the exclude file as the matching source

  gh514-write-set-trackable: 12 passed, 0 failed
```

## Case 4 — negation false positive (added with the gitignore-negation fix)

`git check-ignore -v` exits **0 whenever any pattern matched**, including a negation that
re-includes the path. The original guard read exit 0 as "ignored", so a path git will happily track
blocked the marathon before dispatch and sent the operator to fix a rule that was already correct.

Reproduced directly against `git add`, which is the authority the guard is trying to predict:

| `.gitignore` | `check-ignore -v` | `git add` |
|---|---|---|
| `*.log` | rc=0, prints the rule | **refuses** — genuinely ignored |
| `!logs/keep.log` | rc=0, prints the `!` rule | **accepts** — re-included |
| (no matching rule) | rc=1, no output | accepts |

Row 2 is the defect: identical exit status to row 1, opposite meaning. Git reports the LAST matching
rule (last-match-wins), so the fix inspects that pattern and skips when it is a negation.

**Control observed.** With `utils/py/marathon_drive.py` reverted to the pre-fix version and the new
case 4 in place:

```
FAIL: GH-514 false positive: a path re-included by a negation rule was blocked; git can track it,
      so the run was refused over a rule that is already correct
```

Restored: **14 passed, 0 failed**.

**Case 4 carries its own anti-vacuity half.** "Does not block" would also pass if the guard were
simply disabled, so a second fixture puts the negation FIRST and re-ignores afterwards
(`!marathon-system/**` then `marathon-system/**`) — last-match-wins makes that path genuinely
ignored, and it must still block. Both halves were verified against `git add`'s actual behaviour
rather than inferred from the exit code, which is the mistake that produced the bug.
