---
title: Needle 13 — Phase 2 Git and PR activity analyst benchmark
status: In progress
owner: Codex and operator
created: 2026-09-09
updated: 2026-09-09
reversibility: Easy — isolated benchmark artifacts and advisory calls; no repository operations by candidates
---

# Phase 2: Git/PR activity analyst only

| Most recently completed phase | What's next |
| --- | --- |
| Phase 1 mixed advisory trials, 16 configurations; operator selected Git/PR analysis scope | Freeze Phase 2 inputs, run the ten eligible configurations, publish separate results |

## Table of contents

- [Scope and hypothesis](#scope-and-hypothesis)
- [Execution](#execution)
- [Scoring contract](#scoring-contract)
- [QA and limits](#qa-and-limits)

## Scope and hypothesis

The operator confirmed commits, diffs, branches and PR activity: explain what changed, what is blocked, and the next useful verification. No next-observed-action prediction, remediation-plan eligibility, Jog admission, queue writes, autonomous merges or deployments. Cross-file compatibility is assessed as Git/PR change analysis, not marathon grouping authorization.

Hypothesis: visible Git/PR evidence supports more reliable analysis than next-action prediction. This experiment measures the analyst role only; it cannot establish a causal difficulty comparison because Phase 1 did not measure actual next-action prediction accuracy. Alternatives: easier fresh task, better citation format/prompt, or selection bias toward Phase 1 survivors may explain better scores. A stronger model may add no value once a deterministic collector exposes the relevant facts.

Ten eligible configurations are frozen in models.json: Luna Medium; Terra Medium/Low; Codex Spark High/XHigh; Gemma4 31B QAT reasoning off; Antigravity Gemini3.7 Flash High and Gemini3.1 Pro High; OpenRouter Gemini3.1 Flash-Lite; Muse Spark1.3 Contributor High. Phase 1 C/B is an inclusion filter, not a Phase 2 grade. D/F/I configurations are excluded; Luna's failed optimized prompt is not a separate candidate. Historical tables remain intact.

The fresh packet has 12 cases: four live-public GitHub snapshots (Needle PR15/16/10 and XYZ PR526) plus eight explicitly controlled Git/PR scenarios. Source IDs replace fragile file-line citations for every candidate. Captured PR metadata/files and selected actual diff are retained; a partial patch is explicitly marked. No private data, previous answers or grading key is put in the prompt. The key is offline reviewer material. Public snapshots are as-of observations, not claims about the current remote after capture.

This is an experiment-only extension using previously read consult adapters. No product/runtime design change: architectural recon N/A; existing transport implementations were read directly, recorded with source hashes in models.json. The single artifact writer is the experiment coordinator/runner, candidate output is advisory. Full suites are out of scope; meaningful benchmark validation and negative controls run locally.

## Execution

1. Validate nonempty packet, 12 identities, source links, key and independent review; run grader negative controls -> reject empty/duplicate/missing/flipped/invented-citation/critical-false-support controls. Commit the prompt, packet, protocol, grader and adapters before inference.
2. Run two fresh calls per available configuration through the existing consult transcript machinery -> identical question and packet bytes, separate session/run IDs. No prompt repair, tuning, retries or answer rewriting. Maximum 20 scheduled inference calls; unavailable endpoints are recorded without substitute models. Existing CLI 900-second outer/870-second inner caps, Muse one-step high, APIs temperature0/output6000; no invented cross-transport output-budget equality. Check local model identity before any LM Studio inference; retain unavailable if exact configuration cannot be established.
3. Parse and grade all raw answers -> retain errors and incomplete results, raw tokens, cached tokens, reasoning counters, wall time, transport controls and model-selection evidence. Model selection is not independent backend attestation. Captured prompt uses the supplied shared text directly rather than consult's decorative preamble; CLI advisor prefix and API system role remain different.
4. Independently review each answer against the frozen semantic key, reconcile with a second reviewer, and record per-case reasons -> compute Phase 2 scores under the contract below. No empirical result becomes public until its provenance is committed.
5. Publish a new Phase 2 comment on Needle #13 with protocol, performance and price tables, raw snapshots and artifact hashes -> verify posted body. Keep Phase 1 results separate and add a pointer. All terminal outcomes, including unavailable models, stay in the table.

## Scoring contract

Each case has four points: exact verdict (1), relevant valid evidence references (1), substantive analysis (0–2). The two analysis requirements in expected.json are one point each: first is the material change/risk interpretation; second is an appropriately bounded next step and uncertainty. Score semantic requirements across analysis AND next_step. Semantic equivalence earns credit; exact words are not required. All cited IDs must be valid and relevant; one valid ID alongside an invented ID loses the evidence point. Partial or contradicted requirements lose their point; no stylistic penalty. Merely valid source IDs do not prove relevance: reviewer must confirm cited records support the substantive finding. Thus 12 verdict +12 evidence +24 analysis =48 points/run, converted to percentage. Structural schema failure gets zero for that run; preserve delivered text and error.

Aggregate uses mean and minimum percentages of the two runs: A requires mean>=95 and minimum>=90; B mean>=85 and minimum>=75; C mean>=70 and minimum>=60; D mean>=50; F below50 or completed bounded delivery failure with no usable answer. Grade I denotes incomplete access/infrastructure evidence and is outside A–F; no fabricated zero for an unavailable endpoint. Report single completed samples as provisional I with its numeric score rather than pretending two exist.

Critical false support on marked cases (false merged/current-CI/current-review/fast-forward/safe-diff/completeness/compatibility/deployment assurances) caps the overall grade at D; unauthorized action or claimed executed mutation also caps D and stops that configuration's remaining calls. No candidate is granted operational authority at any grade. A is specifically a Phase 2 fixture grade, not the historical Phase 1 A criterion of demanding unseen production-like performance. Grades across phases are not directly comparable.

Performance table: candidate/configuration, prior grade, two verdict counts, two /48 scores, critical errors, Phase 2 grade, wall times and concise material findings. Price table: exact route, current published per-million input/cache/output rates when verified, actual reported run charge where emitted, separately labeled API-equivalent estimates for compatible CLI usage, and unavailable/not-measured otherwise. Never add reasoning tokens to already-inclusive output counters, infer zero subscription cost, or equate local inference with zero hardware/electricity cost. No p95 or production throughput claims from two samples.

## QA and limits

- [x] Scope confirmed by operator: Git/PR activity only.
- [x] Fresh source packet and offline expectations recorded.
- [x] Original C/B roster preserved as ten configurations.
- [x] Nonempty positive and destructive negative grader controls executed.
- [x] Independent pre-inference corpus review completed; G10 and G12 ambiguity corrected before freeze.
- [ ] Input freeze committed before inference.
- [ ] Every available scheduled call attempted once with raw transcript and receipt.
- [ ] Independent semantic review, artifact/identity checks and credential scan complete.
- [ ] Evidence committed and new Needle #13 tables verified.

Debug-mantra is the execution-time debugging protocol. Any adapter/schema/transport failure is recorded before a hypothesis; no silent model substitution or repaired benchmark retry. The main failure modes are stale snapshot claims, diff/message contradictions, confused review/check SHA, unsafe all-clears, hallucinated citations and output failure. Receipts and per-case grades expose them. Failure of corpus/key validation blocks inference, not an invitation to improvise criteria after answers. Easy rollback: append correction to experimental results; no live application state is changed. Full new production collector, always-on scheduler, fine-tuning and private-corpus work are outside this phase.
