# Plan draft: #418 Marathon planner still reads the frozen ROADMAP.md — 37 DB-parked items are invisible to it since the ROADMAP_SOURCE=releases flip

> draft; preflight and independent plan QA outstanding

- Request: `gh-418-dbaddb6ed93e` (tick `slot_001`)
- Draft status: **ready**
- Planner state: ready; flags: none
- Rating: 88/78/80/75
- Capture doc: PROJECT/2-WORKING/GH-418-MARATHON-ADOPT-RELEASES-DB.md (sha256 3e3c5681210565f2ac2843320eaf66f99be6d895ba5aea35f6c181717e8c1b9f)
- Issue sha256: dbaddb6ed93ed6db399593f47e8a3a46954c988b6af605c2ca8a6098b2a058d5 (updated 2026-09-04T01:28:34Z)
- Dependencies: #423

## Scope

_Source: PROJECT/2-WORKING/GH-418-MARATHON-ADOPT-RELEASES-DB.md:L9 (frontmatter goal)_

marathon-plan ranks lanes from releases.db (via the rendered ledger), with zero DB-parked items invisible

## Acceptance criteria

_Source: issue#418:L49 (Acceptance)_

- [ ] In releases-mode, `marathon-plan.sh` sources items from `roadmap_items`; zero DB-parked items are invisible to it.
- [ ] In legacy mode the behaviour is unchanged, asserted by a test.
- [ ] The generated plan doc names its real source.
- [ ] Red control witnessed and recorded in `test/baselines/`: a DB-only item is absent from a pre-fix plan and present in a post-fix one.
- [ ] A deterministic check fails if a shipped script reads `ROADMAP.md` for current state while `ROADMAP_SOURCE=releases`.

_Source: PROJECT/2-WORKING/GH-418-MARATHON-ADOPT-RELEASES-DB.md:L126 (Acceptance)_

- [ ] In releases-mode, `marathon-plan.sh` sources items from `roadmap_items`; zero DB-parked items are invisible to it.
- [ ] In legacy mode the behaviour is unchanged, asserted by a test.
- [ ] The generated plan doc names its real source.
- [ ] Red control witnessed and recorded in `test/baselines/`: a DB-only item is absent from a pre-fix plan and present in a post-fix one.
- [ ] A deterministic check fails if a shipped script reads `ROADMAP.md` for current state while `ROADMAP_SOURCE=releases`.

## Open questions

_missing_

## Write set

- `utils/py/marathon_plan.py` (PROJECT/2-WORKING/GH-418-MARATHON-ADOPT-RELEASES-DB.md:preflight-contract)
- `utils/py/_marathon_plan.py` (PROJECT/2-WORKING/GH-418-MARATHON-ADOPT-RELEASES-DB.md:preflight-contract)
- `test/gh418-planner-ledger-source.sh` (PROJECT/2-WORKING/GH-418-MARATHON-ADOPT-RELEASES-DB.md:preflight-contract)
- `test/baselines/GH-418-negative-control.md` (PROJECT/2-WORKING/GH-418-MARATHON-ADOPT-RELEASES-DB.md:preflight-contract)

## Unresolved file names

- none

## Existing preflight contract

```json
{
  "artifacts": [
    "utils/py/marathon_plan.py",
    "utils/py/_marathon_plan.py",
    "test/gh418-planner-ledger-source.sh",
    "test/baselines/GH-418-negative-control.md"
  ],
  "artifacts_new": [
    "test/baselines/GH-418-negative-control.md",
    "test/gh418-planner-ledger-source.sh"
  ],
  "fix_probes": [
    {
      "note": "bug evidence \u2014 must fire unfixed at pre-work time",
      "path": "utils/py/marathon_plan.py",
      "pattern": "ROADMAP.md",
      "type": "grep_present"
    },
    {
      "note": "new lane artifact \u2014 must not exist yet",
      "path": "test/gh418-planner-ledger-source.sh",
      "type": "path_absent"
    },
    {
      "note": "new lane artifact \u2014 must not exist yet",
      "path": "test/baselines/GH-418-negative-control.md",
      "type": "path_absent"
    }
  ],
  "gate": "bash validate.sh",
  "lanes": {
    "agy_safe": [
      "utils/py/",
      "utils/timeline/",
      "test/"
    ],
    "orchestrator_only": []
  },
  "remediation": {
    "criteria": "marathon-plan ranks the DB-parked queue (rendered ledger markdown) without reading ROADMAP.md; repo-wide grep pins no live ROADMAP.md read in the planner",
    "source": "issue#418"
  },
  "target": {
    "ref": "development",
    "repo": "."
  }
}
```
