---
gh_issue: 1222
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1222
title: "releases: _live_manifest_count double-counts a shipped+redialed issue (#1214 P5)"
status: Active (2-WORKING — marathon GH-1214 phase p1)
created: 2026-10-25
updated: 2026-10-25
owner: marathon-gh-1214
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: false   # rated 2026-10-25 at marathon prep: two COUNT queries, confirmed reachable by Kimi K3.1 QA on #1214
non_goals:
  - Changing redial semantics (a redial still inserts a second row — GH-111/GH-351 append-only trail)
  - Rewriting already-captured baseline_count values in existing databases
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1214 (umbrella, Phase 5)
  - GH-111, GH-351 (row-per-dial design)
goal: >
  A release's live manifest count and the migration-004 backfill count each issue once, even when
  that issue has both a shipped row and a redialed dialed_in row in the same release.
---

# GH-1222 — `_live_manifest_count` double-counts a shipped+redialed issue

## Status

| What was just completed | What's next |
|---|---|
| 2026-10-25: promoted to 2-WORKING as phase p1 of marathon #1214; contract added; reachability confirmed by Kimi K3.1 QA (`releases_app.py:114-123,2618-2677`) | Marathon phase p1 (agy builder, codex reviewer): switch both queries to `COUNT(DISTINCT issue_ref_id)`, record the manual check, gate green |

Umbrella: #1214 · Phase p1 · first in the chain (no `depends_on`).

## Ground truth (`origin/development` 395e9d64)

- `utils/py/releases_app.py:114-123` — re-dialing a shipped item inserts a **second** row (`dialed_in`) beside the `shipped` row.
- `utils/py/releases_app.py:2517-2522` — `_live_manifest_count` runs `SELECT COUNT(*) FROM manifest_items WHERE release_id = ? AND state IN ('dialed_in','shipped')`, which counts that issue twice. It feeds the write-once `baseline_count` (`:2533`).
- `utils/py/releases_app.py:824-833` — migration 004's backfill uses the same shape.

## Plan (one phase)

1. Change `_live_manifest_count` to `COUNT(DISTINCT issue_ref_id)` and add a `GH-1222` comment explaining why: one issue can hold a shipped row and a redialed row at once.
2. Make the same change in migration 004's backfill query, with the same comment tag.
3. Record a manual check under `TESTS-RESULTS/2026-10-25+GH-1222/` using a throwaway database under `$TMPDIR`, never the repo's `releases.db`. Dial an issue, ship it, redial it; show the count is 1, not 2, before the fix (red control) and after; show that a second distinct issue raises the count to 2. Write `manual-check.md` with the commands and output, plus `provenance.jsonl`.

Rules: Python only; shortest diff (`/ponytail`); no new suite or registry entry (GH-831 D7). Edit an existing suite only if a pinned assertion becomes untrue. Do not touch `releases.db` / `releases.sql` / `CHANGELOG.md` (orchestrator reconciles at landing).

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
      "pattern": "GH-1222"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-25+GH-1222/manual-check.md"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-25+GH-1222/provenance.jsonl"
    }
  ],
  "artifacts": [
    "utils/py/releases_app.py",
    "TESTS-RESULTS/2026-10-25+GH-1222/manual-check.md",
    "TESTS-RESULTS/2026-10-25+GH-1222/provenance.jsonl"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-10-25+GH-1222/manual-check.md",
    "TESTS-RESULTS/2026-10-25+GH-1222/provenance.jsonl"
  ],
  "remediation": {
    "source": "issue#1222",
    "criteria": "_live_manifest_count and the migration-004 backfill in utils/py/releases_app.py count DISTINCT issue_ref_id over dialed_in+shipped rows, so a shipped-then-redialed issue counts once while distinct issues still add; a GH-1222 comment explains why; a manual red/green check on a throwaway DB is recorded under TESTS-RESULTS/2026-10-25+GH-1222/ with provenance.jsonl; existing releases suites stay green."
  },
  "lanes": {
    "agy_safe": [
      "utils/py/releases_app.py",
      "TESTS-RESULTS/2026-10-25+GH-1222/manual-check.md",
      "TESTS-RESULTS/2026-10-25+GH-1222/provenance.jsonl"
    ],
    "orchestrator_only": []
  }
}
```

## Acceptance

- After a ship and a redial of one issue in a throwaway DB, `_live_manifest_count` returns 1 for it, and the migration-004 backfill expression counts it once.
- Two distinct live issues count 2.
- `test/gh32-releases-app.sh` and the full `bash validate.sh` are green.
- Manual check + `provenance.jsonl` present under `TESTS-RESULTS/2026-10-25+GH-1222/`.

## Lessons Learned (For Future Agents)

- (filled at closeout)
