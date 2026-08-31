#!/usr/bin/env python3
# pi-turn.py — Python-default port of relay-automation/pi-turn.sh (GH-295). Same contract, same exit
# codes; see the Bash file's header comment for the full env-var reference and design rationale.
import json
import os
import sys
import subprocess
from rtl import RelayTurnLib, claim_task_or_exit, rtl_default_log, resolve_turn_root

def die(msg):
    print(f"pi-turn: {msg}", file=sys.stderr)
    sys.exit(2)

def parse_pi_usage(log_path):
    # Pi's --mode json stream is JSONL (one JSON object per line), not a single blob and not a JSON
    # array. Scan every line and keep the LAST usage block seen (the turn_end/agent_end event carries
    # the cumulative usage for the whole turn). Best-effort: any parse failure just yields (0, 0), same
    # "loud-partial, not fatal" posture as the Bash shim's inline python parser.
    tin = tout = 0
    try:
        with open(log_path, "r", errors="replace") as fh:
            for line in fh:
                line = line.strip()
                if not line or not line.startswith("{"):
                    continue
                try:
                    d = json.loads(line)
                except Exception:
                    continue
                msg = d.get("message")
                if not isinstance(msg, dict):
                    continue
                usage = msg.get("usage")
                if not isinstance(usage, dict):
                    continue
                tin = usage.get("input", tin) or tin
                tout = usage.get("output", tout) or tout
    except Exception:
        pass
    return tin, tout

