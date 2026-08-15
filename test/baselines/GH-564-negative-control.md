# GH-564 — negative control

Recorded 2026-08-15. Per GH-419: a check never observed failing is not evidence.

## The field report this comes from

A peer session found the **shared clone's** `origin` rewritten to this suite's throwaway bare repo:

```
$ git -C "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm" remote -v
origin  /var/folders/.../T//gh544-prepush.1PlVmM/bare.M2KszU (fetch)
origin  /var/folders/.../T//gh544-prepush.1PlVmM/bare.M2KszU (push)
```

Every `git push`, `git fetch` and `git ls-remote` in that clone was silently addressing a fixture.
The peer's pushes failed loudly (`does not appear to be a git repository`) — the *quiet* version is a
fetch that reports success against the wrong repository.

## The mechanism — not a missing `-C`

Every call in the file already passed `-C "$r"`. Both escapes are silent no-ops on an **empty**
string, and the file runs without `set -e`:

- `git -C "" …` — documented: *"if `<path>` is present but empty … the current working directory is
  left unchanged"*
- `( cd "" && git push … )` — `cd ""` is a bash no-op; the subshell stays in the caller's directory

Directly demonstrated on a stand-in repo before writing the fix:

```
victim origin BEFORE: https://example.com/real.git
$ r=""; git -C "$r" remote set-url origin "$b"
victim origin AFTER:  /…/scratchpad/emptyc/bare
$ ( cd "$r" && echo "$PWD" )
/…/scratchpad/emptyc/victim        # cd "" did not move
```

Reachability: `mkrepo` did `r="$(mktemp -d "$WORK/repo.XXXXXX")"` with **no guard**, while `$WORK`
itself had been guarded on the line above since day one. A failed `mktemp` — disk full, `TMPDIR`
reaped mid-run, sandbox refusal — yields `r=""`, which flows into `mkremote`, `realpush` and `drive`.
Same family as **GH-177** (a `mktemp` failure resolving to the repo root, feeding a destructive trap).

## Observed RED before the fix

The three `require_fixture` calls removed from `mkremote` / `realpush` / `drive`, suite otherwise
unchanged:

```
  FAIL: empty repo path is REFUSED by mkremote (exit 2), not silently applied to $PWD
  FAIL:   and the caller's real clone keeps its origin
  FAIL: empty repo path is REFUSED by realpush (exit 2) — `cd ""` would push the caller's repo
  FAIL: empty repo path is REFUSED by drive (exit 2)
  FAIL: a REAL repo path outside $WORK is REFUSED (exit 2) — the guard is containment, not a null check
  FAIL:   and that real repo's origin is still untouched
  gh544-pre-push-gate: 72 pass, 6 fail
```

**The load-bearing line is `and the caller's real clone keeps its origin`.** It fails pre-fix, which
means the old code genuinely rewrote a real repository's `origin` inside the run — the reported
incident, reproduced deterministically rather than argued from the source.

## Observed GREEN after the fix

```
  gh544-pre-push-gate: 78 pass, 0 fail
```

## What makes this control discriminating

**72 assertions pass pre-fix.** A guard that simply refused everything would satisfy the six new
assertions and destroy the other 72. The positive control is explicit:

```
  PASS: CONTROL: a legitimate fixture under $WORK is still admitted (exit 0)
  PASS:   and it really did get its bare origin
```

The containment case is the second half. `require_fixture` demands the path exist **and live under
`$WORK`**, not merely be non-empty — so a future edit cannot satisfy these assertions with
`[ -n "$r" ]` while still letting a real path through. The first draft of this block placed the
victim repo *inside* `$WORK`; the guard correctly admitted it and the assertion failed for the wrong
reason. Moving the victim outside `$WORK` is what makes it test containment rather than nullness.

## Not fixed here

A count across `test/*.sh` finds **32 files** that assign a `mktemp -d` result and pass a variable to
`git -C "$…"`. Whether any of the other 31 can reach an empty value is unaudited. Tracked separately;
this baseline covers `gh544-pre-push-gate.sh` only.
