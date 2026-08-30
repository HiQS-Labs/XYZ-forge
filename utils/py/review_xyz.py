#!/usr/bin/env python3
"""review_xyz.py (GH-132) — Deterministic, multi-model code review engine for XYZ.

Provides throwaway-worktree isolated code review dispatch for non-Codex/Agy models
(Qwen 3.8-Max, GLM-5.3 via Command Code or OpenRouter) alongside Codex and Agy,
verifies citations on graded findings, and manages GitHub PR/issue commenting.
"""

import argparse
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import urllib.request

def xyz_write_ops_log_append(pattern, cmd):
    if os.environ.get("XYZ_WRITE_OPS_LOG") == "0":
        return
    import json
    import time
    stamp = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
    host = os.uname().nodename
    session = os.environ.get("TERM_SESSION_ID", "")
    cwd = os.getcwd()
    record = {
        "timestamp": stamp,
        "host": host,
        "session": session,
        "cwd": cwd,
        "pattern": pattern,
        "command": cmd,
        "stage": "run"
    }
    log_path = os.environ.get("XYZ_WRITE_OPS_LOG", os.path.expanduser("~/.local/state/xyz/write-ops.jsonl"))
    try:
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        fd = os.open(log_path, os.O_CREAT | os.O_WRONLY | os.O_APPEND, 0o600)
        with os.fdopen(fd, "a") as f:
            f.write(json.dumps(record) + "\n")
    except Exception:
        pass

from datetime import datetime

# Shared RTL helpers
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rtl import resolve_turn_root  # noqa: E402
from turn_diagnostics import TurnDiagnostics  # noqa: E402

# Citation & finding patterns
_CLAIM_WORD_RE = re.compile(
    r"(^|[^A-Za-z])([Vv]erified|[Cc]onfirmed|LGTM|[Ll]ooks [Gg]ood|[Cc]hecks [Oo]ut|[Aa]ll [Gg]ood"
    r"|[Ww]orks [Aa]s [Ee]xpected|[Nn]o issues( found)?)([^A-Za-z]|$)"
)
_CITATION_RE = re.compile(r'"[^"]+"|`[^`]+`|[A-Za-z0-9_./-]+:[0-9]+')
_PASS_TAG_RE = re.compile(r"\[Pass\]", re.IGNORECASE)
_BLOCKER_TAG_RE = re.compile(r"\[Blocker\]", re.IGNORECASE)
_SHOULD_TAG_RE = re.compile(r"\[Should\]", re.IGNORECASE)
_NIT_TAG_RE = re.compile(r"\[Nit\]", re.IGNORECASE)
_VERDICT_RE = re.compile(
    r"(?:\*{1,2})?Verdict:(?:\*{1,2})?\s*([A-Za-z ]+)", re.IGNORECASE
)
_LINKED_ISSUE_RE = re.compile(
    r"\b(?:[Ff]ixes|[Cc]loses|[Rr]esolves)\s+#?([0-9]{1,6})\b|\b[Gg][Hh]-([0-9]{1,6})\b"
)


def log_err(msg):
    print(f"review-xyz: {msg}", file=sys.stderr)


def die(msg, code=2):
    log_err(msg)
    sys.exit(code)


def resolve_model_slug(model_name, xyz_root):
    """Resolve colloquial model name using openrouter-model-aliases.yml or return as-is."""
    script = os.path.join(xyz_root, "relay-automation", "resolve-model-alias.sh")
    if os.path.isfile(script):
        try:
            r = subprocess.run(
                [script, model_name], capture_output=True, text=True, check=False
            )
            if r.returncode == 0 and r.stdout.strip():
                return r.stdout.strip()
        except Exception:
            pass
    return model_name


def infer_engine(model_name, explicit_engine=None):
    """Infer the underlying execution engine from model name if not specified."""
    if explicit_engine and explicit_engine != "auto":
        return explicit_engine
    m_lower = model_name.lower()
    if (
        m_lower.startswith("openrouter/")
        or "stealth" in m_lower
        or "ox-alpha" in m_lower
    ):
        return "openrouter"
    if m_lower.startswith("aider:"):
        return "aider"
    if m_lower in ("codex", "openai", "gpt-4", "o3", "o1"):
        return "codex"
    if m_lower in ("agy", "gemini", "antigravity"):
        return "agy"
    # Default frontier coding & Chinese lab models to Command Code
    return "commandcode"


