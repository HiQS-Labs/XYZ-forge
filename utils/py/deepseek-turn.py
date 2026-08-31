#!/usr/bin/env python3
import os
import sys
import subprocess
import shlex
import shutil
import tempfile
import signal
from rtl import RelayTurnLib, claim_task_or_exit, rtl_default_log, resolve_turn_root
from turn_diagnostics import TurnDiagnostics
from model_alias import resolve_model_slug


def die(msg):
    print(f"deepseek-turn: {msg}", file=sys.stderr)
    sys.exit(2)


def default_deepseek_bin():
    if "DEEPSEEK_BIN" in os.environ:
        return os.environ["DEEPSEEK_BIN"]
    default_path = "/Users/noelsaw/Documents/GH Repos/deepseek-harness/apps/cli/lib/bin.js"
    if os.path.exists(default_path):
        return default_path
    which_dsh = shutil.which("dsh")
    if which_dsh:
        return which_dsh
    return default_path


def default_deepseek_flags():
    return shlex.split(os.environ.get("DEEPSEEK_FLAGS", ""))


def generate_patch_overlay(provider, model_id, api_key_env):
    """Generate a temporary cordis patch overlay configuring the LLM route."""
    if provider == "openrouter":
        base_url = "https://openrouter.ai/api/v1"
        key_env = api_key_env or "OPENROUTER_API_KEY"
    else:
        base_url = "https://api.deepseek.com"
        key_env = api_key_env or "DEEPSEEK_API_KEY"

    content = f"""- id: llm-deepseek
  name: '@deepseek-ai/dsh-llm-deepseek'
  config:
    apiKeyEnv: {key_env}
    baseURL: {base_url}
    thinking: enabled
    reasoningEffort: high
    models:
      - id: {model_id}
        name: {model_id}
"""
    fd, path = tempfile.mkstemp(prefix="dsh-patch-", suffix=".cordis.yml")
    with os.fdopen(fd, "w") as f:
        f.write(content)
    return path


def _kill_turn_group(proc):
    """Kill the child process's entire process group."""
    try:
        pgid = os.getpgid(proc.pid)
    except (ProcessLookupError, PermissionError, OSError):
        return

    for sig, wait_s in ((signal.SIGTERM, 5), (signal.SIGKILL, 2)):
        try:
            os.killpg(pgid, sig)
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


