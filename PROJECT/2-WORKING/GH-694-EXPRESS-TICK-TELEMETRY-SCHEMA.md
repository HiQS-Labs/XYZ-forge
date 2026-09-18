---
title: "GH-694: express telemetry in .tick/events/ breaks tick's fold in the same clone (localeCompare of undefined)"
status: active
created: 2026-09-18
updated: 2026-09-18
owner: unassigned
goal: Align express telemetry event envelope with Tick schema and guard Tick projection against non-task/malformed events
gh_issue: 694
source: https://github.com/HiQS-Labs/XYZ-forge/issues/694
doc_type: fix
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/592
  - https://github.com/HiQS-Labs/XYZ-forge/pull/597
  - https://github.com/HiQS-Labs/XYZ-forge/issues/267
context_tags: [express, tick, telemetry, schema, project, fold]
non_goals:
  - Cross-language schema validation engines or complex middleware
  - Restructuring the central mirror (it receives the same additive envelope)
  - Changes to governance documents
effort: 1
complexity: 1
risk: 1
---

# GH-694 — express telemetry in .tick/events/ breaks tick's fold in the same clone

## Status

| What was just completed | What's next |
|---|---|
| Dual-sided fix implemented in express.py and src/project.js; regression tests pinned in test/gh267-express-skill.sh; Plan QA & Final QA attested | Opus 5 QA round 2 & PR update |

## Background & Observed Friction

In task clones where `/express` has fired, running `./bin/tick info`, `./bin/tick release`, or any command that invokes `fold` throws:
```text
TypeError: Cannot read properties of undefined (reading 'localeCompare')
```

`utils/py/express.py` `write_tick()` was writing an ad-hoc JSON record into `.tick/events/` missing standard Tick event fields (`schema_version`, `ts`, `type`, `task`, `agent`). `src/project.js` `foldWithMeta()` bucketed events by `ev.task` (`undefined`), resulting in a task entry with `id: undefined` that crashed `renderState()`.

## Required Changes

1. **Producer (`utils/py/express.py`):**
   - Emit canonical Tick event envelope (`schema_version: "0.2.0"`, `ts: now_iso()`, `type: "express." + verb.replace("express-", "")`, `task: "GH-<n>"` if issue else `"lane"`, `agent: "express"`).
2. **Consumer (`src/project.js`):**
   - Add defensive check in `foldWithMeta()`: `if (!ev || typeof ev.task !== 'string' || !ev.task) continue; if (!ev.type || !ev.type.startsWith('task.')) continue;`.
3. **Verification (`test/gh267-express-skill.sh`):**
   - Add consumer coexistence assertion: run `TICK_REPO_ROOT="$FX" "$HERE/../bin/tick" project` after express refusal/landing/resume fixtures and assert exit code 0.

## Acceptance Criteria
- [x] `test/gh267-express-skill.sh` passes (98/98) and validates `tick project` exits 0 after express telemetry writes.
- [x] `npm test` passes (23/23).
- [x] Plan QA approved & attested by agy.
- [x] Final QA approved & attested by agy.

