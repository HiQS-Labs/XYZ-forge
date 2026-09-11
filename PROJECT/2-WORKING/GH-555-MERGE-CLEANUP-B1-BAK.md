---
gh_issue: 555
source: https://github.com/HiQS-Labs/XYZ-forge/issues/555
title: "merge-cleanup B1 leaves releases.db.bak after ledger conflict resolution"
status: 2-WORKING
created: 2026-09-10
updated: 2026-09-10
owner: unassigned
doc_type: capture
complexity: 1
risk: 2
effort: 1
ratings_provisional: false
goal: "Leave a successfully resolved B1 landing clone free of the rebuild backup that makes the gate red."
---

## Status

| What was just completed | What's next |
|---|---|
| Reproduced while landing PR #538: B1 resolved the ledger correctly but left `releases.db.bak`, causing `gh32-releases-artifacts.sh` to fail. | Remove only the known rebuild backup after successful rebuild and pin clean-tree behavior in the real B1 fixture. |

## Acceptance

- [ ] A successful B1 resolution leaves no `releases.db.bak` and no unexpected untracked files.
- [ ] Cleanup happens only after `check --rebuild` succeeds; a failed rebuild preserves its recovery evidence.
- [ ] Cleanup is confined to the exact clone root and exact backup filename.
- [ ] The existing real B1 fixture proves both successful cleanup and failed-rebuild preservation.

## Swarm Preflight Contract

```json
{
  "target": {"repo": ".", "ref": "development"},
  "gate": "python3 test/gh534_phase_b_tests.py",
  "fix_probes": [
    {"type": "grep_absent", "path": "skills/merge-cleanup/scripts/ledger_merge.py", "pattern": "releases\\.db\\.bak.*unlink|unlink.*releases\\.db\\.bak", "note": "bug evidence: B1 has no successful-rebuild cleanup"}
  ],
  "artifacts": ["skills/merge-cleanup/scripts/ledger_merge.py", "test/gh534_phase_b_tests.py"],
  "remediation": {"source": "issue#555", "criteria": "successful B1 resolution deletes only the exact rebuild backup and leaves a clean clone; failed rebuild retains recovery evidence"},
  "lanes": {"agy_safe": ["skills/merge-cleanup/scripts/ledger_merge.py", "test/gh534_phase_b_tests.py"], "orchestrator_only": []}
}
```
