# Qwen local trial — interrupted before a response was retained

The first request was saved on 2026-09-09 at 00:16:32 PDT; the last client heartbeat was written at 00:22:32 PDT. The user reports a hard crash. No response, answer, completion receipt or second request exists in this evidence directory. There is no model score, completed API latency, token usage or demonstrated crash cause. Client heartbeats do not establish server inference progress.

The requested model was Qwen 2.5 Coder 32B, MLX, 4-bit. Full request and partial relay transcript are preserved, with hashes and settings in [provenance.jsonl](provenance.jsonl). The unchanged 16-case key and grader remain in the sibling Luna evidence directory. This is missing/incomplete evidence, not 0/16 or proof that Qwen cannot perform the task.

The experiment requested a separate 32K context instance while the original 8K instance remained loaded. That observation does not diagnose the reported crash. The transport's instance-ID check was corrected while the first request was pending; no response was saved on which to exercise that check. No automatic inference retry was performed.
