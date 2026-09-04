# Red control — GH-414 comment-reference check

Observed pre-fix shape: `src/events.js` cited
`decisions/2026-06-18-epoch-fencing.md` and
`decisions/2026-07-01-cross-agent-dep-conflict.md`. Both files existed in the source tree, but the
launch-artifact build dropped `decisions/`, so the shipped copies of those comments pointed at absent
files. The source-only governance scan stayed green because it never inspected comments or the built
artifact.

The executable red control in `test/gh414-comment-reference-check.sh` reproduces that exact split:
the source fixture retains both ADRs, the artifact fixture drops them, and `pdda.sh governance` must
fail with one comment-reference finding per citation. Restoring both files makes the same invocation
pass; adding a new nonexistent source-comment reference fails independently.
