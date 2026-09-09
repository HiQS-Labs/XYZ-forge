# Gemma local replication — frozen before inference

Use the original 16 synthetic cases, six technical questions and unchanged Luna grade.py/key. Same complete inline source-packet.txt as Qwen (referenced from the sibling evidence directory); change model name in questions only. No previous model output, key, or parent analysis is sent. Two sequential fresh requests at temperature 0 measure repeatability, not independent statistical evidence. No post-answer prompt tuning or silent repair of answers.

Exact requested/loaded instance: gemma-4-12b-it-mlx; inventory reports Gemma 4 12B Instruct, MLX, 6-bit, context 262144. Omit context_length to reuse the current loaded instance, rather than requesting an additional instance. Native local /api/v1/chat, no integrations, store=false, no previous response, max_output_tokens=6000. No reasoning option supplied. stream=true captures partial data; preserve raw SSE, per-event times, final result, request hashes and exact monotonic client duration. Timeout 840 seconds per HTTP read; harness total cap 900 seconds; no automatic inference retries.

Reuse shipped consult.sh with an experiment-local executable override; the codex slot/filename does not mean Codex inference or sandboxing. Model has no shell, filesystem or execution tools. Save an initial pending receipt before the request, flush events as received, fsync at least once per second of event traffic, and require chat.end plus identity validation for transport success. Schema and semantic grading remain separate. Run unchanged grader controls before inference. Full runtime suites are not relevant to these experiment artifacts and will not be run.

Differences from Qwen: different model/quantization and preloaded context, streaming rather than nonstreaming. Differences from Luna additionally include inline source vs adaptive tools, runtime, prompt and reasoning settings. No causal model-ranking claim, real next-action accuracy, production p95, hardware-cost or tool-authority qualification. Publish reviewed results to Needle #13 only; XYZ #522 receives only the requested forward pointer.

API reference: https://lmstudio.ai/docs/developer/rest/streaming-events
