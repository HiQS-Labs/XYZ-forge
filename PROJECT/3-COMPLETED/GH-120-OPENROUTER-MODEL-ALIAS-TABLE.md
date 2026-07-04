---
gh_issue: 120
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/120
title: "Build a fuzzy-match OpenRouter model-name lookup table (alias -> canonical slug) for relay-automation"
status: Shipped (17e2681) — issue #120 closed 2026-07-03
created: 2026-07-03
updated: 2026-07-03
owner: noel
doc_type: feature
complexity: 1
risk: 1
effort: 2
roadmap_exempt: false
goal: >
  Ship a local, fuzzy-match OpenRouter model-name lookup table so relay-automation tooling can
  resolve a colloquial model name (e.g. "GLM 5.2", "Nemotron Ultra 3") to its canonical
  provider/slug id without a live API query on every lookup.
non_goals:
  - Not building the optional `--verify` re-query mode against OpenRouter's live model list in
    this lane — that is explicit follow-up work, not required for acceptance here.
  - Not a general Claude Code / cross-repo preference store — this is Aider/OpenRouter-harness
    tooling, scoped to relay-automation/.
related:
  - relay-automation/openrouter-model-aliases.yml (new)
---

# GH-120 — OpenRouter model-alias fuzzy lookup table

## Status

| What was just completed | What's next |
|---|---|
| Shipped 2026-07-03 as marathon Lane E (`17e2681`, wired into `validate.sh` in `973a4d3`): `openrouter-model-aliases.yml` + `resolve-model-alias.sh` (4-tier fuzzy matcher: normalized exact → squashed → sorted-token → substring) + `test/model-alias.sh` (10/10 pass). Independently re-verified via a GLM 5.2 reverse-dogfood review (2026-07-03), which traced the fuzzy-match tiers by hand and confirmed the free-variant collision case resolves correctly; that review also caught a stale README claim ("not yet wired into validate.sh"), fixed in `1642304`. Issue #120 closed 2026-07-03. | Nothing — done. Optional follow-up (explicitly out of scope, not queued): a `--verify` mode re-querying OpenRouter's live catalog to flag stale aliases. |

## Motivation

Resolving colloquial model names ("GLM 5.2", "Nemotron Ultra 3") to their canonical OpenRouter
slug (`z-ai/glm-5.2`, `nvidia/nemotron-3-ultra-550b-a55b`) currently requires a live query against
`https://openrouter.ai/api/v1/models` every time — captured live 2026-07-03 during GH-118 testing.
Slow, burns a network call per lookup, doesn't scale across sessions.

## Fix direction

1. Ship `relay-automation/openrouter-model-aliases.yml` seeded with the models tested so far:
   ```yaml
   glm-5.2: z-ai/glm-5.2
   nemotron ultra 3: nvidia/nemotron-3-ultra-550b-a55b
   nemotron ultra 3 free: nvidia/nemotron-3-ultra-550b-a55b:free
   ```
2. A small lookup helper that normalizes input (lowercase, strip punctuation/hyphens) and does a
   token/substring fuzzy match against the table's keys, returning the canonical slug.
3. Document in `relay-automation/README.md` (or the `relay-xyz` skill) how to add a new alias
   when testing a new model.

## Definition of done

- `relay-automation/openrouter-model-aliases.yml` exists with at least the 3 seeded aliases above.
- A lookup helper resolves a colloquial name to the canonical slug, fuzzy-matching close variants
  (e.g. "Nemotron 3 Ultra" or "nemotron-ultra3" still resolves).
- Documented how to add a new alias.
- New `test/model-alias.sh` asserts the seeded aliases resolve correctly, including at least one
  fuzzy-variant case; wired into `validate.sh`.

## Swarm Preflight Contract

Consumed by `utils/swarm-preflight.sh`. Same-repo build (`target.ref: main`). Independent zone
(agy-safe), one new data file + one new helper + one new test. Stub `.yml` (header/comment only,
no entries) and a placeholder `test/model-alias.sh` (always-pass) were pre-created 2026-07-03 so
`swarm-preflight`'s artifact-existence check (GH-39 A2) passes; freshness is instead driven by a
`grep_absent` probe on real alias content, not file existence.

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash test/model-alias.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "relay-automation/openrouter-model-aliases.yml", "pattern": "glm-5.2:" } ],
  "artifacts":   [ "relay-automation/openrouter-model-aliases.yml", "test/model-alias.sh" ],
  "remediation": { "source": "GH-120#fix-direction", "criteria": "relay-automation/openrouter-model-aliases.yml exists seeded with at least glm-5.2, 'nemotron ultra 3', and 'nemotron ultra 3 free' mapped to their canonical OpenRouter slugs; a lookup helper normalizes and fuzzy-matches an input name against the table; usage documented; new test/model-alias.sh asserts the seeded aliases resolve, including a fuzzy variant, and is wired into validate.sh." },
  "lanes":       { "agy_safe": [ "relay-automation/openrouter-model-aliases.yml", "test/model-alias.sh" ], "orchestrator_only": [] }
}
```
