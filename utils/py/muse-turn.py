#!/usr/bin/env python3
"""muse-turn.py (GH-518) — relay turn adapter for Meta's native `muse` CLI.

Modeled on commandcode-turn.py (GH-42): Python is the only implementation, the Bash file is a
thin entry point, and containment/enforcement stay in RelayTurnLib rather than being re-derived
here.

The one thing this shim owns that its siblings do not is MODEL POLICY, and it is worth saying
why it lives in code instead of a doc.

Meta ships Muse Spark 1.3 at two tiers. They are the same model; only the terms differ:

    muse-spark-1.3              $1.25 / $4.25 / $0.15 per M   no data clause
    muse-spark-1.3-contributor  $0.10 / $0.20 / $0.002 per M  "your content, including
                                                               inter-session messages, may be
                                                               used for product improvement"

The operator's rule is that the discounted tier is for open-source repositories only. A relay
turn ships repository content -- diffs, file bodies, review prose -- to whichever tier is
dispatched, and content sent under that clause cannot be recalled. So the rule cannot be a
comment that a future caller is trusted to remember; it has to be the default behavior.

Hence resolve_model() FAILS CLOSED. It returns the clause-free model unless it can positively
establish that the target repository is public. Every uncertainty -- gh missing, gh unauthenticated,
network down, not a GitHub remote, lookup timed out, unparseable answer -- lands on the safe tier.
The expensive model is the safe one here, which is exactly why the failure direction has to be
chosen deliberately: the cheap path is the one that leaks.

`MUSE_MODEL` overrides everything, because an operator naming a model explicitly is making an
informed choice; `MUSE_ALLOW_CONTRIBUTOR=0` pins the safe tier even for public repos.
"""
import os
import subprocess
import sys
import tempfile

from rtl import RelayTurnLib, claim_task_or_exit, rtl_default_log, resolve_turn_root
from turn_diagnostics import TurnDiagnostics

# The tier carrying no data-use clause. Every ambiguous path resolves here.
SAFE_MODEL = "muse-spark-1.3"
# The discounted tier. Reached only by a positive public-repository determination.
CONTRIBUTOR_MODEL = "muse-spark-1.3-contributor"

# A visibility lookup is a network round trip on the critical path of a turn. If GitHub is slow
# we take the safe model and move on rather than spending the turn's budget on a pricing question.
VISIBILITY_TIMEOUT_S = 15


def die(msg):
    print(f"muse-turn: {msg}", file=sys.stderr)
    sys.exit(2)


def repo_visibility(repo_root):
    """Return (visibility, reason). visibility is 'PUBLIC', 'PRIVATE', or '' when undetermined.

    '' is not an error state the caller should retry -- it is the answer "we do not know", which
    resolve_model treats exactly like PRIVATE.
    """
    try:
        proc = subprocess.run(
            ["gh", "repo", "view", "--json", "visibility", "-q", ".visibility"],
            cwd=repo_root,
            capture_output=True,
            text=True,
            timeout=VISIBILITY_TIMEOUT_S,
            stdin=subprocess.DEVNULL,
        )
    except FileNotFoundError:
        return "", "gh CLI not installed"
    except subprocess.TimeoutExpired:
        return "", f"gh repo view exceeded {VISIBILITY_TIMEOUT_S}s"
    except Exception as exc:
        return "", f"gh repo view raised {exc!r}"

    if proc.returncode != 0:
        detail = (proc.stderr or "").strip().splitlines()
        return "", "gh repo view exit %d%s" % (
            proc.returncode, (": " + detail[0]) if detail else "")

    answer = (proc.stdout or "").strip().upper()
    if answer in ("PUBLIC", "PRIVATE", "INTERNAL"):
        # INTERNAL is org-visible, not open source. Deliberately not treated as public.
        return answer, "gh reported %s" % answer
    return "", "gh returned unrecognized visibility %r" % (answer,)


