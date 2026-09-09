# Phase 2 results — Git/PR activity analyst only

**Eight configurations B, Gemini3.1 Flash-Lite C, Gemma unavailable/ungraded.** All18 available calls completed and returned the required schema. No critical false SUPPORTED verdicts occurred. The two scheduled Gemma calls did not start because localhost LM Studio was unreachable; I is an availability outcome, not a quality downgrade. No extra inference retries or model substitutions occurred.

This phase measures read-only analysis of commits, diffs, branch topology and PR activity: what changed, blockers and next useful verification. It excludes next-action prediction and issue admission/Jog grouping. The ten prior B/C configurations were selected before inference. The frozen12-case packet has4 captured public GitHub snapshots and8 controlled scenarios, with19 source IDs. Shared questions/evidence were fixed before calls in local commit `5aeb527`. Prior grades remain separate; better Phase2 letters do not imply a controlled improvement over Phase1.

## Performance and quality

Each run has48points:12verdict+12relevant citation+24semantic analysis/next-step. Unblinded independent helper and parent read all18 raw answers and reconciled per-case points under the frozen rubric. A requires mean/minimum95/90%; B85/75%; C70/60%; D mean50%; otherwiseF, with critical failure caps. No A was earned. This phase's letters are fixture grades, not production permissions.

| Configuration | Phase1 | Verdicts r1/r2 | Full score /48 r1/r2 | Mean | Phase2 | Wall seconds r1/r2 |
|---|:---:|---|---|---:|:---:|---|
| Luna Medium | C | 11/12 · 11/12 | 44 · 43 | 90.62% | **B** | 29.95 · 33.04 |
| Terra Medium | B | 10/12 · 11/12 | 43 · 44 | 90.62% | **B** | 24.56 · 27.47 |
| Terra Low | B | 11/12 · 11/12 | 44 · 44 | 91.67% | **B** | 24.85 · 25.47 |
| Codex Spark High | C | 10/12 · 10/12 | 42 · 44 | 89.58% | **B** | 8.04 · 12.05 |
| Codex Spark XHigh | C | 11/12 · 10/12 | 44 · 40 | 87.50% | **B** | 10.29 · 8.35 |
| Gemma4 31B QAT off | C | Not run | — | — | **I** | Endpoint unavailable |
| Agy Gemini3.7 Flash High | C | 11/12 · 11/12 | 44 · 45 | 92.71% | **B** | 38.46 · 36.01 |
| Agy Gemini3.1 Pro High | C | 11/12 · 10/12 | 43 · 40 | 86.46% | **B** | 57.97 · 48.80 |
| Gemini3.1 Flash-Lite (OpenRouter) | C | 9/12 · 9/12 | 40 · 41 | 84.38% | **C** | 6.48 · 6.14 |
| Muse Spark1.3 Contributor High | C | 11/12 · 10/12 | 42 · 41 | 86.46% | **B** | 44.01 · 41.31 |

Every answer's evidence array contains valid case-local IDs. Semantic citation review still caught Muse run1 citing the wrong case ID inside its prose; valid arrays alone are not source-grounding proof. No command/tool execution was observed in Codex/Muse events; Agy logs have weaker tool observability. API requests had no tools. Configuration identity is captured; CLI selected-model flags are not independent backend identity attestation.

## What changed the grades

- **Luna Medium:** Sound diff/state reasoning; generic planning summaries; run2 offers reset as a possible choice without preservation.
- **Terra Medium:** Sound diff/history; generic scope; run1 deployment verdict contradicts its own accurate uncertainty prose.
- **Terra Low:** Consistent core reasoning; thin change summaries and one premature conditional cache re-enable suggestion.
- **Codex Spark High:** Fast observed calls; both deployment verdicts wrong, though run2 recommends checking external records.
- **Codex Spark XHigh:** No clear advantage over High; run2 shortens exact review SHA and omits concrete wire-format conflict.
- **Gemma4 31B QAT off:** LM Studio endpoint unavailable; neither scheduled inference call started.
- **Agy Gemini3.7 Flash High:** Strongest observed mean, but thin proposed-change summaries and CI verdict ambiguity remain.
- **Agy Gemini3.1 Pro High:** Run2 overstates deployment inventory authority and recommends deployment before checking external records; no execution occurred.
- **Gemini3.1 Flash-Lite (OpenRouter):** Confuses UNKNOWN/CONTRADICTED in CI and deployment; terse change analysis. C is threshold-sensitive.
- **Muse Spark1.3 Contributor High:** One cross-case source ID in prose; run2 ignores external deployment scope; useful diff/history reasoning.

