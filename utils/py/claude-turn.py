#!/usr/bin/env python3
import os
import sys
import tempfile
import subprocess
import shlex
import json
import shutil
from rtl import RelayTurnLib, claim_task_or_exit, make_tick_env, resolve_tick_bin, resolve_turn_root

def die(msg):
    print(f"claude-turn: {msg}", file=sys.stderr)
    sys.exit(2)

def main():
    xyz_root = os.environ.get("XYZ_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    # GH-296 follow-up: mirror codex-turn.py's fix — fall back to the CWD's git toplevel (not
    # xyz_root) when CLAUDE_TURN_ROOT is unset, so a same-repo vendored .xyz/ install resolves
    # correctly instead of rooting worktree isolation + claim paths at the harness's own directory.
    root = resolve_turn_root(os.environ.get("CLAUDE_TURN_ROOT"), xyz_root)
    
    me = os.environ.get("RELAY_AGENT", "")
    f = os.environ.get("RELAY_FILE", "")
    t = os.environ.get("RELAY_TASK", "RELAY-TURN")
    claude_agent = os.environ.get("CLAUDE_AGENT", "")

    if not me: die("RELAY_AGENT required")
    if not f: die("RELAY_FILE required")
    if not claude_agent: die("CLAUDE_AGENT required")

    if me != claude_agent:
        print(f"claude-turn: actor {me} is not the Claude agent ({claude_agent}) — deferring (window-driven)", file=sys.stderr)
        sys.exit(0)

    resolved_claude = ""
    claude_bin_env = os.environ.get("CLAUDE_BIN", "")
    if claude_bin_env and shutil.which(claude_bin_env):
        resolved_claude = claude_bin_env
    else:
        if shutil.which("claude"):
            resolved_claude = "claude"
        elif os.access(os.path.expanduser("~/.claude/local/claude"), os.X_OK):
            resolved_claude = os.path.expanduser("~/.claude/local/claude")
            
    if not resolved_claude:
        print("claude CLI not found on PATH; set CLAUDE_BIN or use a codex/agy builder", file=sys.stderr)
        sys.exit(3)
        
    allow_paths = os.environ.get("ALLOW_PATHS", "")
    peer = os.environ.get("RELAY_PEER", "")
    tick_repo_root = os.environ.get("TICK_REPO_ROOT", root)
    
    rtl = RelayTurnLib(root, xyz_root, f, allow_paths)
    
    prompt = rtl.turn_prompt(me, t, peer)
    tick_repo_root, tick_bin = claim_task_or_exit(root, xyz_root, f, allow_paths, t, me, "claude-turn")
    
    claude_log = os.environ.get("CLAUDE_LOG", os.path.join(tempfile.gettempdir(), f"claude-turn-{os.getpid()}.json"))
    model = os.environ.get("CLAUDE_MODEL", "claude-sonnet-4-6")
    max_turns = os.environ.get("CLAUDE_MAX_TURNS", "12")
    max_budget = os.environ.get("CLAUDE_MAX_BUDGET", "0.50")
    
    block_cmds_str = os.environ.get("CLAUDE_BLOCK_CMDS", "codex gemini consult consult.sh marathon-drive.sh relay-drive.sh")
    block_cmds = block_cmds_str.split() if block_cmds_str else []
    
    shadow_dir = ""
    if block_cmds:
        shadow_dir = tempfile.mkdtemp(prefix="claude-turn-shadow.")
        for c in block_cmds:
            stub_path = os.path.join(shadow_dir, c)
            with open(stub_path, "w") as stub_f:
                stub_f.write("#!/usr/bin/env bash\n")
                stub_f.write(f'printf "blocked: %s is off-limits to a headless builder turn (CLAUDE_BLOCK_CMDS)\\n" {shlex.quote(c)} >&2\n')
                stub_f.write("exit 127\n")
            os.chmod(stub_path, 0o755)

    rtl.before()
    
    turn_timeout = int(os.environ.get("RELAY_TURN_TIMEOUT_S", 300))
    bounded_rc = 0
    
    wt = ""
    run_cwd = root
    
    run_env = dict(os.environ)
    if shadow_dir:
        run_env["PATH"] = shadow_dir + os.pathsep + run_env.get("PATH", "")
    
    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
        wt = rtl.worktree_begin()
        if wt:
            run_env["TICK_REPO_ROOT"] = tick_repo_root
            run_cwd = wt
            print(f"claude-turn: worktree isolation ON ({wt})", file=sys.stderr)
        else:
            print("claude-turn: worktree isolation requested but `git worktree add` failed — failing turn", file=sys.stderr)
            if shadow_dir: shutil.rmtree(shadow_dir, ignore_errors=True)
            sys.exit(5)

    cmd = [
        resolved_claude, "-p", prompt,
        "--model", model,
        "--allowedTools", "Bash,Read,Edit,Write",
        "--permission-mode", "acceptEdits",
        "--output-format", "json",
        "--max-turns", str(max_turns),
        "--max-budget-usd", str(max_budget)
    ]
    
    try:
        with open(claude_log, "w") as log_f:
            subprocess.run(cmd, env=run_env, cwd=run_cwd, timeout=turn_timeout, stdout=log_f, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, check=True)
    except subprocess.TimeoutExpired:
        bounded_rc = 7
    except subprocess.CalledProcessError as e:
        bounded_rc = e.returncode
    except Exception as e:
        bounded_rc = 5
        
    if shadow_dir:
        shutil.rmtree(shadow_dir, ignore_errors=True)
        
    if wt:
        off_lane = rtl.worktree_end(wt)
        if off_lane:
            print("claude-turn: builder made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)", file=sys.stderr)
            sys.exit(6)

    if bounded_rc == 7:
        print(f"claude-turn: claude -p exceeded {turn_timeout}s wall-clock cap — killed", file=sys.stderr)
    elif bounded_rc != 0:
        print(f"claude-turn: claude -p failed (exit {bounded_rc})", file=sys.stderr)
        sys.exit(5)
        
    rc = rtl.enforce(t, me, claude_log, "claude")
    if bounded_rc == 7:
        sys.exit(7)

    if os.path.exists(claude_log) and os.path.getsize(claude_log) > 0:
        try:
            with open(claude_log) as f:
                data = json.load(f)
            usage = data.get("usage", {})
            tokens_in = usage.get("input_tokens", 0) + usage.get("cache_read_input_tokens", 0)
            tokens_out = usage.get("output_tokens", 0)
            
            if tokens_in > 0 or tokens_out > 0:
                cost_tick_bin = tick_bin or resolve_tick_bin(tick_repo_root, xyz_root)
                if cost_tick_bin:
                    tick_res = subprocess.run(
                        [cost_tick_bin, "cost", t, "--agent", me, "--tokens-in", str(tokens_in), "--tokens-out", str(tokens_out), "--tool", "claude"],
                        env=make_tick_env(tick_repo_root),
                        capture_output=True,
                    )
                    if tick_res.returncode != 0:
                        print(f"claude-turn: tokens not captured for {t}", file=sys.stderr)
            else:
                print(f"claude-turn: tokens not captured for {t} (zero or no stats in transcript)", file=sys.stderr)
        except Exception:
            pass
            
    sys.exit(rc)

if __name__ == "__main__":
    main()
