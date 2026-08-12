# GH-509 Phase 3 — recorded negative control: pushes are routed, and renames cannot escape

Per #419, a check never observed failing is not evidence.

| Mutation | Assertion that fired | Result |
|---|---|---|
| `push` moved back onto the unconditional-full branch (pre-fix behaviour) | docs-only push uses the docs gate | 1 failure |
| rename guard fed the DEFAULT rename-detecting diff | a renamed regression test selects full | 1 failure |
| `--no-renames` removed from the workflow's collection command | workflow must use `--no-renames` | fired (+1 collateral, see below) |
| *(none — restored)* | — | `ci-route` **23/0**, `ci-workflow` **40/0** |

## The rename control demonstrates the defect rather than describing it

The classifier is not where the bug lives. `ci-route.sh` behaves correctly for whatever paths it is
handed; the defect is in **which paths it is handed**. So this control drives a real `git mv` through
the exact command the workflow runs:

```
$ git diff --name-only $BASE HEAD        # git's default: rename detection ON
test/new-regression.sh                    # the SOURCE path is invisible
$ git diff --no-renames --name-only $BASE HEAD
test/new-regression.sh
test/old-regression.sh                    # only this surfaces the removal
```

With the source path hidden, a renamed regression test reads as an ordinary changed file that still
exists, so `ci-route.sh`'s fail-closed branch is never reached — while that branch's own comment says
*"A deleted/renamed regression cannot be exercised as a changed-area test."* Deletion reached it;
rename never did.

A first assertion is recorded as pinning this: `control: plain --name-only reports ONE path for a
rename`. If a future git changes that behaviour, the guard's premise is stale and this line says so
rather than the guard silently becoming decoration.

## Both directions, so the rule is not a blanket

The reverse case is asserted too: the same fixture with the file merely **edited** must *not* be
forced to full. A guard that routed every `test/*.sh` change to full would pass the rename case for
entirely the wrong reason and quietly restore the burn Phase 3 exists to remove.

## Two mistakes of mine, recorded because they nearly shipped

**1. `git checkout --` destroyed the new tests.** Undoing a mutation with `git checkout -- test/ci-route.sh`
restored **HEAD**, not the pre-mutation state — and the file had uncommitted work, so the entire new
block vanished. It was noticed only because the restored run reported the *old* pass count. Every
control here now uses a file backup (`cp … "$TMPDIR/…"`) instead. Same class as a tree-wide `git stash`
in a repo with concurrent agents: a git-level undo is the wrong instrument for a working-tree
experiment.

**2. A dropped `cd` made the reverse assertion fail.** `ci-route.sh` resolves `[[ -f "$path" ]]`
against the working directory, which is the whole mechanism under test. Run from the harness root,
*every* fixture path looks vanished — so the rename case would have passed for the wrong reason and
the edit case failed outright. Both fixture invocations now run with the fixture as CWD, and the
reason is in a comment so it is not re-derived.

## Collateral on the third mutation, stated

Removing `--no-renames` also trips *"workflow delegates routing to the tested classifier"*, because
that assertion matches the full call line. Both failures are correct; the mutation is broader than
either assertion. Reported as two rather than smoothed to one.

## The fixture tripped `path-integrity.sh`, and the exemption has its own control

The full suite caught something the targeted runs could not: `test/path-integrity.sh` scans every
tracked script for path-like tokens and requires them to resolve. `test/old-regression.sh` and
`test/new-regression.sh` exist only inside a `mktemp` repo at runtime, so it reported them as broken
references.

Added to that file's documented `fixture_literals` allowlist, with the reason recorded alongside the
eleven entries already there. The justification is specific rather than "it's a test": **the rename
must be real.** The defect being pinned is that `git diff --name-only` reports only a rename's
destination — no hand-written path string reproduces that, only `git mv` does. Both names can never
exist in this tree, so the exemption cannot mask a real path break.

**The exemption was then controlled, because an allowlist that quietly became a blanket would disarm
the check for this whole file.** Injecting a *different* non-existent path into the same script:

```
broken path reference 'test/genuinely-missing-file.sh' in test/ci-route.sh
FAIL: one or more referenced paths do not exist
```

Still caught. The two exempted names are exempt; the file is not.

## One pre-existing assertion was updated, not deleted

`require_marker "utils/ci-route.sh pull_request"` pinned a literal that Phase 3 legitimately changed —
the call is now `utils/ci-route.sh "$EVENT_NAME"` because pushes are classified too. The invariant it
protects is unchanged and still asserted: routing is delegated to the tested classifier rather than
reimplemented inline in YAML, where it would have no test at all.
