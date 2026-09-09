# Gemini 2.5 Flash-Lite — protocol before inference

Two fresh sequential calls, same frozen source packet, 16 cases and six questions, same system instruction, temperature 0, max_tokens 6000, 900-second harness cap. No tools, prior answers, answer key, JSON repair, or post-answer tuning. Model name substitutions only in questions. Reasoning option omitted: provider documents Flash-Lite thinking disabled by default. No model fallback; OpenRouter provider fallback disabled and parameter support required.

Gemini and Agy CLIs were inspected but their help does not expose the same explicit system instruction, temperature and output-token controls; direct HTTP via the existing consult executable override preserves these controls. The codex output slot is transcript transport, not Codex inference. Google key availability probe failed API_KEY_INVALID; no inference occurred there. User explicitly authorized OpenRouter paid fallback. Credential comes only from OPENROUTER_API_KEY environment and is sent as HTTPS Authorization; no credential logging or saving.

Changed transport/cloud provider makes this a controlled task replication, not a causal speed/model comparison. Quantization and cloud hardware not known. Requests streamed, raw SSE/events saved, client TTFT and full duration captured, response model/provider/usage retained. Original unchanged grader and key apply; 16 repeated cases are not 32 independent cases. No production/real predictive accuracy claims. No runtime source modified; no full suite needed.

References: https://openrouter.ai/google/gemini-2.5-flash-lite/api ; https://openrouter.ai/docs/api/api-reference/chat/send-chat-completion-request ; https://ai.google.dev/gemini-api/docs/generate-content/thinking
