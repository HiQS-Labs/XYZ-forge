#!/usr/bin/env python3
import os
import sys
import tempfile
import subprocess
import shlex
from rtl import RelayTurnLib, claim_task_or_exit, rtl_default_log, resolve_turn_root

def die(msg):
    print(f"agy-turn: {msg}", file=sys.stderr)
    sys.exit(2)

def agy_auth_preflight(agy_bin):
    secs = int(os.environ.get("AGY_AUTH_TIMEOUT_S", 5))
    out_file = os.path.join(tempfile.gettempdir(), f"agy-auth-{os.getpid()}.log")
    rc = 0
    try:
        with open(out_file, "w") as out_f:
            subprocess.run([agy_bin, "whoami"], timeout=secs, stdout=out_f, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, check=True)
        if os.path.exists(out_file): os.remove(out_file)
        return True
    except subprocess.TimeoutExpired:
        print(f"agy-turn: agy auth pre-flight timed out after {secs}s; likely expired auth opening an interactive login. Run `agy login` in a normal terminal, then retry.", file=sys.stderr)
        rc = 7
    except subprocess.CalledProcessError as e:
        print(f"agy-turn: agy auth pre-flight failed (exit {e.returncode}). Run `agy login` in a normal terminal, then retry.", file=sys.stderr)
        rc = e.returncode
    except Exception as e:
        print(f"agy-turn: agy auth pre-flight failed. Run `agy login` in a normal terminal, then retry.", file=sys.stderr)
        rc = 5

    try:
        if os.path.exists(out_file):
            with open(out_file) as f:
                lines = f.readlines()
                for line in lines[:3]:
                    line = line.strip()
                    if line:
                        print(f"agy-turn: auth pre-flight: {line}", file=sys.stderr)
            os.remove(out_file)
    except Exception:
        pass
    return False

def agy_validate_model(agy_bin):
    model = os.environ.get("AGY_MODEL", "")
    if not model:
        return True

    secs = int(os.environ.get("AGY_AUTH_TIMEOUT_S", 5))
    out_file = os.path.join(tempfile.gettempdir(), f"agy-models-{os.getpid()}.log")
    try:
        with open(out_file, "w") as out_f:
            subprocess.run([agy_bin, "models"], timeout=secs, stdout=out_f, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, check=True)
    except subprocess.TimeoutExpired:
        print(f"agy-turn: agy models probe timed out after {secs}s while validating AGY_MODEL={model!r}. Refusing to fall back silently.", file=sys.stderr)
        try:
            if os.path.exists(out_file):
                with open(out_file) as f:
                    for line in f.readlines()[:3]:
                        line = line.strip()
                        if line:
                            print(f"agy-turn: models probe: {line}", file=sys.stderr)
        except Exception:
            pass
        if os.path.exists(out_file):
            os.remove(out_file)
        return False
    except subprocess.CalledProcessError as e:
        print(f"agy-turn: agy models probe failed (exit {e.returncode}) while validating AGY_MODEL={model!r}. Refusing to fall back silently.", file=sys.stderr)
        try:
            if os.path.exists(out_file):
                with open(out_file) as f:
                    for line in f.readlines()[:3]:
                        line = line.strip()
                        if line:
                            print(f"agy-turn: models probe: {line}", file=sys.stderr)
        except Exception:
            pass
        if os.path.exists(out_file):
            os.remove(out_file)
        return False
    except Exception:
        print(f"agy-turn: agy models probe failed while validating AGY_MODEL={model!r}. Refusing to fall back silently.", file=sys.stderr)
        if os.path.exists(out_file):
            os.remove(out_file)
        return False

    try:
        with open(out_file) as f:
            available = [line.rstrip("\r\n") for line in f if line.rstrip("\r\n")]
    except Exception:
        available = []
    finally:
        if os.path.exists(out_file):
            os.remove(out_file)

    if model in available:
        return True

    print(f"agy-turn: requested AGY_MODEL={model!r} is unavailable on this agy account. Run `agy models` to choose a listed model; refusing to fall back silently.", file=sys.stderr)
    return False

