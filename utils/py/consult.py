#!/usr/bin/env python3
import os
import re
import sys
import tempfile
import subprocess
import shlex
import time
from datetime import datetime
import shutil
from rtl import RelayTurnLib, resolve_tick_bin, resolve_tick_repo_root

# Aider can exit 0 while printing an auth/config error transcript, or return only reasoning tokens with
# empty visible content (GH-147 spike 0.1/0.4). Either is a failed advisor, not a real answer — trusting
# the exit code alone false-greens the consult.
_AIDER_FAIL_RE = re.compile(
    r"litellm\.[A-Za-z]*Error|AuthenticationError|Incorrect API key|invalid_api_key"
    r"|Unable to list models|No API key was provided|NotFoundError|Traceback \(most recent call last\)"
)

def die(msg):
    print(f"consult: {msg}", file=sys.stderr)
    sys.exit(2)

def warn(msg):
    print(f"consult: {msg}", file=sys.stderr)

def aider_answer_ok(out_path):
    """False if the Aider transcript shows an auth/config failure or has no visible answer."""
    try:
        with open(out_path, "r", errors="replace") as f:
            text = f.read()
    except OSError:
        return False
    if not text.strip():
        with open(out_path, "a") as f:
            f.write("\nconsult: Aider returned no visible content (empty answer — likely reasoning-only or a silent failure).\n")
        return False
    if _AIDER_FAIL_RE.search(text):
        with open(out_path, "a") as f:
            f.write("\nconsult: Aider transcript shows an auth/config failure — counted as FAILED (was exit 0).\n")
        return False
    return True

def guarded_with_timeout(cmd, cwd, log_file, timeout_s, env=None):
    try:
        with open(log_file, "w") as f:
            proc = subprocess.Popen(cmd, cwd=cwd, env=env, stdout=f, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL)
            return proc
    except Exception as e:
        with open(log_file, "a") as f:
            f.write(f"\nconsult: failed to launch process: {e}\n")
        return None

def agy_auth_preflight(agy_bin, log_file):
    secs = int(os.environ.get("AGY_AUTH_TIMEOUT_S", 5))
    tmp = f"{log_file}.auth"
    try:
        with open(tmp, "w") as f:
            subprocess.run([agy_bin, "whoami"], stdout=f, stderr=subprocess.STDOUT, timeout=secs, check=True)
        if os.path.exists(tmp): os.remove(tmp)
        return True
    except subprocess.TimeoutExpired:
        with open(log_file, "a") as f:
            if os.path.exists(tmp):
                with open(tmp) as tf: f.write(tf.read())
            f.write(f"\nconsult: agy auth pre-flight timed out after {secs}s; likely expired auth opening an interactive login. Run `agy login` in a normal terminal, then retry.\n")
    except subprocess.CalledProcessError as e:
        with open(log_file, "a") as f:
            if os.path.exists(tmp):
                with open(tmp) as tf: f.write(tf.read())
            f.write(f"\nconsult: agy auth pre-flight failed (exit {e.returncode}). Run `agy login` in a normal terminal, then retry.\n")
    except Exception as e:
        pass

    if os.path.exists(tmp): os.remove(tmp)
    return False

