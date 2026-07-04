---
gh_issue: 87
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/87
title: Deep Research mode — provider-agnostic grounded search seam (Agy Gemini Search first adapter)
status: Phase 1 implemented on branch, awaiting review/merge and issue #87 close-out
created: 2026-07-02
updated: 2026-07-03
owner: noel
doc_type: feature
goal: >
  Ship a provider-agnostic grounded-search adapter, isolated from the harness's default model
  client and Aider's OpenAI-compatible config, with Agy Gemini Search as the first backend and a
  normalized {answer, citations, query, provider, model, raw} contract so a second backend
  (Perplexity) can be added later without reworking the seam.
complexity: 3
risk: 2
effort: 3
phases: 3
roadmap_exempt: false
non_goals:
  - Not changing the harness's default model provider or Aider's global OpenAI-compatible base URL
  - Not hard-coding the design to Agy Gemini Search only; Agy Gemini Search is the first desired backend, not the lasting abstraction
related:
  - skills/consult/SKILL.md
---

# GH-87 — Deep Research mode

## Status

| What was just completed | What's next |
|---|---|
| Phase 1 shipped on branch `marathon/gh-87-deep-research-mode-2026-07-03` (worktree build): `relay-automation/deep-research.mjs` — a zero-dep Node adapter wrapping the `agy` CLI as the first grounded-search backend, normalizing output to `{answer, citations, query, provider, model, raw}`. Runs `agy -p` in a throwaway tmpdir (side-effect free) with a hard timeout via `execFile`'s `timeout` option; fail-closed typed errors (`binary_missing`/`timeout`/`empty_output`/`backend_error`) on stderr, never a silent fallback. `test/deep-research.sh` (21 assertions) covers request construction, CITATIONS-heading normalization, bare-URL fallback extraction, side-effect-free isolation, and all four failure modes. Wired into `validate.sh` (91/91 passing, full suite, live-agent test skipped via `RELAY_SELF_SUFFICIENCY_SKIP=1` to avoid real API spend). | Review + merge the branch, then close issue #87. Perplexity remains a follow-up phase (not started) — the normalized schema and adapter boundary are already provider-agnostic to receive it without a rework. |

## Problem

The harness now supports Aider CLI as a headless runner, and agents need a grounded web-search
capability that can return fresh, cited answers without coupling the rest of the harness to one
provider. The GitHub ask originally named Perplexity Sonar as the first desired backend, but the local plan
should keep the **search-provider seam provider-agnostic** so a second backend can be added later
without reworking the tool contract or global provider config.

## Local framing

- Treat grounded search as a **dedicated provider seam**, isolated from the harness's default model
  client and from Aider's general OpenAI-compatible model configuration.
- Use **Agy Gemini Search** as the **first concrete adapter/backend** via an isolated CLI wrapper, with Perplexity as a follow-up phase.
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
  - isolated CLI wrapper for Agy Gemini Search
  - normalized response parsing from the CLI output
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
- Agy Gemini Search remains the first implementation target and may still be surfaced as an
  `agy_search` tool if external compatibility wants that name, but the local architecture
  must not assume Agy Gemini Search-only semantics.
- Aider's default provider settings remain untouched; search uses its own isolated adapter/client.

## Definition of done

- [x] The repo has a dedicated grounded-search adapter/client with isolated env/config (`relay-automation/deep-research.mjs`; `AGY_BIN`/`DEEP_RESEARCH_TIMEOUT_MS` env, no shared state with Aider's config).
- [x] Agy Gemini Search works as the first backend via the Agy CLI and returns normalized cited output.
- [x] Search failures never silently fall back to the default provider (typed error + exit 1 on missing binary/timeout/empty output/non-zero exit).
- [x] Tests cover request shape, normalization, missing config, transport failures, and citation parsing (`test/deep-research.sh`, 21 assertions; "missing config" realized as CLI-missing/binary_missing since Agy auth has no API-key config to test, unlike the original Perplexity framing).

## Implementation Plan

**Confirmation of Agy Grounded Search:**
The Antigravity CLI (`agy`) has Google grounded search built-in. By leveraging this built-in capability, we can retrieve real-time, cited answers and parse the citation links directly from the CLI's output. This removes the need for a third-party subscription or new external dependencies for Phase 1.

**Reversibility & Blast Radius:**
- **Reversibility:** Easy. This introduces a standalone adapter module that is not yet wired into the core `tick` loop or the agent planner. If the design needs to change, it can be reverted entirely.
- **Blast Radius:** None (Leaf-util). It does not touch `relay-turn-lib.sh`, the `tick` event log kernel, or Aider's global configuration.

### Execution Steps
1. **Create `relay-automation/deep-research.mjs`**:
   - Use the Node standard library (`child_process.execFile` or `spawn`) to invoke the Agy CLI safely without new `package.json` dependencies.
2. **Parse and Normalize Output**:
   - Extract the core text and citation links from the Agy CLI stdout.
   - Construct the normalized JSON payload: `{answer, citations, query, provider: "agy", model: "gemini", raw: <full output>}`.
3. **Fail-Closed Error Handling**:
   - If the `agy` CLI is missing, times out, or returns a non-zero exit code, emit a typed error.
   - Never silently fall back to a default model.
4. **Create `test/deep-research.sh`**:
   - Assert normalized extraction works for mock standard outputs.
   - Assert fail-closed behavior for CLI missing / timeout / non-zero exit states.
5. **Verify**:
   - Run `bash test/deep-research.sh` locally. `-> expect 0`
   - Run `bash validate.sh` for global regressions. `-> expect 0`

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
  "remediation": "Build the grounded-search adapter/client as an isolated relay-automation/ module utilizing the Agy CLI (e.g., `agy <search_command>`) for the first backend, mirroring the isolated-adapter pattern already used by relay-automation/aider-turn.sh and consult.sh. Parse the CLI output to construct normalized {answer, citations, query, provider, model, raw} output. Ensure a fail-closed typed error on CLI failure or timeout (never a silent fallback to the default model provider), and include latency/model/citation-presence logging. Keep the tool side-effect free. Add test/deep-research.sh covering CLI invocation, response normalization, CLI missing/failure handling, and citation extraction.",
  "lanes": {
    "agy_safe": ["relay-automation/deep-research.mjs", "test/deep-research.sh"],
    "orchestrator_only": [],
    "note": "Independent leaf-util zone: new isolated adapter module, no kernel/relay-drive touch, no mutation of Aider's default provider config. agy-safe, parallel-safe with any other wave lane. This is a proposed single-lane artifact set covering the Phase-1 scope (adapter+tool+tests); the doc's phases=3 rating anticipates follow-on hardening phases not yet broken out here."
  }
}
```