def extract_diff(args, root):
    """Extract the unified diff to review based on CLI flags."""
    diff_text = ""
    pr_meta = None

    if args.diff_file:
        if not os.path.isfile(args.diff_file):
            die(f"diff file not found: {args.diff_file}")
        with open(args.diff_file, "r", errors="replace") as f:
            diff_text = f.read()
    elif args.pr:
        pr_id = str(args.pr).strip()
        # Extract PR metadata via gh
        try:
            meta_res = subprocess.run(
                [
                    "gh",
                    "pr",
                    "view",
                    pr_id,
                    "--json",
                    "number,title,body,headRefName,baseRefName,url",
                ],
                cwd=root,
                capture_output=True,
                text=True,
                check=True,
            )
            pr_meta = json.loads(meta_res.stdout)
        except Exception as e:
            die(f"failed to query PR #{pr_id} via gh: {e}")

        try:
            diff_res = subprocess.run(
                ["gh", "pr", "diff", pr_id],
                cwd=root,
                capture_output=True,
                text=True,
                check=True,
            )
            diff_text = diff_res.stdout
        except Exception as e:
            die(f"failed to extract diff for PR #{pr_id} via gh: {e}")
    elif args.branch:
        base = args.base or "development"
        cmd = ["git", "-C", root, "diff", f"{base}...{args.branch}"]
        if getattr(args, "paths", None):
            cmd += ["--"] + args.paths
        else:
            cmd += ["--", ".", ":(exclude)releases.sql", ":(exclude)*.db*"]
        try:
            diff_res = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True,
            )
            diff_text = diff_res.stdout
        except Exception as e:
            die(f"failed to diff branch {args.branch} against {base}: {e}")
    else:
        # Default: current uncommitted changes + staged changes or diff against base
        base = args.base or "HEAD"
        cmd = ["git", "-C", root, "diff", base]
        if getattr(args, "paths", None):
            cmd += ["--"] + args.paths
        else:
            cmd += ["--", ".", ":(exclude)releases.sql", ":(exclude)*.db*"]
        try:
            diff_res = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True,
            )
            diff_text = diff_res.stdout
        except Exception as e:
            die(f"failed to git diff against {base}: {e}")

    return diff_text, pr_meta


def has_uncited_claims(text, window=3):
    """Check if any [Pass] or affirmative claim lacks a citation nearby."""
    lines = text.splitlines()
    if not lines:
        return True
    any_cite = any(_CITATION_RE.search(l) for l in lines)
    if not any_cite:
        return True
    for i, line in enumerate(lines):
        claim = bool(_PASS_TAG_RE.search(line)) or bool(_CLAIM_WORD_RE.search(line))
        if not claim:
            continue
        window_end = min(len(lines), i + window + 1)
        cited = any(_CITATION_RE.search(lines[j]) for j in range(i, window_end))
        if not cited:
            return True
    return False


def build_review_prompt(diff_text, pr_meta=None, custom_instructions=""):
    """Construct the standardized, high-rigor review prompt."""
    pr_context = ""
    if pr_meta:
        pr_context = (
            f"=== PULL REQUEST CONTEXT ===\n"
            f"PR #{pr_meta.get('number')}: {pr_meta.get('title')}\n"
            f"Base: {pr_meta.get('baseRefName')} <- Head: {pr_meta.get('headRefName')}\n"
            f"URL: {pr_meta.get('url')}\n"
            f"Description:\n{pr_meta.get('body', '')}\n\n"
        )

    preamble = (
        "You are an EXPERT ADVERSARIAL CODE REVIEWER performing a formal, deterministic code review.\n"
        "Your duty is to inspect the diff for correctness, security, race conditions, edge-case regressions,\n"
        "containment leaks, and architectural soundness.\n\n"
        "RULES FOR REVIEW:\n"
        "1. Be precise and cite exact file and line numbers (`path/to/file.py:123`) or symbol names for EVERY finding.\n"
        "2. Do not hallucinate findings; reproduce the defect logically before reporting.\n"
        "3. Grade each finding into exactly one bucket:\n"
        "   - `[Blocker]`: Critical defect, correctness bug, security hole, data loss risk, or regression.\n"
        "   - `[Should]`: High-value architectural flaw, missing edge-case handling, or test gap.\n"
        "   - `[Nit]`: Style, typo, minor readability improvement.\n"
        "   - `[Pass]`: Specific verified assertion that you checked and confirmed correct (cite file:line).\n"
        "4. Conclude with an explicit VERDICT line:\n"
        "   - `**Verdict:** Approved` (if 0 Blockers and all critical paths pass)\n"
        "   - `**Verdict:** Changes requested` (if 1+ Blockers or severe Shoulds exist)\n"
        "   - `**Verdict:** Escalated` (if fundamental architectural divergence requires human operator call)\n"
        "5. Provide an Actionable Checklist at the end (`- [ ] task`).\n"
    )

    if custom_instructions:
        preamble += f"\nADDITIONAL INSTRUCTIONS:\n{custom_instructions}\n"

    return f"{preamble}\n\n{pr_context}=== UNIFIED DIFF UNDER REVIEW ===\n{diff_text}"


