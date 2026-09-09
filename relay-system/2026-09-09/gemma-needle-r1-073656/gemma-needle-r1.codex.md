> **ATTESTATION**
> Model: gemma-4-12b-it-mlx
> Provider: LM Studio localhost / MLX
> Sandbox: no model tools; not a Codex sandbox

transport: LM Studio HTTP-only experiment adapter, not Codex inference
provider: LM Studio localhost / MLX
sandbox: no model tools; not a Codex sandbox
[event] chat.start at 0.064s
[event] prompt_processing.start at 0.281s
[adapter] awaiting streaming completion
[adapter] awaiting streaming completion
[adapter] awaiting streaming completion
[adapter] awaiting streaming completion
[adapter] awaiting streaming completion
[adapter] awaiting streaming completion
[adapter] awaiting streaming completion
[adapter] awaiting streaming completion
[adapter] awaiting streaming completion
[adapter] awaiting streaming completion
[adapter] awaiting streaming completion
[adapter] awaiting streaming completion
[adapter] awaiting streaming completion
[event] prompt_processing.end at 199.613s
[event] message.start at 201.136s
[adapter] awaiting streaming completion
[adapter] awaiting streaming completion
[adapter] awaiting streaming completion
[adapter] awaiting streaming completion
[adapter] awaiting streaming completion
[adapter] awaiting streaming completion
[event] message.end at 293.2s
[event] chat.end at 293.201s
model: gemma-4-12b-it-mlx
```json
{
  "decisions": [
    {"id": "A01", "decision": "HOLD", "reason": "Missing remediation plan in issue body; fails 'Remediation plan in the issue' gate (xyz-522.json:103)."},
    {"id": "A02", "decision": "ACCEPT", "reason": "Meets all gates: plan in issue, independent review, PRS, and readiness (xyz-522.json:103-114)."},
    {"id": "A03", "decision": "HOLD", "reason": "Plan edited after review without new content-hash comparison or renewed attestation (xyz-522.json:103, 114)."},
    {"id": "A04", "decision": "HOLD", "reason": "Parallel pair writes different files with no pinned interface or integration agreement (xyz-522.json:103, 114)."},
    {"id": "A05", "decision": "ACCEPT", "reason": "Validates A02 with disjoint write-sets and no shared-contract collision (xyz-522.json:103, 114)."},
    {"id": "A06", "decision": "HOLD", "reason": "Issue is parked; operator has not released the park (xyz-522.json:103, 114)."},
    {"id": "A07", "decision": "HOLD", "reason": "System override instruction contradicts the required independent review hash (xyz-522.json:103, 114)."},
    {"id": "A08", "decision": "HOLD", "reason": "Dependency inventory unavailable; scanner proposes treating unseen as completed (xyz-522.json:103, 114)."},
    {"id": "O01", "decision": "ACCEPT", "reason": "Valid prediction boundary; disjoint source-session families (needle-13.json:45)."},
    {"id": "O02", "decision": "HOLD", "reason": "Input includes next user request, violating the 'never include' rule (needle-13.json:50)."},
    {"id": "O03", "decision": "HOLD", "reason": "Scorer credits empty response as correct for semantic no_action; lacks explicit label (needle-13.json:55)."},
    {"id": "O04", "decision": "HOLD", "reason": "Claim of PTQ non-causality is based on unpaired/disjoint row sets (needle-12.json:30)."},
    {"id": "O05", "decision": "ACCEPT", "reason": "Valid situation with held-out support and matching row IDs (needle-13.json:65)."},
    {"id": "O06", "decision": "HOLD", "reason": "Parser claim of 100% well-formed is a name-extraction rate, not structural validity (needle-12.json:30)."},
    {"id": "O07", "decision": "HOLD", "reason": "Attributes feedback to p18 but uses result from p17; violates session integrity (cases.json:75)."},
    {"id": "O08", "decision": "HOLD", "reason": "Claim of +5pp accuracy and <2s latency is a synthetic proxy, not production proof (cases.json:80)."}
  ],
  "answers": [
    {
      "question": "Q1",
      "answer": "XYZ Admission seeks to admit issues into Jog/Marathon based on remediation plans and reviews; Oracle Prediction seeks to forecast the next software action. Both reuse the same taxonomy/labels (needle-main-labels-v1.json:19) and serialization logic (needle-main-serialize.py:74). Admission requires specific 'plan in issue' and 'independent review' (xyz-522.json:103, 114), while prediction requires 'no next user request' and 'observation horizon' (needle-13.json:45, 102). The same workflow does NOT establish both; admission is a policy gate, prediction is a performance metric.",
      "evidence": ["xyz-522.json:103", "needle-main-labels-v1.json:19", "needle-main-serialize.py:74", "needle-13.json:45", "needle-13.json:102"]
    },
    {
      "question": "Q2",
      "answer": "Needle main uses a simple log append (needle-main-oracle_stop_hook.py:83); 710c uses a detached worker (oracle_infer.py) and atomic os.replace for result files (oracle_infer.py:58). Atomic replace prevents torn reads but not stale worker publication if the same session_id is reused concurrently. Test: concurrent scanners against a single admission identity (xyz-522.json:134).",
      "evidence": ["needle-main-oracle_stop_hook.py:83", "oracle_infer.py:58", "xyz-522.json:134"]
    },
    {
      "question": "Q3",
      "answer": "No; 44 labels are the contract, but 100% parse is a name-extraction rate (needle-12.json:30). Needle#12 warns that the engine only serves 5 of 44 tools (needle-12.json:30) and that 'no_action' is a distinct abstention from an unmapped/failed result (needle-main-labels-v1.json:230). Inconsistency: needle-main-labels-v1.json claims 'no arguments' (line 4), but the engine probe shows it only retrieves top-5 tools.",
      "evidence": ["needle-12.json:30", "needle-main-labels-v1.json:4", "needle-main-labels-v1.json:230"]
    },
    {
      "question": "Q4",
      "answer": "Deterministic: Parsing, schema validation (needle-main-labels-v1.json), and 'jog add' logic for status/position (releases_app.py:3900-3914). Gemma Reasoning: Grouping logic (xyz-522.json:103), plan substance evaluation, and 'why' generation (needle-main-serialize.py:91). Shared contracts are in MACHINE-CONTRACTS.md; output validation is a deterministic gate (xyz-522.json:130).",
      "evidence": ["needle-main-labels-v1.json:4", "releases_app.py:3900", "xyz-522.json:103", "needle-main-serialize.py:91", "MACHINE-CONTRACTS.md:31"]
    },
    {
      "question": "Q5",
      "answer": "Smallest experiment: A 60-case holdout (20 eligible/20 ineligible) with 'bug-only' and 'placeholder plan' controls (xyz-522.json:130). Each must separately evaluate: Gemma's grouping logic vs. human (XYZ), and Luna's p95 latency/cost/refusal rates (needle-13.json:102). Must check for leakage via session identity and ensure independent labels.",
      "evidence": ["xyz-522.json:130", "needle-13.json:102"]
    },
    {
      "question": "Q6",
      "answer": "Narrow/Stop if: 1) Luna fails the +5pp gain or <2s latency gate (needle-13.json:102); 2) Gemma fails the 'no false accepts' gate (xyz-522.json:130). This trial cannot establish production metrics because it lacks real-world concurrency (race guarantees), actual dollar spend, private data privacy audits, or production latency/throughput under load.",
      "evidence": ["needle-13.json:102", "xyz-522.json:130"]
    }
  ],
  "limitations": [
    "No live API access to gpt-5.6-luna for actual cost/latency measurement.",
    "No ability to execute the 'jog add' or 'preflight' scripts to verify real-world race conditions.",
    "Source files are static; cannot verify if 'current' labels in needle-main-labels-v1.json match the live repo."
  ]
}
```
Request receipt: {"schema": "needle13/gemma-local-spike@1", "run": "r1", "status": "complete", "started_at": "2026-09-09T14:36:56.844051+00:00", "requested_model": "gemma-4-12b-it-mlx", "request_sha256": "a45f6b712ee4a37928a261b13b24bb2c4c9045d96d27a10205e4e3113c529501", "source_packet_sha256": "dee4d8c16f2352bf4ff448aecac65d1de803d064df68c73d46e3c30c3dc41f2e", "transport": "consult CODEX_BIN override -> LM Studio native SSE API", "full_request_wall_seconds": 293.20137929099974, "stats": {"input_tokens": 34206, "total_output_tokens": 2003, "reasoning_output_tokens": 0, "tokens_per_second": 21.67944224324697, "time_to_first_token_seconds": 200.643}, "http_status": 200, "event_counts": {"chat.end": 1, "chat.start": 1, "message.delta": 2002, "message.end": 1, "message.start": 1, "prompt_processing.end": 1, "prompt_processing.progress": 18, "prompt_processing.start": 1}, "errors": [], "attested_model_instance_id": "gemma-4-12b-it-mlx", "model_inventory_after": {"type": "llm", "publisher": "lmstudio-community", "key": "gemma-4-12b-it-mlx", "display_name": "Gemma 4 12B Instruct", "architecture": "gemma4_unified", "quantization": {"name": "6bit", "bits_per_weight": 6}, "size_bytes": 9760971326, "params_string": "12B", "loaded_instances": [{"id": "gemma-4-12b-it-mlx", "config": {"context_length": 262144, "parallel": 4, "reasoning_budget_message": ""}}], "max_context_length": 262144, "format": "mlx", "capabilities": {"vision": true, "trained_for_tool_use": true}, "description": null}, "model_identity_matches": true, "nonmessage_output_types": [], "response_sha256": "510fd426a7d9a67a57a4facb5bec578397d1e6f6c99e27289bd4e88761e10a9d"}
