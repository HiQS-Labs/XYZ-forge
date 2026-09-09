# Gemma 4 31B QAT local comparison — results

**Both runs completed and scored 16/16 on the frozen synthetic decisions. Technical answers retained material citation and reasoning problems.** This is completed classification evidence, not qualification for autonomous technical review or production Needle prediction.

## Method and results

Exact model: `google/gemma-4-31b-qat`, **Gemma 4 31B QAT, GGUF Q4_0, 4-bit**, verified against LM Studio inventory and both returned instance IDs. This is a GGUF run, unlike the earlier MLX candidates. The original single instance was loaded at context 8192, too small for the complete packet. Unloaded that exact instance and loaded one instance at context 49152, preserving the documented load settings: eval_batch_size 2048, flash_attention true, offload_kv_cache_to_gpu true. Recorded setup/load responses separately from inference timing. After both runs, restored 8192 and verified every originally visible load setting and exactly one instance. No second copy was kept loaded.

Same frozen 16 cases, six questions, complete source packet, system prompt, original grader/key and two sequential fresh request procedure. Verified request parity with Bonsai after candidate-name substitutions only. Both request payloads and both final answers were byte-identical. Settings: reasoning=off, temperature 0, max_output_tokens 6000, integrations=[], store=false, stream=true, no previous response or per-request context override. Model defaults to reasoning on; this trial tests reasoning off, matching Bonsai's setting and Gemma 12B's observed zero reasoning tokens. No inference retries, prompt tuning or output repair. Inputs frozen in `aeebb64` before inference.

| Measure | Run 1 | Run 2 |
|---|---:|---:|
| Correct decisions | 16/16 | 16/16 |
| False ACCEPT / false HOLD | 0 / 0 | 0 / 0 |
| Full client request duration | 627.309 s | 193.769 s |
| Server time to first token | 429.578 s | 0.802 s |
| Server input tokens | 34,215 | 34,215 |
| Server output tokens | 2,117 | 2,117 |
| Server output tokens/second | 10.709 | 10.971 |
| Reasoning output tokens | 0 | 0 |
| Invalid coordinates in answers[].evidence | 12/19 | 12/19 |
| References outside supplied packet, including invalid coordinates | 13/19 | 13/19 |

The first prompt-processing phase ended around 429.7 seconds. The faster repeat is consistent with warm/prefix-cache reuse; cache effects were not isolated experimentally. Its subsecond first token is not a subsecond usable answer: the repeated response still took about 194 seconds to finish. Two samples do not establish a p95. This approximately 34K-token technical-review input is not Needle's short serving prompt. Hardware/electricity cost was not measured.

## Independent technical assessment

- **Correct distinction in Q2:** it says atomic replacement alone does not prevent stale publication and proposes two workers for different prompts in one session. This avoids Bonsai's material error. It correctly distinguishes main's logging hook from the 710c detached worker. No race was executed by this trial.
- **Improved separation in Q1, with a remaining mistake:** it distinguishes admission eligibility/grouping from next-observed-action prediction and does not claim both share Needle's 44-label taxonomy. However it still treats a +5pp predictive-accuracy threshold as a demonstration of product usefulness; observed accuracy and recommendation usefulness need distinct evidence.
- **Invalid citations:** the supplied issue JSON files each have one original line; references such as `xyz-522:11` and `needle-13:13` are not original file coordinates. After resolving stem/basename aliases, 12 of 19 references in `answers[].evidence` are out of range in each identical answer. Another reference, `releases_app.py:313`, exists but was outside the supplied function excerpt and reads `return common`, not the claimed attempt reset. The true reset is in the supplied `cmd_jog_add` excerpt. Counts assess reference coordinates/availability, not semantic validity of the remaining citations.
- **False inconsistency in Q3:** labels taking no arguments does not contradict representing tool calls in JSON. The answer does not identify the actual no_action/abstention contract drift. It calls abstention a refusal, too narrowly: a model can abstain due to uncertainty without refusing the task. The O03 case correctly recognizes that an unobserved event is censored rather than semantic no_action.
- **Useful but incomplete Q4/Q5/Q6:** it recognizes attempt_count reset and deterministic review/hash/PRS checks, but cites the wrong reset line and does not fully explain parked-state protection. Experiment advice omits requested coverage/stronger-model detail and treats disjoint session families as sufficient leakage prevention; future-request/target leakage also needs independent checks. These answers are not an approved implementation or evaluation plan.

The correct case decisions and syntactically valid JSON do not validate the accompanying prose. No tools were available, so Luna's attempted-write issue was not retested. No private workflow corpus, live queue writes, actual 44-label next-action benchmark or native local-baseline comparison ran.

## Comparison limits and evidence

Luna, Gemma 12B, Bonsai 27B and now Gemma 31B QAT each matched the same 16 explicit cases twice. Qwen 2.5 Coder 32B remains unscored after interruption. The case set has not distinguished the completed candidates; independent source review continues to expose different errors. Do not treat this as 32 independent held-out examples per model or as a causal capability/speed ranking. Engine (GGUF vs MLX), quantization, tokenizer, loaded context and warm state differ; Luna additionally had adaptive source-reading tools and medium reasoning.

[Protocol](PROTOCOL.md), [questions](QUESTIONS.md), [provenance](provenance.jsonl), [verification](verification.json), [citation audit](citation-audit.json), [run 1 answer](r1-answer.json), [run 2 answer](r2-answer.json). Setup/restoration receipts, raw requests, SSE, timestamped events and final API JSON are retained in this directory. Both complete message streams matched final answers. Empty-stream, missing-end and missing-delta controls failed as intended; original grader controls passed. Hashes and model identities verified. Raw SSE blank event separators are preserved despite git whitespace warnings; other changed artifacts pass the whitespace check. No product runtime code changed and no full runtime suite ran.

The codex-named relay slot is executable-override plumbing, not Codex/OpenAI inference or sandboxing. Updates are posted only to [Needle #13](https://github.com/HiQS-Labs/Needle-fork/issues/13).

- [Run 1 relay transcript](../../relay-system/2026-09-09/gemma31-needle-r1-081305/gemma31-needle-r1.codex.md)

- [Run 2 relay transcript](../../relay-system/2026-09-09/gemma31-needle-r2-082353/gemma31-needle-r2.codex.md)
