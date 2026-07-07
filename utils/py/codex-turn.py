#!/usr/bin/env python3
import os
import sys
import tempfile
import subprocess
import shlex
from rtl import RelayTurnLib

def die(msg):
    print(f"codex-turn: {msg}", file=sys.stderr)
    sys.exit(2)

def default_codex_flags():
    # GH-106: mirror the Bash default so a headless Codex turn never hangs on an
    # interactive approval prompt while still staying inside workspace-write.
    return os.environ.get("CODEX_FLAGS", "-s workspace-write -c approval_policy=never").split()

def claim_paths_for_turn(root, relay_file, allow_paths):
    claim_paths = os.path.relpath(relay_file, root) if os.path.isabs(relay_file) else relay_file
    if claim_paths.startswith(f"..{os.sep}") or claim_paths == "..":
        claim_paths = relay_file

    if allow_paths:
        for path in (ap.strip() for ap in allow_paths.split(",")):
            if path:
                claim_paths += f",{path}"
    return claim_paths

def main():
    xyz_root = os.environ.get("XYZ_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    root = os.environ.get("CODEX_TURN_ROOT", xyz_root)
    codex_bin = os.environ.get("CODEX_BIN", "codex")

    me = os.environ.get("RELAY_AGENT", "")
    f = os.environ.get("RELAY_FILE", "")
    t = os.environ.get("RELAY_TASK", "RELAY-TURN")
    codex_agent = os.environ.get("CODEX_AGENT", "")

    if not me: die("RELAY_AGENT required")
    if not f: die("RELAY_FILE required")
    if not codex_agent: die("CODEX_AGENT required")

    if me != codex_agent:
        print(f"codex-turn: actor {me} is not the Codex agent ({codex_agent}) — deferring (window-driven)", file=sys.stderr)
        sys.exit(0)

    allow_paths = os.environ.get("ALLOW_PATHS", "")
    peer = os.environ.get("RELAY_PEER", "")
    
    rtl = RelayTurnLib(root, xyz_root, f, allow_paths)
    
    prompt = rtl.turn_prompt(me, t, peer)
    tick_repo_root = os.environ.get("TICK_REPO_ROOT", root)
    drift_brief = rtl.drift_brief(me, tick_repo_root)
    if drift_brief:
        prompt = drift_brief + "\n" + prompt

    # GH-165: mirror the Bash shim — establish ownership of the specific handed-off
    # token before launching Codex, so rtl.enforce's GH-67 post-commit handoff has
    # real authority to release/done instead of warning on a non-owner token.
    claim_paths = claim_paths_for_turn(root, f, allow_paths)
    tick_bin = os.path.join(tick_repo_root, "bin", "tick")
    if os.path.isfile(tick_bin) and os.access(tick_bin, os.X_OK):
        tick_env = dict(os.environ)
        tick_env["TICK_REPO_ROOT"] = tick_repo_root
        subprocess.run(
            [tick_bin, "claim", t, "--agent", me, "--paths", claim_paths],
            env=tick_env,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

        info_res = subprocess.run([tick_bin, "info", t], env=tick_env, capture_output=True, text=True)
        claimer = "none"
        for line in info_res.stdout.splitlines():
            if line.startswith("claimer:"):
                claimer = line.split(":", 1)[1].strip()
                break

        if claimer != me:
            print(
                f"codex-turn: could not establish token ownership of {t} (claimer={claimer}, expected {me}) — refusing to run so the turn cannot commit with the token open under the old owner; inspect `tick info {t}`",
                file=sys.stderr,
            )
            sys.exit(5)

        subprocess.run(
            [tick_bin, "ping", t, "--agent", me],
            env=tick_env,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    cflags = default_codex_flags()
    codex_extra_flags = []
    
    codex_log = os.environ.get("CODEX_LOG", os.path.join(tempfile.gettempdir(), f"codex-turn-{os.getpid()}.log"))
    
    rtl.before()
    
    turn_timeout = int(os.environ.get("RELAY_TURN_TIMEOUT_S", 300))
    
    wt = ""
    run_cwd = root
    
    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
        wt = rtl.worktree_begin()
        if wt:
            run_cwd = wt
            codex_extra_flags = ["--add-dir", f"{root}/.tick"]
            print(f"codex-turn: worktree isolation ON ({wt})", file=sys.stderr)
            os.environ["TICK_REPO_ROOT"] = tick_repo_root
        else:
            print("codex-turn: worktree isolation requested but `git worktree add` failed — failing turn", file=sys.stderr)
            sys.exit(5)

    codex_env = dict(os.environ)
    if os.environ.get("CODEX_ALLOW_API_KEY", "0") != "1":
        codex_env.pop("OPENAI_API_KEY", None)

    cmd = [codex_bin, "exec"] + cflags + codex_extra_flags + [prompt]
    
    bounded_rc = 0
    try:
        with open(codex_log, "w") as log_f:
            subprocess.run(cmd, env=codex_env, cwd=run_cwd, timeout=turn_timeout, stdout=log_f, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, check=True)
    except subprocess.TimeoutExpired:
        bounded_rc = 7
    except subprocess.CalledProcessError as e:
        bounded_rc = e.returncode
    except Exception as e:
        bounded_rc = 5

    if wt:
        off_lane = rtl.worktree_end(wt)
        if off_lane:
            print("codex-turn: codex made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)", file=sys.stderr)
            sys.exit(6)

    if bounded_rc == 7:
        print(f"codex-turn: codex exec exceeded {turn_timeout}s wall-clock cap — killed", file=sys.stderr)
    elif bounded_rc != 0:
        print(f"codex-turn: codex exec failed (exit {bounded_rc})", file=sys.stderr)
        sys.exit(5)
        
    rc = rtl.enforce(t, me, codex_log, "codex")
    
    if bounded_rc == 7:
        sys.exit(7)

    sys.exit(rc)

if __name__ == "__main__":
    main()
