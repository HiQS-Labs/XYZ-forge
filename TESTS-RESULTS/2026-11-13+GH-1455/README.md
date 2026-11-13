# GH-1455 evidence: shebang for `pdda_fn.sh`

Manual check (AGENTS.md *No new tests*, GH-831): the repo's own shellcheck scan, run before and after the
one-line fix. Nothing new is added to any suite.

The scan is the exact command from `ci-local.sh` (`shellcheck_tracked`), shellcheck 0.11.0, base
`37ca5e0d272c04fd2a9cd02ef4b0cfd1bbf5d2c8`:

```
git ls-files -z -- '*.sh' | xargs -0 -P 4 -n 1 shellcheck -S error
```

| Run | Tree | Result |
|---|---|---|
| `shellcheck-before.log` (red control) | base, unfixed | exit 1: one finding, `TESTS-RESULTS/2026-11-04+GH-1344/pdda_fn.sh` line 1, SC2148 (no shebang), out of 656 tracked `.sh` files |
| `shellcheck-base-blob.log` (red control, one file) | the unfixed file extracted from the base commit | `shellcheck -S error` exit 1, SC2148 |
| `shellcheck-after.log` | base plus the fix | exit 0, no findings, 656 tracked `.sh` files |

Also checked: `bash -n` on the fixed file passes; the recorded invocation uses bash
(`TESTS-RESULTS/2026-11-04+GH-1344/provenance.jsonl` records `bash pdda_fn.sh <tree> <fixture> 1292`), the file
mode is 644 and its body is unchanged; no file in `TESTS-RESULTS/2026-11-04+GH-1344/` records a hash of it;
before this fix it was the only tracked `.sh` without a shebang, and none remain.

The scan covers the same files and flags as the hosted job (`.github/workflows/ci.yml`, "Shellcheck tracked
shell scripts"), but the hosted steps are skipped on a docs-only route. By `utils/ci-route.sh:65` every file in this change is a
docs surface (`TESTS-RESULTS/*`, `*.md`, `PROJECT/*`), so the configured behavior is that they are skipped for
this PR too; their actual outcome here was not checked. The full `ci-local.sh` was not re-run: the only step that failed in the GH-1452 run was this scan.

Not done, by decision: running shellcheck on changed `.sh` files at pre-push is paused and documented in
`PARKED/2026-11-13-pre-push-shellcheck.md`.
