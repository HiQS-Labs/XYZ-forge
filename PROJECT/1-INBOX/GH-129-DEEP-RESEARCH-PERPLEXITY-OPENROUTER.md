---
gh_issue: 129
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/129
title: "deep-research: add Perplexity grounded search (Sonar) via OpenRouter as the second backend"
status: built + live-verified 2026-07-04, PR open
created: 2026-07-04
updated: 2026-07-04
owner: noel
doc_type: enhancement
goal: >
  Add Perplexity grounded search (Sonar) via OpenRouter as the second deep-research.mjs backend,
  behind a --provider flag that defaults to agy, reusing the repo's established OPENROUTER_API_KEY
  gateway convention and the GH-87 normalized {answer, citations, query, provider, model, raw}
  contract — fail-closed, no silent cross-provider fallback, no new dependencies.
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: false
non_goals:
  - Not changing the default provider — `--provider agy` (and no flag) stays byte-identical
  - Not adding a Perplexity vendor account or SDK — OpenRouter is the gateway, per the Aider-lane convention
  - Not building GH-124's real-backend smoke test or runaway-grounding guard here (same files, separate issue — serialize)
  - Not wiring provider fallback/racing — fail-closed typed errors only, per GH-87's contract
related:
  - relay-automation/deep-research.mjs
  - test/deep-research.sh
  - relay-automation/README.md
  - PROJECT/3-COMPLETED/GH-87-DEEP-RESEARCH-MODE.md
  - PROJECT/2-WORKING/GH-124-DEEP-RESEARCH-REAL-AGY-HARDENING.md
---

# GH-129 — deep-research: Perplexity Sonar via OpenRouter (second backend)

## Status

