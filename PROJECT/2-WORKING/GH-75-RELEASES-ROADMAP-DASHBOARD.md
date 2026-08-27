---
title: Single-page HTML dashboard — releases + roadmap in one read-only view
status: Proposed (1-INBOX — not yet active)
created: 2026-08-27
updated: 2026-08-27
owner: noel
gh_issue: 75
source: https://github.com/HiQS-Labs/XYZ-forge/issues/75
doc_type: feature
complexity: 3
risk: 2
effort: 3
phases: 1
ratings_provisional: true
non_goals:
  - Any write path — the dashboard opens the DB read-only, takes no lock, bumps no generation.
  - Replacing RELEASES-PREVIEW.html — extend, do not fork.
related:
  - GH-269 (switchover makes the DB the only roadmap truth this page renders)
fix_probes:
  - python3 utils/py/releases_app.py dashboard --help
---

# GH-75 — Single-page HTML dashboard: releases + roadmap in one view

One self-contained read-only HTML page rendering both ledgers in `releases.db`:
release cards (version, status, target, manifest open/closed split) plus roadmap
cards grouped by section, with a trust header (generation, receipt count, sync
staleness banner). Full requirements in the issue body.

**2026-08-27 validity scan (pre-jog):** the issue predates the current preview
pipeline. `RELEASES-PREVIEW.html` (644 lines) already exists and is refreshed by
the writer protocol — but it renders the releases side only (zero roadmap
content) and there is no `releases dashboard` verb and no `docs/dashboard.html`.
So the work is NOT done; the right build is to **extend the existing preview
generator** with the roadmap panel + trust header (or grow it into the
`dashboard` verb the issue names) rather than building a parallel renderer.
Issue's `roadmap sync`-staleness banner requirement is obsolete in releases-mode
(sync refuses); the staleness signal should instead compare dump generation vs
DB. Source of truth: https://github.com/HiQS-Labs/XYZ-forge/issues/75

## Status

| Field | Value |
| --- | --- |
| Stage | 1-INBOX capture; scanned 2026-08-27 — not started, scope repointed at existing preview generator |

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh",
  "fix_probes": [
    {
      "type": "grep_absent",
      "path": "utils/py/releases_app.py",
      "pattern": "def cmd_dashboard"
    },
    {
      "type": "path_absent",
      "path": "test/gh75-dashboard.sh"
    }
  ],
  "artifacts": [
    "utils/py/releases_app.py",
    "test/gh75-dashboard.sh",
    "validate.sh"
  ],
  "remediation": {
    "source": "issue#75 (scope repointed 2026-08-27: extend the existing preview generator, not a parallel renderer)",
    "criteria": "releases dashboard verb renders one self-contained read-only HTML page with BOTH panels (release cards + roadmap cards grouped by section) and a trust header (generation, receipt count, dump-vs-DB staleness banner); read-only DB open, no lock, no generation bump; test/gh75-dashboard.sh registered in validate.sh covers empty states and read-only invariants."
  },
  "artifacts_new": [
    "test/gh75-dashboard.sh"
  ]
}
```
