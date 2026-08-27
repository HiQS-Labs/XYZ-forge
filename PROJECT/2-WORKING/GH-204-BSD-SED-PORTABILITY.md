---
title: "GH-204: BSD `sed -i ''` idiom silently no-ops on Linux at production call sites"
status: Active
created: 2026-08-24
updated: 2026-08-27
owner: orchestrator (Claude Code)
goal: no production write is silently lost on Linux — every in-place edit uses a portable idiom and a regression test asserts on destination-file CONTENT, not exit code
gh_issue: 204
source: https://github.com/HiQS-Labs/XYZ-forge/issues/204
branch: gh-204/sed-portability
doc_type: bugfix
effort: 2
complexity: 2
risk: 2
release: 0.7.4 Linux-RC (dialed in 2026-08-24, mfi-01M0V6HC4T1SXQWANXQ31AAT3K)
related:
  - "#224 — Linux MVP RC umbrella (this is a Phase 2 exit item)"
  - "#209 — external PR fixed the TEST-side sed sites; this doc covers the production remainder"
non_goals:
  - Editing relay-automation/relay-drive.sh — FROZEN Bash twin (GH-308 guard blocks it); the Python lane utils/py/relay_drive.py is authoritative and the twin's Linux limitation is documented, not patched
---

# GH-204 — BSD `sed -i ''` no-ops on Linux (production remainder)

## Status

| What was just completed | What's next |
|---|---|
| all 7 acceptance items landed on `fix/gh204-production-sed`: portable idioms at both production sed sites, content-asserted escalation write in the authoritative Python lane, and `test/gh204-sed-portability.sh` green + registered in validate.sh | reviewer merges the PR into `development`; #224 Phase 2 exit item closes |

Scoped per Agy's empirical review on #224 (2026-08-24): PR #209 already fixed the test-side
call sites; the remaining sites are production/runtime. `git grep "sed -i ''"` at f3400b61:

- `relay-automation/relay-drive.sh:546` — `STATUS: Escalated` divergence write lost on Linux.
  **FROZEN twin (GH-308)** — the fix lands in `utils/py/relay_drive.py` (verify its escalation
  write is portable and content-asserted), never in the Bash file.
- `utils/build-launch-artifact.sh:283` — author home-path redaction silently lost on GNU sed.
- `test/meter-release.sh:528` — fixture scrub (`/usr/bin/sed -i ''`), lost on Linux.

## Plan

1. `utils/py/relay_drive.py` (~line 682): confirm the `STATUS: Escalated` write is pure-Python
   (portable); add a content assertion to the regression suite for it.
2. `utils/build-launch-artifact.sh:283`: replace `sed -i ''` with a portable idiom
   (`sed ... > tmp && mv tmp file`, or `perl -pi -e`); the redaction counter must reflect a
   real content change, not sed's exit code.
3. `test/meter-release.sh:528`: same portable rewrite.
4. New `test/gh204-sed-portability.sh`: (a) repo-wide grep pins zero remaining `sed -i ''`
   outside the frozen twins; (b) asserts on destination-file CONTENT after each fixed call
   site's code path runs (exit codes mask the loss — the issue's acceptance). Register in
   validate.sh TESTS.

## Acceptance

- [x] Neither call site uses the BSD-only `sed -i ''` form; both work on GNU and BSD sed.
- [x] The escalation path **fails loudly** if the `STATUS:` rewrite does not land in the authoritative Python lane (`utils/py/relay_drive.py`) — it must not print "escalated" or exit 4 when the file was not changed.
- [x] `build-launch-artifact.sh` reports a redaction failure distinguishably from "nothing to redact".
- [x] The residual check no longer depends on a hardcoded username.
- [x] A regression test covers the escalation path asserting on **file content**, not exit code alone.
- [x] `test/gh204-sed-portability.sh` green and registered in validate.sh.
- [x] `test/meter-release.sh:528` rewritten portably.

## Acceptance — deviations from the issue

- [changed] `relay-drive.sh`'s escalation path **fails loudly** if the `STATUS:` rewrite does not land — it must not print "escalated" or exit 4 when the file was not changed. -> The escalation path **fails loudly** if the `STATUS:` rewrite does not land in the authoritative Python lane (`utils/py/relay_drive.py`) — it must not print "escalated" or exit 4 when the file was not changed. — reason: `relay-automation/relay-drive.sh` is a FROZEN Bash twin (GH-308 guard blocks edits); the fix lands in the Python lane and the twin's Linux limitation is documented rather than patched.
- [added] `test/gh204-sed-portability.sh` green and registered in validate.sh. — reason: the regression test the issue's criterion 5 requires needs a named, gate-registered suite.
- [added] `test/meter-release.sh:528` rewritten portably. — reason: third call site of the same defect class found at f3400b61 (Agy review on #224).

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "path_absent", "path": "test/gh204-sed-portability.sh" } ],
  "artifacts":     [ "utils/build-launch-artifact.sh", "test/meter-release.sh", "utils/py/relay_drive.py", "test/gh204-sed-portability.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh204-sed-portability.sh" ],
  "remediation":   { "source": "self#plan", "criteria": "no sed -i '' outside frozen twins; content-asserted regression test green; portable escalation write in the Python lane" },
  "lanes":         { "agy_safe": [ "test/gh204-sed-portability.sh", "utils/build-launch-artifact.sh", "test/meter-release.sh" ], "orchestrator_only": [ "relay-automation/", ".tick/" ] }
}
```
