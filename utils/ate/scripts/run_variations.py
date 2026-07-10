#!/usr/bin/env python3
"""
Gemma-driven Aider variation tester.

Runs a grid of Aider CLI variations against a target pipeline (Aider -> OpenRouter
-> GLM 5.2 by default), asks a local Gemma model (served by LM Studio) to classify
each result, and appends one JSON record per variation to error_log.jsonl.

Polls control.json before every iteration so a supervising frontier model (Claude)
can abort the run mid-flight.

When the run ends (time limit, abort, or the iteration safety cap) it chains
straight into compile_issue.py, filing one GitHub issue titled
"ATE - [test-name] yyyy-mm-dd" with every finding from this run in a single
severity-ranked checklist — pass --gh-repo to enable this.

Requires: `pip install requests pyyaml`
LM Studio: Developer tab -> Start Server (default http://localhost:1234/v1)
"""
from __future__ import annotations

import argparse
import itertools
import json
import os
import signal
import subprocess
import time
import sys
from pathlib import Path

import requests
import yaml

CLASSIFY_PROMPT = """You are triaging the output of a test run for the {pipeline_name} \
coding pipeline. Given the command, exit code, and truncated stdout/stderr below, \
classify the result. Respond with ONLY a JSON object, no prose, no markdown fences:

{{"status": "pass" or "fail",
  "severity": "critical" | "high" | "medium" | "low" | "none",
  "category": short slug e.g. "crash" | "auth_failure" | "bad_diff" | "timeout" | "no_edit" | "ok",
  "likely_cause": one short sentence}}

Only call something "fail"/"crash" if there is concrete evidence: a non-zero exit code, a \
Python traceback, an explicit error/auth-failure message, or a malformed/no-op diff. A \
non-zero exit code is REQUIRED for "critical" or "crash". A cosmetic warning line (e.g. \
"Unknown context window size and costs, using sane defaults") with exit code 0 and a \
successful "Applied edit" line is NOT a failure on its own.

COMMAND: {command}
EXIT_CODE: {exit_code}
STDOUT_TAIL:
{stdout}
STDERR_TAIL:
{stderr}
"""


def ask_gemma(base_url: str, model: str, prompt: str, timeout: int = 60) -> dict:
    try:
        resp = requests.post(
            f"{base_url}/chat/completions",
            json={
                "model": model,
                "messages": [{"role": "user", "content": prompt}],
                "temperature": 0.1,
                "max_tokens": 300,
            },
            timeout=timeout,
        )
        resp.raise_for_status()
        text = resp.json()["choices"][0]["message"]["content"].strip()
    except requests.exceptions.RequestException as e:
        return {
            "status": "unknown",
            "severity": "medium",
            "category": "classification_request_error",
            "likely_cause": f"LM Studio request failed: {e}",
        }
    except (KeyError, IndexError, TypeError, json.JSONDecodeError) as e:
        return {
            "status": "unknown",
            "severity": "medium",
            "category": "classification_response_shape_error",
            "likely_cause": f"LM Studio response had an unexpected shape: {e}",
        }
    # Gemma sometimes wraps JSON in fences despite instructions; strip them.
    text = text.strip("`")
    if text.startswith("json"):
        text = text[4:].strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return {
            "status": "unknown",
            "severity": "medium",
            "category": "classification_parse_error",
            "likely_cause": f"Gemma returned non-JSON: {text[:200]}",
        }


def build_variations(grid: dict) -> list[dict]:
    keys = ["edit_formats", "map_tokens", "auto_commits"]
    values = [grid[k] for k in keys]
    combos = []
    for edit_format, map_tokens, auto_commits in itertools.product(*values):
        combos.append(
            {
                "edit_format": edit_format,
                "map_tokens": map_tokens,
                "auto_commits": auto_commits,
            }
        )
    return combos


def initial_commit(repo: str) -> str:
    return subprocess.run(
        ["git", "rev-parse", "HEAD"], cwd=repo, capture_output=True, text=True, check=True,
    ).stdout.strip()


