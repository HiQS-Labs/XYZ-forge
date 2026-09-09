# Qwen3.8 27B MLX — bounded answer-delivery failure

Overall grade **F for this tested configuration's answer delivery**; reasoning quality and decision accuracy are ungraded. Both valid API requests completed with reasoning only and no final message. This differs from Qwen 2.5's interrupted request (I/incomplete). It is not a general capability grade.

| Metric | Run 1 | Run 2 |
|---|---:|---:|
| Full client request seconds | 1020.883221125 | 626.548790916 |
| Input tokens | 32796 | 32796 |
| Output tokens | 5999 | 5999 |
| Reasoning tokens | 5999 | 5999 |
| First token seconds (reasoning, not final answer) | 400.837 | 3.092 |
| Returned decisions | 0 | 0 |
| Decision accuracy | unavailable | unavailable |
| API transport | complete | complete |
| Task answer | absent | absent |

Exact requested and attested model: `qwen3.8-27b-mlx`, MLX 8-bit, loaded context107264. No model reload or reasoning setting override. Reasoning option was not advertised by inventory; omitted as in Gemma12, but the actual server produced reasoning. Bonsai and Gemma31 explicitly used reasoning=off. This is a material comparison limitation.

The user authorized 1200 seconds for this candidate only during run1. The original live request was preserved by a supervisor-only pause plus independent deadline watcher; run2 used CONSULT_TIMEOUT=1200 normally. Both finished before that cap. The unchanged max_output_tokens6000 was almost entirely consumed by reasoning. This is consistent with output-budget exhaustion, but no explicit server stop reason establishes the internal cause. The time exception did not increase output budget.

Original 16 cases, six questions, system prompt, full source packet, temp0 and no tools retained. Requests are byte-identical across repeats; only model and candidate names differ from Gemma12. No prior answers or answer key supplied. The original grader rejected both blank final answers; this is not 0/16 accuracy. No reasoning text was reinterpreted as a final answer or graded retroactively.

Verification checked nonempty streams, chat.start/chat.end, no server errors, response/event equality, complete reasoning-delta reconstruction, absence of messages, model identity, identical request bytes and unchanged source hash. Empty stream, missing end and missing reasoning delta controls each failed for both runs. Full runtime suite is not relevant to transport/evidence-only artifacts and was not run. Raw SSE blank separators are retained unchanged. `provenance.jsonl` retains receipts and hashes. Original input commit f426317; authorized exception commit9c70ae3. No product runtime or live admission changed.

Public raw snapshot should report response output types/counts and receipts, not infer a final answer from intermediate reasoning. Raw provider output is retained locally in response.json/SSE and timestamped events. Future testing with documented reasoning control or a larger output allowance would be a separate protocol, not a repair silently applied to these runs.
