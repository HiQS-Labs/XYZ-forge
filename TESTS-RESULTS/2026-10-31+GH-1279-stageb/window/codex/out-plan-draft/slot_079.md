# Plan draft: #255 marathon-drive's blocked-before-dispatch refusal omits XYZ_ARCHIVE_ROOT, the remedy that actually fits

> draft; preflight and independent plan QA outstanding

- Request: `gh-255-ae5d7d407488` (tick `slot_079`)
- Draft status: **held** (held: planner state already-closed)
- Planner state: already-closed; flags: none
- Rating: 28/22/50/92
- Capture doc: PROJECT/1-INBOX/GH-255-ARCHIVE-ROOT-REMEDY.md (sha256 02f30fc06bbec4579def8f8d350cc0be0f76a051a7b0ef3bfb9e91fd7062f15f)
- Issue sha256: ae5d7d40748881f6a448f40f69495638efc21887bcf8426a452d92f667672893 (updated 2026-10-24T22:00:33Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-255-ARCHIVE-ROOT-REMEDY.md:L22 (frontmatter goal)_

An operator or agent that hits the blocked-before-dispatch refusal on a repo which deliberately ignores relay-system/ is pointed at XYZ_ARCHIVE_ROOT first, with a runnable export line, instead of being steered into --target-root and failing a second time.

_Source: codex-authored (codex-authored)_

Verify the current blocked-before-dispatch refusal and archive-root behavior, then plan context-sensitive remedies for ignored transcript paths.

_Source: codex-authored (codex-authored)_

Update the marathon help text to distinguish archive-root and target-root use cases without changing the refusal or automatically setting an archive location.

## Acceptance criteria

_Source: issue#255:L47 (Acceptance criteria)_

- [ ] The blocked-before-dispatch message names `XYZ_ARCHIVE_ROOT` first when the blocked paths are transcripts.
- [ ] The message includes a runnable export line, not just the variable name.
- [ ] `marathon.sh --help` distinguishes when to use `XYZ_ARCHIVE_ROOT` vs `--target-root`.
- [ ] A test pins the remedy text against the transcript-blocked case.

_Source: codex-authored (codex-authored)_

When all blocked paths are transcripts under relay-system/, the refusal identifies that case and presents XYZ_ARCHIVE_ROOT first with an export example.

_Source: codex-authored (codex-authored)_

The help text distinguishes when to use XYZ_ARCHIVE_ROOT and --target-root.

_Source: codex-authored (codex-authored)_

An existing or new test verifies the remedy text for the transcript-blocked case.

## Open questions

_Source: codex-authored (codex-authored)_

What does the remainder of the revised capture specify about remedy ordering when blocked paths include non-transcript files?

_Source: codex-authored (codex-authored)_

Does the current archive-root implementation resolve every blocked transcript path in the reported case?

## Write set

- `utils/py/marathon_drive.py` (issue#255:L3)
- `relay-automation/CONSUMING.md` (issue#255:L20)
- `PROJECT/PDDA.md` (PROJECT/1-INBOX/GH-255-ARCHIVE-ROOT-REMEDY.md:L32)
- `relay-system/2026-08-26/gh255-plan-qa.md` (PROJECT/1-INBOX/GH-255-ARCHIVE-ROOT-REMEDY.md:L59)

## Unresolved file names

- `marathon.sh` (issue#255:L15; 2 tracked files share this name)
- `ESCALATION.md` (PROJECT/1-INBOX/GH-255-ARCHIVE-ROOT-REMEDY.md:L62; 44 tracked files share this name)
- `RELAY.md` (PROJECT/1-INBOX/GH-255-ARCHIVE-ROOT-REMEDY.md:L70; 89 tracked files share this name)

## Contract probes

- none
