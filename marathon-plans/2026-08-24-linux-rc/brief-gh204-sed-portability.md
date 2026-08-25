# Lane brief — GH-204: BSD `sed -i ''` portability (production remainder)

Source of truth: `PROJECT/2-WORKING/GH-204-BSD-SED-PORTABILITY.md` (issue
https://github.com/HiQS-Labs/XYZ-forge/issues/204; Linux-RC umbrella #224 Phase 2).

## Deliverable

1. `utils/build-launch-artifact.sh:283` and `test/meter-release.sh:528`: replace `sed -i ''`
   with a portable idiom (`sed ... > tmp && mv`, or `perl -pi -e`). The redaction path must
   report a redaction failure distinguishably from "nothing to redact", and the residual check
   must not depend on a hardcoded username.
2. `utils/py/relay_drive.py` (escalation write near line 682): verify the `STATUS: Escalated`
   write is pure-Python/portable and fails loudly when the rewrite does not land.
3. New `test/gh204-sed-portability.sh`: pins zero `sed -i ''` outside GH-308 frozen twins, and
   asserts on destination-file CONTENT after each fixed path runs (never exit code alone).
   Register in validate.sh TESTS.

## Hard constraints

- Do NOT edit `relay-automation/relay-drive.sh` — FROZEN Bash twin, the GH-308 guard fails the
  gate on any diff to it. Its line-546 sed stays; the Python lane is authoritative.
- Acceptance checklist (with declared deviations) lives in the capture doc — reviewer verifies
  against it verbatim.
