#!/usr/bin/env python3
"""kimi-turn.py (GH-1215) — relay turn adapter for the Kimi Code CLI (`kimi`).

Modeled on muse-turn.py (GH-518): Python is the only implementation, the Bash file is a thin entry
point, and containment/enforcement stay in RelayTurnLib rather than being re-derived here.

Why a native shim at all: Kimi K3.1 already reached the relay through aider-turn.sh + OpenRouter
(HiQS-Labs/XYZ-CLIO#12), but Aider's whole-file edit format broke relay-block validation once
(exit 8) and that route spends OpenRouter credit rather than the operator's Kimi plan.

Three CLI facts shape this file, all measured against Kimi Code CLI 2.3.1 rather than taken from
documentation:

  - `kimi -p "<prompt>"` is the headless mode and already edits files and runs Bash without asking.
    `--yolo` and `--auto` are REFUSED alongside `-p` ("Cannot combine --prompt with --yolo"), so no
    approval flag is passed and KIMI_FLAGS must not carry one.
  - There is no prompt-file or stdin mode (`-p -` takes `-` as the prompt), so the turn prompt rides
    in argv, unlike muse's --prompt-file. A relay prompt is a few KB against macOS's 1 MB ARG_MAX; an
    E2BIG launch failure lands in the generic launch handler below as exit 5.
  - `--output-format stream-json` writes one JSON object per line. That is what lets the empty-output
    guard tell model output from the CLI's own version and resume-hint events.
"""
import json
import os
import shlex
import shutil
import subprocess
import sys

from rtl import (RelayTurnLib, claim_task_or_exit, rtl_default_log, resolve_turn_root,
                 rtl_run_bounded)
from turn_diagnostics import TurnDiagnostics, TERMINATION_WALL_CAP

DEFAULT_MODEL = "kimi-code/k3.1-pro"
# Where the Kimi Code installer puts the binary. Its PATH edit lands in ~/.zshrc, which a
# non-interactive shell (launchd, a driven turn) never reads, so a bare `kimi` may not resolve.
INSTALLER_BIN = os.path.join("~", ".kimi-code", "bin", "kimi")


def die(msg):
    print(f"kimi-turn: {msg}", file=sys.stderr)
    sys.exit(2)


def default_kimi_bin():
    """KIMI_BIN, else `kimi` on PATH, else the installer's location. find-harness.sh asks this."""
    explicit = os.environ.get("KIMI_BIN", "").strip()
    if explicit:
        return explicit
    return shutil.which("kimi") or os.path.expanduser(INSTALLER_BIN)


def has_model_output(log_path, offset=0):
    """True when the stream-json log, from byte `offset`, holds an assistant message or tool call.

    `offset` is the log's size before this invocation: KIMI_LOG is appended to and relay_drive.py
    reuses one log across a drive's turns, so an earlier turn's output must not satisfy this one.

    Meta events (`system.version`, `session.resume_hint`) and any non-JSON chatter do not count:
    the CLI emits those even when the model produced nothing, which is the GH-178 / GH-518 trap of
    a log that is non-empty only because the CLI introduced itself.
    """
    try:
        with open(log_path) as log_f:
            log_f.seek(offset)
            for line in log_f:
                try:
                    event = json.loads(line)
                except ValueError:
                    continue
                if not isinstance(event, dict) or event.get("role") != "assistant":
                    continue
                content = event.get("content")
                if (isinstance(content, str) and content.strip()) or event.get("tool_calls"):
                    return True
    except OSError:
        pass
    return False


