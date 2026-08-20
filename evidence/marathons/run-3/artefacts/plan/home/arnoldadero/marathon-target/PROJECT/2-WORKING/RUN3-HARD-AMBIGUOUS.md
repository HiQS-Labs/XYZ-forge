---
title: "ledgerkit run 3 — uneven difficulty, including one deliberately under-specified phase"
status: 2-WORKING
roadmap_exempt: true
created: 2026-08-20
updated: 2026-08-20
owner: unassigned
doc_type: capture
complexity: 4
risk: 2
effort: 4
goal: >
  Four phases of deliberately uneven difficulty — one routine, one genuinely hard
  (exact BigInt decimal arithmetic), one deliberately under-specified, one routine
  — to observe what the reviewer does when the builder produces weak work or when
  the brief cannot be satisfied as written.
---

## Status

| What was just completed | What's next |
|---|---|
| Run 1 (independent) and run 2 (dependency chain) established the baseline shapes. | An uneven run: the interesting data is in phases 2 and 3, not in whether the suite goes green. |

## Why this shape

Runs 1 and 2 vary STRUCTURE. This run varies DIFFICULTY, which is what actually
stresses a builder/reviewer loop over a long horizon.

- **r3p2** is hard but fully specified. Exact decimal arithmetic on `BigInt` has
  well-known traps — HALF_EVEN at the boundary, sign symmetry on negative
  rounding, scale alignment. The brief names them, so a weak result is visible
  against a stated bar. It also explicitly invites the builder to declare a
  narrower correct subset instead of over-claiming.
- **r3p3** is under-specified ON PURPOSE. "Sensibly", "good quality", "the best
  one", "tune how strict" — no thresholds, no algorithm, no tie-break rule, and
  acceptance says only "realistic data". A builder can satisfy every word of it
  with something almost arbitrary. The question being observed is whether the
  reviewer notices that the brief cannot be objectively checked and says so, or
  whether it approves against a bar nobody set.

Neither phase is expected to fail. Both are expected to produce something
arguable, which is the point.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "npm test",
  "fix_probes":  [
    { "type": "path_absent", "path": "src/sort.js" },
    { "type": "path_absent", "path": "test/sort.test.js" },
    { "type": "path_absent", "path": "src/decimal.js" },
    { "type": "path_absent", "path": "test/decimal.test.js" },
    { "type": "path_absent", "path": "src/fuzzy-match.js" },
    { "type": "path_absent", "path": "test/fuzzy-match.test.js" },
    { "type": "path_absent", "path": "src/stats.js" },
    { "type": "path_absent", "path": "test/stats.test.js" }
  ],
  "artifacts":   [
    "src/parse.js",
    "src/index.js",
    "src/sort.js",
    "test/sort.test.js",
    "src/decimal.js",
    "test/decimal.test.js",
    "src/fuzzy-match.js",
    "test/fuzzy-match.test.js",
    "src/stats.js",
    "test/stats.test.js"
  ],
  "artifacts_new": [
    "src/sort.js",
    "test/sort.test.js",
    "src/decimal.js",
    "test/decimal.test.js",
    "src/fuzzy-match.js",
    "test/fuzzy-match.test.js",
    "src/stats.js",
    "test/stats.test.js"
  ],
  "remediation": { "source": "self#run3", "criteria": "four phases of uneven difficulty land with npm test green; the weak/ambiguous phases are judged on what the reviewer says, not only on the gate" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
