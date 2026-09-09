# Gemma 4 12B Instruct local replication — results

**Both runs completed and matched all 16 synthetic decisions. Technical prose and citations did not pass independent review.** Retain Gemma as a bounded classification candidate; this is not production qualification or proof of reliable technical review.

## Configuration and measured results

LM Studio inventory and both returned instance IDs identify `gemma-4-12b-it-mlx`: Gemma 4 12B Instruct, MLX, **6-bit**. Used the already-loaded 262144-context instance; no context override, model reload or added instance was observed in the stream. Two fresh sequential, byte-identical requests: temperature 0, maximum 6000 output tokens, tools/integrations disabled, store=false, streaming enabled, no previous response. No reasoning option supplied; server reports zero reasoning output tokens.

| Measure | Run 1 | Run 2 |
|---|---:|---:|
| Matching decisions | 16/16 | 16/16 |
| False ACCEPT / false HOLD | 0 / 0 | 0 / 0 |
| Full client request duration | 293.201 s | 90.260 s |
| Server time to first token | 200.643 s | 1.909 s |
| Server input tokens | 34,206 | 34,206 |
| Server output tokens | 2,003 | 1,898 |
| Server output tokens/second | 21.679 | 21.512 |
| Invalid line coordinates in answers[].evidence | 10/20 | 9/17 |

First-run prompt processing ended at approximately 199.6 seconds. The much faster second first-token time is consistent with warm/prefix-cache reuse, but cache behavior was not isolated experimentally. The second response still took about 90 seconds to finish. Do not equate time to first token with time to a usable prediction, or either observation with a p95. The 34K-token source-review workload is not Needle's short production prediction prompt. Actual hardware/electricity cost was not measured.

## Independent assessment

The same frozen 16 authored policy/evaluation cases and original grading key were used. Both accepted the four valid cases and held the twelve invalid/unsupported claims. This is 16 cases repeated twice, not 32 independent held-out examples. Temperature-zero repetitions produced identical decisions but different prose. Successful syntactic JSON and case decisions do not establish real next-action accuracy, unassisted diagnosis, semantic citation validity or authority under tool access.

- **Cross-project conflation (both Q1):** Gemma claims XYZ admission and Needle prediction reuse the same 44-label taxonomy and serializer. The supplied sources do not establish this. Admission reason codes and next-observed-action labels serve different targets.
- **Invalid citation coordinates:** the three supplied GitHub JSON snapshots each have one original line. References such as `xyz-522.json:103` and `needle-13.json:45` cannot point to original source lines. A bounded audit of `answers[].evidence` found 10/20 invalid coordinates in run 1 and 9/17 in run 2 after resolving basename aliases. Other coordinates existing does not establish semantic support. Neither the parser nor the relay harness's citation heuristics verified these claims.
- **Target confusion (Q3):** both blur semantic `no_action` with abstention. Run 1 contrasts a no-arguments output contract with top-five retrieval as though these were contradictory; they concern different behaviors. Run 2 imports issue-plan review requirements into Oracle quality evaluation and treats a named label serialized as an empty list as inherently inconsistent. The real issue is the distinction between semantic no_action, model abstention and censored/no-event observations.
- **Useful but incomplete source reasoning (Q2/Q4):** both distinguish main's logging hook from the 710c detached worker and recognize that atomic replace is not stale-result prevention. However Q4 does not clearly surface that terminal Jog rows can be reactivated with attempts reset; a correct A06 HOLD is not a complete explanation of the writer boundary. These are source-review observations, not reproduced races.
- **Incomplete experiment advice (Q5/Q6):** answers drift back to Luna despite evaluating Gemma, omit required baseline/coverage detail, and in run 1 describe a 60-case set using only two groups of 20. Retain the frozen project-specific evaluation plans; do not execute this prose as an approved plan.

No model tools were provided, so this run does not test the attempted-write failure found in Luna's tool-using run. No private corpus, real queue writes, hook deployment, native local-baseline comparison or 44-label next-action prediction benchmark was executed.

## Comparison limits and evidence

Luna previously matched 16/16 twice but had prose authority/citation and instruction-following problems. Qwen 2.5 Coder 32B MLX 4-bit remains unscored: its first request was interrupted before a response was saved. Gemma now has completed synthetic decision evidence; these different runtimes, context delivery and model settings do not isolate model capability or establish a ranking.

Protocol and adapter were frozen before inference in `72f3106`. Reused the Qwen inline source packet unchanged, and original Luna grader/key unchanged. Prompt adapts model names only from the Qwen API question packet. Source text includes the original issue snapshots, not subsequent results or the answer key.

[Protocol](PROTOCOL.md), [questions](QUESTIONS.md), [source reference](source-reference.json), [run provenance](provenance.jsonl), [citation audit](citation-audit.json), [verification](verification.json), [run 1 answer](r1-answer.json), [run 2 answer](r2-answer.json). Raw SSE, timestamped events, final API JSON, requests and receipts are saved alongside these files. Full relay transcripts are linked below. No full runtime suite ran: runtime product code was unchanged. The original grader controls passed; additional stream checks rejected empty streams, missing chat.end and missing message deltas, and both complete streams matched their final answers exactly.

Use [Needle #13](https://github.com/HiQS-Labs/Needle-fork/issues/13) for future updates. [XYZ #522 now points there](https://github.com/HiQS-Labs/XYZ-forge/issues/522#issuecomment-5603637627). No further result comment goes to XYZ #522 for now.

Streaming contract reference: [LM Studio SSE events](https://lmstudio.ai/docs/developer/rest/streaming-events). The codex-named relay slot is the executable override transport; model inference was entirely LM Studio.

- [Run 1 relay transcript](../../relay-system/2026-09-09/gemma-needle-r1-073656/gemma-needle-r1.codex.md)

- [Run 2 relay transcript](../../relay-system/2026-09-09/gemma-needle-r2-074216/gemma-needle-r2.codex.md)
