---
title: Lane brief — GH-2: reproduce and contain the orphan-backup relocation
status: Active (2-WORKING)
created: 2026-08-24
updated: 2026-08-24
owner: noel
branch: development
doc_type: project
roadmap_exempt: true
goal: >
  Lane brief for marathon phase gh2-orphan-backup-repro.
---

# Lane brief — GH-2: reproduce and contain the orphan-backup relocation

## Status

| What was just completed | What's next |
|---|---|
| Brief authored. | Phase execution. |

Execution surface of record: `PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md`
(issue: https://github.com/HiQS-Suite/XYZ-forge/issues/2)

## Task

A test-suite run moved an untracked file from a project docs directory into
`.tick/orphan-backups/` — same family as #1's sandbox escape: an unguarded empty/derived path
variable redirecting file operations onto real content. Silent data loss for anything not
under version control. Known trigger condition: `mktemp` failure under parallel load.

1. Reproducer `test/gh2-orphan-backup-repro.sh` (new): force the mktemp-failure path under
   parallel load and assert no file outside the fixture moves (negative control: with the
   guard stubbed out, the relocation must be detected).
2. Audit every suite + harness script for `mv` / `find -delete` / `rm -rf` on derived paths;
   each call site gains a resolved-containment check at the use boundary (reusing #1's
   `require_fixture` helper where present — consuming it, not editing it). Record the audit
   table in the capture doc (`PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md`), one row
   per call site with its resolved-containment check.
3. Register the suite in validate.sh TESTS.

## Definition of done

- Reproducer green with the guard active: nothing outside the fixture moves under simulated
  `mktemp` failure.
- Reproducer green with the guard stubbed out: the relocation is detected (negative control).
- Audit table of every `mv`/`find -delete`/`rm -rf` call site on a derived path recorded in
  the capture doc, each carrying a resolved-containment check.
- `test/gh2-orphan-backup-repro.sh` green and registered in validate.sh.
- `bash validate.sh` green.
