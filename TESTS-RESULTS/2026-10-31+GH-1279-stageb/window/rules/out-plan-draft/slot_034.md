# Plan draft: #514 skills: new co-author skill "keel" — balance modularity, flexibility, maintainability, and ponytail for spec writing and total refactors

> draft; preflight and independent plan QA outstanding

- Request: `gh-514-197a5fa3545c` (tick `slot_034`)
- Draft status: **needs-recon** (held: no sourced write set)
- Planner state: needs-contract; flags: none
- Rating: 70/25/50/65
- Capture doc: PROJECT/1-INBOX/GH-514-KEEL-SKILL.md (sha256 a36a14dcefe89faa70984644ff48938f8966347a015e38247a3b6c71602b89fc)
- Issue sha256: 197a5fa3545ca08ababca73f17cb2cf1cd31bc222599b575fdba2d9d75f6074f (updated 2026-09-09T02:12:21Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-514-KEEL-SKILL.md:L7 (frontmatter goal)_

give technical specs and total-refactor plans a co-author skill that balances modularity (especially new builds), flexibility, and maintainability under a reversibility spine, with ponytail delegated to the mechanism layer only

## Acceptance criteria

_Source: issue#514:L28 (Acceptance criteria)_

- [ ] `skills/keel/SKILL.md` exists in XYZ Forge, skill-creator frontmatter conventions (folded block-scalar description with colons, per c4088fae).
- [ ] SKILL.md states the precedence stack and payer rule as hard rules; ponytail is invoked, not copied.
- [ ] Spec mode and total-refactor mode each have a procedure applying the four checks; refactor mode delegates ground truth to `/recon` when present.
- [ ] Zero new Bash files (GH-551); any supporting scripts are Python in `utils/py/` if needed.
- [ ] Global symlinks (ZCode + other apps per start-task convention) installed only on explicit operator request.

_Source: PROJECT/1-INBOX/GH-514-KEEL-SKILL.md:L74 (Acceptance criteria (debug-mantra plan pivot))_

- [ ] `skills/keel/SKILL.md` exists, skill-creator frontmatter conventions
      (folded block-scalar description with colons, per c4088fae).
- [ ] SKILL.md states the precedence stack and payer rule as hard rules;
      ponytail is invoked, not copied inline.
- [ ] Spec mode and total-refactor mode each have a procedure applying the
      four checks; refactor mode delegates ground truth to `/recon` when
      present.
- [ ] Zero new Bash files (GH-551).
- [ ] Global symlinks installed only on explicit operator request.

## Open questions

_missing_

## Write set

_none sourced_

## Unresolved file names

- `SKILL.md` (issue#514:L31; 77 tracked files share this name)

## Contract probes

- none
