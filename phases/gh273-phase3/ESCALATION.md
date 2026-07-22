# ESCALATION — Marathon Phase gh273-phase3

phase: gh273-phase3
task: MARATHON-GH273-PHASE3-TURN
relay-drive-exit: 0
reason: pre-advance-failed
relay-file: phases/gh273-phase3/RELAY.md

## Resolution (manual, 2026-07-21)

Fourth occurrence of the same pre-existing `test/xyz-harness-hooks.sh` "relay green count" flake
(Phases 0-2), unrelated to this build. Standalone re-run 61/61 pass; full `validate.sh` re-run exit
0. Given this phase's higher stakes (a script capable of `git push`/PR-create/merge), verified the
build directly before closing out: `relay-automation/marathon-closeout.sh` supports `--dry-run` as
required, and `test/marathon-closeout.sh` correctly PATH-shadows `git`/`gh` inside a disposable
`mktemp` scratch repo — no real network or repo state touched. `bash test/marathon-closeout.sh` run
standalone: 18/18 pass (dry-run inertness, happy path, red-checks halt at exit 4, unmergeable halt
at exit 4, command-failure exit 3, usage exit 2, `bash -n` clean). **Phase 3 is manually confirmed
shipped.**
