# GH-1159 manual checks (no new tests, GH-831; operator chose manual checks only)

Provenance: branch `claude/peaceful-gates-1b06pd`, working tree on top of `29270781f07e2fae9179e9d8f6a6cc9f58810b41`, base `9a61625f`,
2026-10-18, cloud container (root, Python 3.13.16).

## Manual checks — `qualification-checks.py` → `qualification-checks.log` (ALL PASS, 17/17)

`python3 TESTS-RESULTS/2026-10-18+GH-1159/qualification-checks.py skills/2-daily/merge-cleanup/scripts <base-copy> .`
where `<base-copy>` holds the four merge-cleanup scripts from `git show 9a61625f:...`.

- (a) Repo with no key: `qualification` is null; the rendered batch block contains none of `wave-reconcile`, `validate.sh` or `development`, and says no sweep command is declared.
- (b) Forge's committed key: `sweep_inputs` (minus the new `full_suite` field) and the rendered block are byte-identical to base.
- (c) Invalid values fail closed: an unknown `full_suite`, `none` with a command, an extra key, an empty command, or a non-object.
- `per_batch` (grouped in a subshell, `;` stays inside and parses), `none`, and `promotion` without a command each render as planned.
- Red control: Forge's file with the key removed prints no `wave-reconcile` command.

## Smoke (GH-1088)

Main path: `merge_cleanup.py --primary <forge> --show-merge-policy` → prints the `qualification`
object (promotion + the wave-reconcile dispatch), exit 0.
Adjacent paths: a fresh repo with no file → `"qualification": null`, exit 0. The same repo with
`{"qualification":{"full_suite":"weekly"}}` → `ERROR … qualification must be an object …`, exit 2.
An old persisted (pre-GH-1159) batch record renders unchanged (last line of the log).

## Existing suite — `bash test/gh436-merge-cleanup.sh`

188 tests, 1 failure, 1 skipped. The failure is
`gh534_phase_a_tests.TestA4TickClaims.test_iv_unreadable_event_log_preserves`. It is outside the
GH-1159 diff and comes from the environment: the test uses `chmod 0` to make the event log
unreadable, and this container runs as root (uid 0), which ignores that. Every other case passes,
including `test_emitted_sweep_command_parses` with Forge's `qualification` passed in.
