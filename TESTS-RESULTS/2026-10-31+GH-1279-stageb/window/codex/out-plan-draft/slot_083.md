# Plan draft: #1075 merge-cleanup batch record: resume keeps stale per-PR file lists, so shared-file overlaps can be missed (GH-1064 follow-up)

> draft; preflight and independent plan QA outstanding

- Request: `gh-1075-a1c34cac032e` (tick `slot_083`)
- Draft status: **held** (held: planner state already-closed)
- Planner state: already-closed; flags: none
- Rating: 50/50/50/80
- Capture doc: PROJECT/2-WORKING/GH-1075-BATCH-RESUME-STALE-FILES.md (sha256 5b14848a0683b7874160cc7dc9ed36f2d8ecb2499d1572e35738593e000a03a7)
- Issue sha256: a1c34cac032eabf2e12446ea8691d5cfb8c274fc562e60eab4fcb88be90aab23 (updated 2026-10-24T22:00:30Z)
- Dependencies: none

## Scope

_Source: PROJECT/2-WORKING/GH-1075-BATCH-RESUME-STALE-FILES.md:L18 (jog: goal auto-filled from title; refine)_

---
## Status

| What was just completed | What's next |
|---|---|
| Promoted to active working contract via jog | Execute implementation and verify probes |

_Source: PROJECT/2-WORKING/GH-1075-BATCH-RESUME-STALE-FILES.md:L17 (frontmatter goal)_

merge-cleanup batch record keeps stale per-PR file lists on resume

_Source: codex-authored (codex-authored)_

Verify the current resume and sweep-input behavior, including whether the reported issue has already been fixed.

_Source: codex-authored (codex-authored)_

Refresh files and soft for already-planned PRs from the current queue while preserving their order and outcomes.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

On resume, shared_files reflects current file lists for landed PRs.

_Source: codex-authored (codex-authored)_

The change leaves landing, the QA gate and the verdict unaffected.

_Source: codex-authored (codex-authored)_

Verify using the existing gh436 suite and a manual check.

## Open questions

_Source: codex-authored (codex-authored)_

Do current code and merge history still exhibit the reported stale-list behavior?

## Write set

- `skills/2-daily/merge-cleanup/scripts/batch_record.py` (PROJECT/2-WORKING/GH-1075-BATCH-RESUME-STALE-FILES.md:preflight-contract)

## Unresolved file names

- none

## Contract probes

- command ``: unverified

## Existing preflight contract

```json
{
  "artifacts": [
    "skills/2-daily/merge-cleanup/scripts/batch_record.py"
  ],
  "fix_probes": [
    {
      "cmd": "cd skills/2-daily/merge-cleanup/scripts && python3 -c \"import batch_record as b,tempfile,os,sys;d=tempfile.mkdtemp();rec={'planned':[b._row(1,{'number':1,'files':['a']})],'outcomes':{'1':{'status':'unattempted'}},'path':os.path.join(d,'r.json')};b.extend(rec,[{'number':1,'files':['a','b']}]);sys.exit(0 if rec['planned'][0]['files']==['a','b'] else 1)\"",
      "expect_nonzero": true,
      "note": "pre-fix: extend() leaves a known PR's files stale (exit 1); landed when files refresh (exit 0)",
      "type": "command"
    }
  ],
  "gate": "bash ci-local.sh",
  "lanes": {
    "agy_safe": [
      "skills/2-daily/merge-cleanup/scripts/batch_record.py"
    ],
    "orchestrator_only": []
  },
  "remediation": {
    "criteria": "On --resume, extend() refreshes files and soft for already-planned PRs from the current queue; order and outcomes unchanged. Verify with the existing gh436 suite plus a manual check (GH-831).",
    "source": "issue#1075"
  },
  "target": {
    "ref": "development",
    "repo": "."
  }
}
```