def parse_review_output(raw_output, strict_citations=False):
    """Extract verdict, graded findings, checklist, and citations from review output."""
    v_match = _VERDICT_RE.search(raw_output)
    if v_match:
        raw_v = v_match.group(1).strip().lower()
        if any(w in raw_v for w in ["change", "request", "reject", "fail", "needs"]):
            verdict = "Changes requested"
        elif "escalat" in raw_v:
            verdict = "Escalated"
        elif raw_v in ["approved", "approve", "passed", "pass", "lgtm"]:
            verdict = "Approved"
        else:
            verdict = "Changes requested"
    else:
        verdict = "Changes requested"

    findings = {"Blocker": [], "Should": [], "Nit": [], "Pass": []}
    checklist = []
    has_checklist_blocker = False

    for line in raw_output.splitlines():
        line_clean = line.strip()
        if line_clean.startswith("- [ ]") or line_clean.startswith("* [ ]"):
            checklist.append(line_clean)
            if _BLOCKER_TAG_RE.search(line_clean):
                has_checklist_blocker = True
            continue

        if _BLOCKER_TAG_RE.search(line_clean):
            findings["Blocker"].append(line_clean)
        elif _SHOULD_TAG_RE.search(line_clean):
            findings["Should"].append(line_clean)
        elif _NIT_TAG_RE.search(line_clean):
            findings["Nit"].append(line_clean)
        elif _PASS_TAG_RE.search(line_clean):
            findings["Pass"].append(line_clean)

    if (findings["Blocker"] or has_checklist_blocker) and verdict == "Approved":
        verdict = "Changes requested"

    if strict_citations and has_uncited_claims(raw_output) and verdict == "Approved":
        verdict = "Changes requested"

    return {
        "verdict": verdict,
        "findings": findings,
        "checklist": checklist,
        "raw": raw_output,
    }


def _kill_turn_group(proc):
    """Kill the reviewer process's entire process group, not just the launcher."""
    for sig, wait_s in ((signal.SIGTERM, 5), (signal.SIGKILL, 2)):
        try:
            os.killpg(os.getpgid(proc.pid), sig)
        except (ProcessLookupError, PermissionError, OSError):
            return
        try:
            proc.wait(timeout=wait_s)
            return
        except subprocess.TimeoutExpired:
            pass
    try:
        proc.wait(timeout=1)
    except Exception:
        pass


