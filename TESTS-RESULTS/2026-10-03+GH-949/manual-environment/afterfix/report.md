# After-fix K1 / GH-912 selector-envelope controls

Candidate `76ad7e4e1ec64afe4b63383b3dc4e80cd9549a2d` was verified in the disposable `verify` full clone only. The task clone was used solely as the valid ambient selector target (`XYZ_HARNESS` and `XYZ_REPO_ROOT`); no suite ran with task-clone CWD.

## Result

Both existing focused suites passed with the ambient selectors injected into the subprocess environment, then cleared by `runner_envelope_begin` before suite execution:

| Suite | Result | Envelope assertions |
| --- | --- | --- |
| `test/find-harness.sh` | 50 pass, 0 fail | both selectors unset; envelope-owned `XYZ_HARNESS_DB` exists; identity/tree/worktrees/locks clean; scratch and state removed |
| `test/gh396-find-harness-roots.sh` | 41 pass, 0 fail | same assertions |

The existing assertions cover explicit fixture overrides (the first suite's configured override and the second suite's override precedence and invalid-override fallthrough). Thus the after-fix result addresses the false-failure caused by *inherited* caller selectors while retaining per-case override behavior.

The exact suite argv was `python3 utils/py/proc_group.py --timeout 150 -- bash -c <envelope-and-suite wrapper>`, CWD `/Users/noelsaw/task-clones/ate-remediation-20261003/verify`. The wrapper sourced `test/lib/runner-envelope.sh`, called `runner_envelope_begin "$PWD" <label>`, asserted both env names absent and the database under `${TMPDIR:-/tmp}/runner-envelope.*/harnesses.db`, ran the suite, called `runner_envelope_assert`, and called `runner_envelope_scrub`; it checked both scratch paths were gone. The exact wrapper and complete combined stdout/stderr for each run are preserved in `logs/*.json`; the reusable external driver is `run_afterfix.py`.

## Identity and attribution limits

Verify clone HEAD was `76ad7e4e1ec64afe4b63383b3dc4e80cd9549a2d`, branch `development`, clean, with `core.bare=false`, unchanged origin, and unchanged `.git/config` hash before/after both runs. `runner_envelope_assert` also reported clean after both suites.

Task clone HEAD was also `76ad7e4e1ec64afe4b63383b3dc4e80cd9549a2d`, branch `fix/gh949-ate-remediation`, with unchanged config/remote/HEAD. Its sampled status was clean immediately before the first suite and after it, then showed `?? TESTS-RESULTS/2026-10-03+GH-949/` during the second suite's before/after sample. This is outside the verify clone and concurrent parent evidence activity was underway; attribution of that task-clone untracked directory is therefore intentionally unresolved. It does not affect the verify-clone envelope attestation.

The driver retained an obsolete expected task-clone HEAD (`863480b…`) from before the candidate fast-forward and exited nonzero after both runs because that final static expectation failed. This is an orchestration guard mismatch only: each proc-group suite command returned 0, and the captured suite/envelope assertions all passed. It is recorded here rather than hiding it. See `provenance.jsonl` and `identity-before.json` / `identity-after.json` for the captured facts.

## Source basis

At candidate HEAD, `test/lib/runner-envelope.sh:59-63` unsets `XYZ_HARNESS` and `XYZ_REPO_ROOT` at the beginning of `runner_envelope_begin`. It only creates/exports `XYZ_HARNESS_DB` when that variable is absent, so an existing DB selection is preserved. Both focused suites remain existing repo tests; no source or suite was edited for this manual evidence.

Producer disposition: the parent created TESTS-RESULTS/2026-10-03+GH-949 in the task clone while these suites ran in verify; this was the expected evidence copy, not a suite write. The final wrapper guard compared the task clone against a stale pre-implementation SHA. The wrapper failure is retained and not called a pass. Both independently recorded suite return codes, selector/DB assertions and verification-clone envelope checks passed; the stale external-clone guard does not invalidate those results.