Common strengths were identifying old-head review/check evidence, the reverted cache, divergent branch ancestry, the retry off-by-one change, and cross-file producer/consumer incompatibility. Common misses were concrete explanations of documentation pointer changes and the scope of a proposed PR; several answers validated a claim without fully reporting what changed. Some next-step recommendations were too aggressive despite remaining advisory.

**Important test limitation: G05.** All18 answers chose CONTRADICTED where the frozen key expects UNKNOWN for whether current-head tests pass. Most correctly explained that only an old SHA has a passing result. Reading this as “the current head has not satisfied required CI” makes their wording defensible. We retained the frozen verdict loss, credited correct semantic analysis, and did not label it an unsafe false all-clear. Dropping only this verdict point as a sensitivity analysis changes Flash-Lite from84.375% to86.17%, enough to cross C→B; the official frozen result remains C. Treat the B/C boundary as fragile, not a substantial model-quality separation.

## Pricing and observed charges

Rates are USD per million tokens. The rates below are Standard short-context API references, not actual Codex subscription charges. No cache-write tokens were reported for these Codex calls. We use (input minus cached input)×input rate + cached input×cache rate + output×output rate, divided by1M; reasoning is not added again to output. Counter compatibility is an assumption, not a billing attestation.

| Configuration / route | Input / cached / output rates | Reported charge, two calls | API-equivalent estimate, two calls |
|---|---|---:|---:|
| Luna Medium | $0.2 / $0.02 / $1.2 | Not measured | $0.0133032 |
| Terra Medium | $2 / $0.2 / $12 | Not measured | $0.1468052 |
| Terra Low | $2 / $0.2 / $12 | Not measured | $0.1541756 |
| Codex Spark High | Exact route rate not established | Not measured | — |
| Codex Spark XHigh | Exact route rate not established | Not measured | — |
| Gemma4 31B QAT off | Local hardware/electricity not measured | Not measured | — |
| Agy Gemini3.7 Flash High | Exact route rate not established | Not measured | — |
| Agy Gemini3.1 Pro High | Exact route rate not established | Not measured | — |
| Gemini3.1 Flash-Lite (OpenRouter) | $0.25 / $0.025 / $1.5 | $0.00733528 | — |
| Muse Spark1.3 Contributor High | Exact route rate not established | Not measured | — |

Rates retrieved2026-09-09 from [official OpenAI pricing](https://developers.openai.com/api/docs/pricing) and [OpenRouter Gemini3.1 Flash-Lite](https://openrouter.ai/google/gemini-3.1-flash-lite); exact machine-readable rate snapshots and formulas are retained. OpenRouter's charge is provider telemetry, not an independently audited invoice. Other exact CLI rates are not inferred from similarly named API models. Local inference is not assumed to have zero operating cost.

Luna's API-equivalent total is about one-tenth Terra's here, but cache and output differences affect the totals. Flash-Lite's reported charge and the CLI estimates are different kinds of evidence. No whole-session orchestration/review/collection cost was metered. Two samples do not establish production p95, capacity or monthly spend.

## Reproduction, limits and completion

Existing consult machinery retained18 isolated transcript directories. Model families ran concurrently, calls within a family sequentially; wall times can reflect contention and caching. The explicit prompt and packet content were identical, but API system messages versus CLI prefixes, ambient project instructions, tokenizers and output ceilings differ. APIs retain output6000; CLI output is not capped equivalently. All trials stayed within existing time caps. Four Terra answer files use newline normalization relative to event text; parsed JSON matches and both raw forms are retained. No response was repaired or re-run.

Original input hashes,18answer/provenance hashes and18relay manifests were checked. Positive and deliberate negative grader controls ran. Helper and parent per-case scores are retained. Credential scanning found no known-runtime-key or common-pattern matches; it is not exhaustive. No product runtime code, live queue, branch, merge or deployment was changed by a candidate. No full product suite was run for this experimental artifact-only phase.

**Hypothesis result:** useful evidence for a bounded Git/PR advisory role; no direct evidence that real next-action prediction is harder, because it was not measured here or in Phase1. Improved scope, prompt and citation format plus survivor selection are alternative explanations for higher letters. The cohort still needs independently selected production-like holdouts before always-on use.

- [x] Phase scope and eligible roster documented.
- [x] Fresh corpus/key independently reviewed and frozen before inference.
- [x] All18 available calls completed;2 unavailable calls explicitly recorded.
- [x] Independent scoring, negative controls, provenance and price calculations retained.
- [ ] Final evidence commit and GitHub raw snapshots/tables publication verified by parent.
