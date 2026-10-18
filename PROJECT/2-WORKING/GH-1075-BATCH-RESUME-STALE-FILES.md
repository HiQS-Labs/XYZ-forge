---
gh_issue: 1075
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1075
title: merge-cleanup batch record keeps stale per-PR file lists on resume
status: Active
created: 2026-10-14
fix_probes:
  - test -f skills/2-daily/merge-cleanup/scripts/batch_record.py
  - python3 test/gh436-merge-cleanup.py --help
doc_type: feedback
effort: 1
complexity: 1
risk: 1
phases: 1
updated: 2026-10-16
owner: Noel Saw
goal: "merge-cleanup batch record keeps stale per-PR file lists on resume"
# jog: goal auto-filled from title; refine
---
## Status

| What was just completed | What's next |
|---|---|
| Promoted to active working contract via jog | Execute implementation and verify probes |

# GH-1075: batch record keeps stale per-PR file lists on resume

Found in review of #1069 (GH-1064). `batch_record.extend()` appends only PRs it has not seen before.
On `--resume`, a known PR whose branch changed since the batch began keeps the file list captured when
the batch was created. The sweep's `shared_files` can then miss overlaps between landed PRs.

Smallest fix: in `extend()`, refresh `files` and `soft` for already-planned PRs from the current queue.
Keep order and outcomes unchanged. Verify with a manual check (GH-831).

## Merge evidence

- PR #1069 merged 2026-10-15 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash ci-local.sh",
  "fix_probes": [
    {
      "type": "command",
      "cmd": "cd skills/2-daily/merge-cleanup/scripts && python3 -c \"import batch_record as b,tempfile,os,sys;d=tempfile.mkdtemp();rec={'planned':[b._row(1,{'number':1,'files':['a']})],'outcomes':{'1':{'status':'unattempted'}},'path':os.path.join(d,'r.json')};b.extend(rec,[{'number':1,'files':['a','b']}]);sys.exit(0 if rec['planned'][0]['files']==['a','b'] else 1)\"",
      "expect_nonzero": true,
      "note": "pre-fix: extend() leaves a known PR's files stale (exit 1); landed when files refresh (exit 0)"
    }
  ],
  "artifacts": [
    "skills/2-daily/merge-cleanup/scripts/batch_record.py"
  ],
  "remediation": {
    "source": "issue#1075",
    "criteria": "On --resume, extend() refreshes files and soft for already-planned PRs from the current queue; order and outcomes unchanged. Verify with the existing gh436 suite plus a manual check (GH-831)."
  },
  "lanes": {
    "agy_safe": [
      "skills/2-daily/merge-cleanup/scripts/batch_record.py"
    ],
    "orchestrator_only": []
  }
}
```

## Merge evidence

- PR #1097 merged 2026-10-18 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
