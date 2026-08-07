#!/usr/bin/env python3
import os
import sys
import tempfile
import subprocess
import shlex
from rtl import RelayTurnLib, claim_task_or_exit, rtl_default_log, resolve_turn_root
from turn_diagnostics import TurnDiagnostics

def die(msg):
    print(f"codex-turn: {msg}", file=sys.stderr)
    sys.exit(2)

def default_codex_flags():
    # GH-106: mirror the Bash default so a headless Codex turn never hangs on an
    # interactive approval prompt while still staying inside workspace-write.
    return os.environ.get("CODEX_FLAGS", "-s workspace-write -c approval_policy=never").split()

def main():
    xyz_root = os.environ.get("XYZ_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    root = resolve_turn_root(os.environ.get("CODEX_TURN_ROOT"), xyz_root)
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
    
    # GH-161: default the transcript to a PERSISTENT path under relay-system/logs/<date>/ (mirrors
    # Bash codex-turn.sh) and export RTL_LOG BEFORE the first rtl call — so the Bash rtl_init/enforce
    # traces (fine-grained under RTL_TRACE=1, unconditional log_always) land in this transcript.
    codex_log = os.environ.get("CODEX_LOG") or rtl_default_log(root, "codex-turn", t)
    os.environ["RTL_LOG"] = codex_log

    rtl = RelayTurnLib(root, xyz_root, f, allow_paths)
    
    prompt = rtl.turn_prompt(me, t, peer)
    tick_repo_root = os.environ.get("TICK_REPO_ROOT", root)
    drift_brief = rtl.drift_brief(me, tick_repo_root)
    if drift_brief:
        prompt = drift_brief + "\n" + prompt

    # GH-165: mirror the Bash shim — establish ownership of the specific handed-off
    # token before launching Codex, so rtl.enforce's GH-67 post-commit handoff has
    # real authority to release/done instead of warning on a non-owner token.
    tick_repo_root, _tick_bin = claim_task_or_exit(root, xyz_root, f, allow_paths, t, me, "codex-turn")

    cflags = default_codex_flags()
    # GH-263/GH-296: unconditionally grant Codex's sandbox the shared .tick lock dir — both under
    # worktree isolation (workdir=throwaway worktree) and the isolation=0 default (workdir=ROOT,
    # which in a same-repo vendored .xyz/ install can still differ from tick_repo_root). Mirrors
    # codex-turn.sh's codex_extra_flags. Built off tick_repo_root (not root), so an explicit
    # TICK_REPO_ROOT override still lands in the sandbox allowlist.
    codex_extra_flags = ["--add-dir", f"{tick_repo_root}/.tick"]

    rtl.before()

        # GH-320: this default MUST match the Bash twin's `${RELAY_TURN_TIMEOUT_S:-N}` and the
    # ceiling its header documents. It read 300 while the twin said 900, and since Python is the
    # executing lane every turn was silently capped at a fraction of the documented budget —
    # observed live as an exit-7 kill on a review turn that had 900s on paper.
    turn_timeout = int(os.environ.get("RELAY_TURN_TIMEOUT_S", 900))

    wt = ""
    run_cwd = root

    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
        wt = rtl.worktree_begin()
        if wt:
            run_cwd = wt
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
    # Sample the turn while it runs so an exit-7 timeout can be attributed to a
    # cause. subprocess.run reaps the child before raising, so nothing can be
    # probed after the fact — see turn_diagnostics.
    diag = TurnDiagnostics(worktree=run_cwd)
    diag.start()
    try:
        # GH-161: append (not truncate) — rtl_init already wrote its decision-trace line into codex_log
        # via the exported RTL_LOG; a truncating open here would silently wipe it (mirrors codex-turn.sh:170).
        with open(codex_log, "a") as log_f:
            subprocess.run(cmd, env=codex_env, cwd=run_cwd, timeout=turn_timeout, stdout=log_f, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, check=True)
    except subprocess.TimeoutExpired:
        bounded_rc = 7
    except subprocess.CalledProcessError as e:
        bounded_rc = e.returncode
    except Exception as e:
        bounded_rc = 5
    finally:
        diag.stop()

    if wt:
        off_lane = rtl.worktree_end(wt)
        if off_lane:
            print("codex-turn: codex made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)", file=sys.stderr)
            sys.exit(6)

    if bounded_rc == 7:
        # Exit code stays 7 for callers; the reason names WHY.
        _reason, _detail = diag.classify()
        print(f"codex-turn: codex exec exceeded {turn_timeout}s wall-clock cap — killed [{_reason}]", file=sys.stderr)
        print(f"codex-turn: timeout attribution: {_detail}", file=sys.stderr)
    elif bounded_rc != 0:
        print(f"codex-turn: codex exec failed (exit {bounded_rc})", file=sys.stderr)
        sys.exit(5)
        
    rc = rtl.enforce(t, me, codex_log, "codex")
    
    if bounded_rc == 7:
        sys.exit(7)

    sys.exit(rc)

if __name__ == "__main__":
    main()