def main():
    xyz_root = os.environ.get("XYZ_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    root = os.environ.get("CONSULT_ROOT", xyz_root)
    consult_tick_root = resolve_tick_repo_root(root)
    consult_tick_bin = resolve_tick_bin(consult_tick_root, xyz_root)
    
    rtl = RelayTurnLib(root, xyz_root, "", "")  # Dummy init for transcript root
    
    codex_bin = os.environ.get("CODEX_BIN", "codex")
    agy_bin = os.environ.get("AGY_BIN", os.environ.get("GEMINI_BIN", "agy"))
    gemini_bin = os.environ.get("GEMINI_BIN", agy_bin)
    aider_bin = os.environ.get("AIDER_BIN", "aider")
    
    prompt_file = ""
    prompt_text = ""
    out_dir = ""
    models_str = "codex,agy"
    label = "consult"
    
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--prompt-file" and i + 1 < len(args):
            prompt_file = args[i+1]
            i += 2
        elif arg == "--prompt" and i + 1 < len(args):
            prompt_text = args[i+1]
            i += 2
        elif arg == "--out" and i + 1 < len(args):
            out_dir = args[i+1]
            i += 2
        elif arg == "--models" and i + 1 < len(args):
            models_str = args[i+1]
            i += 2
        elif arg == "--label" and i + 1 < len(args):
            label = args[i+1]
            i += 2
        elif arg == "--help":
            print("Usage: consult.sh --prompt \"question\" [--out DIR] [--models codex,agy] [--label SLUG]")
            sys.exit(0)
        else:
            die(f"unknown argument: {arg}")
            
    if not prompt_file and not prompt_text:
        die("one of --prompt-file or --prompt is required")
    if prompt_file and prompt_text:
        die("--prompt-file and --prompt are mutually exclusive")
        
    if prompt_file:
        if not os.path.isfile(prompt_file):
            die(f"prompt file not found: {prompt_file}")
        with open(prompt_file) as f:
            prompt_text = f.read()
            
    try:
        subprocess.run(["git", "-C", root, "rev-parse", "--is-inside-work-tree"], check=True, capture_output=True)
    except subprocess.CalledProcessError:
        warn(f"consult requires a git repo (advisor isolation uses a throwaway worktree): {root}")
        sys.exit(3)
        
    if not out_dir:
        res = rtl._run_rtl(f"rtl_transcript_root {shlex.quote(root)}")
        if res.returncode != 0:
            sys.exit(1)
        ts_base = res.stdout.strip()
        out_dir = os.path.join(ts_base, datetime.now().strftime("%Y-%m-%d"))
        
    run_dir = os.path.join(out_dir, f"{label}-{datetime.now().strftime('%H%M%S')}")
    os.makedirs(run_dir, exist_ok=True)
    
    preamble = "You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy)."
    full_prompt = f"{preamble}\n\n=== CONSULT QUESTION ===\n{prompt_text}"
    
    base_res = subprocess.run(["git", "-C", root, "stash", "create"], capture_output=True, text=True)
    base = base_res.stdout.strip()
    if not base:
        base = "HEAD"
        
    wt = tempfile.mkdtemp(prefix=f"consult-wt-{os.getpid()}-")
    
    res = subprocess.run(["git", "-C", root, "worktree", "add", "--detach", wt, base], capture_output=True)
    if res.returncode != 0:
        die(f"could not create isolation worktree (base {base})")
        
    try:
        try:
            ls_res = subprocess.run(["git", "-C", root, "ls-files", "--others", "--exclude-standard", "-z"], capture_output=True)
            if ls_res.stdout:
                for f in ls_res.stdout.split(b'\0'):
                    if not f: continue
                    f = f.decode('utf-8')
                    src = os.path.join(root, f)
                    dst = os.path.join(wt, f)
                    os.makedirs(os.path.dirname(dst), exist_ok=True)
                    try:
                        shutil.copy2(src, dst)
                    except:
                        pass
        except Exception:
            pass
            
        timeout_s = int(os.environ.get("CONSULT_TIMEOUT", 300))
        models = [m.strip() for m in models_str.split(",") if m.strip()]
        
        procs = []
        
        for m in models:
            if m == "codex":
                f_out = os.path.join(run_dir, f"{label}.codex.md")
                cflags = os.environ.get("CODEX_FLAGS", "-s read-only").split()
                cenv = dict(os.environ)
                if os.environ.get("CODEX_ALLOW_API_KEY", "0") != "1":
                    cenv.pop("OPENAI_API_KEY", None)
                cmd = [codex_bin, "exec"] + cflags + [full_prompt]
                proc = guarded_with_timeout(cmd, wt, f_out, timeout_s, cenv)
                procs.append((proc, "codex", f_out, time.time(), cmd))
            elif m == "agy":
                f_out = os.path.join(run_dir, f"{label}.agy.md")
                if not agy_auth_preflight(agy_bin, f_out):
                    procs.append((None, "agy", f_out, time.time(), None))
                    continue
                cmd = [agy_bin, "--dangerously-skip-permissions", "--print-timeout", f"{timeout_s}s", "-p", full_prompt]
                proc = guarded_with_timeout(cmd, wt, f_out, timeout_s, dict(os.environ))
                procs.append((proc, "agy", f_out, time.time(), cmd))
            elif m == "gemini":
                ext = "json" if os.environ.get("CONSULT_GEMINI_JSON", "0") == "1" else "md"
                f_out = os.path.join(run_dir, f"{label}.gemini.{ext}")
                cenv = dict(os.environ)
                cenv["GOOGLE_GENAI_USE_GCA"] = cenv.get("GOOGLE_GENAI_USE_GCA", "true")
                cmd = [gemini_bin, "--yolo", "--skip-trust"]
                if ext == "json": cmd += ["-o", "json"]
                cmd += ["-p", full_prompt]
                proc = guarded_with_timeout(cmd, wt, f_out, timeout_s, cenv)
                procs.append((proc, "gemini", f_out, time.time(), cmd))
            elif m == "aider":
                f_out = os.path.join(run_dir, f"{label}.aider.md")
                aider_base = os.environ.get("AIDER_OPENAI_API_BASE", "")
                auth_args = []
                if aider_base:
                    # LM Studio / OpenAI-compatible seam (GH-147): the client still needs a non-empty key
                    # even when the local server ignores it, so a dummy is fine for a keyless endpoint.
                    aider_model = os.environ.get("AIDER_MODEL", "openai/agents-a1")
                    auth_args = ["--openai-api-base", aider_base, "--openai-api-key", os.environ.get("AIDER_OPENAI_API_KEY", "dummy")]
                else:
                    if not os.environ.get("OPENROUTER_API_KEY"):
                        with open(f_out, "w") as f:
                            f.write("consult: OPENROUTER_API_KEY not set — Aider cannot reach OpenRouter (or set AIDER_OPENAI_API_BASE for an OpenAI-compatible/LM Studio endpoint). Export it, then retry.\n")
                        procs.append((None, "aider", f_out, time.time(), None))
                        continue
                    aider_model = os.environ.get("AIDER_MODEL", "openrouter/anthropic/claude-3.5-sonnet")
                cmd = [aider_bin, "--model", aider_model] + auth_args + ["--message", full_prompt, "--yes-always", "--no-auto-commits", "--no-gitignore", "--no-check-update", "--no-analytics", "--no-show-model-warnings", "--no-stream", "--map-tokens", "0"]
                proc = guarded_with_timeout(cmd, wt, f_out, timeout_s, dict(os.environ))
                procs.append((proc, "aider", f_out, time.time(), cmd))
            else:
                warn(f"unknown model '{m}' — skipping")
                
        if not procs:
            die(f"no valid models to consult (got: {models_str})")
            
        answered = 0
        failed = 0
        summary = ""
        
        for proc, m, out, start_time, cmd in procs:
            if proc is None:
                failed += 1
                summary += f"\n  [FAIL] {m} -> {out} (see transcript for error)"
                continue
                
            try:
                rem = max(0, timeout_s - (time.time() - start_time))
                proc.wait(timeout=rem)
                if proc.returncode == 0 and (m != "aider" or aider_answer_ok(out)):
                    answered += 1
                    summary += f"\n  [ok]   {m} -> {out}"
                elif proc.returncode == 0:
                    # exit 0 but the aider transcript proved an auth/config failure or empty answer
                    failed += 1
                    summary += f"\n  [FAIL] {m} -> {out} (see transcript for error)"
                else:
                    failed += 1
                    summary += f"\n  [FAIL] {m} -> {out} (see transcript for error)"
                    with open(out, "a") as f:
                        f.write(f"\nconsult: advisor failed with exit {proc.returncode}\n")
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
                failed += 1
                summary += f"\n  [FAIL] {m} -> {out} (see transcript for error)"
                with open(out, "a") as f:
                    f.write(f"\nconsult: advisor failed or exceeded the {timeout_s}s cap\n")
                    
        if os.environ.get("CONSULT_GEMINI_JSON", "0") == "1":
            gj = os.path.join(run_dir, f"{label}.gemini.json")
            if os.path.exists(gj) and os.path.getsize(gj) > 0:
                if consult_tick_bin:
                    tick_env = dict(os.environ)
                    tick_env["TICK_REPO_ROOT"] = consult_tick_root
                    try:
                        subprocess.run(
                            [
                                consult_tick_bin,
                                "cost",
                                f"CONSULT-{label}",
                                "--agent",
                                "gemini",
                                "--from-gemini-json",
                                gj,
                                "--tool",
                                "gemini",
                            ],
                            env=tick_env,
                            stderr=subprocess.DEVNULL,
                            stdout=subprocess.DEVNULL,
                        )
                    except Exception:
                        warn("gemini tokens not captured (no parseable stats)")
                
    finally:
        subprocess.run(["git", "-C", root, "worktree", "remove", "--force", wt], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
        subprocess.run(["git", "-C", root, "worktree", "prune"], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
        if os.path.exists(wt):
            shutil.rmtree(wt, ignore_errors=True)
        
    print(f"consult: {answered} answered, {failed} failed -> {run_dir}{summary}")
    if answered == 0:
        warn("all advisors failed")
        sys.exit(5)
    sys.exit(0)

if __name__ == "__main__":
    main()
