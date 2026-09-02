#!/usr/bin/env python3
"""harness_turn_logger.py (GH-174) — Turn Execution Telemetry Interceptor & Grading Hook.

Provides a Python context manager (HarnessTurnLogger) to automatically log
harness, gateway, model, reasoning level, wall-clock time, diff stats, and trigger
post-turn AI/reviewer grading.
"""

import json
import os
import subprocess
import time
from typing import Any, Dict, List, Optional
from device_config import get_effective_runtime_config


class HarnessTurnLogger:
    """Context manager for transparently logging turn execution into harnesses.db."""

    def __init__(
        self,
        harness_id: str,
        shim: str,
        task_scope: str,
        model_id: Optional[str] = None,
        gateway: Optional[str] = None,
        reasoning_effort: Optional[str] = None,
        cli_flags: Optional[List[str]] = None,
        repo_root: Optional[str] = None,
    ):
        self.cfg = get_effective_runtime_config()
        self.device_id = self.cfg["device_id"]
        self.harness_id = harness_id
        self.shim = shim
        self.task_scope = task_scope
        self.model_id = model_id or self.cfg["model"]
        self.gateway = gateway or self.cfg["gateway"]
        self.reasoning_effort = reasoning_effort or self.cfg["reasoning_effort"]
        self.cli_flags = cli_flags or []
        self.repo_root = repo_root or os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        self.start_time: float = 0.0
        self.invocation_id: Optional[str] = None
        self.exit_code: int = 0
        self.tokens: int = 0
        self.cost: float = 0.0
        self.diff_stat: str = ""

    def __enter__(self):
        self.start_time = time.time()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if not self.cfg.get("logging_enabled", False):
            return

        duration = time.time() - self.start_time
        if exc_type is not None:
            self.exit_code = 1

        # Extract diff stat if inside a git repo
        try:
            r = subprocess.run(
                ["git", "diff", "--stat"],
                cwd=self.repo_root,
                capture_output=True,
                text=True,
                check=False,
            )
            self.diff_stat = r.stdout.strip().splitlines()[-1] if r.stdout.strip() else "0 files changed"
        except Exception:
            self.diff_stat = "n/a"

        # Log invocation via harness_app.py
        harness_app = os.path.join(self.repo_root, "utils", "py", "harness_app.py")
        if os.path.exists(harness_app):
            cmd = [
                "python3", harness_app, "log",
                "--device-id", str(self.device_id),
                "--harness-id", str(self.harness_id),
                "--model-id", str(self.model_id),
                "--gateway", str(self.gateway),
                "--reasoning-effort", str(self.reasoning_effort),
                "--shim", str(self.shim),
                "--flags", json.dumps(self.cli_flags),
                "--task-scope", str(self.task_scope),
                "--seconds", f"{duration:.2f}",
                "--exit-code", str(self.exit_code),
                "--tokens", str(self.tokens),
                "--cost", f"{self.cost:.4f}",
                "--diff-stat", str(self.diff_stat),
            ]
            res = subprocess.run(cmd, cwd=self.repo_root, capture_output=True, text=True, check=False)
            if res.returncode == 0:
                self.invocation_id = res.stdout.strip()
            else:
                # GH-346: this branch did not exist. A non-zero harness_app.py exit was discarded in
                # silence, so a turn could report success while writing NO audit row — measured, not
                # hypothetical: invocation_logs has foreign keys to devices/harnesses/models, and an
                # unseeded or unregistered harness_id fails with "FOREIGN KEY constraint failed".
                # Still non-fatal (a turn must never fail because logging did), but never silent.
                import sys as _sys
                print(
                    f"harness-turn-logger: telemetry row NOT written for {self.harness_id} "
                    f"(harness_app.py exit {res.returncode}): {(res.stderr or '').strip()[-300:]}",
                    file=_sys.stderr,
                )

    def record_evaluation(
        self,
        evaluated_by: str,
        role: str,
        grade: str,
        gate_passed: bool,
        narrative: str,
        cleanliness: int = 5,
        seam_score: int = 5,
        failure_tag: str = "none",
    ) -> Optional[str]:
        """Record post-turn AI / reviewer evaluation into harnesses.db."""
        if not self.invocation_id:
            return None

        harness_app = os.path.join(self.repo_root, "utils", "py", "harness_app.py")
        cmd = [
            "python3", harness_app, "eval",
            "--invocation-id", str(self.invocation_id),
            "--evaluated-by", str(evaluated_by),
            "--role", str(role),
            "--grade", str(grade),
            "--gate-passed", "1" if gate_passed else "0",
            "--cleanliness", str(cleanliness),
            "--seam-score", str(seam_score),
            "--narrative", str(narrative),
            "--failure-tag", str(failure_tag),
        ]
        res = subprocess.run(cmd, cwd=self.repo_root, capture_output=True, text=True, check=False)
        return res.stdout.strip() if res.returncode == 0 else None
