---
gh_issue: 594
source: https://github.com/HiQS-Labs/XYZ-forge/issues/594
title: "express: is_doc_path exempts every PROJECT/** path from bounds — an unrelated governance edit can ride the hotfix lane uncounted"
status: Active (2-WORKING)
created: 2026-09-21
updated: 2026-09-21
owner: unassigned
doc_type: capture
complexity: 1
risk: 2
effort: 1
rating: "pri/sev/appeal/effort 60/60/90/60 · calc 270"
rating_ovr: null
is_manual_override: false
ratings_provisional: true
goal: >
  express's bounds exempt only the lane's own capture doc and CHANGELOG.md; an unrelated
  PROJECT/** edit counts and trips `bounds`.
---

# GH-594 — express: is_doc_path exempts every PROJECT/** path from bounds — an unrelated governance edit can ride the hotfix lane uncounted

## Status

| What was just completed | What's next |
|---|---|
| Queued by the 2026-09-21 `/10days` sweep: validity, reproducibility and not-already-done verified against HEAD e565c0fe (see Why); contract auto-drafted. | Marathon lane fires from `marathon/10days-2026-09-21` via `swarm-preflight → marathon-drive`, scoped by the contract's `artifacts`. |

## Why

`utils/py/express.py:398-401` `is_doc_path` returns true for every `PROJECT/` path, and both the
core-file count and the insertion count honour it (callers at `:395`/`:413`/`:478`), so any
governance doc edit rides the hotfix lane uncounted — contrary to `skills/express/SKILL.md` ("only
the lane's OWN paperwork"). `capture_doc_path(root, issue)` at `:919` already exists to narrow it.
Found by Codex QA on GH-592 (finding I7) and deliberately left out of that PR; no fix commit or PR
references #594.

## Acceptance

Authored by `/10days` — the tracking issue has no `## Acceptance` section swarm-preflight recognises, so there is no block to copy verbatim. These criteria transcribe the issue's fix / expected-behaviour text.

- [ ] `is_doc_path` (or its callers) exempts only the current issue's capture doc
      (`capture_doc_path(root, issue)`) plus `CHANGELOG.md`, passing the issue through the
      existing helpers; every other `PROJECT/**` edit is counted by both the core-file and
      insertion bounds.
- [ ] `test/gh267-express-skill.sh` gains a red control: a diff that also edits an unrelated
      `PROJECT/**` file trips `bounds`; the lane's own capture doc + CHANGELOG.md still pass.
- [ ] `skills/express/SKILL.md` states the narrowed exemption where it describes bounds.
- [ ] `bash validate.sh` exits 0.

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
      "type": "grep_present",
      "path": "utils/py/express.py",
      "pattern": "return p == \"CHANGELOG\\.md\" or p\\.startswith\\(\"PROJECT/\"\\)"
    },
    {
      "type": "grep_absent",
      "path": "test/gh267-express-skill.sh",
      "pattern": "unrelated PROJECT"
    }
  ],
  "artifacts": [
    "utils/py/express.py",
    "test/gh267-express-skill.sh",
    "skills/express/SKILL.md"
  ],
  "remediation": {
    "source": "issue#594",
    "criteria": "Narrow express's PROJECT/** exemption to the lane's own capture doc + CHANGELOG.md, with a red control"
  },
  "lanes": {
    "agy_safe": [
      "utils/py/express.py",
      "test/gh267-express-skill.sh",
      "skills/express/SKILL.md"
    ],
    "orchestrator_only": []
  }
}
```

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified. Fix probes detect the BUG (`grep_present` = bug still there, `grep_absent` = fix landed), per swarm-preflight polarity.
