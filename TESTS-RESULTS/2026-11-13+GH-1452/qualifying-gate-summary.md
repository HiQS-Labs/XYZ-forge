# Qualifying gate: `ci-local.sh` on the final approved commit

Route: `full` (tier 3, kernel/gate surface: `skills/*/merge-cleanup/` scripts and SKILL.md), from
`utils/ci-route.sh pull_request` over `git diff --name-only 6c0c76bb5 HEAD`.

Run once, in a disposable full clone, after final Codex QA was Approved:

- Command: `bash ci-local.sh --base 6c0c76bb5`
- Commit: `7ac2ccf901858f2f210ed613034126c462821296`, the relay attestation commit on top of the approved
  `463522042b35`. Commits after it change only this evidence folder.
- Clone identity before and after: same HEAD, same origin, clean tree. The runner envelope reported
  `clean — identity, tracked tree, worktrees, and driver lock unchanged under ci-local.sh`.
- Wall time: 2026-11-13T19:09:27Z to 20:13:36Z (about 64 minutes). Full log: `ci-local-final.log.gz`
  (17,084 lines, home paths redacted).

## Result: 9 of 10 steps passed, 1 failed, exit 1

| Step | Result |
|---|---|
| prerequisites, bash syntax, node syntax, settings JSON | pass |
| PDDA deterministic gate | pass (zero errors) |
| frozen twin guard | pass |
| `npm ci` + acorn-extract | pass |
| `validate.sh` suite | pass |
| clone-identity invariant (GH-1) | pass |
| **shellcheck tracked scripts** | **FAILED** |

The one failure is not in anything this branch touches:

```
In TESTS-RESULTS/2026-11-04+GH-1344/pdda_fn.sh line 1:
# usage: pdda_fn.sh <tree> <fixture_root> <issue>
^-- SC2148 (error): Tips depend on target shell and yours is unknown. Add a shebang or a 'shell' directive.
```

- `git diff --name-only 6c0c76bb5 HEAD -- TESTS-RESULTS/2026-11-04+GH-1344` lists zero files: the file is unchanged by this branch.
- The same file extracted from the base commit `6c0c76bb5` fails the same rule when run through the local
  `shellcheck` directly (SC2148, no shebang).
- Correction (GH-1455, 2026-11-13): an earlier version of this note said hosted CI was green, so the local
  run flagged a file the hosted job does not. That was wrong. The hosted job runs the same check on the same
  files (`.github/workflows/ci.yml`, `git ls-files -- '*.sh'` with `shellcheck -S error`), but its shellcheck
  steps are skipped on a docs-only route. On the latest two `development` runs (43504181832 and 43505530482)
  both shellcheck steps show `skipped`, so green meant the check did not run, not that it passed. And
  `utils/ci-route.sh:65` counts `TESTS-RESULTS/*` as a docs surface, so a script committed there never reaches
  the hosted scan; only `ci-local.sh` scans every tracked `.sh`. The file would fail the hosted job on any
  non-docs push.

This gate is therefore **not green**, and it is not claimed as green. The failure pre-exists on the base,
is unrelated to merge-cleanup, and was left unfixed in the GH-1452 PR: the repair would edit a committed
evidence file from another issue (GH-1344), outside that change's scope. It was reported in that PR as a
remaining limitation and tracked as GH-1455, and it is fixed there by adding a shebang to `pdda_fn.sh` (the
same fix as #121 for `utils/fuzzing/fuzz-loop.sh`). Evidence: `TESTS-RESULTS/2026-11-13+GH-1455/`.