def main():
    if "--print-bin" in sys.argv[1:]:
        print(default_kimi_bin())
        sys.exit(0)
    if "-h" in sys.argv[1:] or "--help" in sys.argv[1:]:
        print("Usage: kimi-turn.py [--print-bin]")
        print("Required environment variables: RELAY_AGENT, RELAY_FILE, KIMI_AGENT")
        print("Optional: RELAY_TASK, RELAY_PEER, ALLOW_PATHS, KIMI_BIN, KIMI_MODEL, KIMI_FLAGS,")
        print("          KIMI_LOG, KIMI_TURN_ROOT, RELAY_TURN_TIMEOUT_S")
        sys.exit(0)

    xyz_root = os.environ.get(
        "XYZ_ROOT",
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    root = resolve_turn_root(os.environ.get("KIMI_TURN_ROOT"), xyz_root)

    me = os.environ.get("RELAY_AGENT", "")
    f = os.environ.get("RELAY_FILE", "")
    t = os.environ.get("RELAY_TASK", "RELAY-TURN")
    kimi_agent = os.environ.get("KIMI_AGENT", "")

    if not me:
        die("RELAY_AGENT required")
    if not f:
        die("RELAY_FILE required")
    if not kimi_agent:
        die("KIMI_AGENT required")

    if me != kimi_agent:
        print(f"kimi-turn: actor {me} is not the Kimi agent ({kimi_agent}) — deferring (window-driven)",
              file=sys.stderr)
        sys.exit(0)

    kimi_bin = default_kimi_bin()
    kimi_model = os.environ.get("KIMI_MODEL", "").strip() or DEFAULT_MODEL
    kimi_flags = shlex.split(os.environ.get("KIMI_FLAGS", ""))

    allow_paths = os.environ.get("ALLOW_PATHS", "")
    peer = os.environ.get("RELAY_PEER", "")

    kimi_log = os.environ.get("KIMI_LOG") or rtl_default_log(root, "kimi-turn", t)
    os.environ["RTL_LOG"] = kimi_log

    rtl = RelayTurnLib(root, xyz_root, f, allow_paths)

    prompt = rtl.turn_prompt(me, t, peer)
    tick_repo_root = os.environ.get("TICK_REPO_ROOT", root)
    drift_brief = rtl.drift_brief(me, tick_repo_root)
    if drift_brief:
        prompt = drift_brief + "\n" + prompt

    tick_repo_root, _tick_bin = claim_task_or_exit(
        root, xyz_root, f, allow_paths, t, me, "kimi-turn")

    rtl.before()

    turn_timeout = int(os.environ.get("RELAY_TURN_TIMEOUT_S", 900))

    bounded_rc = 0
    wt = ""
    run_cwd = root
    kimi_env = dict(os.environ)
    kimi_env["TICK_REPO_ROOT"] = tick_repo_root

    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
        wt = rtl.worktree_begin()
        if wt:
            run_cwd = wt
            print(f"kimi-turn: worktree isolation ON ({wt})", file=sys.stderr)
        else:
            print("kimi-turn: worktree isolation requested but `git worktree add` failed — failing turn",
                  file=sys.stderr)
            bounded_rc = 5

    rtl.apply_reviewer_turn_env(kimi_env, run_cwd, me)

    # Kimi's workspace is its cwd, so the isolation worktree (when on) is what bounds its tools.
    # Containment does not depend on that: the path allowlist, commit guard and worktree isolation
    # in RelayTurnLib are what bound the turn.
    cmd = [kimi_bin, "-p", prompt, "-m", kimi_model, "--output-format", "stream-json"] + kimi_flags

    try:
        log_offset = os.path.getsize(kimi_log)
    except OSError:
        log_offset = 0

    diag = TurnDiagnostics(worktree=run_cwd)
    if bounded_rc == 0:
        diag.start()
        try:
            with open(kimi_log, "a") as log_f:
                # rtl_run_bounded, not subprocess.run(timeout=...): it kills the whole process group
                # on timeout, so Kimi's Bash children cannot outlive the turn (see muse-turn.py).
                # Returns the child's status, or 7 on timeout.
                bounded_rc = rtl_run_bounded(
                    turn_timeout, cmd,
                    cwd=run_cwd, env=kimi_env,
                    stdout=log_f, stderr=subprocess.STDOUT,
                )
        except FileNotFoundError:
            print(f"kimi-turn: kimi binary not found at {kimi_bin} "
                  f"(set KIMI_BIN, or install the Kimi Code CLI)", file=sys.stderr)
            bounded_rc = 5
        except Exception as exc:
            print(f"kimi-turn: kimi launch failed: {exc}", file=sys.stderr)
            bounded_rc = 5
        finally:
            diag.stop()

    # GH-648 L6: record the observed timeout in the run log before containment cleanup can replace
    # exit 7 with exit 6.
    if bounded_rc == 7:
        with open(kimi_log, "a") as log_f:
            record = diag.emit_termination_record(TERMINATION_WALL_CAP, stream=log_f)
        print(f"kimi-turn: kimi exceeded {turn_timeout}s wall-clock cap — killed [{record['reason']}]",
              file=sys.stderr)
        print(f"kimi-turn: timeout attribution: {record['detail']}", file=sys.stderr)

    if wt:
        off_lane = rtl.worktree_end(wt)
        if off_lane:
            print("kimi-turn: kimi made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)",
                  file=sys.stderr)
            bounded_rc = 6

    if bounded_rc not in (0, 7):
        print(f"kimi-turn: kimi failed (exit {bounded_rc})", file=sys.stderr)

    # GH-178's empty-exit-0 failure mode: a turn with no assistant output is a failed turn.
    if bounded_rc == 0 and not has_model_output(kimi_log, log_offset):
        print("kimi-turn: kimi exited 0 but produced NO model output (only CLI meta events) — "
              "failing the turn.", file=sys.stderr)
        bounded_rc = 5

    rc = rtl.enforce(t, me, kimi_log, "kimi")

    try:
        from harness_turn_logger import HarnessTurnLogger
        with HarnessTurnLogger(
            harness_id="kimi",
            shim="kimi-turn.py",
            task_scope=t,
            # The model actually dispatched (GH-346 Phase 0).
            model_id=kimi_model,
            # Kimi Code is its own router: it bills the operator's Kimi plan, not OpenRouter.
            gateway=os.environ.get("KIMI_GATEWAY", "moonshot"),
            cli_flags=["-p", "-m", kimi_model, "--output-format", "stream-json"] + kimi_flags,
            repo_root=xyz_root,
        ) as logger:
            logger.exit_code = bounded_rc or rc
    except Exception as _telemetry_exc:
        print("kimi-turn: telemetry not recorded: %r" % (_telemetry_exc,), file=sys.stderr)

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
