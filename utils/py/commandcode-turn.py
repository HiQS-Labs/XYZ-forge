#!/usr/bin/env python3
import os
import sys
import subprocess
import shlex
from rtl import RelayTurnLib, claim_task_or_exit, rtl_default_log, resolve_turn_root
from turn_diagnostics import TurnDiagnostics

def die(msg):
    print(f"commandcode-turn: {msg}", file=sys.stderr)
    sys.exit(2)

def default_commandcode_flags():
    return shlex.split(os.environ.get(
        "COMMANDCODE_FLAGS",
        "--no-session --skip-onboarding --no-auto-update --yolo"))

def main():
    if "-h" in sys.argv[1:] or "--help" in sys.argv[1:]:
        print("Usage: commandcode-turn.py")
        print("Required environment variables: RELAY_AGENT, RELAY_FILE, RELAY_TASK")
        sys.exit(0)

    xyz_root = os.environ.get("XYZ_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    root = resolve_turn_root(os.environ.get("COMMANDCODE_TURN_ROOT"), xyz_root)
    commandcode_bin = os.environ.get("COMMANDCODE_BIN", "cmd")

    me = os.environ.get("RELAY_AGENT", "")
    f = os.environ.get("RELAY_FILE", "")
    t = os.environ.get("RELAY_TASK", "RELAY-TURN")
    commandcode_agent = os.environ.get("COMMANDCODE_AGENT", "")

    if not me: die("RELAY_AGENT required")
    if not f: die("RELAY_FILE required")
    if not commandcode_agent: die("COMMANDCODE_AGENT required")

    if me != commandcode_agent:
        print(f"commandcode-turn: actor {me} is not the Commandcode agent ({commandcode_agent}) — deferring (window-driven)", file=sys.stderr)
        sys.exit(0)

    allow_paths = os.environ.get("ALLOW_PATHS", "")
    peer = os.environ.get("RELAY_PEER", "")

    commandcode_log = os.environ.get("COMMANDCODE_LOG") or rtl_default_log(root, "commandcode-turn", t)
    os.environ["RTL_LOG"] = commandcode_log

    rtl = RelayTurnLib(root, xyz_root, f, allow_paths)

    prompt = rtl.turn_prompt(me, t, peer)
    tick_repo_root = os.environ.get("TICK_REPO_ROOT", root)
    drift_brief = rtl.drift_brief(me, tick_repo_root)
    if drift_brief:
        prompt = drift_brief + "\n" + prompt

    tick_repo_root, _tick_bin = claim_task_or_exit(root, xyz_root, f, allow_paths, t, me, "commandcode-turn")

    cflags = default_commandcode_flags()
    commandcode_model = os.environ.get("COMMANDCODE_MODEL", "meta/muse-spark-1.2-contributor")

    rtl.before()

    turn_timeout = int(os.environ.get("RELAY_TURN_TIMEOUT_S", 900))

    bounded_rc = 0
    wt = ""
    run_cwd = root
    commandcode_env = dict(os.environ)
    # Commandcode can run tick from a worktree or a cross-repo target.  Always
    # give its child the token root, not merely the current working directory.
    commandcode_env["TICK_REPO_ROOT"] = tick_repo_root

    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
        wt = rtl.worktree_begin()
        if wt:
            run_cwd = wt
            print(f"commandcode-turn: worktree isolation ON ({wt})", file=sys.stderr)
        else:
            print("commandcode-turn: worktree isolation requested but `git worktree add` failed — failing turn", file=sys.stderr)
            # The token was already claimed.  Fall through to rtl.enforce so
            # it is released and the failed-turn outcome is durable (GH-432).
            bounded_rc = 5

    cmd = [commandcode_bin] + cflags + ["--model", commandcode_model, "--print", prompt]

    diag = TurnDiagnostics(worktree=run_cwd)
    if bounded_rc == 0:
        diag.start()
        try:
            with open(commandcode_log, "a") as log_f:
                subprocess.run(cmd, env=commandcode_env, cwd=run_cwd, timeout=turn_timeout, stdout=log_f, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, check=True)
        except subprocess.TimeoutExpired:
            bounded_rc = 7
        except subprocess.CalledProcessError as exc:
            bounded_rc = exc.returncode
        except Exception as exc:
            print(f"commandcode-turn: commandcode launch failed: {exc}", file=sys.stderr)
            bounded_rc = 5
        finally:
            diag.stop()

    if wt:
        off_lane = rtl.worktree_end(wt)
        if off_lane:
            print("commandcode-turn: commandcode made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)", file=sys.stderr)
            # Enforce after containment so the already-claimed token is handed
            # off and the relay records the failed turn instead of orphaning it.
            bounded_rc = 6

    if bounded_rc == 7:
        _reason, _detail = diag.classify()
        print(f"commandcode-turn: commandcode exec exceeded {turn_timeout}s wall-clock cap — killed [{_reason}]", file=sys.stderr)
        print(f"commandcode-turn: timeout attribution: {_detail}", file=sys.stderr)
    elif bounded_rc != 0:
        print(f"commandcode-turn: commandcode exec failed (exit {bounded_rc})", file=sys.stderr)

    if bounded_rc == 0 and (not os.path.exists(commandcode_log) or os.path.getsize(commandcode_log) == 0):
        print("commandcode-turn: commandcode exited 0 but produced NO output — failing the turn.", file=sys.stderr)
        bounded_rc = 5

    rc = rtl.enforce(t, me, commandcode_log, "commandcode")

    # In-root enforcement violations take priority over a subprocess result.
    if rc == 6:
        sys.exit(6)
    if bounded_rc == 6:
        sys.exit(6)
    if bounded_rc == 7:
        sys.exit(7)
    if bounded_rc != 0:
        sys.exit(5)

    sys.exit(rc)

if __name__ == "__main__":
    main()