def execute_model_review(engine, model_name, prompt, wt_dir, timeout_s, env):
    """Execute the model review in the throwaway worktree with timeout containment."""
    log_file = os.path.join(wt_dir, "review_transcript.log")

    if engine == "openrouter":
        api_key = env.get("OPENROUTER_API_KEY")
        if not api_key:
            raise ValueError("OPENROUTER_API_KEY is not set in environment")
        clean_model = model_name
        if clean_model.startswith("openrouter/"):
            clean_model = clean_model[len("openrouter/") :]
        req_data = json.dumps(
            {
                "model": clean_model,
                "messages": [{"role": "user", "content": prompt}],
            }
        ).encode("utf-8")
        req = urllib.request.Request(
            "https://openrouter.ai/api/v1/chat/completions",
            data=req_data,
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://github.com/HiQS-Labs/XYZ-forge",
                "X-Title": "XYZ-forge review-xyz",
            },
        )
        start_t = time.time()
        try:
            with urllib.request.urlopen(req, timeout=timeout_s) as resp:
                res_json = json.loads(resp.read().decode("utf-8"))
                raw_text = (
                    res_json.get("choices", [{}])[0]
                    .get("message", {})
                    .get("content", "")
                )
                with open(log_file, "w") as out_f:
                    out_f.write(raw_text)
                return raw_text, time.time() - start_t
        except Exception as exc:
            log_err(f"OpenRouter API request failed: {exc}")
            return None, time.time() - start_t

    if engine == "commandcode":
        cmd_bin = env.get("COMMANDCODE_BIN", "cmd")
        cmd_flags = env.get(
            "COMMANDCODE_FLAGS", "--no-session --skip-onboarding --no-auto-update --yolo"
        ).split()
        full_cmd = [cmd_bin, "-p", prompt, "--model", model_name] + cmd_flags
    elif engine == "aider":
        aider_bin = env.get("AIDER_BIN", "aider")
        aider_model = model_name
        if not (
            aider_model.startswith("openrouter/")
            or aider_model.startswith("openai/")
            or aider_model.startswith("anthropic/")
        ):
            aider_model = f"openrouter/{model_name}"
        full_cmd = [
            aider_bin,
            "--model",
            aider_model,
            "--message",
            prompt,
            "--yes-always",
            "--no-auto-commits",
            "--no-gitignore",
            "--no-check-update",
            "--no-analytics",
            "--no-show-model-warnings",
            "--no-detect-urls",
            "--no-browser",
            "--no-stream",
            "--map-tokens",
            "0",
        ]
    elif engine == "codex":
        codex_bin = env.get("CODEX_BIN", "codex")
        cflags = env.get("CODEX_FLAGS", "-s read-only").split()
        full_cmd = [codex_bin, "exec"] + cflags + [prompt]
    elif engine == "agy":
        agy_bin = env.get("AGY_BIN", "agy")
        full_cmd = [
            agy_bin,
            "--dangerously-skip-permissions",
            "--print-timeout",
            f"{timeout_s}s",
            "-p",
            prompt,
        ]
    else:
        raise ValueError(f"unknown engine: {engine}")

    start_t = time.time()
    diag = TurnDiagnostics(worktree=wt_dir)
    diag.start()
    try:
        with open(log_file, "w") as out_f:
            proc = subprocess.Popen(
                full_cmd,
                cwd=wt_dir,
                env=env,
                stdout=out_f,
                stderr=subprocess.STDOUT,
                stdin=subprocess.DEVNULL,
                start_new_session=True,
            )
            try:
                proc.wait(timeout=timeout_s)
                if proc.returncode != 0:
                    log_err(f"model execution exited with status {proc.returncode}")
                    return None, time.time() - start_t
            except subprocess.TimeoutExpired:
                _reason, detail = diag.classify()
                log_err(
                    f"model execution exceeded {timeout_s}s timeout [{_reason}: {detail}]"
                )
                _kill_turn_group(proc)
                with open(log_file, "a") as err_f:
                    err_f.write(f"\nreview-xyz: execution timed out after {timeout_s}s\n")
                return None, time.time() - start_t
    except Exception as exc:
        log_err(f"failed to launch engine '{engine}': {exc}")
        return None, time.time() - start_t
    finally:
        diag.stop()

    duration = time.time() - start_t
    try:
        with open(log_file, "r", errors="replace") as f:
            raw_text = f.read()
    except OSError:
        raw_text = ""

    return raw_text, duration


def format_final_report(review_data, pr_meta, model_name, engine, duration, diff_lines):
    """Format the structured markdown report for GitHub PR comments / stdout."""
    verdict = review_data["verdict"]
    findings = review_data["findings"]
    checklist = review_data["checklist"]
    raw_body = review_data["raw"].strip()

    uncited = has_uncited_claims(raw_body)
    cit_warn = ""
    if uncited:
        cit_warn = (
            "> ⚠️ **ATTENTION:** One or more claims lacked verified file:line citations. "
            "Treat unverified [Pass] / claim assertions as conditional.\n\n"
        )

    b_count = len(findings["Blocker"])
    s_count = len(findings["Should"])
    n_count = len(findings["Nit"])
    p_count = len(findings["Pass"])

    pr_header = ""
    if pr_meta:
        pr_header = f" for PR #{pr_meta.get('number')} (`{pr_meta.get('title')}`)"

    report = (
        f"## 🛡️ Code Review Report{pr_header}\n\n"
        f"**Verdict:** `{verdict}` | **Model:** `{model_name}` (`{engine}`) | **Latency:** `{duration:.1f}s` | **Diff:** `{diff_lines} lines`\n\n"
        f"| Findings | Count |\n"
        f"|:---|:---:|\n"
        f"| 🛑 `[Blocker]` | {b_count} |\n"
        f"| ⚠️ `[Should]` | {s_count} |\n"
        f"| 💡 `[Nit]` | {n_count} |\n"
        f"| ✅ `[Pass]` | {p_count} |\n\n"
        f"{cit_warn}"
        f"### Summary & Findings\n\n"
        f"{raw_body}\n\n"
    )

    if checklist:
        report += "### 📋 Actionable Checklist\n" + "\n".join(checklist) + "\n\n"

    report += (
        f"---\n"
        f"*Generated deterministically by `/review-xyz` in throwaway worktree isolation on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}.*"
    )
    return report


