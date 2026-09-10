#!/usr/bin/env python3
"""Run one fresh, tools-disabled MiniCPM MLX Gen-1 sample."""

import hashlib
import json
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parent
PYTHON = Path("/Users/noelsaw/minicpm5-mlx-env/bin/python")
MODEL = Path("/Users/noelsaw/minicpm5-2b-mlx")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] not in {"r1", "r2"}:
        raise SystemExit("usage: run_mlx.py r1|r2")
    run = sys.argv[1]
    prompt = (ROOT / "prompt.txt").read_text()
    request = json.loads((ROOT / "request.json").read_text())
    command = [
        str(PYTHON), "-m", "mlx_lm.generate",
        "--model", str(MODEL),
        "--system-prompt", request["system_prompt"],
        "--prompt", "-",
        "--max-tokens", str(request["max_output_tokens"]),
        "--temp", "0",
        "--seed", str(request["seed"]),
        "--verbose", "False",
    ]
    started_at = datetime.now(timezone.utc).isoformat()
    started = time.monotonic()
    proc = subprocess.run(
        command,
        input=prompt,
        text=True,
        capture_output=True,
        timeout=1200,
        check=False,
    )
    elapsed = time.monotonic() - started
    answer_path = ROOT / f"{run}-answer.md"
    stderr_path = ROOT / f"{run}-stderr.txt"
    answer_path.write_text(proc.stdout)
    stderr_path.write_text(proc.stderr)
    receipt = {
        "schema": "needle13/minicpm5-mlx-gen1@1",
        "run": run,
        "status": "complete" if proc.returncode == 0 else "failed",
        "started_at": started_at,
        "model_id": request["model_id"],
        "model_revision": request["revision"],
        "model_path": str(MODEL),
        "quantization_bits": 4,
        "mlx_lm_version": "0.31.3",
        "temperature": 0,
        "seed": request["seed"],
        "max_output_tokens": request["max_output_tokens"],
        "fresh_process": True,
        "wall_seconds": elapsed,
        "returncode": proc.returncode,
        "prompt_sha256": sha256(ROOT / "prompt.txt"),
        "answer_sha256": sha256(answer_path),
        "stderr_sha256": sha256(stderr_path),
        "answer_bytes": answer_path.stat().st_size,
        "stderr_bytes": stderr_path.stat().st_size,
    }
    (ROOT / f"{run}-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps(receipt, indent=2))
    return proc.returncode


if __name__ == "__main__":
    raise SystemExit(main())
