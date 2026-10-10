# Recipe fallback QA — 2026-10-05 (PDT)

Related: [HiQS #28](https://github.com/NeochromeTeam/hiqs-ai-resolve/issues/28), [personal chain tracker #2](https://github.com/noelsaw1/noels-cross-project-tasks/issues/2).

## Resolver fixture

Implementation: `71fa959917fb2f23ddd249f3847901700daddc4e`.

The existing capability-cascade unit test now drives the real resolver from a test-only caller and fictional HTTP `Response` objects. It starts with no failures, executes the selected local-fetch fixture, observes HTTP 403, records `http_403`, and resolves again. The scraper fixture returns useful content with HTTP 200; the caller stops. The browser fixture has no configured response and cannot be attempted silently. Assertions cover attempt order, status, useful output, preserved failure log and fallback trace.

This verifies resolver selection after a declared failure and a caller's stopping contract. It does **not** establish a production executor, call real providers in the unit suite, or provide evidence that fictional services work in production. No new XYZ test, test registry, runner or gate is introduced.

`provenance.jsonl` records command strings and argv, expected/actual exit codes and log hashes. For publication, the absolute Mac checkout path is redacted and trailing blank lines are trimmed; modified entries preserve the original raw-output hash as well. The red control changes only the first fixture status from 403 to 200 and fails; the original bytes are restored before the focused and full checks. TypeScript, 379 tests, schema freshness and whitespace checks pass. These commands operate in the HiQS task clone, never a full XYZ clone.

## Live credentials and operations

`provider-smoke.jsonl` contains sanitized receipts for five **independent** bounded requests on this Mac. Firecrawl, Browserbase Fetch and Parallel Extract each returned the requested purpose of `https://example.com`. Browserbase project preflight succeeded. Perplexity completed a web-search request. Gemini completed a grounded-search request with explicit Google Search calls/results and a cited answer. All final provider requests returned HTTP 200.

These receipts cover the five personal recipe-chain providers, not every service in the catalog. They do not prove sequential research execution, forced live-provider fallbacks, exhausted-cascade behavior, discovery in every IDE or execution on the other three Macs. Raw responses and the one-off smoke script remain in a private local receipt directory; keys, key paths, account/project identifiers and authorization headers are omitted here.

Two smoke-harness mistakes were corrected: extracted markdown need not repeat the page title, so the scraper receipts validate the actual requested purpose from retained payloads; the Gemini credential file contains descriptive text as well as a key, so the corrected loader selects one unambiguous Google API key. The initial Gemini request used the wrong text and returned 400; the corrected request returned 200. No credential value is recorded.

## Starting research today

Invoke `research-chain` by name (or `$research-chain` in a supporting agent) with a question and an output destination. It describes Gemini Grounded Search → Perplexity → source extraction, with Firecrawl → Browserbase → Parallel on failure per URL. The current skill does **not** call HiQS automatically and is not a published/admitted catalog recipe. HiQS currently selects an eligible step from an explicit failure history; the caller executes the provider and logs failures. The sequential research stages must not be flattened into a fallback cascade. Resolver-backed integration remains tracked in personal #2.
