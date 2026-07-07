#!/usr/bin/env python3
import os
import sys
import tempfile
import subprocess
import shlex
import time
from rtl import RelayTurnLib

def die(msg):
    print(f"aider-turn: {msg}", file=sys.stderr)
    sys.exit(2)

def main():
    xyz_root = os.environ.get("XYZ_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    root = os.environ.get("AIDER_TURN_ROOT", xyz_root)
    aider_bin = os.environ.get("AIDER_BIN", "aider")
    aider_model = os.environ.get("AIDER_MODEL", "openrouter/anthropic/claude-3.5-sonnet")

    me = os.environ.get("RELAY_AGENT", "")
    f = os.environ.get("RELAY_FILE", "")
    t = os.environ.get("RELAY_TASK", "RELAY-TURN")
    aider_agent = os.environ.get("AIDER_AGENT", "")

    if not me: die("RELAY_AGENT required")
    if not f: die("RELAY_FILE required")
    if not aider_agent: die("AIDER_AGENT required")

    if me != aider_agent:
        print(f"aider-turn: actor {me} is not the aider agent ({aider_agent}) — deferring (window-driven)", file=sys.stderr)
        sys.exit(0)

    if not os.environ.get("OPENROUTER_API_KEY"):
        print("aider-turn: OPENROUTER_API_KEY is not set — Aider cannot reach OpenRouter. Export it (your OpenRouter key) then retry.", file=sys.stderr)
        sys.exit(5)

    allow_paths = os.environ.get("ALLOW_PATHS", "")
    peer = os.environ.get("RELAY_PEER", "")
    
    rtl = RelayTurnLib(root, xyz_root, f, allow_paths)
    
    prompt = rtl.turn_prompt(me, t, peer)
    tick_repo_root = os.environ.get("TICK_REPO_ROOT", root)
    drift_brief = rtl.drift_brief(me, tick_repo_root)
    
    if drift_brief:
        prompt = drift_brief + "\n" + prompt
        
    prompt += "\n\nNOTE (Aider harness): do NOT run any tick commands — the harness has already claimed the token and will release/close it for you after your edit. Spend this turn ONLY editing the file(s) added to the chat: append your block to the relay file and set its STATUS, and edit the artifact(s) if this is a build turn."

    rel_relay = os.path.relpath(f, root)
    file_args = ["--file", rel_relay]
    claim_paths = [rel_relay]
    
    if allow_paths:
        aps = [ap.strip() for ap in allow_paths.split(',')]
        for ap in aps:
            if ap:
                file_args.extend(["--file", ap])
                claim_paths.append(ap)
                
    claim_paths_str = ",".join(claim_paths)
    
    read_args = []
    if not allow_paths:
        rtl_artifact = rtl.get_artifact()
        if rtl_artifact and os.path.isfile(rtl_artifact):
            read_args.extend(["--read", rtl_artifact])
            try:
                # get changed files from diff
                diff_cmd = ["sed", "-nE", "s#^diff --git a/(.+) b/.+$#\\1#p; s#^\\+\\+\\+ b/(.+)$#\\1#p", rtl_artifact]
                diff_res = subprocess.run(diff_cmd, capture_output=True, text=True)
                changed_files = set(diff_res.stdout.splitlines())
                for cp in changed_files:
                    if cp and os.path.isfile(os.path.join(root, cp)) and cp != rel_relay:
                        read_args.extend(["--read", cp])
            except Exception:
                pass

    tick_bin = os.environ.get("TICK_BIN") or os.path.join(tick_repo_root, "bin", "tick")
    if not (os.path.isfile(tick_bin) and os.access(tick_bin, os.X_OK)):
        tick_bin = os.path.join(xyz_root, "bin", "tick")
    if os.path.isfile(tick_bin) and os.access(tick_bin, os.X_OK):
        tick_env = dict(os.environ)
        tick_env["TICK_REPO_ROOT"] = tick_repo_root
        subprocess.run([tick_bin, "claim", t, "--agent", me, "--paths", claim_paths_str], env=tick_env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        info_res = subprocess.run([tick_bin, "info", t], env=tick_env, capture_output=True, text=True)
        claimer = "none"
        for line in info_res.stdout.splitlines():
            if line.startswith("claimer:"):
                claimer = line.split(":", 1)[1].strip()
                break
                
        if claimer != me:
            print(f"aider-turn: could not establish token ownership of {t} (claimer={claimer}, expected {me}) — refusing to run so the turn cannot commit with the token open under the old owner; inspect `tick info {t}`", file=sys.stderr)
            sys.exit(5)
            
        subprocess.run([tick_bin, "ping", t, "--agent", me], env=tick_env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    aider_log = os.environ.get("AIDER_LOG", os.path.join(tempfile.gettempdir(), f"aider-turn-{os.getpid()}.log"))
    aider_aux_dir = os.environ.get("AIDER_AUX_DIR", os.path.join(tempfile.gettempdir(), f"aider-aux-{os.getpid()}"))
    os.makedirs(aider_aux_dir, exist_ok=True)
    
    turn_timeout = int(os.environ.get("RELAY_TURN_TIMEOUT_S", 300))
    
    aider_args = [
        "--model", aider_model, "--yes-always", "--no-auto-commits", "--no-gitignore",
        "--no-check-update", "--no-analytics", "--no-show-model-warnings", "--no-stream", "--map-tokens", "0",
        "--chat-history-file", os.path.join(aider_aux_dir, "chat.history.md"),
        "--input-history-file", os.path.join(aider_aux_dir, "input.history"),
        "--llm-history-file", os.path.join(aider_aux_dir, "llm.history")
    ] + file_args + read_args
    
    xflags = os.environ.get("AIDER_FLAGS", "")
    if xflags:
        aider_args.extend(shlex.split(xflags))
        
    rtl.before()
    
    wt = ""
    run_cwd = root
    
    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
        wt = rtl.worktree_begin()
        if wt:
            run_cwd = wt
            print(f"aider-turn: worktree isolation ON ({wt})", file=sys.stderr)
            os.environ["TICK_REPO_ROOT"] = tick_repo_root
        else:
            print("aider-turn: worktree isolation requested but `git worktree add` failed — failing turn", file=sys.stderr)
            sys.exit(5)

    cmd = [aider_bin] + aider_args + ["--message", prompt]
    
    bounded_rc = 0
    try:
        with open(aider_log, "w") as log_f:
            subprocess.run(cmd, cwd=run_cwd, timeout=turn_timeout, stdout=log_f, stderr=subprocess.STDOUT, check=True)
    except subprocess.TimeoutExpired:
        bounded_rc = 7
    except subprocess.CalledProcessError as e:
        bounded_rc = e.returncode
    except Exception as e:
        bounded_rc = 5

    if wt:
        off_lane = rtl.worktree_end(wt)
        if off_lane:
            print("aider-turn: aider made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)", file=sys.stderr)
            sys.exit(6)

    if bounded_rc == 7:
        print(f"aider-turn: aider exceeded {turn_timeout}s wall-clock cap — killed", file=sys.stderr)
    elif bounded_rc != 0:
        print(f"aider-turn: aider failed (exit {bounded_rc}) — see {aider_log}", file=sys.stderr)
        sys.exit(5)
        
    if bounded_rc == 0 and os.path.getsize(aider_log) == 0:
        print("aider-turn: aider exited 0 but produced NO output — likely a blocked/misconfigured backend. Failing the turn.", file=sys.stderr)
        sys.exit(5)
        
    rc = rtl.enforce(t, me, aider_log, "aider")
    
    if bounded_rc == 7:
        sys.exit(7)

    sys.exit(rc)

if __name__ == "__main__":
    main()
