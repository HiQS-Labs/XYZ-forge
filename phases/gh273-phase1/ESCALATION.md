# ESCALATION — Marathon Phase gh273-phase1

phase: gh273-phase1
task: MARATHON-GH273-PHASE1-TURN
relay-drive-exit: 0
reason: pre-advance-failed
relay-file: phases/gh273-phase1/RELAY.md

## Resolution (manual, 2026-07-21)

Same pattern as GH-273 Phase 0's escalation: `bash validate.sh` failed on `test/xyz-harness-hooks.sh`'s
pre-existing "relay green count" assertion (unrelated to this build — Phase 1's artifacts are only
`.claude/commands/pre-marathon.md` / `post-marathon.md`, no test files touched). Reproduced clean:
standalone `bash test/xyz-harness-hooks.sh` → 61/61 pass. Full `validate.sh` re-run confirms green
(see CHANGELOG for the exact result). Not re-firing marathon-drive again for this phase — learned from
Phase 0 that a same-phase-id retry against an already-`done` token corrupts `RELAY.md` (GH-274); this
run used a distinct `--phase-id gh273-phase1` so no collision occurred here, but the token is now
`done` regardless, so a third invocation would still fail. **Phase 1 is manually confirmed shipped.**
