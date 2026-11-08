# Plan draft: #1087 docs: restore spacing in the GH-1051 work record

> draft; preflight and independent plan QA outstanding

- Request: `gh-1087-494ba87c1702` (tick `slot_083`)
- Draft status: **held** (held: planner state already-closed)
- Planner state: already-closed; flags: none
- Rating: 20/10/20/95
- Capture doc: PROJECT/2-WORKING/GH-1087-GH1051-RECORD-SPACING.md (sha256 effb6c8d8058463b35db31d9474bd271a28d1922f97e9cc94a5fa8a715ed5de4)
- Issue sha256: 494ba87c1702544e038fc1b709c7a02f5092cefd99ee7bc3062b3bfcadb3b21a (updated 2026-10-24T22:00:37Z)
- Dependencies: none

## Scope

_Source: PROJECT/2-WORKING/GH-1087-GH1051-RECORD-SPACING.md:L9 (frontmatter goal)_

PROJECT/3-COMPLETED/GH-1051-PAGES-DEVELOPMENT.md reads cleanly: joined words and identifiers (onlydevelopment, pushdevelopment/main, registeredci-workflow and any siblings) get their separators and code formatting back, with every fact, date and SHA unchanged.

## Acceptance criteria

_Source: PROJECT/2-WORKING/GH-1087-GH1051-RECORD-SPACING.md:L36 (Acceptance)_

- [ ] The three named joined tokens are gone and read as separated words / formatted identifiers.
- [ ] No other line of the file changed in meaning; `git diff --stat` touches only that file.
- [ ] `bash utils/pdda/pdda.sh run` has zero errors (GH-831: no new suite).

## Open questions

_missing_

## Write set

- `PROJECT/3-COMPLETED/GH-1051-PAGES-DEVELOPMENT.md` (PROJECT/2-WORKING/GH-1087-GH1051-RECORD-SPACING.md:preflight-contract)

## Unresolved file names

- none

## Contract probes

- grep_present `PROJECT/3-COMPLETED/GH-1051-PAGES-DEVELOPMENT.md`: landed

## Existing preflight contract

```json
{
  "artifacts": [
    "PROJECT/3-COMPLETED/GH-1051-PAGES-DEVELOPMENT.md"
  ],
  "fix_probes": [
    {
      "note": "pre-fix symptom: joined tokens present; landed when none remain",
      "path": "PROJECT/3-COMPLETED/GH-1051-PAGES-DEVELOPMENT.md",
      "pattern": "onlydevelopment|pushdevelopment/main|registeredci-workflow",
      "type": "grep_present"
    }
  ],
  "gate": "bash utils/pdda/pdda.sh run",
  "lanes": {
    "agy_safe": [
      "PROJECT/3-COMPLETED/GH-1051-PAGES-DEVELOPMENT.md"
    ],
    "orchestrator_only": []
  },
  "remediation": {
    "criteria": "Restore separators and identifier formatting in the GH-1051 work record while preserving all facts, dates, SHAs and links; touch only that file.",
    "source": "issue#1087"
  },
  "target": {
    "ref": "development",
    "repo": "."
  }
}
```