def reset_repo(repo: str, sha: str, keep: list[str]) -> None:
    """Each variation reruns the same nominal task; without a reset, later
    variations edit whatever state earlier ones left behind (e.g. a docstring
    already applied), turning the task into a no-op and making results
    incomparable across the grid. `keep` excludes run_variations.py's own
    untracked log/control files, which otherwise live in this same repo dir
    and would be wiped by `git clean` before their contents are read back."""
    subprocess.run(["git", "reset", "--hard", sha], cwd=repo, capture_output=True, check=True)
    clean_cmd = ["git", "clean", "-fdx"]
    for path in keep:
        clean_cmd += ["-e", path]
    subprocess.run(clean_cmd, cwd=repo, capture_output=True, check=True)


def run_aider(repo: str, model: str, variation: dict, message: str, timeout: int,
              openai_api_base: str | None = None, openai_api_key: str | None = None):
    cmd = [
        "aider",
        "--model", model,
        "--edit-format", variation["edit_format"],
        "--map-tokens", str(variation["map_tokens"]),
        "--yes",
        "--no-stream",
        "--message", message,
    ]
    if not variation["auto_commits"]:
        cmd.append("--no-auto-commits")
    # GH-147 contract: same AIDER_OPENAI_API_BASE/AIDER_OPENAI_API_KEY seam used by
    # relay-automation/consult.sh and utils/py/consult.py, so an OpenAI-compatible
    # endpoint (e.g. LM Studio) can stand in for the OpenRouter target.
    if openai_api_base:
        cmd += ["--openai-api-base", openai_api_base, "--openai-api-key", openai_api_key or "dummy"]

    start = time.time()
    # Run in its own process group so a timeout can kill any children aider
    # spawns, not just the direct aider process.
    proc = subprocess.Popen(
        cmd, cwd=repo, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        text=True, errors="replace", start_new_session=True,
    )
    try:
        stdout, stderr = proc.communicate(timeout=timeout)
        return {
            "command": " ".join(cmd),
            "exit_code": proc.returncode,
            "stdout": stdout[-4000:],
            "stderr": stderr[-4000:],
            "wall_seconds": round(time.time() - start, 1),
            "timed_out": False,
        }
    except subprocess.TimeoutExpired:
        os.killpg(proc.pid, signal.SIGKILL)
        stdout, stderr = proc.communicate()
        return {
            "command": " ".join(cmd),
            "exit_code": None,
            "stdout": (stdout or "")[-4000:],
            "stderr": (stderr or "")[-4000:],
            "wall_seconds": round(time.time() - start, 1),
            "timed_out": True,
        }


def check_control(control_path: Path) -> dict | None:
    if not control_path.exists():
        return None
    try:
        data = json.loads(control_path.read_text())
    except json.JSONDecodeError:
        return None
    return data


