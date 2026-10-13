# Manual environment evidence — pre-fix K1 / GH-912

Base under test: disposable full clone `/Users/noelsaw/task-clones/ate-remediation-20261003/verify`, HEAD `3fbed72f781d1ad060e298b798a44c32edef393d`, clean at baseline. The task clone was supplied only as an inherited environment value: `/Users/noelsaw/task-clones/ate-remediation-20261003/task`, HEAD `863480bf1bb10f54c2b8c0845a64d123bf84d49e`, clean relative to its branch and six commits ahead of `origin/development`. It has executable `relay-automation/relay-drive.sh` and `bin/tick`, so it satisfies the locator's explicit-override `_has_harness` check. No suite ran in that task clone.

## Results

The existing `test/find-harness.sh` passes **50/0** with both `XYZ_HARNESS` and `XYZ_REPO_ROOT` unset. With both variables inherited and pointed at the valid task clone, it exits 1 at **48/2**. The failing assertions are:

- `test/find-harness.sh:46–48`: “harness clone: no concurrency warning”; the explicit task-clone override wins while CWD is the verify clone, so the locator reports the verify clone as a foreign repo using a centralized harness.
- `test/find-harness.sh:69–71`: “vendored .xyz: no concurrency warning”; the explicit task-clone override wins over the fixture’s local `.xyz`, so the fixture no longer resolves as vendored.

The existing `test/gh396-find-harness-roots.sh` passes **41/0** clean and exits 1 at **40/1** with both variables inherited. Its failure is `test/gh396-find-harness-roots.sh:238–243`: “file-symlinked locator: resolves root correctly via file symlink”; the call invokes the locator without clearing the ambient override, and the result is the task clone path instead of the verify clone’s `HARNESS_DIR`. The suite’s other locator calls generally use `env -u XYZ_HARNESS -u XYZ_REPO_ROOT` for auto-discovery or explicit assignments for override cases, which is why they stay green.

Each run is an existing focused suite in the verify clone, launched as `python3 utils/py/proc_group.py --timeout 90 -- bash test/<suite>`. The runner script records exact argv, effective selector variables, stdout/stderr, UTC time, and verify/task clone identity before and after each case in `logs/*.json`; `summary.json` gives a compact result. All four verify and task identity snapshots match. `runner-envelope.sh` is source-only in this exercise: it handles `XYZ_HARNESS_DB` scratch and identity snapshots but does not unset `XYZ_HARNESS` or `XYZ_REPO_ROOT`; the suite dispatches in `validate.sh` and `ci-local.sh` invoke plain `bash test/$t`. The relevant exact source excerpts are preserved in `source-excerpts.txt`.

No runner-envelope scratch was allocated because `runner_envelope_begin` and either gate runner were not invoked. The focused suites used their existing fixtures; no broad gate, new suite, production edit, live model, or GitHub write ran.

## Pre-fix implication

This is a witnessed GH-912 test-isolation failure, separate from intended locator semantics: the locator correctly honors its explicit overrides, while tests’ auto-resolution assertions assume those variables are absent. At the shared suite-launch boundary, clearing only inherited `XYZ_HARNESS` and `XYZ_REPO_ROOT` is the smallest broad isolation change found in source; it preserves per-case overrides set inside suites. `XYZ_HARNESS_DB` must remain untouched because GH-365 intentionally tests that envelope export. The independent K1 fix must make the locator safe when `HOME` is unset, including the eager `CONFIG_FILE`/`SEARCH_ROOTS` expansions and later AGY fallback; it was not exercised in this run.
