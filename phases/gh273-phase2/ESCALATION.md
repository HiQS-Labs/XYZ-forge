# ESCALATION — Marathon Phase gh273-phase2

phase: gh273-phase2
task: MARATHON-GH273-PHASE2-TURN
relay-drive-exit: 0
reason: pre-advance-failed
relay-file: phases/gh273-phase2/RELAY.md

## Resolution (manual, 2026-07-21)

Third occurrence of the same pattern (Phases 0 and 1): `test/xyz-harness-hooks.sh`'s pre-existing
"relay green count" assertion failed under the full `validate.sh` suite, unrelated to this build
(Phase 2's only artifact is `.claude/loose-ends-sequence.md`, no test files touched). Standalone
`bash test/xyz-harness-hooks.sh` → 61/61 pass; full `validate.sh` re-run → exit 0. Codex correctly
applied the `loose-ends` skill's documented path-resolution rule (relative to the manifest's own
directory, `.claude/`, not CWD) — bullets use `../utils/...`, which resolves correctly. **Phase 2 is
manually confirmed shipped.**
