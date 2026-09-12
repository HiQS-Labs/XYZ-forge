#!/usr/bin/env python3
"""Score Tiel-Coder zero-shot over the frozen six-label public holdout."""
from __future__ import annotations

import collections
import hashlib
import json
import statistics
import sys
import time
import urllib.request
from pathlib import Path

LABELS = ("edit", "git", "read", "run_command", "run_tests", "search")
EXPECTED_SHA256 = "f016551eda2f9912c2ab81887669281452777ac103737f6e9b092044064a8587"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


holdout = Path(sys.argv[1])
private_out = Path(sys.argv[2])
public_out = Path(sys.argv[3])
if digest(holdout) != EXPECTED_SHA256:
    raise SystemExit("holdout hash mismatch")
rows = [json.loads(line) for line in holdout.read_text().splitlines() if line.strip()]
if len(rows) != 100:
    raise SystemExit(f"expected 100 rows, got {len(rows)}")

predictions = []
support = collections.Counter()
correct = collections.Counter()
latencies = []
for index, row in enumerate(rows, 1):
    expected = row["answers"][0]["name"]
    support[expected] += 1
    descriptions = "; ".join(f'{tool["name"]}: {tool["description"]}' for tool in row["tools"])
    prompt = (
        row["query"] + "\n\nAllowed labels: " + descriptions
        + "\nReturn exactly one allowed label and nothing else."
    )
    request_obj = {
        "model": "tiel-coder-35b-a3b-mtp-ud-q4_k_xl",
        "messages": [
            {"role": "system", "content": row["system"]},
            {"role": "user", "content": prompt},
        ],
        "temperature": 0,
        "seed": 0,
        "max_tokens": 16,
        "stream": False,
        "cache_prompt": False,
    }
    req = urllib.request.Request(
        "http://127.0.0.1:18080/v1/chat/completions",
        data=json.dumps(request_obj).encode(),
        headers={"Content-Type": "application/json"},
    )
    started = time.monotonic()
    with urllib.request.urlopen(req, timeout=120) as response:
        obj = json.load(response)
    latency = time.monotonic() - started
    latencies.append(latency)
    message = obj["choices"][0]["message"]
    raw = (message.get("content") or "").strip()
    prediction = raw if raw in LABELS else None
    if prediction == expected:
        correct[expected] += 1
    predictions.append({
        "index": index,
        "expected": expected,
        "prediction": prediction,
        "raw": raw,
        "reasoning": message.get("reasoning_content") or "",
        "latency_seconds": latency,
        "finish_reason": obj["choices"][0].get("finish_reason"),
        "usage": obj.get("usage"),
    })
    print(f"{index}/100", file=sys.stderr, flush=True)

private_out.write_text("".join(json.dumps(row) + "\n" for row in predictions))
valid = sum(row["prediction"] is not None for row in predictions)
hits = sum(row["prediction"] == row["expected"] for row in predictions)
ordered = sorted(latencies)
metrics = {
    "schema": "needle/coding-core-tiel-zero-shot@1",
    "model_id": "peculiar-ragdoll/Tiel-Coder-35B-A3B-GGUF-MTP",
    "model_revision": "bbe9e566f39e4fc9652ac66b71968289a03c520a",
    "artifact": "Tiel-Coder-35B-A3B-MTP-UD-Q4_K_XL.gguf",
    "artifact_sha256": "54f46c4ce544c225122b0f066c2336f10404be7bc53b0cc94d1dbbc5e826bdc1",
    "runtime": "llama.cpp 0.4.0 build 10809 (5266f24da)",
    "mtp": True,
    "reasoning": "off",
    "temperature": 0,
    "seed": 0,
    "max_output_tokens": 16,
    "holdout_sha256": digest(holdout),
    "rows": len(rows),
    "valid_outputs": valid,
    "invalid_outputs": len(rows) - valid,
    "correct": hits,
    "top1_accuracy": hits / len(rows),
    "support": dict(sorted(support.items())),
    "correct_by_label": dict(sorted(correct.items())),
    "recall_by_label": {
        label: correct[label] / count for label, count in sorted(support.items())
    },
    "predicted_distribution": dict(sorted(collections.Counter(
        row["prediction"] or "INVALID" for row in predictions
    ).items())),
    "latency_seconds": {
        "total": sum(latencies),
        "mean": statistics.mean(latencies),
        "median": statistics.median(latencies),
        "p95_nearest_rank": ordered[94],
        "min": min(latencies),
        "max": max(latencies),
    },
    "private_predictions_sha256": digest(private_out),
    "caveat": "Narrow zero-shot probe on a reused 100-row/two-instance development set; not a full benchmark grade.",
}
public_out.write_text(json.dumps(metrics, indent=2) + "\n")
print(json.dumps(metrics, indent=2))
