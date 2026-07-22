# ESCALATION — Marathon Phase p1

phase: p1
task: MARATHON-P1-TURN
relay-drive-exit: 0
reason: pre-advance-failed
relay-file: phases/p1/RELAY.md

## Resolution (manual, 2026-07-21)

The `bash validate.sh` pre-advance gate failed on `test/xyz-harness-hooks.sh` — but on a pre-existing
assertion ("relay green count", last touched in the unrelated GH-232 fix, several commits before this
build), not on any of the 14 new skill-nudge assertions Codex added (all passed). Reproduced clean:
`bash test/xyz-harness-hooks.sh` alone → 61/61 pass; a full `bash validate.sh` re-run immediately after
→ exit 0, no failures listed. Flaky full-suite failure, not a Phase 0 regression.

The `MARATHON-P1-TURN` tick token was already `status: done` from the successful build+review, so
re-invoking `marathon-drive.sh` for the same phase couldn't reopen it — it re-rendered `RELAY.md` to a
fresh `STATUS: Open` template and failed immediately after (exit 1), discarding the accurate Approved
record. That render commit was `git revert`ed to restore this file to its true terminal state.

**Phase 0 is manually confirmed shipped**: `relay-automation/hooks/skill-nudge.sh` +
`test/xyz-harness-hooks.sh` additions committed in `79b4728`/`31a9f76`, full `validate.sh` green.
