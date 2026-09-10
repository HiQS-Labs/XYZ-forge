# ModernBERT-base — GH-547 compatibility results

The downloaded checkpoint loads and performs masked-token inference on this Mac. It cannot run the existing generative Git/PR analyst benchmark unchanged. Comparable grade: **N/A (task/architecture mismatch)**. No analyst answers or action predictions were generated or graded.

Frozen model revision: `8949b909ec900327062f0ebf497f51aef5e6f0c8`. Questions and packet copied byte-for-byte from the archived Phase 2 experiment, committed before the probe in `c188102`; their hashes are in results.json and provenance.jsonl. This probe concatenates QUESTIONS.md + newline + packet.json; provider-specific prefixes from earlier transports are not included.

| Check | Observed result |
|---|---|
| Architecture | ModernBertForMaskedLM |
| can_generate() | false |
| Shared input length | 9,512 ModernBERT tokens |
| Native configured maximum | 8,192 tokens |
| Local device | CPU, 4 PyTorch threads; MPS available but not exercised |
| Model/tokenizer load | 0.601 seconds, excludes Python/import startup |
| Masked-token forward pass 1 / 2 | 1.075 / 0.102 seconds |
| Both smoke outputs | Paris ranked first for “The capital of France is [MASK].” |
| Analyst / next-action score | Not measured; N/A |
| API charge | No inference API used; local compute cost not measured |

The two smoke passes reuse one loaded model and are not independent analyst trials, a p95 estimate, or evidence of the Needle serving target. The model-card example only establishes basic runtime operation. No truncation, random classification head, prompt repair or token-probability proxy was substituted for the frozen analyst rubric.

The next experiment would need a trained classification head, a separate labeled training set and an appropriate held-out protocol. Per-case inputs could address context size, but would change the earlier whole-packet protocol and must be disclosed. A 44-label next-observed-action evaluation needs actual historical action labels; analyst fixtures cannot substitute.

Runtime: Python 3.12.13, torch 2.14.0, transformers 5.17.0; packages isolated in ~/.cache/xyz-modernbert-venv. Reproduction: run probe.py with that environment and the pinned downloaded checkpoint. Raw log, outputs, input hashes and provenance are committed here. No product-runtime files changed. No full product suite was run; this is an archival experiment branch, not merge or promotion readiness. Publication skips the local pre-push product gate; the directly executed compatibility/inference probe is the focused evidence.