def resolve_model(repo_root):
    """Pick the model for this turn. Returns (model_id, reason) -- the reason is logged, always."""
    explicit = os.environ.get("MUSE_MODEL", "").strip()
    if explicit:
        return explicit, "explicit MUSE_MODEL"

    if os.environ.get("MUSE_ALLOW_CONTRIBUTOR", "1") == "0":
        return SAFE_MODEL, "contributor tier disabled by MUSE_ALLOW_CONTRIBUTOR=0"

    visibility, why = repo_visibility(repo_root)
    if visibility == "PUBLIC":
        return CONTRIBUTOR_MODEL, "repository is public (%s)" % why
    return SAFE_MODEL, "not established as public — %s" % why


def main():
    if "-h" in sys.argv[1:] or "--help" in sys.argv[1:]:
        print("Usage: muse-turn.py")
        print("Required environment variables: RELAY_AGENT, RELAY_FILE, MUSE_AGENT")
        print("Optional: RELAY_TASK, RELAY_PEER, ALLOW_PATHS, MUSE_BIN, MUSE_MODEL,")
        print("          MUSE_ALLOW_CONTRIBUTOR, MUSE_REASONING_EFFORT, RELAY_TURN_TIMEOUT_S")
        sys.exit(0)

    xyz_root = os.environ.get(
        "XYZ_ROOT",
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    root = resolve_turn_root(os.environ.get("MUSE_TURN_ROOT"), xyz_root)

    # GH-518: absolute path by default. The CLI was installed with MUSE_NO_MODIFY_PATH=1, so
    # ~/.local/bin is deliberately NOT on PATH and a bare `muse` would not resolve under a
    # non-interactive shell.
    muse_bin = os.environ.get("MUSE_BIN", os.path.expanduser("~/.local/bin/muse"))

    me = os.environ.get("RELAY_AGENT", "")
    f = os.environ.get("RELAY_FILE", "")
    t = os.environ.get("RELAY_TASK", "RELAY-TURN")
    muse_agent = os.environ.get("MUSE_AGENT", "")

    if not me:
        die("RELAY_AGENT required")
    if not f:
        die("RELAY_FILE required")
    if not muse_agent:
        die("MUSE_AGENT required")

    if me != muse_agent:
        print(f"muse-turn: actor {me} is not the Muse agent ({muse_agent}) — deferring (window-driven)",
              file=sys.stderr)
        sys.exit(0)

    allow_paths = os.environ.get("ALLOW_PATHS", "")
    peer = os.environ.get("RELAY_PEER", "")

    muse_log = os.environ.get("MUSE_LOG") or rtl_default_log(root, "muse-turn", t)
    os.environ["RTL_LOG"] = muse_log

    rtl = RelayTurnLib(root, xyz_root, f, allow_paths)

    prompt = rtl.turn_prompt(me, t, peer)
    tick_repo_root = os.environ.get("TICK_REPO_ROOT", root)
    drift_brief = rtl.drift_brief(me, tick_repo_root)
    if drift_brief:
        prompt = drift_brief + "\n" + prompt

    tick_repo_root, _tick_bin = claim_task_or_exit(
        root, xyz_root, f, allow_paths, t, me, "muse-turn")

    # Decide the model against the repository the turn actually writes to, not the harness root:
    # a cross-repo relay can be driven from XYZ-forge (public) into a private target.
    muse_model, model_reason = resolve_model(tick_repo_root)
    print(f"muse-turn: model {muse_model} — {model_reason}", file=sys.stderr)

    reasoning_effort = os.environ.get("MUSE_REASONING_EFFORT", "high")

    rtl.before()

    turn_timeout = int(os.environ.get("RELAY_TURN_TIMEOUT_S", 900))

    bounded_rc = 0
    wt = ""
    run_cwd = root
    muse_env = dict(os.environ)
    muse_env["TICK_REPO_ROOT"] = tick_repo_root

    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
        wt = rtl.worktree_begin()
        if wt:
            run_cwd = wt
            print(f"muse-turn: worktree isolation ON ({wt})", file=sys.stderr)
        else:
            print("muse-turn: worktree isolation requested but `git worktree add` failed — failing turn",
                  file=sys.stderr)
            bounded_rc = 5

    # --prompt-file rather than a positional argument: a relay prompt carries the whole thread
    # plus a drift brief and routinely exceeds a comfortable argv size, and a file keeps the
    # turn text out of the process table.
    prompt_fd, prompt_path = tempfile.mkstemp(prefix="muse-turn-", suffix=".prompt")
    try:
        with os.fdopen(prompt_fd, "w") as pf:
            pf.write(prompt)

        cmd = [
            muse_bin, "exec",
            "--model", muse_model,
            "--reasoning-effort", reasoning_effort,
            "--prompt-file", prompt_path,
        ]

        diag = TurnDiagnostics(worktree=run_cwd)
        if bounded_rc == 0:
            diag.start()
            try:
                with open(muse_log, "a") as log_f:
                    subprocess.run(cmd, env=muse_env, cwd=run_cwd, timeout=turn_timeout,
                                   stdout=log_f, stderr=subprocess.STDOUT,
                                   stdin=subprocess.DEVNULL, check=True)
            except FileNotFoundError:
                print(f"muse-turn: muse binary not found at {muse_bin} "
                      f"(set MUSE_BIN, or reinstall via https://dev.meta.ai/install.sh)",
                      file=sys.stderr)
                bounded_rc = 5
            except subprocess.TimeoutExpired:
                bounded_rc = 7
            except subprocess.CalledProcessError as exc:
                bounded_rc = exc.returncode
            except Exception as exc:
                print(f"muse-turn: muse launch failed: {exc}", file=sys.stderr)
                bounded_rc = 5
            finally:
                diag.stop()
    finally:
        try:
            os.unlink(prompt_path)
        except OSError:
            pass

    if wt:
        off_lane = rtl.worktree_end(wt)
        if off_lane:
            print("muse-turn: muse made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)",
                  file=sys.stderr)
            bounded_rc = 6

    if bounded_rc == 7:
        _reason, _detail = diag.classify()
        print(f"muse-turn: muse exec exceeded {turn_timeout}s wall-clock cap — killed [{_reason}]",
              file=sys.stderr)
        print(f"muse-turn: timeout attribution: {_detail}", file=sys.stderr)
    elif bounded_rc != 0:
        print(f"muse-turn: muse exec failed (exit {bounded_rc})", file=sys.stderr)

    # GH-178's empty-exit-0 failure mode is not agy-specific; treat it as a failed turn here too.
    if bounded_rc == 0 and (not os.path.exists(muse_log) or os.path.getsize(muse_log) == 0):
        print("muse-turn: muse exited 0 but produced NO output — failing the turn.", file=sys.stderr)
        bounded_rc = 5

    rc = rtl.enforce(t, me, muse_log, "muse")

    try:
        from harness_turn_logger import HarnessTurnLogger
        with HarnessTurnLogger(
            harness_id="muse",
            shim="muse-turn.py",
            task_scope=t,
            # Log the model actually dispatched. GH-346 Phase 0 fixed exactly this drift in
            # commandcode-turn.py, where an unset env var ran one model and recorded another.
            model_id=muse_model,
            # Muse is both harness and router: this shim holds no OpenRouter key and no base URL,
            # and `muse` resolves the model against Meta's own provider catalog.
            gateway=os.environ.get("MUSE_GATEWAY", "meta"),
            reasoning_effort=reasoning_effort,
            cli_flags=["exec", "--model", muse_model,
                       "--reasoning-effort", reasoning_effort, "--prompt-file"],
            repo_root=xyz_root,
        ) as logger:
            logger.exit_code = bounded_rc or rc
    except Exception as _telemetry_exc:
        print("muse-turn: telemetry not recorded: %r" % (_telemetry_exc,), file=sys.stderr)

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
