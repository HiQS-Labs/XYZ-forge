---
complexity: low
risk: low
effort: low
ratings_provisional: false
title: relay telemetry extractor — on-demand ETL to focus5float health feed
status: Complete (3-COMPLETED)
created: 2026-06-25
updated: 2026-06-30
closed: 2026-06-30
owner: noelsaw1
branch: main
gh_issue: 24
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/24
track: standalone tooling
goal: >
  On-demand ETL script that reads relay-system/<date>/*.md files for a configurable date
  range and outputs aggregated health telemetry JSON matching the focus5float stoplight
  schema: [{ health, title, description, updatedAt }]. Health is derived from STATUS: and
  VERDICT: fields extracted from relay file headers and ## Log sections.
---

## Status

| Most recently completed | What's next |
|---|---|
| **✅ VALIDATED + CLOSED 2026-06-30.** `utils/telemetry/extract-relay-telemetry.sh` run against live `relay-system/` (2026-06-27→06-30): **14 records, valid JSON, exact schema** (`health/title/description/updatedAt`), health histogram 8 green / 4 orange / 2 red, mapping correct (green = STATUS Closed/Approved). Output: `relay-system/combined/aggregated-2026-06-27-to-2026-06-30.json`. | Done. (Output-only tool — no `validate.sh` integration by design; re-run on demand with `--from/--to`.) |

## Scope

- **Script:** `utils/telemetry/extract-relay-telemetry.sh`
- **Parameters:** `--from YYYY-MM-DD`, `--to YYYY-MM-DD` (default: last 7 days), `--out PATH`
- **Input:** `relay-system/<date>/*.md` files where `<date>` is in `[from, to]`
- **Output:** `relay-system/combined/aggregated-FROM-to-TO.json`
- **Schema:** `[{ "health": "green|orange|red", "title": "...", "description": "...", "updatedAt": "..." }]`

## Health mapping

| health | Condition |
|---|---|
| green | STATUS: Approved or Closed |
| orange | STATUS: Escalated, Changes requested, or In Progress with at least one VERDICT present |
| red | No VERDICT in log, empty log section, or VERDICT: FAIL under a non-terminal STATUS |

## Non-goals

- No scheduling or automation — strictly on-demand single invocation
- No relay file mutation
- No validate.sh integration (output-only tool; does not affect the relay protocol)