def file_issue(log_path: Path, gh_repo: str, test_name: str, dry_run: bool) -> None:
    """Chain into compile_issue.py so the run ends with one filed GitHub issue
    instead of a log that needs a separate manual rollup step."""
    script = Path(__file__).resolve().parent / "compile_issue.py"
    cmd = [
        sys.executable, str(script),
        "--log", str(log_path),
        "--repo", gh_repo,
        "--test-name", test_name,
    ]
    if dry_run:
        cmd.append("--dry-run")
    print(f"[run_variations] filing rollup issue: {' '.join(cmd)}")
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print(f"[run_variations] compile_issue.py exited {result.returncode} — issue may not "
              f"have been filed; {log_path} is preserved for a manual rollup.")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True, help="scratch git repo to run aider in")
    ap.add_argument("--variations", required=True, help="path to variations.yaml")
    ap.add_argument("--log", default="error_log.jsonl")
    ap.add_argument("--control", default="control.json")
    ap.add_argument("--lmstudio-url", default="http://localhost:1234/v1")
    ap.add_argument("--lmstudio-model", required=True,
                     help="exact model id as shown in LM Studio's /v1/models")
    ap.add_argument("--minutes", type=float, default=180)
    ap.add_argument("--per-variation-timeout", type=int, default=None,
                     help="overrides per_variation_timeout_seconds in the yaml")
    ap.add_argument("--gh-repo", default=None,
                     help="owner/repo to auto-file the rollup issue in when the run ends "
                          "(omit to skip auto-filing and just leave the log for a manual "
                          "compile_issue.py run)")
    ap.add_argument("--test-name", default=None,
                     help="slug for the issue title 'ATE - [test-name] yyyy-mm-dd'; "
                          "defaults to the variations file's stem")
    ap.add_argument("--dry-run-issue", action="store_true",
                     help="build the rollup issue body but don't actually call gh "
                          "(passed through to compile_issue.py as --dry-run)")
    ap.add_argument("--pipeline-name", default="Aider -> OpenRouter -> GLM 5.2",
                     help="description of the pipeline under test, used in the classifier "
                          "prompt (default matches the stock OpenRouter target)")
    args = ap.parse_args()

    aider_openai_api_base = os.environ.get("AIDER_OPENAI_API_BASE")
    aider_openai_api_key = os.environ.get("AIDER_OPENAI_API_KEY", "dummy")

    grid = yaml.safe_load(Path(args.variations).read_text())
    combos = build_variations(grid)
    timeout = args.per_variation_timeout or grid.get("per_variation_timeout_seconds", 180)
    test_name = args.test_name or Path(args.variations).stem

    log_path = Path(args.log)
    control_path = Path(args.control)
    # Reset any stale abort left over from a previous run in this directory,
    # so a fresh invocation doesn't die on iteration 0.
    control_path.write_text(json.dumps({"action": "continue"}))
    deadline = time.time() + args.minutes * 60

    base_sha = initial_commit(args.repo)

    print(f"[run_variations] {len(combos)} variations queued, "
          f"deadline in {args.minutes} min, logging to {log_path}")

    for i, variation in enumerate(itertools.cycle(combos)):
        if time.time() > deadline:
            print("[run_variations] time budget exhausted, stopping.")
            break

        control = check_control(control_path)
        if control and control.get("action") == "abort":
            print(f"[run_variations] abort received: {control.get('reason', '')}")
            break

        reset_repo(args.repo, base_sha, keep=[log_path.name, control_path.name])
        result = run_aider(args.repo, grid["model"], variation, grid["message"], timeout,
                            openai_api_base=aider_openai_api_base, openai_api_key=aider_openai_api_key)

        if result["timed_out"]:
            classification = {
                "status": "fail",
                "severity": "high",
                "category": "timeout",
                "likely_cause": f"Aider did not finish within {timeout}s",
            }
        else:
            prompt = CLASSIFY_PROMPT.format(
                pipeline_name=args.pipeline_name,
                command=result["command"],
                exit_code=result["exit_code"],
                stdout=result["stdout"][-1500:],
                stderr=result["stderr"][-1500:],
            )
            classification = ask_gemma(args.lmstudio_url, args.lmstudio_model, prompt)

        record = {
            "iteration": i,
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S"),
            "variation": variation,
            **result,
            "classification": classification,
        }
        with log_path.open("a") as f:
            f.write(json.dumps(record) + "\n")

        print(f"[{i}] {variation} -> {classification.get('status')}/"
              f"{classification.get('severity')} ({classification.get('category')})")

        if i >= len(combos) * 20:  # sane upper bound even if minutes is huge
            print("[run_variations] hit iteration safety cap, stopping.")
            break

    print("[run_variations] done.")

    if args.gh_repo:
        file_issue(log_path, args.gh_repo, test_name, args.dry_run_issue)
    else:
        print(f"[run_variations] --gh-repo not set; skipping automatic issue filing. "
              f"To file manually: python3 compile_issue.py --log {log_path} "
              f"--repo OWNER/REPO --test-name {test_name}")


if __name__ == "__main__":
    sys.exit(main())
