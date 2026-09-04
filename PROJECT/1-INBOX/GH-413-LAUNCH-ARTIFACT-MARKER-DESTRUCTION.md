---
title: The launch-artifact marker authorises a destructive rebuild of any directory — marker alone, no git history required
status: Proposed (1-INBOX — not yet active)
created: 2026-09-03
owner: noelsaw1
gh_issue: 413
source: https://github.com/HiQS-Labs/XYZ-forge/issues/413
doc_type: bug
complexity: 1
risk: 4
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Reworking the build script's overall design; the cheapest correct fix is deleting the marker.
  - Adding a push step or any network behaviour — the script correctly never pushes.
related:
  - GH-406 (umbrella — external review by Russ K.)
  - GH-204 (redaction portability work — last touched this file, ordering untouched)
goal: >
  Close an E1-proven path by which a directory containing nothing but a copied marker file is
  accepted as "a previous artifact, safe to rebuild" and cleared with rm -rf, and restore the two
  ADRs the build drops but the kernel cites.
---

# GH-413: the marker authorises destruction

> **1-INBOX capture**, not an active-work doc. On promotion, create the status table.

## Why this is the top quick win

Lowest effort on the umbrella, highest irreversibility. `.xyz-launch-artifact` is tracked in this
repo and so is `utils/build-launch-artifact.sh`, so **any public reader holds both halves** of the
mechanism.

## E1 evidence, re-executed at HEAD

A/B in a throwaway directory, torn down afterwards, live repo read-only:

| Fixture | Contents | Destination guard |
|---|---|---|
| CONTROL `victim-plain/` | two files, **no marker** | **refused** — "carries no `.xyz-launch-artifact` marker… Refusing to delete files this script did not create" |
| TEST `victim-marker/` | two files + marker, **no `.git` at all** | **accepted** — proceeded past `:153-166`, died later at the unrelated dirty-tree check (rc 2) |

The test files survived only because the working tree was dirty. On a clean tree the next
statement is `find "$DEST_NORM" -mindepth 1 -maxdepth 1 -exec rm -rf {} +`. An independent run
against two fresh clones took one from 1,144 commits to 1, `.git` included.

The control proves the guard is real and *can* fail — so the marker is a specific hole, not
missing machinery.

## Phase

Single phase, four small changes: delete the marker (or make it authority-free); refuse a
destination with >1 commit absent `--discard-history`; rewrite the "re-run freely" header; add
both cited ADRs to `KEEP_FILES` (umbrella finding 1.5, same file).

Red control: the pre-fix script wipes the marker-only fixture; the fixed one refuses it.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "utils/build-launch-artifact.sh", "pattern": "discard-history" } ],
  "artifacts":   [
    "utils/build-launch-artifact.sh",
    "test/gh413-launch-artifact-destination-guard.sh",
    "test/baselines/GH-413-negative-control.md"
  ],
  "remediation": { "source": "issue#413", "criteria": "a marker-only directory with no git history is refused, a multi-commit destination needs --discard-history, and both cited ADRs survive into the artifact" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
