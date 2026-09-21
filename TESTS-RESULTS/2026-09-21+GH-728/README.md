# GH-728 evidence — /merge-cleanup-deep skill

Doc-and-skill change; no script, test, or CLI change. Two contract checks ran in a disposable full
clone with the working-tree changes copied in (task clone untouched):

- `gh589-skill-viewer.log` — `test/gh589-skill-viewer.sh`: 8/8, exit 0. The viewer derives the skill
  set from `skills/*/SKILL.md`; the new folder parses and the set equals the folder set (60).
- `gh534-parity-guard.log` — `gh534_phase_c_tests.py::TestParityGuard`: 7/7, exit 0 against the
  edited `skills/merge-cleanup/SKILL.md` (capability table and CLI option list untouched).

The pre-push gate on the task clone is the full-suite receipt (see the PR).
