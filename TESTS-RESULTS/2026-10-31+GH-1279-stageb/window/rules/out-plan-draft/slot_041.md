# Plan draft: #1266 ARCHITECTURE.md Skills Index drift: weekly-planner has no row and the hand-typed tier counts are stale

> draft; preflight and independent plan QA outstanding

- Request: `gh-1266-ba4a7f871885` (tick `slot_041`)
- Draft status: **ready**
- Planner state: ready; flags: none
- Rating: 30/20/50/95
- Capture doc: PROJECT/1-INBOX/GH-1266-ARCHITECTURE-MD-SKILLS-INDEX.md (sha256 33f49b7f710f82fcba62e080d4a0a05005f0a28bb1c413edc60e3074c976bb67)
- Issue sha256: ba4a7f87188573bffe0acd14fa7d7265f8882604c46357f89335e30113577384 (updated 2026-10-30T16:50:00Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-1266-ARCHITECTURE-MD-SKILLS-INDEX.md:L126 (Phase 0 — Explore & scope)_

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.

_Source: PROJECT/1-INBOX/GH-1266-ARCHITECTURE-MD-SKILLS-INDEX.md:L23 (frontmatter goal)_

TODO: one-paragraph statement of what "done" looks like for this idea.

## Acceptance criteria

_Source: issue#1266:L31 (Acceptance)_

- [ ] For every tier, `ls -d skills/<tier>/*/ | wc -l` is positive and equals `grep -c "(skills/<tier>/" ARCHITECTURE.md` (recorded for all four with the actual numbers; a 0 = 0 pair does not pass). Red control: on the base, `3-weekly` gives 16 vs 15 (recorded).
- [ ] `grep -c '(skills/3-weekly/weekly-planner/SKILL.md)' ARCHITECTURE.md` is 1. Red control: base gives 0.
- [ ] `grep -cE '^### `[0-9]-[a-z]+`.*\([0-9]+\)$' ARCHITECTURE.md` is 0 (no counts left) **and** `grep -cE '^### `[0-9]-[a-z]+` — [^(]+$' ARCHITECTURE.md` is 4 (the four count-free headings are present, so an empty file cannot pass). Red control: base gives 4 and 0 respectively (recorded).
- [ ] `bash utils/pdda/pdda.sh run` passes on the final commit.

_Source: PROJECT/1-INBOX/GH-1266-ARCHITECTURE-MD-SKILLS-INDEX.md:L76 (Acceptance)_

- [ ] For every tier, `ls -d skills/<tier>/*/ | wc -l` is positive and equals `grep -c "(skills/<tier>/" ARCHITECTURE.md` (recorded for all four with the actual numbers; a 0 = 0 pair does not pass). Red control: on the base, `3-weekly` gives 16 vs 15 (recorded).
- [ ] `grep -c '(skills/3-weekly/weekly-planner/SKILL.md)' ARCHITECTURE.md` is 1. Red control: base gives 0.
- [ ] `grep -cE '^### `[0-9]-[a-z]+`.*\([0-9]+\)$' ARCHITECTURE.md` is 0 (no counts left) **and** `grep -cE '^### `[0-9]-[a-z]+` — [^(]+$' ARCHITECTURE.md` is 4 (the four count-free headings are present, so an empty file cannot pass). Red control: base gives 4 and 0 respectively (recorded).
- [ ] `bash utils/pdda/pdda.sh run` passes on the final commit.

## Open questions

_missing_

## Write set

- `ARCHITECTURE.md` (PROJECT/1-INBOX/GH-1266-ARCHITECTURE-MD-SKILLS-INDEX.md:preflight-contract)

## Unresolved file names

- none

## Contract probes

- grep_absent `ARCHITECTURE.md`: unfixed

## Existing preflight contract

```json
{
  "artifacts": [
    "ARCHITECTURE.md"
  ],
  "fix_probes": [
    {
      "note": "pre-fix: no weekly-planner row; landed when the row exists",
      "path": "ARCHITECTURE.md",
      "pattern": "skills/3-weekly/weekly-planner/SKILL.md",
      "type": "grep_absent"
    }
  ],
  "gate": "bash utils/pdda/pdda.sh run",
  "remediation": {
    "criteria": "Add the weekly-planner row before weekly-shipped; delete the four hand-maintained tier counts; ARCHITECTURE.md only; no generator, no new test (GH-831). Land after #1258 Phase 1 or rebase over it.",
    "source": "issue#<this>"
  },
  "target": {
    "ref": "development",
    "repo": "."
  }
}
```
