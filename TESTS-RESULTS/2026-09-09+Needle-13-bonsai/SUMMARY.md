# Bonsai 27B local comparison — results

**Both runs completed and scored 16/16 on the frozen synthetic decisions. The technical prose failed review, including a material stale-publication error.** Consistent classification is promising; these results do not qualify autonomous technical review, production next-action prediction or a model ranking.

## Method and measured results

LM Studio inventory and both returned instances verified `prism-ml/bonsai-27b`: **Bonsai 27B, MLX, 2-bit**. Reused the already-loaded 228096-context instance without a context override. Both requests were byte-identical and both final answers were byte-identical.

The complete original source packet, 16 cases, six questions, system prompt, grading key, grader and streaming procedure match Gemma's trial. Verified request parity after only model-name substitutions and adding **reasoning=off**. Bonsai defaults to reasoning on; turning it off deliberately aligns this comparison with Gemma's observed zero reasoning tokens. This does not evaluate Bonsai's reasoning-on capability. Both responses reported zero reasoning tokens.

Other settings: temperature 0, max_output_tokens 6000, no tools/integrations, store=false, stream=true, no prior response. Two sequential fresh requests; no model retries, prompt tuning or output repair. Inputs and adapter were committed before inference in `3e96bea`.

| Measure | Run 1 | Run 2 |
|---|---:|---:|
| Correct decisions | 16/16 | 16/16 |
| False ACCEPT / false HOLD | 0 / 0 | 0 / 0 |
| Full client request duration | 377.815 s | 138.949 s |
| Server time to first token | 243.130 s | 4.249 s |
| Server input tokens | 32,749 | 32,749 |
| Server output tokens | 2,564 | 2,564 |
| Server output tokens/second | 19.060 | 19.053 |
| Reasoning output tokens | 0 | 0 |
| Invalid citation ranges in answers[].evidence | 5/14 | 5/14 |

These are 16 authored cases repeated twice, not 32 independent held-out examples. The first prompt-processing phase ended at approximately 240.8 seconds. The repeat's faster first token is consistent with warm/prefix-cache effects, which were not independently isolated. The repeated answer still required about 139 seconds to finish. Neither two samples nor time to first token establishes a production p95. The large source-review prompt is not Needle's short serving input; tokenizer differences explain why identical source text need not yield Gemma's token count. Hardware/electricity cost was not measured.

## Independent technical review

- **Material Q2 error, repeated identically:** Bonsai says atomic `os.replace` prevents stale worker publication because readers avoid a torn file. Atomic replacement alone does not check whether the result belongs to the latest prompt/generation. Its proposed tests—one final artifact and parseable JSON—would pass even if an older worker overwrote the newest result. This contradicts its own correct O07 HOLD for the p17/p18 scenario. The supplied `needle-710c-oracle_infer.py:55-60` shows replacement without a current-generation comparison. This is source review, not a race reproduced in this trial.
- **Q1 conflates project contracts:** it says admission and prediction can reuse Needle's serializer and canonical label taxonomy. The packet does not establish this; issue-admission reasons and next-observed-action labels are different targets. It also substitutes a +5pp accuracy criterion for a separate demonstration of recommendation usefulness.
- **Unsupported citations:** five of fourteen references in `answers[].evidence` name ranges outside the supplied files in each run. The issue snapshots have one original JSON line, so ranges such as `xyz-522.json:143–160` do not exist. Additionally, Q1/Q5 cite `needle-710c-oracle_config.py:38` for an accuracy threshold and frozen experiment: that line is the `show: True` display setting, not evidence for either claim. Existing coordinates do not prove semantic support; the range-count audit is not an overall citation-accuracy score.
- **Useful Q4 finding:** it identifies that `cmd_jog_add` can reset attempt_count on re-add and that automatic rescans must respect parked work. This is a meaningful source detail, but the accompanying shared-serializer claim is not a verified admission validator.
- **Partial Q3/Q5 reasoning:** it recognizes the unpaired comparison problem and that name extraction is not structural output validity. However its proposed versioning inconsistency is not established by the cited lines, and experiment advice drifts back to Luna despite Bonsai being the candidate. Do not execute this prose as an approved plan.

No tools were available to the model, so Luna's attempted-write issue was not retested here. No private workflow corpus, real queue writes, native local baseline or actual 44-label next-action predictions were evaluated. A clean decision score does not validate the generated explanation.

## Comparison and retained evidence

| Candidate | Completed synthetic case runs | Technical-review qualification |
|---|---|---|
| Luna | 16/16 twice | Authority wording, citation and attempted-write failures |
| Gemma 4 12B, MLX 6-bit | 16/16 twice | Contract/no_action confusion and invalid citations |
| Bonsai 27B, MLX 2-bit, reasoning off | 16/16 twice | Atomicity/staleness confusion, contract conflation and unsupported citations |
| Qwen 2.5 Coder 32B, MLX 4-bit | No completed response retained | Unscored after interruption; cause unverified |

Same cases and verified request parity improve comparability with Gemma. Model family, quantization, tokenizer, loaded context and warm state still differ; Luna additionally used adaptive source-reading tools and medium reasoning. This is not a causal capability or speed leaderboard. The synthetic decision set has not distinguished the three completed candidates; deeper source reasoning has exposed failures that a 16/16 score hides.

[Protocol](PROTOCOL.md), [question packet](QUESTIONS.md), [source reference](source-reference.json), [provenance](provenance.jsonl), [verification](verification.json), [citation audit](citation-audit.json), [run 1 answer](r1-answer.json), [run 2 answer](r2-answer.json). Raw SSE, per-event timing, final API JSON and requests are preserved alongside these artifacts. Both complete message streams matched the final responses; empty, missing-end and missing-delta negative controls failed. Original grader controls passed, and request/response hashes and model identity matched. Raw SSE blank event separators remain intact despite git whitespace warnings; other changed artifacts pass the whitespace check. No product runtime code or full runtime suite was changed/run.

Model inference used LM Studio locally. The codex-named relay slot is executable-override plumbing, not OpenAI inference or Codex sandboxing. Future results belong in [Needle #13](https://github.com/HiQS-Labs/Needle-fork/issues/13); no additional result comment is being added to XYZ #522.

- [Run 1 relay transcript](../../relay-system/2026-09-09/bonsai-needle-r1-075729/bonsai-needle-r1.codex.md)

- [Run 2 relay transcript](../../relay-system/2026-09-09/bonsai-needle-r2-080405/bonsai-needle-r2.codex.md)