def main():
    xyz_root = os.environ.get("XYZ_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    # GH-296 follow-up: mirror codex-turn.py's fix — an explicit AGY_TURN_ROOT still wins (so the
    # CROSS-REPO warning below can still fire for a genuinely different target), but the unset
    # default now falls back to the CWD's git toplevel instead of xyz_root, so a same-repo vendored
    # .xyz/ install (xyz_root inside the repo, sharing its git toplevel) resolves correctly without
    # needing the warning as a workaround.
    root = resolve_turn_root(os.environ.get("AGY_TURN_ROOT"), xyz_root)
    agy_bin = os.environ.get("AGY_BIN", "agy")

    me = os.environ.get("RELAY_AGENT", "")
    f = os.environ.get("RELAY_FILE", "")
    t = os.environ.get("RELAY_TASK", "RELAY-TURN")
    agy_agent = os.environ.get("AGY_AGENT", "")

    if not me: die("RELAY_AGENT required")
    if not f: die("RELAY_FILE required")
    if not agy_agent: die("AGY_AGENT required")

    if me != agy_agent:
        print(f"agy-turn: actor {me} is not the agy agent ({agy_agent}) — deferring (window-driven)", file=sys.stderr)
        sys.exit(0)

    if not agy_auth_preflight(agy_bin):
        sys.exit(5)
    if not agy_validate_model(agy_bin):
        sys.exit(5)
        
    allow_paths = os.environ.get("ALLOW_PATHS", "")
    peer = os.environ.get("RELAY_PEER", "")
    tick_repo_root = os.environ.get("TICK_REPO_ROOT", root)
    
    rtl = RelayTurnLib(root, xyz_root, f, allow_paths)

    try:
        res = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True)
        cwd_git_root = res.stdout.strip()
        if cwd_git_root and os.path.abspath(root) != cwd_git_root:
            print(f"agy-turn: CROSS-REPO mode (AGY_TURN_ROOT={root} != CWD git root={cwd_git_root}) — agy resolves relative paths against CWD, not the target repo. List TARGET files by ABSOLUTE path in {f} or agy will silently find nothing. (CONSUMING.md)", file=sys.stderr)
    except Exception:
        pass

    prompt = rtl.turn_prompt(me, t, peer)
    drift_brief = rtl.drift_brief(me, tick_repo_root)
    if drift_brief:
        prompt = drift_brief + "\n" + prompt
    tick_repo_root, _tick_bin = claim_task_or_exit(root, xyz_root, f, allow_paths, t, me, "agy-turn")

    # GH-161 parity fix: codex-turn.py already uses rtl_default_log (persistent, gitignored
    # relay-system/logs/<day>/... — survives past the turn); this port was missed, the same gap
    # found and fixed in aider-turn.py/aider-turn.sh.
    agy_log = os.environ.get("AGY_LOG") or rtl_default_log(root, "agy-turn", t)
    
    turn_timeout = int(os.environ.get("RELAY_TURN_TIMEOUT_S", 300))
    agy_args = ["--dangerously-skip-permissions", "--print-timeout", f"{turn_timeout}s"]
    
    if os.environ.get("AGY_MODEL"):
        agy_args += ["--model", os.environ.get("AGY_MODEL")]
        
    aflags = os.environ.get("AGY_FLAGS", "").split()
    if aflags:
        agy_args += aflags

    rtl.before()
    
    wt = ""
    run_cwd = root
    run_env = dict(os.environ)
    
    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
        wt = rtl.worktree_begin()
        if wt:
            run_env["TICK_REPO_ROOT"] = tick_repo_root
            run_cwd = wt
            print(f"agy-turn: worktree isolation ON ({wt})", file=sys.stderr)
        else:
            print("agy-turn: worktree isolation requested but `git worktree add` failed — failing turn", file=sys.stderr)
            sys.exit(5)

    cmd = [agy_bin] + agy_args + ["-p", prompt]
    bounded_rc = 0
    
    try:
        with open(agy_log, "w") as log_f:
            subprocess.run(cmd, env=run_env, cwd=run_cwd, timeout=turn_timeout, stdout=log_f, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, check=True)
    except subprocess.TimeoutExpired:
        bounded_rc = 7
    except subprocess.CalledProcessError as e:
        bounded_rc = e.returncode
    except Exception as e:
        bounded_rc = 5
        
    if wt:
        off_lane = rtl.worktree_end(wt)
        if off_lane:
            print("agy-turn: agy made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)", file=sys.stderr)
            sys.exit(6)
        # GH-178 B1: Verify agy grounding stayed contained to $WT.
        if bounded_rc == 0 and os.path.exists(agy_log) and os.path.getsize(agy_log) > 0:
            # Filter out false-positive shapes before the ROOT substring scan:
            #   [trace] lines (instrumentation, legitimately contain RTL_ROOT)
            #   TICK_REPO_ROOT="..." (harness-mandated tick-command narration, GH-183)
            #   file:// URIs and markdown link targets ](...) (file citations, GH-187)
            breached = False
            with open(agy_log, "r", errors="replace") as log_f:
                for line in log_f:
                    if line.startswith("[trace] "):
                        continue
                    if "TICK_REPO_ROOT=" in line or "file://" in line or "](" in line:
                        continue
                    if root in line:
                        breached = True
                        break
            if breached:
                print(f"agy-turn: agy transcript cited the real repo root ({root}) instead of the isolated worktree. This is an isolation breach. Failing the turn.", file=sys.stderr)
                with open(agy_log, "a") as log_f:
                    log_f.write("\n[FAIL] agy isolation breach: transcript cited the real repo root instead of the worktree.\n")
                sys.exit(5)

    if bounded_rc == 7:
        print(f"agy-turn: agy -p exceeded {turn_timeout}s wall-clock cap — killed", file=sys.stderr)
    elif bounded_rc != 0:
        print(f"agy-turn: agy -p failed (exit {bounded_rc})", file=sys.stderr)
        sys.exit(5)

    if bounded_rc == 0 and (not os.path.exists(agy_log) or os.path.getsize(agy_log) == 0):
        print("agy-turn: agy -p exited 0 but produced NO output — likely a blocked backend (run sandbox-OFF). Failing the turn.", file=sys.stderr)
        sys.exit(5)
        
    rc = rtl.enforce(t, me, agy_log, "agy")
    
    if bounded_rc == 7:
        sys.exit(7)

    sys.exit(rc)

if __name__ == "__main__":
    main()