def main():
    if "-h" in sys.argv[1:] or "--help" in sys.argv[1:]:
        print("Usage: deepseek-turn.py")
        print("Required environment variables: RELAY_AGENT, RELAY_FILE, RELAY_TASK")
        sys.exit(0)

    xyz_root = os.environ.get(
        "XYZ_ROOT",
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    )
    root = resolve_turn_root(os.environ.get("DEEPSEEK_TURN_ROOT"), xyz_root)
    deepseek_bin = default_deepseek_bin()

    me = os.environ.get("RELAY_AGENT", "")
    f = os.environ.get("RELAY_FILE", "")
    t = os.environ.get("RELAY_TASK", "RELAY-TURN")
    deepseek_agent = os.environ.get("DEEPSEEK_AGENT", "")

    if not me:
        die("RELAY_AGENT required")
    if not f:
        die("RELAY_FILE required")
    if not deepseek_agent:
        die("DEEPSEEK_AGENT required")

    if me != deepseek_agent:
        print(
            f"deepseek-turn: actor {me} is not the DeepSeek agent ({deepseek_agent}) — deferring (window-driven)",
            file=sys.stderr,
        )
        sys.exit(0)

    allow_paths = os.environ.get("ALLOW_PATHS", "")
    peer = os.environ.get("RELAY_PEER", "")

    deepseek_log = os.environ.get("DEEPSEEK_LOG") or rtl_default_log(
        root, "deepseek-turn", t
    )
    os.environ["RTL_LOG"] = deepseek_log

    rtl = RelayTurnLib(root, xyz_root, f, allow_paths)

    prompt = rtl.turn_prompt(me, t, peer)
    tick_repo_root = os.environ.get("TICK_REPO_ROOT", root)
    drift_brief = rtl.drift_brief(me, tick_repo_root)
    if drift_brief:
        prompt = drift_brief + "\n" + prompt

    tick_repo_root, _tick_bin = claim_task_or_exit(
        root, xyz_root, f, allow_paths, t, me, "deepseek-turn"
    )

    dflags = default_deepseek_flags()
    # GH-346 Phase 1: let the operator write DEEPSEEK_MODEL="deepseek v4 pro" and have the alias
    # table canonicalise it. This is an ENHANCEMENT layered over the literal, not a swap:
    # resolve-model-alias.sh exits 1 with no output on a miss and has no canonical-slug
    # passthrough, so a bare resolver call would blank out every already-canonical id. The literal
    # below stays as the floor and resolve_model_slug() returns its input unchanged on any miss.
    deepseek_model = resolve_model_slug(
        os.environ.get("DEEPSEEK_MODEL", "deepseek/deepseek-v4-pro"), xyz_root
    )
    deepseek_provider = os.environ.get("DEEPSEEK_PROVIDER", "openrouter")
    api_key_env = "OPENROUTER_API_KEY" if deepseek_provider == "openrouter" else "DEEPSEEK_API_KEY"

    patch_file = generate_patch_overlay(deepseek_provider, deepseek_model, api_key_env)

    rtl.before()

    turn_timeout = int(os.environ.get("RELAY_TURN_TIMEOUT_S", 900))

    bounded_rc = 0
    wt = ""
    run_cwd = root
    deepseek_env = dict(os.environ)
    deepseek_env["TICK_REPO_ROOT"] = tick_repo_root
    deepseek_env["DSH_PERMISSION_MODE"] = os.environ.get(
        "DSH_PERMISSION_MODE", "danger-full-access"
    )

    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
        wt = rtl.worktree_begin()
        if wt:
            run_cwd = wt
            print(f"deepseek-turn: worktree isolation ON ({wt})", file=sys.stderr)
        else:
            print(
                "deepseek-turn: worktree isolation requested but `git worktree add` failed — failing turn",
                file=sys.stderr,
            )
            bounded_rc = 5

    # Build runner command
    if deepseek_bin.endswith(".js"):
        cmd = ["node", deepseek_bin, "--profile", "headless", "--patch", patch_file] + dflags + [prompt]
    else:
        cmd = [deepseek_bin, "--profile", "headless", "--patch", patch_file] + dflags + [prompt]

    diag = TurnDiagnostics(worktree=run_cwd)
    if bounded_rc == 0:
        diag.start()
        try:
            with open(deepseek_log, "a") as log_f:
                proc = subprocess.Popen(
                    cmd,
                    env=deepseek_env,
                    cwd=run_cwd,
                    stdout=log_f,
                    stderr=subprocess.STDOUT,
                    stdin=subprocess.DEVNULL,
                    start_new_session=True,
                )
                try:
                    proc.wait(timeout=turn_timeout)
                    bounded_rc = proc.returncode
                except subprocess.TimeoutExpired:
                    _kill_turn_group(proc)
                    bounded_rc = 7
        except Exception as exc:
            print(f"deepseek-turn: deepseek launch failed: {exc}", file=sys.stderr)
            bounded_rc = 5
        finally:
            diag.stop()
            try:
                os.remove(patch_file)
            except OSError:
                pass

    if wt:
        off_lane = rtl.worktree_end(wt)
        if off_lane:
            print(
                "deepseek-turn: deepseek made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)",
                file=sys.stderr,
            )
            bounded_rc = 6

    if bounded_rc == 7:
        _reason, _detail = diag.classify()
        print(
            f"deepseek-turn: deepseek exec exceeded {turn_timeout}s wall-clock cap — killed [{_reason}]",
            file=sys.stderr,
        )
        print(f"deepseek-turn: timeout attribution: {_detail}", file=sys.stderr)
    elif bounded_rc != 0:
        print(f"deepseek-turn: deepseek exec failed (exit {bounded_rc})", file=sys.stderr)

    if bounded_rc == 0 and (
        not os.path.exists(deepseek_log) or os.path.getsize(deepseek_log) == 0
    ):
        print(
            "deepseek-turn: deepseek exited 0 but produced NO output — failing the turn.",
            file=sys.stderr,
        )
        bounded_rc = 5

    rc = rtl.enforce(t, me, deepseek_log, "deepseek")

    try:
        from harness_turn_logger import HarnessTurnLogger
        with HarnessTurnLogger(
            harness_id="dsh",
            shim="deepseek-turn.py",
            task_scope=t,
            model_id=deepseek_model,
            gateway=deepseek_provider,
            reasoning_effort=os.environ.get("DEEPSEEK_REASONING_EFFORT", "high"),
            cli_flags=dflags,
            repo_root=xyz_root,
        ) as logger:
            logger.exit_code = bounded_rc or rc
    except Exception:
        pass

    if rc == 6 or bounded_rc == 6:
        sys.exit(6)
    if bounded_rc == 7:
        sys.exit(7)
    if bounded_rc != 0:
        sys.exit(5)

    sys.exit(rc)


if __name__ == "__main__":
    main()
