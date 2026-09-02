#!/usr/bin/env python3
import os
import sys
import tempfile
import subprocess
import shlex
import json
import shutil
from rtl import RelayTurnLib, claim_task_or_exit, make_tick_env, resolve_tick_bin, resolve_turn_root, rtl_default_log
from turn_diagnostics import TurnDiagnostics

def die(msg):
    print(f"claude-turn: {msg}", file=sys.stderr)
    sys.exit(2)

def warn_if_workspace_untrusted(root):
    """Warn, without changing turn control flow, when Claude lacks workspace trust."""
    config_path = os.path.expanduser("~/.claude.json")
    try:
        with open(config_path, encoding="utf-8") as config_file:
            config = json.load(config_file)
        project = config.get("projects", {}).get(root)
        trusted = isinstance(project, dict) and project.get("hasTrustDialogAccepted") is True
    except (OSError, json.JSONDecodeError, AttributeError):
        trusted = False

    if not trusted:
        print(
            f"claude-turn: WARNING: workspace {root!r} is not trusted; Claude may ignore project permissions. "
            "Run Claude Code interactively in this directory and accept the trust dialog, or set "
            f"projects[{root!r}][\"hasTrustDialogAccepted\"] to true in {config_path}.",
            file=sys.stderr,
        )

def main():
    if "-h" in sys.argv[1:] or "--help" in sys.argv[1:]:
        print("Usage: claude-turn.py")
        print("Required environment variables: RELAY_AGENT, RELAY_FILE, RELAY_TASK")
        sys.exit(0)

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
    # GH-308 port (GH-68): prepend any UNREAD peer dependency-drift notice to the turn brief, mirroring
    # claude-turn.sh's `rtl_drift_brief`. claude-turn.py was the ONLY Python turn shim missing this —
    # codex/pi/agy/aider all call it — so on the default lane the Claude builder silently lost the
    # "a peer changed a shared surface since your last turn" heads-up.
    drift_brief = rtl.drift_brief(me, tick_repo_root)
    if drift_brief:
        prompt = drift_brief + "\n" + prompt
    tick_repo_root, tick_bin = claim_task_or_exit(root, xyz_root, f, allow_paths, t, me, "claude-turn")
    
    # GH-161 parity (codex-turn.py and agy-turn.py already resolve through rtl_default_log):
    # persistent transcript path by default. The 2026-07-30 rebalance-OS marathon (GH-382's
    # panic run) lost both p5 builder transcripts to this tempdir default — the host reset
    # mid-phase and the reboot cleared tmp, so the only record of what the builder wrote died
    # with the machine. Stays pure JSON (the cost block is json.load-parsed below), so no rtl
    # trace lines are pointed here — unlike the codex/agy logs, which are plain text.
    claude_log = os.environ.get("CLAUDE_LOG") or rtl_default_log(root, "claude-turn", t)
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
    
        # GH-320: this default MUST match the Bash twin's `${RELAY_TURN_TIMEOUT_S:-N}` and the
    # ceiling its header documents. It read 300 while the twin said 600, and since Python is the
    # executing lane every turn was silently capped at a fraction of the documented budget —
    # observed live as an exit-7 kill on a review turn that had 900s on paper.
    #
    # GH-386: raised 600 -> 900, so every builder now shares one wall cap. `claude` was the only
    # shim below 900 (agy, codex, aider and pi all use it), and nothing anywhere said why — GH-320's
    # comment above explains why the TWINS must agree, not why this value differs from every other
    # agent, so the next reader had to guess.
    #
    # The guess a reader would most likely make is "600 is a cost control, because a headless
    # `claude -p` bills per call". That is wrong, and the reason is three lines up: cost is already
    # bounded by CLAUDE_MAX_BUDGET, passed to the CLI as `--max-budget-usd` (default $0.50). A
    # shorter wall cap buys no money that flag is not already saving; what it buys is a builder
    # killed mid-edit, which is the exact failure GH-320 fixed one notch lower and #386 observed
    # again at this one — a phase whose packet read 900 was killed at 600, partway through writing
    # a ~1690-LOC artifact pair. GH-492's idle bound (RELAY_TURN_IDLE_S) is the mechanism that ends
    # a turn EARLY when it is genuinely stuck, and it is builder-agnostic; the wall cap is the
    # backstop behind it and has no reason to vary by agent.
    turn_timeout = int(os.environ.get("RELAY_TURN_TIMEOUT_S", 900))
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
            # The token was claimed already.  Keep running through cleanup and enforce so the
            # relay can persist its handoff/containment outcome instead of remaining claimed by
            # this dead turn.
            bounded_rc = 5

    # GH-380: trust is a per-directory Claude Code setting. This is deliberately warn-only:
    # no config is modified and an untrusted (or unreadable) workspace still runs.
    # Claude evaluates the directory it is launched in; under worktree isolation that is `wt`,
    # rather than the original target root.
    if bounded_rc == 0:
        warn_if_workspace_untrusted(run_cwd)

    # GH-346: named so the telemetry block below can record the flags this turn actually ran with.
    # It previously passed `cflags`, a name bound nowhere in this file — NameError, swallowed by the
    # logger's `except Exception: pass`, so claude wrote NO telemetry row on any turn. The prompt is
    # deliberately excluded: it is unbounded text, not a flag.
    claude_cli_flags = [
        "--model", model,
        "--allowedTools", "Bash,Read,Edit,Write",
        "--permission-mode", "acceptEdits",
        "--output-format", "json",
        "--max-turns", str(max_turns),
        "--max-budget-usd", str(max_budget)
    ]
    cmd = [resolved_claude, "-p", prompt] + claude_cli_flags
    
    # Sample the turn while it runs so an exit-7 timeout can be attributed to a
    # cause. subprocess.run reaps the child before raising TimeoutExpired, so
    # nothing can be probed after the fact — see turn_diagnostics.
    diag = TurnDiagnostics(worktree=run_cwd)
    if bounded_rc == 0:
        diag.start()
        try:
            with open(claude_log, "w") as log_f:
                subprocess.run(cmd, env=run_env, cwd=run_cwd, timeout=turn_timeout, stdout=log_f, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, check=True)
        except subprocess.TimeoutExpired:
            bounded_rc = 7
        except subprocess.CalledProcessError as e:
            bounded_rc = e.returncode
        except Exception:
            bounded_rc = 5
        finally:
            diag.stop()

    if shadow_dir:
        shutil.rmtree(shadow_dir, ignore_errors=True)
        
    if wt:
        off_lane = rtl.worktree_end(wt)
        if off_lane:
            print("claude-turn: builder made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)", file=sys.stderr)
            # Containment remains an exit-6 result, but must first reach rtl.enforce so the
            # already-claimed token cannot be orphaned.
            bounded_rc = 6

    if bounded_rc == 7:
        # Exit code stays 7 for callers; the reason names WHY, so a blocked OS
        # dialog is never mistaken for an agent that merely needed more budget.
        _reason, _detail = diag.classify()
        print(f"claude-turn: claude -p exceeded {turn_timeout}s wall-clock cap — killed [{_reason}]", file=sys.stderr)
        print(f"claude-turn: timeout attribution: {_detail}", file=sys.stderr)
    elif bounded_rc != 0:
        print(f"claude-turn: claude -p failed (exit {bounded_rc})", file=sys.stderr)

    # GH-432: a failed turn must still reach rtl_enforce. This branch used to `sys.exit(5)` right
    # here, two lines above the timeout path that deliberately falls THROUGH — so the one case where
    # persistence matters most was the one case that skipped the file-scoped commit, the allowlist
    # containment check, the transcript archive, the GH-67 token handoff, and the drift signal, all
    # at once. The reported symptom is all five at once: relay edit uncommitted, token still claimed
    # by a dead agent, no path to a terminal state without a manual `tick done`.
    #
    # Worktree isolation is what makes the loss precise rather than partial: worktree_end() above has
    # ALREADY copied the agent's allowlisted edits back into the real tree, so they are sitting there,
    # correct and uncommitted, when the exit discards the only code path that would commit them.
    #
    # Containment is not weakened by running enforce on a failure — enforce is where containment
    # LIVES (off-lane edits are reverted and exit 6 there, as they already were for a timeout).
    rc = rtl.enforce(t, me, claude_log, "claude")
    # An in-root enforcement violation takes priority over a failed or timed-out subprocess.
    if rc == 6:
        sys.exit(6)
    if bounded_rc == 6:
        sys.exit(6)
    if bounded_rc == 7:
        sys.exit(7)
    if bounded_rc != 0:
        # Exit code is unchanged from before the fix: callers still see 5 for a failed turn. Only
        # the side effects that precede it changed.
        sys.exit(5)

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
            
    try:
        from harness_turn_logger import HarnessTurnLogger
        with HarnessTurnLogger(
            harness_id="claude",
            shim="claude-turn.py",
            task_scope=t,
            # GH-346 Phase 0: log the model that actually dispatched, not a second, drifted
            # default. This read its own CLAUDE_MODEL with a different fallback than the
            # dispatch site above, so an unset CLAUDE_MODEL ran claude-sonnet-4-6 and recorded
            # anthropic/claude-3-7-sonnet in harnesses.db.
            model_id=model,
            gateway=os.environ.get("CLAUDE_GATEWAY", "anthropic"),
            reasoning_effort=os.environ.get("CLAUDE_REASONING_EFFORT", "high"),
            cli_flags=claude_cli_flags,
            repo_root=xyz_root,
        ) as logger:
            logger.exit_code = bounded_rc or rc
    except Exception as _telemetry_exc:
        # GH-346: this used to be a bare `pass`. Three shims passed an undefined name as
        # cli_flags, raised NameError here, and silently wrote NO telemetry row for the entire
        # life of the shim -- a telemetry system that fails closed and says nothing. Still
        # non-fatal (a turn must never fail because logging did), but never again invisible.
        print(f"claude-turn: telemetry not recorded: %r" % (_telemetry_exc,), file=sys.stderr)

    sys.exit(rc)

if __name__ == "__main__":
    main()
