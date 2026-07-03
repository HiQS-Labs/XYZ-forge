---
gh_issue: 87
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/87
title: Deep Research mode — provider-agnostic grounded search seam (Perplexity first adapter)
status: Proposed (1-INBOX — not yet active)
created: 2026-07-02
updated: 2026-07-02
owner: noel
doc_type: feature
complexity: 3
risk: 2
effort: 3
phases: 3
roadmap_exempt: false
non_goals:
  - Not changing the harness's default model provider or Aider's global OpenAI-compatible base URL
  - Not hard-coding the design to Perplexity only; Perplexity is the first desired backend, not the lasting abstraction
related:
  - skills/consult/SKILL.md
---

# GH-87 — Deep Research mode

## Problem

The harness now supports Aider CLI as a headless runner, and agents need a grounded web-search
capability that can return fresh, cited answers without coupling the rest of the harness to one
provider. The GitHub ask names Perplexity Sonar as the first desired backend, but the local plan
should keep the **search-provider seam provider-agnostic** so a second backend can be added later
without reworking the tool contract or global provider config.

## Local framing

- Treat grounded search as a **dedicated provider seam**, isolated from the harness's default model
  client and from Aider's general OpenAI-compatible model configuration.
- Use **Perplexity's OpenAI-compatible API** as the **first concrete adapter/backend**, not the only
  design shape.
- Keep failures **fail-closed**: if the grounded-search backend is unavailable, return a typed tool
  error and never silently fall back to the default model provider.

## Requested capabilities

- Add a first-class grounded-search tool for agents that accepts:
  - `query: string` required
  - `search_context_size: "low" | "medium" | "high"` optional
  - `temperature: number` optional, default `0.0`
  - `max_tokens: number` optional
- Return normalized tool output:
  - `answer`
  - `citations`
  - `query`
  - `provider`
  - `model`
  - `raw`
- Build a dedicated grounded-search adapter/client with:
  - isolated API key / base URL / model config
  - an OpenAI-compatible chat-completions request shape
  - preserved unknown provider payload fields in `raw`
  - latency / model / citation-presence logging
- Use a factual, citation-oriented system prompt that forbids fabricated URLs, titles, or quotes.
- Add tests for:
  - request construction
  - response normalization
  - missing API key
  - timeout / non-200 handling
  - citation extraction

## Provider-agnostic acceptance read

- The underlying seam is generic enough that a second grounded-search backend can be added without
  changing the normalized result schema or the harness's default model-provider configuration.
- Perplexity remains the first implementation target and may still be surfaced as a
  `perplexity_search` tool if external compatibility wants that name, but the local architecture
  must not assume Perplexity-only semantics.
- Aider's default provider settings remain untouched; search uses its own isolated adapter/client.

## Definition of done

- [ ] The repo has a dedicated grounded-search adapter/client with isolated env/config.
- [ ] Perplexity works as the first backend and returns normalized cited output.
- [ ] Search failures never silently fall back to the default provider.
- [ ] Tests cover request shape, normalization, missing config, transport failures, and citation parsing.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "path_absent", "path": "relay-automation/deep-research.mjs" }
  ],
  "artifacts": [
    "relay-automation/deep-research.mjs",
    "test/deep-research.sh"
  ],
  "remediation": "Build the grounded-search adapter/client as an isolated relay-automation/ module (Node stdlib fetch only, no new dependency), mirroring the isolated-adapter pattern already used by relay-automation/aider-turn.sh and consult.sh: request construction against Perplexity's OpenAI-compatible chat-completions API (PERPLEXITY_API_KEY / PERPLEXITY_BASE_URL default https://api.perplexity.ai / PERPLEXITY_MODEL default sonar), normalized {answer, citations, query, provider, model, raw} output, fail-closed typed error on missing key/timeout/non-200 (never a silent fallback to the default model provider), and latency/model/citation-presence logging. Keep the tool side-effect free. Add test/deep-research.sh covering request construction, response normalization, missing API key, timeout/non-200 handling, and citation extraction.",
  "lanes": {
    "agy_safe": ["relay-automation/deep-research.mjs", "test/deep-research.sh"],
    "orchestrator_only": [],
    "note": "Independent leaf-util zone: new isolated adapter module, no kernel/relay-drive touch, no mutation of Aider's default provider config. agy-safe, parallel-safe with any other wave lane. This is a proposed single-lane artifact set covering the Phase-1 scope (adapter+tool+tests); the doc's phases=3 rating anticipates follow-on hardening phases not yet broken out here."
  }
}
```