def post_to_github_pr(pr_number, report_md, root):
    """Post review comment to GitHub PR via gh."""
    try:
        subprocess.run(
            ["gh", "pr", "comment", str(pr_number), "--body", report_md],
            cwd=root,
            check=True,
            capture_output=True,
            text=True,
        )
        print(f"review-xyz: successfully posted review to PR #{pr_number}")
        return True
    except Exception as e:
        log_err(f"failed to post comment to PR #{pr_number}: {e}")
        return False


def post_to_linked_issues(pr_meta, checklist, root):
    """Post follow-up checklist comments to issues referenced in PR body."""
    if not pr_meta or not checklist:
        return
    body = pr_meta.get("body", "") + " " + pr_meta.get("title", "")
    matches = set()
    for g1, g2 in _LINKED_ISSUE_RE.findall(body):
        issue_id = g1 or g2
        if issue_id:
            matches.add(issue_id)
    if not matches:
        return

    checklist_body = (
        f"### 🛡️ Code Review Follow-Up Checklist (from PR #{pr_meta.get('number')})\n\n"
        + "\n".join(checklist)
        + f"\n\n*Posted automatically via `/review-xyz`.*"
    )

    for issue_id in matches:
        if issue_id == str(pr_meta.get("number")):
            continue
        try:
            subprocess.run(
                ["gh", "issue", "comment", issue_id, "--body", checklist_body],
                cwd=root,
                check=True,
                capture_output=True,
                text=True,
            )
            print(f"review-xyz: posted checklist follow-up to linked Issue #{issue_id}")
        except Exception as e:
            log_err(f"failed to comment on Issue #{issue_id}: {e}")


