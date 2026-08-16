# GH-544 negative control — `test/gh544-pre-push-gate.sh`

Recorded 2026-08-14. Per #419: a check never observed failing is not evidence.

Fixed tree: **63 pass, 0 fail.** (38 at first record; +25 from GH-549, below.)

## A — the pre-fix closeout conflates "no checks configured" with "checks failed"

`relay-automation/marathon-closeout.sh` restored to its pre-fix semantics — any non-zero
`gh pr checks` exit treated as failure:

```
FAIL: zero configured checks does NOT refuse the merge (prose fallback)
FAIL:   and says it is merging WITHOUT CI rather than staying silent
FAIL:   and names GH-544 so the reason is findable
FAIL: an empty --json bucket is accepted as no-checks even if the PROSE changes
FAIL:   and says which signal it used
33 pass, 5 fail
```

**The discriminating assertion is the first one**, and note what did *not* fail: *"a genuine check
FAILURE still refuses the merge (exit 4)"* stayed green under the pre-fix code, because the pre-fix
code refused everything. A suite that reddened both would not be telling the two states apart — it
would just be detecting "something changed." This is the property that matters: with hosted CI off,
every PR has zero checks, and the pre-fix branch made automated closeout unable to merge anything
ever again.

### Recorded failure of the first attempt at this control

The first version of Control A replaced the whole block with text containing a quoting error, which
removed the `_checks_out=` anchor the suite's `extract_block` keys on. `eval` then ran an empty
string and every case trivially returned 0, producing **5 failures that looked like a working
control** — including "a genuine check FAILURE still refuses", which should have stayed green.

It is recorded because the misleading result was *plausible*: a red control feels like proof. What
gave it away was a failure that should not have been possible under the pre-fix code. A control that
reddens the wrong assertions is not a weaker control, it is a false one.

## B — THE CONTROL THIS SUITE DID NOT HAVE UNTIL A CROSS-MODEL REVIEW FOUND THE BUG

`relay-automation/marathon-closeout.sh`: the capture moved back OUTSIDE the `if`, i.e.
`_checks_out="$(gh pr checks ...)"; _checks_rc=$?` — the shape the first version of this fix shipped.

```
FAIL: zero configured checks does NOT refuse the merge (prose fallback)
FAIL:   and says it is merging WITHOUT CI rather than staying silent
FAIL:   and names GH-544 so the reason is findable
FAIL: an empty --json bucket is accepted as no-checks even if the PROSE changes
FAIL:   and says which signal it used
FAIL: a NON-empty --json bucket with a failure still refuses (exit 4)
FAIL: a genuine check FAILURE still refuses the merge (exit 4)
FAIL:   and says checks are not green
FAIL:   and echoes gh's own output so the failure is visible
29 pass, 9 fail
```

**This suite previously reported 35 pass / 0 fail against that exact broken code.** The script runs
under `set -euo pipefail`, so a failing `var="$(cmd)"` exits immediately and `_checks_rc=$?` never
runs — the entire no-checks branch was unreachable **dead code in production**. The harness passed it
because it `eval`'d the block without `set -e`: it was running the code under gentler options than
production, which is not testing production.

Verified independently before fixing:
`bash -c 'set -euo pipefail; _o="$(bash -c "exit 1")"; _r=$?; echo REACHED'` prints nothing, exit 1.

Found by a Codex consult, not by this suite. Recorded prominently because the lesson generalises past
this fix: **a green suite is evidence only about the environment the suite creates.** The harness now
runs the extracted block under the production shell options, and this control is what keeps it honest.

The extraction also moved from a `sed` line-range to explicit `# >>> GH-544 checks-gate BEGIN/END`
sentinels — the range stopped at the first `fi` once the block grew a second one, silently truncating
what was under test.

## C — the hook fails OPEN on a red gate

`githooks/pre-push`: final `exit 1` → `exit 0`.

```
FAIL: a red gate refuses the push (exit 1)
FAIL: a MIXED delete+real push is still gated (exit 1)
36 pass, 2 fail
```

The second failure is the one worth having. Without it, appending a branch deletion to a push would
be an undocumented bypass — the delete-skip is a legitimate carve-out that must not widen into
"any push containing a delete is unchecked."

