# GH-1576 manual red/green check (not a suite, GH-831)

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1576. Plan: `PROJECT/2-WORKING/GH-1576-PREPUSH-HOOK-CHECK.md`.

## What this shows

Every start-task-family push step now runs `bash githooks/install.sh --check` immediately before
pushing and refuses (no push, origin unchanged) when the clone's pre-push stub is not installed.
Merge-cleanup's own landing clone is wired at provisioning. Base revision `3dc703600` (red) pushes
from the same unwired clones with no hook at all.

## How it was run

```
bash TESTS-RESULTS/2026-11-21+GH-1576/check.sh red   3dc703600 <task-clone> <this-dir>
bash TESTS-RESULTS/2026-11-21+GH-1576/check.sh green 23d599435 <task-clone> <this-dir>
```

`check.sh` makes a disposable local bare origin, runs the code under test from its own scratch clone
at the given revision, and drives each changed boundary from fresh clones that never ran
`githooks/install.sh`. Per scenario it records the origin ref before and after, the result,
`install.sh --check` (exit 1 = unwired, 0 = wired, 127 = installer missing), and the number of
`hooks/pre-push` lines in `GIT_TRACE` (2 per hook invocation; 0 = no hook ran). Output:
`red.log`, `green.log`, and one JSON line per scenario in `provenance.jsonl` (label, code revision,
boundary, scenario, result, detail, origin refs, check rc, hook invocations).

## Result (see `provenance.jsonl` for exact values)

| Boundary | Red, unwired clone | Green, unwired clone | Green, after install |
|---|---|---|---|
| kickstart `run_record.py` `checkpoint --push` | pushed, ref moved, no hook | rc 1, refused, ref unchanged | pushed, hook invoked; rerun at same head is a no-op |
| kickstart, `githooks/install.sh` missing | pushed | rc 1, refused | n/a |
| merge-cleanup `push_resolved_head` | pushed, no hook | `ok=False`, ref unchanged | clone from `prepare_landing_clone` is wired by the tool, pushes, hook invoked (red: same clone unwired, pushed with no hook) |
| merge-cleanup post-merge writes push | pushed, no hook | `ok=False`, ref unchanged | pushes, hook invoked |
| jog `JogCheckpoint._push` (publication clone) | pushed, no hook | refused, ref unchanged | pushed, hook invoked |
| jog `_require_gate_wired` guard (also used by `publish_jog_receipt`) | no guard exists | refused; refused when installer missing | allowed |
| express closeout push | pushed, no hook | refused (exit 4), ref unchanged | pushed (see limit 2) |

## Limits, stated plainly

1. Runs that say "hook invoked" set `XYZ_SKIP_PREPUSH=1`, so they prove the stub was run by git, not
   that a gate passed. `real-gate.log` is one run without it: kickstart `checkpoint --push` from a
   wired clone. The real hook ran and refused the push (`gate-attempt: REFUSED — task qualification
   has no attempt reservation`), so the hook is live and enforcing; a full-gate pass is exercised by
   this task's own push instead.
2. Express's own landing push sets `XYZ_SKIP_PREPUSH=1` by lane design, so its wired control is
   wiring evidence only, as the plan said.
3. `publish_jog_receipt` (`jog_run.py:1209`) is covered at guard level only: it needs a full approved
   receipt bundle, and it calls the same `_require_gate_wired` as `_push`, which is driven for real.
4. Plain `git push` typed by hand is outside this change and unchanged.
5. `focused-suites.log`: the existing suites for the changed files (no new tests).
