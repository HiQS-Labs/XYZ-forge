---
complexity: low
risk: low
effort: low
ratings_provisional: true
title: relay telemetry extractor — on-demand ETL to focus5float health feed
status: Active — intake 2026-06-25; script authored
created: 2026-06-25
updated: 2026-06-25
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
| GH-24 opened + `utils/telemetry/extract-relay-telemetry.sh` authored 2026-06-25. | Run against relay-system/ to validate output, close issue. |

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
