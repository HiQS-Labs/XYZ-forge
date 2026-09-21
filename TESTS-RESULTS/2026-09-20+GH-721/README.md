# GH-721 evidence — hosted lane publish allowlist admits `1-INBOX`

Source: `fix/hosted-lane-inbox-allowlist` at the SHA in `provenance.jsonl`. Every run below was
executed in a **disposable full clone** of the task branch under the session scratchpad, never
in the task clone (AGENTS.md: no `test/*.sh` from a clone whose state matters). The red control
needs no tree mutation: `GH421_WORKFLOW` points the suite at the `origin/development` copy of the
workflow file. The probe's tracked tree was empty after every run. No operator source, ledger,
workflow run or deployed skill was touched.

`validate-identity.txt` records the interpreters the gate ran under (the pytest/PyYAML venv and
`/opt/homebrew/bin/php`); four suites go red on clean `development` without them.

## Red control

- `red-unfixed-workflow.log` — `test/gh421-auto-wave-reconcile.sh` against the unfixed workflow:
  31 tests, **1 error, exit 1** — `test_publish_allowlist_and_plan_lands` dies with the production
  message, `Refusing undeclared reconciliation artifacts: ['PROJECT/1-INBOX/GH-421-fixture.md']`.
  Same guard, same path class as hosted runs 35530081997 and 35537102291.

## Positive

- `gh421-green.log` — the same suite on the fix: 31 tests, exit 0. The new case admits the
  `1-INBOX` deletion side of a move and still refuses `PROJECT/1-INBOX/scratch-note.md`,
  `utils/py/unexpected.py`, an arbitrary `TESTS-RESULTS/…` path and malformed wave SHAs.
- `neighbour-gh684-hosted-lane-report.log` — `test/gh684-hosted-lane-report.sh` (also parses the
  workflow): 8 tests, exit 0.
- `validate-full.log` — the complete `validate.sh` gate in the disposable clone: 406 suites,
  0 red, exit 0.

Not claimed: the hosted runner. The first hosted run after landing is the hosted proof; its
outcome is recorded on #721 at closeout.
