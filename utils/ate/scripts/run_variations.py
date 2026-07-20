#!/usr/bin/env python3
"""
Gemma-driven variation tester (Aider by default; pluggable per GH-191).

Runs a grid of CLI variations against a target pipeline (Aider -> OpenRouter
-> GLM 5.2 by default), asks a local Gemma model (served by LM Studio) to classify
each result, and appends one JSON record per variation to error_log.jsonl.

GH-191: the harness command is pluggable. By default (no `command_template` in
variations.yaml) this runs the reference Aider config exactly as before. To point
it at a different CLI, declare in variations.yaml:
  command_template: ["some-cli", "--flag", "{some_key}", "--message", "{message}"]
  variation_keys: [some_key]
  some_key: [a, b, c]
`command_template` tokens are substituted via str.format against the variation
dict plus {model}/{message} (argv-list substitution, never a shell string, so
values can't inject shell metacharacters). `variation_keys` names which
grid entries form the itertools.product grid; omit both to keep today's Aider
grid (edit_formats/map_tokens/auto_commits).

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

EDIT_APPLIED below is a deterministic signal computed from git (whether aider actually changed \
the tree). The task is always an edit task, so EDIT_APPLIED=False with exit code 0 means the run \
produced NO change — classify that as "fail"/"no_edit" (severity "high"), NOT a pass, even though \
nothing crashed. Do not mark a run "pass"/"ok" when EDIT_APPLIED is False.

COMMAND: {command}
EXIT_CODE: {exit_code}
EDIT_APPLIED: {edit_applied}
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
    """Build the cartesian-product grid of variations to test.

    GH-191: if variations.yaml declares `variation_keys` (a list of its own
    grid key names), the product is built generically over those — the keys
    land in each combo dict verbatim, so a non-Aider harness can express any
    flag surface. Without `variation_keys`, falls back to the original Aider
    reference grid (edit_formats/map_tokens/auto_commits) unchanged, so every
    existing variations.yaml keeps working exactly as before.
    """
    variation_keys = grid.get("variation_keys")
    if variation_keys:
        values = [grid[k] for k in variation_keys]
        return [dict(zip(variation_keys, combo)) for combo in itertools.product(*values)]

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


def _git(repo: str, *args: str, check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["git", *args], cwd=repo, capture_output=True, text=True, check=check,
    )


class RepoGuardError(Exception):
    """Raised when --repo fails the disposability guard (see assert_disposable_repo)."""


def assert_disposable_repo(repo: str, harness_root: str, allow_destructive: bool) -> None:
    """`reset_repo` runs `git reset --hard` + `git clean -fdx` before every
    variation, which permanently destroys uncommitted and ignored files in
    `repo`. That is fine for a throwaway scratch repo but catastrophic if
    `--repo` is mis-pointed at a real checkout. This gate refuses the two
    realistic footguns before any destructive command runs (GH-195 review):

      1. `repo` IS (or is inside) the harness clone that ships this script —
         running ATE against xyz-3-agents-swarm itself would wipe the harness.
         Hard-refused unconditionally; --allow-destructive-reset does NOT
         override this one.
      2. `repo` has a configured git remote — a fresh `git init` scratch repo
         has none; a real project clone almost always does. Refused unless
         --allow-destructive-reset is passed to acknowledge the risk.
    """
    if not _git(repo, "rev-parse", "--is-inside-work-tree", check=False).returncode == 0:
        raise RepoGuardError(f"--repo is not inside a git work tree: {repo}")

    repo_top = _git(repo, "rev-parse", "--show-toplevel").stdout.strip()
    harness_top = _git(harness_root, "rev-parse", "--show-toplevel", check=False).stdout.strip()
    if harness_top and os.path.realpath(repo_top) == os.path.realpath(harness_top):
        raise RepoGuardError(
            f"refusing to run: --repo resolves to the harness repo itself ({repo_top}). "
            "ATE's per-variation `git reset --hard` + `git clean -fdx` would destroy it. "
            "Point --repo at a disposable scratch repo (see SKILL.md 'Quick start')."
        )

    remotes = _git(repo, "remote").stdout.strip()
    if remotes and not allow_destructive:
        raise RepoGuardError(
            f"refusing to run: --repo ({repo_top}) has a configured git remote "
            f"({remotes.split(chr(10))[0]}), so it looks like a real checkout, not a scratch "
            "repo. ATE destroys uncommitted + ignored files every variation. If this really is "
            "disposable, re-run with --allow-destructive-reset."
        )


def ensure_base_commit(repo: str, keep: list[str]) -> str:
    """Return the SHA `reset_repo` rewinds to before each variation. If `repo`
    already has a HEAD, use it. If it has no commits yet (a fresh `git init`,
    exactly what SKILL.md's Quick start creates), auto-create a base commit from
    the current tree instead of crashing on `git rev-parse HEAD` (GH-195 review
    blocker) — excluding this script's own log/control files so a later
    `git reset --hard` can't truncate the growing log back to an empty committed
    version."""
    head = _git(repo, "rev-parse", "HEAD", check=False)
    if head.returncode == 0:
        return head.stdout.strip()

    _git(repo, "add", "-A")
    for k in keep:
        _git(repo, "rm", "--cached", "--ignore-unmatch", "--", k)
    _git(
        repo,
        "-c", "user.name=ATE", "-c", "user.email=ate@example.com",
        "commit", "--allow-empty", "-m", "ATE base commit (auto-created for reset baseline)",
    )
    return _git(repo, "rev-parse", "HEAD").stdout.strip()


def _clear_stale_index_lock(repo: str) -> None:
    """A killed/timed-out aider can leave `.git/index.lock` behind, which makes
    every subsequent `git reset` fail and would otherwise crash the whole loop
    (GH-195 review nit). Safe to remove here: this is a single-process scratch
    repo and we're about to hard-reset it anyway."""
    lock = Path(_git(repo, "rev-parse", "--git-dir").stdout.strip()) / "index.lock"
    if not lock.is_absolute():
        lock = Path(repo) / lock
    try:
        lock.unlink()
    except FileNotFoundError:
        pass


def reset_repo(repo: str, sha: str, keep: list[str]) -> None:
    """Each variation reruns the same nominal task; without a reset, later
    variations edit whatever state earlier ones left behind (e.g. a docstring
    already applied), turning the task into a no-op and making results
    incomparable across the grid. `keep` excludes run_variations.py's own
    untracked log/control files, which otherwise live in this same repo dir
    and would be wiped by `git clean` before their contents are read back.

    NOTE: destructive (`git reset --hard` + `git clean -fdx`). `--repo` MUST be
    disposable — assert_disposable_repo gates this at startup."""
    _clear_stale_index_lock(repo)
    _git(repo, "reset", "--hard", sha)
    clean_cmd = ["clean", "-fdx"]
    for path in keep:
        clean_cmd += ["-e", path]
    _git(repo, *clean_cmd)


def detect_edit(repo: str, base_sha: str, keep: list[str]) -> bool:
    """Deterministically report whether aider actually changed the tree this
    variation — for auto-commit turns HEAD moves off base_sha; for
    --no-auto-commits turns the working tree goes dirty. Recorded alongside the
    LLM classification so a "pass" with no effective edit is visible instead of
    silently trusted (GH-195 review: the tightened classifier prompt otherwise
    risks passing exit-0/no-edit runs)."""
    if _git(repo, "rev-parse", "HEAD", check=False).stdout.strip() != base_sha:
        return True
    status = _git(repo, "status", "--porcelain").stdout.splitlines()
    keepset = set(keep)
    for line in status:
        path = line[3:].strip().strip('"')
        if path not in keepset:
            return True
    return False


def build_aider_cmd(model: str, variation: dict, message: str,
                     openai_api_base: str | None = None, openai_api_key: str | None = None) -> list[str]:
    """Default/reference argv builder — Aider's own CLI surface, unchanged
    from before GH-191. Used whenever variations.yaml doesn't declare a
    `command_template`, so the stock config keeps working exactly as before."""
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
    return cmd


def build_templated_cmd(template: list, variation: dict, model: str, message: str) -> list[str]:
    """GH-191: build argv for a pluggable, non-Aider harness from
    variations.yaml's `command_template` — a list of argv tokens, each
    substituted via str.format against the variation dict plus {model}/
    {message}. This is list-based (never a shell string), so a variation
    value can't inject shell metacharacters."""
    context = {"model": model, "message": message, **variation}
    return [str(tok).format(**context) for tok in template]


def run_harness(cmd: list[str], repo: str, timeout: int) -> dict:
    """Execute one variation's argv and capture the result. Harness-agnostic
    (GH-191): works the same whether `cmd` came from build_aider_cmd (the
    default) or build_templated_cmd (a pluggable harness) — this is just the
    process/timeout/output-capture plumbing that used to live in run_aider()."""
    start = time.time()
    # Run in its own process group so a timeout can kill any children the
    # harness spawns, not just the direct process.
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
    ap.add_argument("--repo", required=True, help="scratch git repo to run the harness in")
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
    ap.add_argument("--allow-destructive-reset", action="store_true",
                     help="acknowledge that --repo is disposable and may be hard-reset + "
                          "cleaned every variation, even if it has a git remote. Required only "
                          "when --repo has a remote (a fresh scratch `git init` has none).")
    args = ap.parse_args()

    aider_openai_api_base = os.environ.get("AIDER_OPENAI_API_BASE")
    aider_openai_api_key = os.environ.get("AIDER_OPENAI_API_KEY", "dummy")

    # Gate the destructive per-variation reset BEFORE anything runs — refuse the
    # harness repo itself, and refuse a remote-having (real-looking) repo unless
    # the operator explicitly opted in (GH-195 review blocker).
    harness_root = str(Path(__file__).resolve().parent)
    try:
        assert_disposable_repo(args.repo, harness_root, args.allow_destructive_reset)
    except RepoGuardError as e:
        print(f"[run_variations] {e}", file=sys.stderr)
        return 2

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

    keep_files = [log_path.name, control_path.name]
    base_sha = ensure_base_commit(args.repo, keep_files)

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

        reset_repo(args.repo, base_sha, keep=keep_files)
        # GH-191: variations.yaml's optional `command_template` swaps in a
        # pluggable, non-Aider harness; without it, keep building today's
        # exact Aider argv (build_aider_cmd) so existing configs are unaffected.
        command_template = grid.get("command_template")
        if command_template:
            cmd = build_templated_cmd(command_template, variation, grid["model"], grid["message"])
        else:
            cmd = build_aider_cmd(grid["model"], variation, grid["message"],
                                   openai_api_base=aider_openai_api_base, openai_api_key=aider_openai_api_key)
        result = run_harness(cmd, args.repo, timeout)
        # Deterministic signal: did the harness actually change the tree? Captured
        # before the next iteration's reset wipes it (GH-195 review).
        result["edited"] = detect_edit(args.repo, base_sha, keep_files)

        if result["timed_out"]:
            classification = {
                "status": "fail",
                "severity": "high",
                "category": "timeout",
                "likely_cause": f"the harness did not finish within {timeout}s",
            }
        else:
            prompt = CLASSIFY_PROMPT.format(
                pipeline_name=args.pipeline_name,
                command=result["command"],
                exit_code=result["exit_code"],
                edit_applied=result["edited"],
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
