# Run shellcheck on changed `.sh` files at pre-push (paused)

Decision (operator, 2026-11-13): **paused, not built.** Recorded here so the question does not resurface
as a new finding.

## Question

A shebang-less script (`TESTS-RESULTS/2026-11-04+GH-1344/pdda_fn.sh`) reached `development` and was only
caught at the final qualifying gate (`ci-local.sh`, GH-1455), eight days after it was added (2026-11-05). Should
`githooks/pre-push` also run `shellcheck -S error` on the `.sh` files a push changes, so the same class is
caught at push time?

## Why it is paused

- Two occurrences in about three months: `utils/fuzzing/fuzz-loop.sh` (fixed in #121, described in the
  `.github/workflows/ci.yml` header) and `pdda_fn.sh` (fixed under GH-1455, introduced in `0dc1d25fb` on
  2026-11-05). Before the fix it was the only tracked `.sh` without a shebang (656 tracked `.sh` files);
  none remain.
- The guard itself works. `ci-local.sh` `shellcheck_tracked` and the hosted `Shellcheck tracked shell
  scripts` step run the same scan; the local one caught this file.
- The gap is timing, not coverage. Neither `githooks/pre-push` nor `validate.sh` scans the repository's
  tracked scripts (`validate.sh:301` registers only `test/gh365-shellcheck-parallel.sh`, a census suite that
  runs shellcheck on its own scratch corpus). The hosted shellcheck steps are skipped on a docs-only route,
  and `utils/ci-route.sh:65` counts `TESTS-RESULTS/*` as docs, so a script committed there never triggers
  them; only `ci-local.sh` scans every tracked `.sh`.
- AGENTS.md *No new tests* (GH-831) bars new gate machinery without an operator decision, and a hook
  step would be exactly that.

## Cheapest form if revisited

One `git diff --name-only --diff-filter=AM <range> -- '*.sh'` piped to `shellcheck -S error` in
`githooks/pre-push` (seconds, no new suite). Do not exclude `TESTS-RESULTS/` from the scan and do not set a
global `shell=bash`: both would hide the missing-shebang warning that exposed `fuzz-loop.sh`.

## Trigger to revisit

A third shebang-less script lands after the GH-1455 fix, or another gate surprise appears only at the final
qualifying run. Owner of the decision: the operator.

Source: GH-1455 and its correction comment. Not a task, issue or roadmap row.
