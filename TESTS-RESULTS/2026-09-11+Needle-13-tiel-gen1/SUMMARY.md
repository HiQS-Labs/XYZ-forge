# Tiel-Coder-35B-A3B MTP Q4_K_XL — frozen Gen 1 result

**Result: delivery failure in this frozen Gen 1 condition.** Both official runs exhausted the
6,000-token output budget in identical internal reasoning and emitted no final answer. The original
grader rejected both before decision accuracy or technical-answer quality could be scored.

## Configuration and result

- Model revision: `bbe9e566f39e4fc9652ac66b71968289a03c520a`
- Artifact SHA-256: `54f46c4ce544c225122b0f066c2336f10404be7bc53b0cc94d1dbbc5e826bdc1`
- Runtime: llama.cpp 0.4.0 build 10809 (`5266f24da`), Metal offload, MTP enabled
- Input: frozen 16 cases, six questions, and byte-identical MiniCPM source packet
- Settings: temperature 0, seed 0, 6,000 output tokens, no tools, repair, retry, or prompt tuning

| Measure | Run 1 | Run 2 |
|---|---:|---:|
| Prompt tokens | 32,909 | 32,909 |
| Completion tokens | 6,000 | 6,000 |
| Wall time | 217.74 s | 216.82 s |
| Generation rate | 38.68 tok/s | 38.82 tok/s |
| MTP drafts accepted | 2,600 / 3,398 | 2,600 / 3,398 |
| Final-answer bytes | 0 | 0 |
| Reasoning bytes | 26,554 | 26,554 |
| Scoreable decisions | 0 / 16 | 0 / 16 |
| Finish reason | `length` | `length` |

The two reasoning files are byte-identical. Aggregate MTP acceptance was 5,200 / 6,796 (76.52%).
The failure therefore reproduced under fresh server processes; it is not a transient parse or
transport error.

## Interpretation and limits

This rejects Tiel-Coder in the exact unattended long-context Gen 1 advisor configuration. It does
not establish that the model cannot succeed with reasoning disabled, a shorter packet, constrained
decoding, more output tokens, fine-tuning, or another runtime. Those are different experiments and
must not overwrite this result.

The fixture is synthetic and repeatedly used, the two runs are repetitions rather than independent
holdouts, and decision quality was unobservable because no final JSON existed. This is not a full
model benchmark, production qualification, 44-label next-action evaluation, safety certification,
or general coding-capability grade.