| What was just completed | What's next |
|---|---|
| Built 2026-07-04 on branch `gh-129-perplexity-openrouter` (worktree): `--provider agy\|openrouter` flag (default `agy`, byte-identical), `runOpenRouter` via Node global `fetch` (stdlib only), `web_search_options.search_context_size` mapping, annotations→`citations[]`→URL-scan citation normalization, typed `missing_api_key` + AbortController `timeout`. `test/deep-research.sh` **45/45** (23 agy untouched + 22 new stub-HTTP-server assertions); the fake stub credential is hand-baselined in `security-scan-baseline.txt`; `validate.sh` exit 0. **Live-verified against real OpenRouter→Perplexity Sonar the same day (GH-124's lesson applied pre-merge): 4.5s, 15 real citations with titles, normalized correctly.** | PR review + merge; then move this doc to `3-COMPLETED` and close #129. GH-124's lane (same write-set) fires only after this merges — serialize. |

## Problem (grounded in the current code)

`relay-automation/deep-research.mjs` has exactly one backend (`runAgy`), with `PROVIDER`/`MODEL`
hardcoded as top-level constants (`deep-research.mjs:26-27`). The normalized contract, the
fail-closed typed-error posture, and the citation extractor are all provider-agnostic already —
but there is no second backend and no provider selector, so grounded search is single-vendor
(Agy Gemini) and unavailable wherever `agy` isn't installed/authed. Perplexity Sonar through
OpenRouter is the follow-up phase GH-87's own doc names.

## Fix

1. **`--provider agy|openrouter` flag** (default `agy`) in `parseArgs`/`validateArgs`; dispatch in
   `main()` to `runAgy` or a new `runOpenRouter`. Default path byte-identical.
2. **`runOpenRouter`**: `POST {OPENROUTER_BASE_URL:-https://openrouter.ai/api/v1}/chat/completions`
   via Node's global `fetch` (stdlib only), `Authorization: Bearer $OPENROUTER_API_KEY`, model
   `DEEP_RESEARCH_OPENROUTER_MODEL` (default `perplexity/sonar`). Maps `--search-context-size` →
   `web_search_options.search_context_size` (Perplexity's native grounding knob),
   `--temperature`/`--max-tokens` → standard params. Timeout via `AbortController` honoring
   `DEEP_RESEARCH_TIMEOUT_MS`. Reuses the same factual, citation-oriented system prompt.
3. **Citations, in preference order**: `message.annotations[].url_citation` → Perplexity
   `citations[]` passthrough → existing bare-URL scan fallback. Same normalized `citations` shape.
4. **Fail-closed typed errors**, never a silent cross-provider fallback: new `missing_api_key`
   (no `OPENROUTER_API_KEY`), plus `timeout` / `backend_error` (non-200, malformed JSON) /
   `empty_output` mapped onto the existing classifier.
5. **Tests**: `test/deep-research.sh` gains a Node-stdlib stub HTTP server (injected via
   `OPENROUTER_BASE_URL`) asserting request shape (model, web_search_options, auth header),
   citation normalization from annotations/citations/fallback, and all failure modes. The existing
   23 agy assertions stay untouched.
6. **Docs**: second-backend row/usage in `relay-automation/README.md`; env + provider matrix in the
   adapter's header comment.

## Definition of done

- [ ] `--provider openrouter` returns normalized cited output from Perplexity Sonar via OpenRouter;
      no flag / `--provider agy` byte-identical to today.
- [ ] Typed fail-closed errors: `missing_api_key`, `timeout`, `backend_error`, `empty_output` on
      the OpenRouter path; never a silent fallback to another provider.
- [ ] `test/deep-research.sh`: existing 23 assertions green and untouched; new OpenRouter
      stub-server assertions green.
- [ ] `relay-automation/README.md` + adapter header document the backend, env vars
      (`OPENROUTER_API_KEY`, `DEEP_RESEARCH_OPENROUTER_MODEL`, `OPENROUTER_BASE_URL`), and the
      GH-124 serialization note.
- [ ] `bash validate.sh` green.

## Reversibility & blast radius

**Low.** Additive backend behind an opt-in flag; default provider path unchanged. No kernel,
relay-drive, or Aider-config touch. Reverting is deleting `runOpenRouter` + the flag. The only
coordination cost is the **write-set overlap with #124** (same three files) — serialize the two
lanes, never same-wave.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/deep-research.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/deep-research.mjs", "pattern": "openrouter" }
  ],
  "artifacts": [
    "relay-automation/deep-research.mjs",
    "test/deep-research.sh",
    "relay-automation/README.md"
  ],
  "remediation": "Add a --provider agy|openrouter flag (default agy, byte-identical default path) to relay-automation/deep-research.mjs and a runOpenRouter backend: POST ${OPENROUTER_BASE_URL:-https://openrouter.ai/api/v1}/chat/completions via Node global fetch (stdlib only), Authorization Bearer $OPENROUTER_API_KEY, model $DEEP_RESEARCH_OPENROUTER_MODEL default perplexity/sonar, --search-context-size mapped to web_search_options.search_context_size, AbortController timeout honoring DEEP_RESEARCH_TIMEOUT_MS. Citations: message.annotations url_citation entries, then Perplexity citations[] passthrough, then the existing bare-URL scan. Typed fail-closed errors (missing_api_key/timeout/backend_error/empty_output), never a silent cross-provider fallback. Extend test/deep-research.sh with a stub HTTP server injected via OPENROUTER_BASE_URL covering request shape, citation normalization, and failure modes; leave the 23 agy assertions untouched. Document in relay-automation/README.md + the adapter header. GH-129 marker comment near the new backend.",
  "lanes": {
    "agy_safe": ["relay-automation/deep-research.mjs", "test/deep-research.sh", "relay-automation/README.md"],
    "orchestrator_only": [],
    "note": "OVERLAPS GH-124's write-set (same three files) — serialize with #124; never fire both in one parallel wave."
  }
}
```

## Provenance

Operator request 2026-07-04: add Perplexity's grounded search API, via OpenRouter (the repo's
often-used gateway), to the deep-research capability built under GH-87 (2026-07-02→04) and being
hardened under GH-124. GH-87's doc had already reserved Perplexity as the named follow-up phase.
