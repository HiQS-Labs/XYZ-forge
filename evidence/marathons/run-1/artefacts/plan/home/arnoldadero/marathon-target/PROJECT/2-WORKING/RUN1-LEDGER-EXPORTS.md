---
title: "ledgerkit run 1 — four independent export/analysis surfaces"
status: 2-WORKING
roadmap_exempt: true
created: 2026-08-20
updated: 2026-08-20
owner: unassigned
doc_type: capture
complexity: 2
risk: 1
effort: 3
goal: >
  Add four independent, disjoint-write-set capabilities to ledgerkit — CSV export,
  currency normalization, a testable CLI entry point, and duplicate detection —
  each with its own test file, without touching the existing parser or validator.
---

## Status

| What was just completed | What's next |
|---|---|
| `ledgerkit` base library green at 8/8 (`npm test`): parse, validate, summarize. | Four independent phases, each adding one new module plus its test file. |

## Why

`ledgerkit` can read and check a ledger but cannot get data back out of it, cannot
handle more than one currency in a total, and has no command-line surface. These
are four genuinely separate gaps. None of them depends on any other, and no two of
them write the same file — which makes this the right shape for a baseline
marathon: ordering should not matter, and any halt is attributable to one phase.

## Phases

| id | what | writes |
|---|---|---|
| `r1p1` | RFC 4180 CSV export | `src/export-csv.js`, `test/export-csv.test.js` |
| `r1p2` | Currency normalization with explicit rounding | `src/fx.js`, `test/fx.test.js` |
| `r1p3` | Injectable-IO CLI with `--json` and real exit codes | `src/cli.js`, `test/cli.test.js` |
| `r1p4` | Duplicate-entry detection with memo normalization | `src/dedupe.js`, `test/dedupe.test.js` |

Full task specs live in `PROJECT/2-WORKING/RUN1-LEDGER-EXPORTS/phases-briefs/`.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "main"
  },
  "gate": "npm test",
  "fix_probes": [
    {
      "type": "path_absent",
      "path": "src/export-csv.js"
    },
    {
      "type": "path_absent",
      "path": "test/export-csv.test.js"
    },
    {
      "type": "path_absent",
      "path": "src/fx.js"
    },
    {
      "type": "path_absent",
      "path": "test/fx.test.js"
    },
    {
      "type": "path_absent",
      "path": "src/cli.js"
    },
    {
      "type": "path_absent",
      "path": "test/cli.test.js"
    },
    {
      "type": "path_absent",
      "path": "src/dedupe.js"
    },
    {
      "type": "path_absent",
      "path": "test/dedupe.test.js"
    }
  ],
  "artifacts": [
    "src/parse.js",
    "src/validate.js",
    "src/index.js",
    "package.json",
    "src/export-csv.js",
    "test/export-csv.test.js",
    "src/fx.js",
    "test/fx.test.js",
    "src/cli.js",
    "test/cli.test.js",
    "src/dedupe.js",
    "test/dedupe.test.js"
  ],
  "artifacts_new": [
    "src/export-csv.js",
    "test/export-csv.test.js",
    "src/fx.js",
    "test/fx.test.js",
    "src/cli.js",
    "test/cli.test.js",
    "src/dedupe.js",
    "test/dedupe.test.js"
  ],
  "remediation": {
    "source": "self#run1",
    "criteria": "four independent modules, each with node:test coverage, npm test green"
  },
  "lanes": {
    "agy_safe": [],
    "orchestrator_only": []
  }
}
```