## D — the bypass stops announcing itself

`githooks/pre-push`: the `XYZ_SKIP_PREPUSH` message changed to `(silently skipped)`.

```
FAIL:   and says loudly that nothing was verified
37 pass, 1 fail
```

**Exactly one assertion.** A skipped gate that says nothing is indistinguishable from a passing one,
and this is the whole reason the bypass prints to stderr rather than exiting quietly.

## E — `ci.yml`'s push trigger comes back

`push: branches: [main, development]` re-added.

```
FAIL: ci.yml has no push: trigger
37 pass, 1 fail
```

**Exactly one assertion**, and it is the one that costs money. An accidental re-arm is not a
hypothetical: it is a two-line edit, and the invoice arrives weeks later.

## Restored

All files restored from copies; re-run clean at **38 pass, 0 fail** in the same session, so these are
not an always-red detector passing for precise ones. Controls A/C/D/E were re-run against the final
code after the review fixes landed; the counts above are from that final run.

## Honest limits

0. **RESOLVED BY MEASUREMENT — and it corrected the design's own description.** Observed against a
   real check-less PR (#545, gh 2.96.0), both forms behave identically:

   ```
   $ gh pr checks 545                 -> "no checks reported on the '...' branch"   exit 1
   $ gh pr checks 545 --json bucket   -> "no checks reported on the '...' branch"   exit 1
   ```

   **`--json bucket` does not return `[]` for this state**, so the structured signal a cross-model
   review recommended as "primary" does not fire at all — the **prose match is what actually carries
   it**. The implementation was already correct because the fallback was kept, but the comments
   described the wrong branch as load-bearing until this was run. The `[]` branch stays as
   forward-compatibility, and is now labelled as currently-dead rather than as the primary path.

   The general lesson is the reviewer's principle was right (wording is not an API) and its
   application here was still wrong, because gh does not expose this state structurally. A
   recommendation that sounds correct is not evidence either.
2. **The hook is driven with a stub `validate.sh`.** These controls prove the hook's control flow,
   not that the real gate is correct. That is the gate's own suites' job.
3. **Nothing here proves the hook is installed.** The wiring is per clone and not
   version-controlled; a fresh clone has no gate. `githooks/install.sh --check` exists to make that
   detectable, and it is the mitigation, not a fix.

## D — GH-549: the pre-fix wiring pushes UNGATED and SILENT from a branch without `githooks/`

Recorded 2026-08-14, after the defect was observed live rather than predicted: pushing
`chore/ship-litmus-nightwatch` (cut from `development` before the hook landed) printed **no gate
output at all**. `core.hooksPath=githooks` is repo-scoped, not branch-scoped; on a checkout with no
`githooks/` directory git resolves no hook file and runs nothing, with no warning.

The control reproduces the pre-fix wiring exactly and asserts the bug, not the fix:

```
NEGATIVE CONTROL: the pre-fix core.hooksPath wiring pushes UNGATED and silent
  -> git push exits 0 AND the gate's own output ("stub gate ran") never appears
```

Every other GH-544 control drives the hook by **invoking it directly**, which is precisely what this
defect was invisible to: the hook's logic was never wrong — git never dispatched to it. Only a real
`git push` through a real (local bare) remote exercises dispatch. That is why the fix ships with a
real-push harness rather than more direct-invocation cases.

### Recorded failure found BY this suite, not by review

The first implementation resolved the stub's destination with `git rev-parse --git-path hooks`. That
call **obeys `core.hooksPath`** — so while migrating a clone that still had the legacy value set, it
resolved to the in-tree `githooks/` and the installer targeted the very hook it delegates to. It was
caught by the exit code of *"install CLEARS a legacy core.hooksPath=githooks"* (got 4, refusing to
overwrite what it thought was a foreign hook) and is now pinned by an explicit assertion that the
in-tree hook survives migration. Resolution moved to `--git-common-dir`, which ignores the override
and is also what makes one install cover every linked worktree.

### What D still does not cover

A clone that never ran `install.sh` remains ungated, and `git push --no-verify` remains an explicit
escape. Neither is solvable client-side — the hook is the thing that does not run. Closing them
requires a server-side receive policy, which is out of scope while the repo is private.