def main():
    if "-h" in sys.argv[1:] or "--help" in sys.argv[1:]:
        print("Usage: pi-turn.py")
        print("Required environment variables: RELAY_AGENT, RELAY_FILE, RELAY_TASK")
        sys.exit(0)

    xyz_root = os.environ.get("XYZ_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    # GH-308 port (GH-296): fall back to the CWD's git toplevel (not xyz_root) when PI_TURN_ROOT is
    # unset, matching pi-turn.sh and codex/claude-turn.py. pi has no native sandbox — its containment
    # relies entirely on worktree isolation, so mis-rooting the worktree at the harness's own dir
    # undermined the only containment layer on a non-vendored external run.
    root = resolve_turn_root(os.environ.get("PI_TURN_ROOT"), xyz_root)
    pi_bin = os.environ.get("PI_BIN", "pi")
    pi_provider = os.environ.get("PI_PROVIDER", "openrouter")

    me = os.environ.get("RELAY_AGENT", "")
    f = os.environ.get("RELAY_FILE", "")
    t = os.environ.get("RELAY_TASK", "RELAY-TURN")
    pi_agent = os.environ.get("PI_AGENT", "")

    if not me: die("RELAY_AGENT required")
    if not f: die("RELAY_FILE required")
    if not pi_agent: die("PI_AGENT required")

    if me != pi_agent:
        print(f"pi-turn: actor {me} is not the Pi agent ({pi_agent}) — deferring (window-driven)", file=sys.stderr)
        sys.exit(0)

    # GH-295: PI_MODEL has NO default — refuse to guess (the GH-280/aider#5486 class of bug).
    pi_model = os.environ.get("PI_MODEL", "")
    if not pi_model:
        print("pi-turn: PI_MODEL is not set — refusing to guess a model id (GH-280 class of bug). "
              "Set PI_MODEL explicitly, e.g. PI_MODEL=openai/gpt-mini-latest. Run `pi --list-models` "
              "to see what your provider/account exposes.", file=sys.stderr)
        sys.exit(5)

    # GH-441: Pre-flight validation to immediately exit 7 on unsupported providers (avoid timeout hang).
    known_providers = {"openrouter", "openai", "anthropic", "google", "vertex", "ollama", "mistral", "bedrock"}
    if pi_provider not in known_providers:
        print(f"pi-turn: unsupported provider '{pi_provider}' — failing the turn (exit 7)", file=sys.stderr)
        sys.exit(7)

    # Auth pre-flight: default provider (openrouter) reuses this harness's OPENROUTER_API_KEY seam.
    if pi_provider == "openrouter" and not os.environ.get("OPENROUTER_API_KEY"):
        print("pi-turn: OPENROUTER_API_KEY is not set — Pi cannot reach OpenRouter (or set PI_PROVIDER "
              "to a different provider with its own credential env var). Export it, then retry.", file=sys.stderr)
        sys.exit(5)

    allow_paths = os.environ.get("ALLOW_PATHS", "")
    peer = os.environ.get("RELAY_PEER", "")
    tick_repo_root = os.environ.get("TICK_REPO_ROOT", root)

    # GH-161: resolve the transcript path and export RTL_LOG BEFORE the first rtl call, mirroring
    # codex-turn.py, so rtl_init/enforce trace lines land in this turn's transcript.
    pi_log = os.environ.get("PI_LOG") or rtl_default_log(root, "pi-turn", t)
    os.environ["RTL_LOG"] = pi_log

    rtl = RelayTurnLib(root, xyz_root, f, allow_paths)

    prompt = rtl.turn_prompt(me, t, peer)
    drift_brief = rtl.drift_brief(me, tick_repo_root)
    if drift_brief:
        prompt = drift_brief + "\n" + prompt

    # Establish ownership of the specific handed-off token before launching Pi (mirrors codex-turn.py
    # GH-165: rtl.enforce's post-commit release/done is ownership-guarded).
    tick_repo_root, _tick_bin = claim_task_or_exit(root, xyz_root, f, allow_paths, t, me, "pi-turn")

    turn_timeout = int(os.environ.get("RELAY_TURN_TIMEOUT_S", 900))
    pi_args = ["--provider", pi_provider, "--model", pi_model, "--no-session", "--mode", "json"]
    pflags = os.environ.get("PI_FLAGS", "").split()
    if pflags:
        pi_args += pflags

    rtl.before()

    wt = ""
    run_cwd = root

    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
        wt = rtl.worktree_begin()
        if wt:
            run_cwd = wt
            print(f"pi-turn: worktree isolation ON ({wt})", file=sys.stderr)
            os.environ["TICK_REPO_ROOT"] = tick_repo_root
        else:
            print("pi-turn: worktree isolation requested but `git worktree add` failed — failing turn", file=sys.stderr)
            sys.exit(5)

    cmd = [pi_bin] + pi_args + ["-p", prompt]

    bounded_rc = 0
    try:
        # GH-161: append (not truncate) — rtl_init already wrote its decision-trace line into pi_log
        # via the exported RTL_LOG; a truncating open here would silently wipe it.
        with open(pi_log, "a") as log_f:
            subprocess.run(cmd, cwd=run_cwd, timeout=turn_timeout, stdout=log_f, stderr=subprocess.STDOUT,
                            stdin=subprocess.DEVNULL, check=True)
    except subprocess.TimeoutExpired:
        bounded_rc = 7
    except subprocess.CalledProcessError as e:
        bounded_rc = e.returncode
    except Exception:
        bounded_rc = 5

    if wt:
        off_lane = rtl.worktree_end(wt)
        if off_lane:
            print("pi-turn: pi made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)", file=sys.stderr)
            sys.exit(6)

    if bounded_rc == 7:
        print(f"pi-turn: pi exceeded {turn_timeout}s wall-clock cap — killed", file=sys.stderr)
    elif bounded_rc != 0:
        print(f"pi-turn: pi failed (exit {bounded_rc})", file=sys.stderr)

    if bounded_rc == 0 and (not os.path.exists(pi_log) or os.path.getsize(pi_log) == 0):
        print("pi-turn: pi exited 0 but produced NO output — likely a blocked/misconfigured backend. Failing the turn.", file=sys.stderr)
        # GH-432 (agy review): set the failure instead of exiting on it, so this route to a failed
        # turn reaches rtl_enforce like the crash route does. See utils/py/agy-turn.py.
        bounded_rc = 5

    # GH-432: a failed turn still reaches rtl_enforce, so its work is committed and its token handed
    # off instead of leaking. See utils/py/claude-turn.py for the full rationale. Exit 5 is unchanged.
    rc = rtl.enforce(t, me, pi_log, "pi")

    # Best-effort cost capture (GH-295): genuine improvement over the cost-blind agy lane. Never fails
    # the turn — the commit already stood by the time this runs.
    try:
        if os.path.exists(pi_log) and os.path.getsize(pi_log) > 0:
            tokens_in, tokens_out = parse_pi_usage(pi_log)
            if tokens_in > 0 or tokens_out > 0:
                cost_tickroot = os.environ.get("TICK_REPO_ROOT", root)
                from rtl import resolve_tick_bin
                cost_tickbin = resolve_tick_bin(cost_tickroot, xyz_root)
                if cost_tickbin:
                    cost_env = dict(os.environ)
                    cost_env["TICK_REPO_ROOT"] = cost_tickroot
                    cost_res = subprocess.run(
                        [cost_tickbin, "cost", t, "--agent", me,
                         "--tokens-in", str(tokens_in), "--tokens-out", str(tokens_out), "--tool", "pi"],
                        env=cost_env, capture_output=True, text=True,
                    )
                    if cost_res.returncode != 0:
                        print(f"pi-turn: tokens not captured for {t}", file=sys.stderr)
            else:
                print(f"pi-turn: tokens not captured for {t} (zero or no usage in transcript)", file=sys.stderr)
    except Exception:
        pass

    try:
        from harness_turn_logger import HarnessTurnLogger
        with HarnessTurnLogger(
            harness_id="pi",
            shim="pi-turn.py",
            task_scope=t,
            # GH-346 Phase 0: pi-turn refuses to run at all when PI_MODEL is unset (GH-295), so
            # the old "pi-native" default was unreachable and contradicted that contract. Log the
            # dispatch variable, which is guaranteed non-empty by the guard above.
            model_id=pi_model,
            gateway=os.environ.get("PI_GATEWAY", "pi"),
            reasoning_effort=os.environ.get("PI_REASONING_EFFORT", "high"),
            cli_flags=pflags,
            repo_root=xyz_root,
        ) as logger:
            logger.exit_code = bounded_rc or rc
    except Exception as _telemetry_exc:
        # GH-346: this used to be a bare `pass`. Three shims passed an undefined name as
        # cli_flags, raised NameError here, and silently wrote NO telemetry row for the entire
        # life of the shim -- a telemetry system that fails closed and says nothing. Still
        # non-fatal (a turn must never fail because logging did), but never again invisible.
        print(f"pi-turn: telemetry not recorded: %r" % (_telemetry_exc,), file=sys.stderr)

    if bounded_rc == 7:
        sys.exit(7)
    if bounded_rc != 0:
        sys.exit(5)

    sys.exit(rc)

if __name__ == "__main__":
    main()
