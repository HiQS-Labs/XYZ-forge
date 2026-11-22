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
bash TESTS-RESULTS/2026-11-21+GH-1576/check.sh green 438cb57eb <task-clone> <this-dir>
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
| jog `publish_jog_receipt(..., push=True)` (real call; only the Marathon-result and gate-receipt validators are stubbed) | pushed, no hook | refused, ref unchanged | pushed, hook invoked |
| jog `_require_gate_wired` guard | no guard exists | refused; refused when the installer is missing | allowed; installer missing + vendored layout (`XYZ_VENDORED=1`) keeps the host's policy (allowed) |
| express recovery recipe (`SKILL.md`, its own lines extracted verbatim and run in a fresh clone) | pushed from an unwired clone, no hook | wiring lost after the recipe's install step: stops (rc 1) before the push, ref unchanged | recipe on a fresh clone installs the hook, then pushes, hook invoked |
| express closeout push | pushed, no hook | refused (exit 4), ref unchanged | pushed (see limit 2) |
| express closeout: refuse, install, retry with the same `extra_paths` (plan QA F4) | pushed at once | first call refused with nothing committed and the receipt still dirty, origin unchanged | retry after `githooks/install.sh` publishes the same transaction |

## Limits, stated plainly

1. Runs that say "hook invoked" set `XYZ_SKIP_PREPUSH=1`, so they prove the stub was run by git, not
   that a gate passed. `real-gate.log` is one run without it: kickstart `checkpoint --push` from a
   wired clone. The real hook ran and refused the push (`gate-attempt: REFUSED — task qualification
   has no attempt reservation`), so the hook is live and enforcing; a full-gate pass is exercised by
   this task's own push instead.
2. Express's own landing push sets `XYZ_SKIP_PREPUSH=1` by lane design, so its wired control is
   wiring evidence only, as the plan said.
3. The `publish_jog_receipt` witness stubs `_validate_marathon_result` and `gate_receipt.check_receipt`
   (a full approved Marathon result is out of scope here); staging, the evidence commit, the guard and the
   push are the real code.
4. Plain `git push` typed by hand is outside this change and unchanged.
5. In the recipe's "lost wiring" green row the hook count is 1, not 0: the recipe line that deletes the stub
   runs `git rev-parse --git-path hooks/pre-push`, and `GIT_TRACE` prints that command. No hook ran: the push was
   never attempted and the origin ref did not move.
6. `focused-suites.log`: the existing suites for the changed files (no new tests); `full-gate.log` (when
   present): `./validate.sh` from a disposable full clone at the stated revision.
