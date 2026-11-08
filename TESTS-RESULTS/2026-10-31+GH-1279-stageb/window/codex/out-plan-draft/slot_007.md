# Plan draft: #446 marathon_plan.py writes unprompted plan file to disk on default invocation without --dry-run

> draft; preflight and independent plan QA outstanding

- Request: `gh-446-f3440b2763a3` (tick `slot_007`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 65/60/75/80
- Capture doc: PROJECT/1-INBOX/GH-446-MARATHON-PLAN-WRITE-GUARD.md (sha256 340712d9dba2abfd5eb247f3645cefcaba9a00deb4ccfbe60cbc822183ace30a)
- Issue sha256: f3440b2763a35f72752cb76cad062c9f25e1acaa7968b4f2cab56831ff4459fd (updated 2026-10-27T14:16:35Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-446-MARATHON-PLAN-WRITE-GUARD.md:L16 (frontmatter goal)_

Make --dry-run / read-only inspection the safe default for marathon_plan.py, requiring explicit write intent to mutate PROJECT/2-WORKING/MARATHON-PLAN-*.md on disk.

_Source: codex-authored (codex-authored)_

Verify whether commit 5265cfad9815 already resolves the reported default-write behavior before planning further changes.

_Source: codex-authored (codex-authored)_

If the issue remains, plan a read-only default and require explicit write intent for plan generation, including the shell wrapper and existing callers.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

Empty, invalid, and inspection invocations do not create a plan file; invalid or empty invocations show help or exit with an error as appropriate.

_Source: codex-authored (codex-authored)_

An explicit write invocation generates the intended plan file.

_Source: codex-authored (codex-authored)_

Regression coverage verifies the default behavior and explicit write path.

## Open questions

_Source: codex-authored (codex-authored)_

Does the landed commit fully resolve the issue, and do existing callers depend on implicit writes?

## Write set

- `utils/py/marathon_plan.py` (issue#446:L3)

## Unresolved file names

- `marathon-plan.sh` (issue#446:L3; 2 tracked files share this name)

## Contract probes

- none
