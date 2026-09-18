# GH-678 / Pulse issue 2 focused evidence

Candidate implementation: `403924d8e8c6c7248cbd5192eb7eb8492f5b7829`.
`agent-chorus.log`: 215 pass, 0 fail. `matrix.log`: every discovered installer tested.
Negative controls use the same candidate in a disposable full clone, restoring saved bytes:

1. Delete the three-variable `unset` inside `run_installer` in `test/agent-chorus.sh`,
   then run `bash test/agent-chorus.sh`: two containment failures, exit 1.
2. Restore the test. Delete only the `if [ -e "$_legacy" ]` block before the case in
   `migrate_legacy_link`, then run the same suite: legacy ownership failure, exit 1.
3. Restore the installer. Compare HEAD and local Git config with pre-run snapshot: unchanged.

`installer-red-control.json` is an additional sandbox observation comparing the installer
from `3c820f0661165b3becc05b51d3062e67ec9066ee` against `345391d5988724fcb910ee8714d76728c38acbcc`.
Each used a separate temporary HOME, explicit Claude/Codex fixture roots, unset Gemini overrides,
and a pre-existing Gemini Config link to a live fixture owner. The old script replaced that
link; the fixed script preserved it and returned 1. No real app directory was used.

These focused checks do not represent a full validation gate. Relay approval is recorded in
`relay-system/2026-09-17/pulse2-final-qa.md`; its scope is implementation and recovery procedure.