def main():
    parser = argparse.ArgumentParser(
        description="review_xyz — deterministic multi-model code review engine"
    )
    parser.add_argument("--pr", help="Pull Request number or URL to review")
    parser.add_argument("--diff-file", help="Path to unified diff file")
    parser.add_argument("--branch", help="Git branch to review against base")
    parser.add_argument("--base", default="development", help="Base git ref (default: development)")
    parser.add_argument(
        "--model",
        default="Qwen/Qwen3.8-Max",
        help="Reviewer model ID or alias (default: Qwen/Qwen3.8-Max)",
    )
    parser.add_argument(
        "--engine",
        choices=["auto", "commandcode", "aider", "codex", "agy"],
        default="auto",
        help="Execution engine (default: auto)",
    )
    parser.add_argument(
        "--instructions", default="", help="Custom focus instructions for reviewer"
    )
    parser.add_argument(
        "--paths",
        nargs="*",
        help="Optional list of paths/globs to restrict the review diff",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=int(os.environ.get("REVIEW_TIMEOUT", 900)),
        help="Review timeout in seconds (default: 900)",
    )
    parser.add_argument(
        "--post-pr",
        action="store_true",
        help="Post the review comment to the target GitHub PR",
    )
    parser.add_argument(
        "--post-issues",
        action="store_true",
        help="Post checklist follow-ups to linked GitHub issues in PR body",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Extract diff and generate prompt without dispatching model or posting to GitHub",
    )
    parser.add_argument(
        "--strict-citations",
        action="store_true",
        help="Downgrade Approved verdict to Changes requested if claims lack verified citations",
    )
    parser.add_argument(
        "--mock-response",
        help="Supply mock model response text or file path for testing",
    )
    parser.add_argument("--out", help="Write report to output file")

    args = parser.parse_args()

    xyz_root = os.environ.get(
        "XYZ_ROOT",
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    )
    root = resolve_turn_root(os.environ.get("REVIEW_ROOT"), xyz_root)

    # 1. Extract Diff
    diff_text, pr_meta = extract_diff(args, root)
    diff_lines = len(diff_text.splitlines())

    if not diff_text.strip():
        print("review-xyz: empty diff — nothing to review.")
        sys.exit(0)

    # 2. Resolve Model & Engine
    model_slug = resolve_model_slug(args.model, xyz_root)
    engine = infer_engine(model_slug, args.engine)

    # 3. Construct Review Prompt
    prompt = build_review_prompt(diff_text, pr_meta, args.instructions)

    if args.dry_run:
        print(f"=== DRY-RUN REVIEW CONFIG ===")
        print(f"Engine: {engine}")
        print(f"Model: {model_slug} (raw: {args.model})")
        print(f"Diff Size: {diff_lines} lines")
        if pr_meta:
            print(f"Target PR: #{pr_meta.get('number')} ({pr_meta.get('title')})")
        print(f"\n=== GENERATED PROMPT PREVIEW (First 20 lines) ===")
        print("\n".join(prompt.splitlines()[:20]))
        sys.exit(0)

    # 4. Throwaway Worktree Isolation Setup
    wt_dir = tempfile.mkdtemp(prefix=f"review-wt-{os.getpid()}-")
    base_res = subprocess.run(
        ["git", "-C", root, "stash", "create"], capture_output=True, text=True
    )
    base_ref = base_res.stdout.strip() or "HEAD"

    wt_created = False
    try:
        res = subprocess.run(
            ["git", "-C", root, "worktree", "add", "--detach", wt_dir, base_ref],
            capture_output=True,
        )
        if res.returncode == 0:
            wt_created = True
            # Copy untracked files into worktree
            try:
                ls_res = subprocess.run(
                    ["git", "-C", root, "ls-files", "--others", "--exclude-standard", "-z"],
                    capture_output=True,
                )
                if ls_res.stdout:
                    for f_bytes in ls_res.stdout.split(b"\0"):
                        if not f_bytes:
                            continue
                        f_rel = f_bytes.decode("utf-8")
                        src = os.path.join(root, f_rel)
                        dst = os.path.join(wt_dir, f_rel)
                        os.makedirs(os.path.dirname(dst), exist_ok=True)
                        try:
                            shutil.copy2(src, dst)
                        except Exception:
                            pass
            except Exception:
                pass
        else:
            die(f"failed to establish throwaway worktree isolation: {res.stderr.decode()}", code=2)
    except Exception as e:
        die(f"worktree setup failed: {e}", code=2)

    # 5. Dispatch Model or Mock Response
    env = dict(os.environ)
    raw_response = ""
    duration = 0.0

    try:
        if args.mock_response:
            if os.path.isfile(args.mock_response):
                with open(args.mock_response, "r", errors="replace") as f:
                    raw_response = f.read()
            else:
                raw_response = args.mock_response
            duration = 0.05
        else:
            raw_response, duration = execute_model_review(
                engine, model_slug, prompt, wt_dir, args.timeout, env
            )
    finally:
        # 6. Teardown Worktree
        if wt_created:
            try:
                if subprocess.run(
                    ["git", "-C", root, "worktree", "remove", "--force", wt_dir],
                    capture_output=True,
                ).returncode == 0:
                    xyz_write_ops_log_append("git worktree remove", f"git -C {root} worktree remove --force {wt_dir}")
            except Exception:
                pass
        if os.path.exists(wt_dir):
            shutil.rmtree(wt_dir, ignore_errors=True)
            xyz_write_ops_log_append("rm force", f"rm -rf {wt_dir}")

    if not raw_response or not raw_response.strip():
        die("model execution failed to return a review transcript", code=2)

    # 7. Parse Findings & Format Report
    review_data = parse_review_output(raw_response, strict_citations=args.strict_citations)
    report_md = format_final_report(
        review_data, pr_meta, model_slug, engine, duration, diff_lines
    )

    if args.out:
        os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
        with open(args.out, "w") as f:
            f.write(report_md)
        print(f"review-xyz: wrote review report to {args.out}")
    else:
        print(report_md)

    # 8. GitHub PR and Issue Commenting
    if (args.post_pr or args.post_issues) and not pr_meta:
        log_err(
            "review-xyz: warning: --post-pr / --post-issues specified without a valid --pr target — skipping GitHub comments"
        )

    if args.post_pr and pr_meta:
        post_to_github_pr(pr_meta.get("number"), report_md, root)

    if args.post_issues and pr_meta and review_data["checklist"]:
        post_to_linked_issues(pr_meta, review_data["checklist"], root)

    exit_code = 0 if review_data["verdict"] == "Approved" else 5
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
