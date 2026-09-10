# MiniCPM5-2B MLX 4-bit — Gen 1 results

**Grade: F for this frozen Gen 1 condition.** Both official runs exhausted the 6,000-token output budget during internal reasoning and produced no final JSON. The original grader therefore rejected both before decision accuracy or technical-answer quality could be scored.

## Configuration and results

Model: `openbmb/MiniCPM5-2B-MLX`, revision `3d00c3da500debfe345e60e25a87ed2669f5b1ee`, MLX 4-bit, `mlx-lm==0.31.3`. Each run used a fresh process, the byte-identical 34K-token inline source workload, temperature 0, seed 0, a 6,000-token output cap, no tools, no repair, and no retry.

| Measure | Run 1 | Run 2 |
|---|---:|---:|
| Wall time | 168.891 s | 172.536 s |
| Output budget | 6,000 tokens | 6,000 tokens |
| Final JSON blocks | 0 | 0 |
| Scoreable decisions | 0/16 | 0/16 |
| Original grader | rejected | rejected |
| Grade | F | F |

The raw outputs are byte-identical. Each enters a repetitive reasoning loop while trying to compare the two hook snapshots and ends mid-sentence without closing its reasoning section. This makes the failure deterministic under the tested settings, rather than a transient parse error.

## Interpretation

This result rejects MiniCPM5-2B MLX 4-bit as an unattended Gen 1 advisor under the frozen prompt and output budget. It does not establish that the model cannot handle a shorter classifier-only prompt, constrained decoding, a larger output budget, or a prompt optimized on separate calibration data; those would be new experimental conditions and should not overwrite this result.

An invalid pilot is retained separately. Its wrapper accidentally left two prior-model names in Q4 and Q6. The pilot did return JSON, but used six question IDs as decisions, omitted all 16 case decisions, and omitted two answers. It is excluded from the official grade. The corrected official wrapper was frozen in commit `5757f9d` before inference.

The grader's positive and four planted negative controls passed. Both official raw outputs are nonempty, their request hashes match, each process was fresh, and both are retained with receipts and hashes. No product code changed and no production accuracy, latency percentile, cost, privacy, or race guarantee was tested.

