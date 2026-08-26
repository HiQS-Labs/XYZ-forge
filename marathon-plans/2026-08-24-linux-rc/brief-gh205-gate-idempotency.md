# Lane brief — GH-205: gate idempotency (gh174 suite fixture isolation)

Source of truth: `PROJECT/2-WORKING/GH-205-GATE-IDEMPOTENCY.md` (issue
https://github.com/HiQS-Labs/XYZ-forge/issues/205; Linux-RC umbrella #224 Phase 2).

## Deliverable

1. `test/gh174-harness-registry.sh`: every write (`harnesses.db`, `harnesses.sql`,
   `docs/blog-frontier-benchmarks.md`, generated registry views — see `BLOG_FILE="$ROOT/..."`
   at line 126) moves to a fixture copy under the suite's `$WORK` dir. The suite must never
   name `$ROOT` as a write destination.
2. `utils/py/harness_app.py`: only if fixture isolation needs it, add the minimal root/db
   override (e.g. honor `--root`); zero behavior change on real runs.
3. New `test/gh205-gate-idempotency.sh`: runs the gh174 suite in a scratch clone and asserts
   `git status --porcelain` is empty afterward. Register in validate.sh TESTS.

## Hard constraints

- Real (non-test) gate runs keep writing eval telemetry — this lane isolates the TEST suite
  only.
- Acceptance: `bash validate.sh` on a pristine checkout leaves the tree completely clean.
