# Gemma 4 31B QAT replication — frozen before inference

Repeat the original 16 cases, six questions, full inline source packet and unchanged grader/key with two sequential fresh requests. Same system prompt and streaming adapter as Bonsai; changes limited to candidate name, model key, receipt schema and truthful GGUF provider label. No prior answers, key, post-trial issue comments or parent analysis in model input. Both requests must be byte-identical. No prompt tuning, answer repair or automatic model retries.

Requested model google/gemma-4-31b-qat. Inventory reports Gemma 4 31B QAT, GGUF Q4_0, 4-bit. Existing single instance has context_length 8192, insufficient for the complete approximately 34K-token source packet plus output. Temporarily unload that exact instance and load one instance at 49152 context, preserving documented API load options eval_batch_size=2048, flash_attention=true, offload_kv_cache_to_gpu=true. Record full before/after inventories and setup responses; restore original 8192 context after both runs. Never keep two copies of this model loaded for the experiment. Setup/load time is separate from inference request timing.

Request settings match Bonsai: reasoning=off (model defaults on), temperature=0, max_output_tokens=6000, integrations=[], store=false, stream=true, no previous response and no per-request context override. Match Gemma 12B's observed non-reasoning condition. Record actual reasoning tokens. Same HTTP read timeout 840 seconds and harness total cap 900 seconds. Model has no execution tools. Captured via consult CODEX_BIN override, not Codex inference/sandboxing.

Persist request/pending receipt before inference, raw SSE and event times as they arrive, final chat.end, API JSON and hashes. Require complete streams and correct model identity. Original grader controls run before inference; empty/missing-end/missing-delta stream controls must reject. Syntax, decision correctness and independent technical review remain separate. Preserve failures, including setup errors. No product runtime changes or full runtime suite.

Caveats: same packet does not remove tokenizer, quantization, context, engine, cache/hardware/runtime differences; this is GGUF rather than the earlier MLX candidates. Two temperature-zero repetitions are not independent held-out data, and not a production p95 or actual 44-label prediction benchmark. Publish reviewed results only to Needle #13. No update to XYZ #522.

Load/unload references: https://lmstudio.ai/docs/developer/rest/load and https://lmstudio.ai/docs/developer/rest/unload
