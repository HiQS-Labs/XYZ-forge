# Tiel-Coder local Gen 1 replication — frozen before inference

Reuse the frozen 16 synthetic cases, six technical questions, source packet, expected decisions,
and original grader from the MiniCPM5 replication. The only prompt changes are candidate identity
and transport: Tiel-Coder-35B-A3B MTP UD-Q4_K_XL via llama.cpp. No previous candidate output or
answer key is sent.

Run two sequential requests at temperature 0, seed 0, and a 6,000-token output ceiling. Each run
uses a fresh llama-server process with an 8,192-token batch size and 49,152-token context. MTP is
enabled with one draft token and minimum draft probability 0.0. No tools, output repair, retry, or
prompt tuning. Raw response, separated final/reasoning text, timing, usage, hashes, and grader result
are retained. The artifact SHA-256 and Hugging Face revision are pinned in every receipt.

This is a narrow frozen-fixture replication, not a complete model benchmark. It does not establish
production 44-label next-action accuracy, real-world admission usefulness, calibrated citations,
privacy, cost, p95 latency, or safe autonomous execution. Two repeats measure stability under this
configuration, not independent statistical evidence.
