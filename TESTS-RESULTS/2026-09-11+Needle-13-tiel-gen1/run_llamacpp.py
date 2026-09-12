#!/usr/bin/env python3
"""Run one frozen Gen 1 request against a local llama.cpp server."""
from __future__ import annotations

import hashlib
import json
import sys
import time
import urllib.request
from pathlib import Path


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


root = Path(__file__).resolve().parent
run = sys.argv[1]
prompt_bytes = (root / "prompt.txt").read_bytes()
request_obj = {
    "model": "tiel-coder-35b-a3b-mtp-ud-q4_k_xl",
    "messages": [{"role": "user", "content": prompt_bytes.decode()}],
    "temperature": 0,
    "seed": 0,
    "max_tokens": 6000,
    "stream": False,
    "cache_prompt": False,
}
(root / f"{run}-request.json").write_text(json.dumps(request_obj, indent=2) + "\n")
req = urllib.request.Request(
    "http://127.0.0.1:18080/v1/chat/completions",
    data=json.dumps(request_obj).encode(),
    headers={"Content-Type": "application/json"},
)
started = time.time()
started_mono = time.monotonic()
with urllib.request.urlopen(req, timeout=900) as response:
    raw = response.read()
wall = time.monotonic() - started_mono
(root / f"{run}-response.json").write_bytes(raw + (b"\n" if not raw.endswith(b"\n") else b""))
obj = json.loads(raw)
message = obj["choices"][0]["message"]
content = message.get("content") or ""
reasoning = message.get("reasoning_content") or ""
(root / f"{run}-answer.md").write_text(content)
(root / f"{run}-reasoning.md").write_text(reasoning)
receipt = {
    "schema": "needle13/tiel-gen1@1",
    "run": run,
    "status": "complete",
    "started_unix": started,
    "model_id": "peculiar-ragdoll/Tiel-Coder-35B-A3B-GGUF-MTP",
    "model_revision": "bbe9e566f39e4fc9652ac66b71968289a03c520a",
    "artifact": "Tiel-Coder-35B-A3B-MTP-UD-Q4_K_XL.gguf",
    "artifact_sha256": "54f46c4ce544c225122b0f066c2336f10404be7bc53b0cc94d1dbbc5e826bdc1",
    "runtime": "llama.cpp 0.4.0 build 10809 (5266f24da)",
    "mtp": {"enabled": True, "draft_n_max": 1, "draft_p_min": 0.0},
    "temperature": 0,
    "seed": 0,
    "max_output_tokens": 6000,
    "fresh_server_process": True,
    "wall_seconds": wall,
    "prompt_sha256": sha256(prompt_bytes),
    "request_sha256": sha256((root / f"{run}-request.json").read_bytes()),
    "response_sha256": sha256(raw),
    "answer_sha256": sha256(content.encode()),
    "answer_bytes": len(content.encode()),
    "reasoning_bytes": len(reasoning.encode()),
    "finish_reason": obj["choices"][0].get("finish_reason"),
    "usage": obj.get("usage"),
    "timings": obj.get("timings") or {},
}
(root / f"{run}-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
print(json.dumps(receipt, indent=2))
