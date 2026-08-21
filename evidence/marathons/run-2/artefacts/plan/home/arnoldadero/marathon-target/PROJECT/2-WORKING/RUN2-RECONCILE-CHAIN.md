---
title: "ledgerkit run 2 — exact-money reconciliation, built as a dependency chain"
status: 2-WORKING
roadmap_exempt: true
created: 2026-08-20
updated: 2026-08-20
owner: unassigned
doc_type: capture
complexity: 3
risk: 2
effort: 4
goal: >
  Replace float money with exact integer minor units and build a two-ledger
  reconciler on top of it, as a four-phase chain where each phase consumes the
  previous phase's module.
---

## Status

| What was just completed | What's next |
|---|---|
| Run 1 established four independent surfaces on the base library. | A chain where ordering is load-bearing: money -> balance -> reconcile -> report. |

## Why this shape

Run 1 deliberately had no interdependencies. This run is the opposite, to exercise
`depends_on` ordering and the halt-on-first-failure behaviour. Each phase must
READ the previous phase's actual output rather than an assumed interface, so a
weak or non-conforming earlier phase propagates visibly instead of silently.

`src/validate.js` currently tolerates sub-cent drift with `Math.abs(sum) > 0.005`.
That tolerance exists because amounts are floats. r2p1 removes the need for it and
the rest of the chain is written against exactness.

## Phases

| id | depends on | writes |
|---|---|---|
| `r2p1` | — | `src/money.js`, `test/money.test.js` |
| `r2p2` | `r2p1` | `src/balance.js`, `test/balance.test.js` |
| `r2p3` | `r2p2` | `src/reconcile.js`, `test/reconcile.test.js` |
| `r2p4` | `r2p3` | `src/report.js`, `test/report.test.js` |

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "npm test",
  "fix_probes":  [
    { "type": "path_absent", "path": "src/money.js" },
    { "type": "path_absent", "path": "test/money.test.js" },
    { "type": "path_absent", "path": "src/balance.js" },
    { "type": "path_absent", "path": "test/balance.test.js" },
    { "type": "path_absent", "path": "src/reconcile.js" },
    { "type": "path_absent", "path": "test/reconcile.test.js" },
    { "type": "path_absent", "path": "src/report.js" },
    { "type": "path_absent", "path": "test/report.test.js" }
  ],
  "artifacts":   [
    "src/parse.js",
    "src/validate.js",
    "src/money.js",
    "test/money.test.js",
    "src/balance.js",
    "test/balance.test.js",
    "src/reconcile.js",
    "test/reconcile.test.js",
    "src/report.js",
    "test/report.test.js"
  ],
  "artifacts_new": [
    "src/money.js",
    "test/money.test.js",
    "src/balance.js",
    "test/balance.test.js",
    "src/reconcile.js",
    "test/reconcile.test.js",
    "src/report.js",
    "test/report.test.js"
  ],
  "remediation": { "source": "self#run2", "criteria": "exact integer-minor-unit money, and a reconciler chain built on it, npm test green" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
