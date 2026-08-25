#!/usr/bin/env python3
import os
import sys
import time
import signal
import tempfile
import threading
import pty
import subprocess
import shutil
import shlex
from rtl import (RelayTurnLib, claim_task_or_exit, rtl_default_log, resolve_turn_root,
                 narration_mentions_root, agy_auth_output_verdict, agy_auth_timeout_verdict,
                 AGY_AUTH_TIMEOUT_DEFAULT_S)
from turn_diagnostics import TurnDiagnostics

# GH-492: how long the tree may show no CPU growth and no file progress before the turn is
# killed, independent of RELAY_TURN_TIMEOUT_S. Sized from the observed hang: it was already
# unanimous by ~30s of samples, and a genuinely working agy turn produces file writes or CPU
# far more often than every 5 minutes. Set RELAY_TURN_IDLE_S=0 to disable and keep only the
# wall cap.
RELAY_TURN_IDLE_DEFAULT_S = 300
#: Poll interval for the turn's own bound loop. Cheap: it only reads `proc.poll()` and a
#: float the sampler thread already maintains.
TURN_POLL_S = 2

# GH-492 criterion 4: RECORD THE FINDING rather than papering over it with a weaker probe.
# There is no reliable headless pre-flight for agy and there is not expected to be one. GH-375
# measured why: `agy whoami` exits 0 while printing a TTY error, so its exit status is meaningless
# here, and treating that error as failure took test/relay-self-sufficiency.sh from 4/0 to 0/4 on a
# machine where agy was signed in and working. `agy -p` — what the turn actually runs — is headless-
# clean. A second unreliable probe would be worse than none, so none is shipped.
_AUTH_PROBE_FINDING = ("No reliable headless auth probe for agy exists (GH-375); `agy -p` is the "
                       "only honest test and it IS the turn. If this turn fails on credentials, "
                       "run `agy login` in a real terminal.")
#: Set when the pre-flight could not establish auth either way. Held so the failure path can
#: re-raise it as diagnosis, instead of it being shouted on every healthy turn.
_AUTH_UNVERIFIED_DETAIL = None

def _record_auth_unverified(detail):
    global _AUTH_UNVERIFIED_DETAIL
    _AUTH_UNVERIFIED_DETAIL = detail

def die(msg):
    print(f"agy-turn: {msg}", file=sys.stderr)
    sys.exit(2)

def _kill_turn_group(proc):
    """Kill the turn's whole process group, not just the launcher.

    agy spawns children; signalling only the parent leaves them running and holding
    the log open, which is how a "killed" turn keeps burning the host. The process is
    started with start_new_session=True so its pgid is its own pid and this cannot
    reach the harness. SIGTERM first so the CLI can flush its transcript, then SIGKILL.
    """
    for sig, wait_s in ((signal.SIGTERM, 5), (signal.SIGKILL, 2)):
        try:
            os.killpg(os.getpgid(proc.pid), sig)
        except (ProcessLookupError, PermissionError, OSError):
            return
        try:
            proc.wait(timeout=wait_s)
            return
        except subprocess.TimeoutExpired:
            continue

def _probe_idle_blocker(proc, log_path):
    """GH-114: name WHAT an idle turn was blocked on, BEFORE the kill destroys the evidence.

    The observed stall showed `bubbletea: could not open TTY` in the transcript while the
    watchdog reported only the generic "a lock, a prompt, or a hung network call". Probe in
    priority order — the CLI's own words about itself first, then the open-file table:

      tty     — the transcript already contains agy's TTY error prefixes
      lock    — the process tree holds a .lock file open (git index, harness driver lock)
      network — the process tree has TCP/UDP sockets open (model backend call hung)
      unknown — nothing probe-able; say so rather than guess

    Returns (blocker, human_detail). Best-effort throughout: a probe failure degrades to
    "unknown" and can never fail the turn it is describing.
    """
    tail = ""
    try:
        with open(log_path, "rb") as f:
            tail = f.read()[-8192:].decode("utf-8", "replace").lower()
    except OSError:
        pass
    if "could not open tty" in tail or "error opening tty" in tail or "open /dev/tty" in tail:
        return ("tty",
                "the CLI's terminal UI reported it could not open /dev/tty — the headless turn had "
                "no usable TTY (bubbletea blocking on terminal setup). If AGY_PTY=0 was set, remove "
                "it; otherwise investigate why the pty allocation did not reach the child.")
    open_files = ""
    try:
        open_files = subprocess.run(
            ["lsof", "-nP", "-a", "-g", str(proc.pid), "-w"],
            capture_output=True, text=True, timeout=5).stdout.lower()
    except Exception:
        open_files = ""
    if ".lock" in open_files:
        return ("lock",
                "the process tree held a .lock file open (e.g. a git index or harness driver lock) — "
                "it was waiting on a lock held by someone else, not working.")
    if "tcp" in open_files or "udp" in open_files:
        return ("network",
                "the process tree had open network sockets — it was waiting on a network call "
                "(most likely the model backend), not working.")
    return ("unknown",
            "no TTY error, no open lock, no open socket in the process tree — the blocker left no "
            "probe-able trace; the transcript is the remaining evidence.")

def agy_auth_preflight(agy_bin):
    secs = int(os.environ.get("AGY_AUTH_TIMEOUT_S", AGY_AUTH_TIMEOUT_DEFAULT_S))
    out_file = os.path.join(tempfile.gettempdir(), f"agy-auth-{os.getpid()}.log")
    rc = 0
    # GH-426: run the probe in a THROWAWAY directory, never in whatever repo happens to be the
    # caller's CWD.
    #
    # This pre-flight is the only place the harness executes the agent binary OUTSIDE the turn's
    # containment. `subprocess.run` with no `cwd=` inherits the parent's, which for a driven turn is
    # the harness clone — so anything this invocation writes lands in the harness working tree, is
    # never seen by `rtl_check` (which inspects RTL_ROOT, a different repo), and is never reverted.
    #
    # That is exactly what #426 reported as a worktree-isolation leak. It is not one: measured with a
    # per-invocation log, the agent binary is called TWICE — `whoami` with CWD=harness, then the real
    # turn with CWD=the isolation worktree — and the file that reaches the harness comes from the
    # first. The worktree is correctly based on AGY_TURN_ROOT and containment correctly exits 6. The
    # reproducing stub simply writes on every invocation, which real `agy whoami` does not.
    #
    # Fixed anyway, because "the binary we shell out to happens not to write" is an assumption about
    # someone else's program, not a property this harness enforces — and it is the assumption that
    # made a stub indistinguishable from a containment failure for a week.
    probe_cwd = tempfile.mkdtemp(prefix="agy-auth-probe.")
    try:
        with open(out_file, "w") as out_f:
            # GH-221 (2026-08-24): probe `models`, not `whoami`. agy >=1.1.19 removed the `whoami`
            # subcommand entirely (clap usage error on every run), while `models` exists on every
            # agy generation this harness has driven, runs headless without a TTY, and requires
            # live auth + network — the reliable headless probe GH-492 said did not exist at the
            # time. All GH-130/GH-375 verdict routing below is kept as the safety net for future
            # CLI drift.
            subprocess.run([agy_bin, "models"], timeout=secs, stdout=out_f, stderr=subprocess.STDOUT,
                           stdin=subprocess.DEVNULL, check=True, cwd=probe_cwd)
        # GH-375: exit status alone cannot decide this. `agy whoami` EXITS 0 while failing to run at
        # all when there is no TTY — `CLI error: bubbletea: error opening TTY ...` — and stdin is
        # DEVNULL here, so that is the NORMAL path under automation, not an edge case. The probe
        # therefore reported "auth OK" in the one context it exists for. Worse, the captured output,
        # the only place the failure was visible, was deleted on this branch.
        #
        # Matched on agy's own error PREFIXES rather than a bare "error" substring. A bare substring
        # test fails the opposite way: `whoami` prints account identity, so any org, handle, or
        # banner containing "error" would block a lane whose auth is fine — and a false failure here
        # stops the run outright, which is worse than the bug being fixed. Empty output is NOT a
        # failure; see the comment in rtl.agy_auth_output_verdict for the turn that rule cost.
        severity, detail = agy_auth_output_verdict(out_file)
        if not severity:
            if os.path.exists(out_file): os.remove(out_file)
            return True
        if severity == "unverifiable":
            # The probe could not run, so it proved nothing — in EITHER direction. Say so and let the
            # turn proceed: `agy whoami` needs a TTY, `agy -p` (what the turn actually uses) does not,
            # and blocking here stopped a working lane dead the first time it shipped. Measured, not
            # theorised — test/relay-self-sufficiency.sh drives a live agy turn and went 4/0 to 0/4.
            # GH-492 criterion 3: this fires on EVERY headless run, because `agy whoami` can never
            # run headless — so as a WARNING it was noise that carried no information about any
            # particular turn, and it read identically on three healthy turns and one 900s hang.
            # Demoted to a single NOTE line here and re-raised in full ONLY on the failure path,
            # where it is actually diagnostic. The verdict itself is unchanged: still "unverifiable",
            # still non-blocking. GH-375 established what changing that costs.
            _record_auth_unverified(detail)
            print(f"agy-turn: NOTE — agy auth is unverifiable headless (expected); proceeding. {_AUTH_PROBE_FINDING}",
                  file=sys.stderr)
            if os.path.exists(out_file): os.remove(out_file)
            return True
        print(f"agy-turn: agy auth pre-flight exited 0 but {detail}. Run `agy login` in a normal terminal, then retry.", file=sys.stderr)
        rc = 7
        # Fall through to the shared tail below, which echoes the captured output and returns False.
        # That output is the diagnosis — it is what the old success branch deleted.
    except subprocess.TimeoutExpired:
        # GH-375 follow-up: a timeout whose captured output ALREADY says agy could not open a TTY is
        # the same failure as the fast TTY exit, only slower — it says nothing about auth, so it must
        # not block a lane whose `agy -p` works. A timeout with anything else, including silence, is
        # still fatal: that is the shape of a real hang on an interactive login prompt, which is what
        # this branch was written for. See agy_auth_timeout_verdict.
        t_severity, t_detail = agy_auth_timeout_verdict(out_file)
        if t_severity == "unverifiable":
            _record_auth_unverified(t_detail)
            print(f"agy-turn: NOTE — agy auth is unverifiable headless (expected, via timeout); proceeding. {_AUTH_PROBE_FINDING}",
                  file=sys.stderr)
            print("agy-turn: continuing; the auth probe could not run headless, so it is not a usable "
                  "auth check here. If the turn fails on credentials, run `agy login` in a normal terminal.",
                  file=sys.stderr)
            if os.path.exists(out_file): os.remove(out_file)
            return True
        print(f"agy-turn: agy auth pre-flight timed out after {secs}s; {t_detail}. Run `agy login` in a normal terminal, then retry.", file=sys.stderr)
        rc = 7
    except subprocess.CalledProcessError as e:
        # #130: a non-zero probe exit used to be a credentials failure by definition — but the
        # output was already captured (stdout/stderr fold into out_file before the exit status is
        # even known), and agy 1.1.18 has no `whoami` subcommand: it exits 2 with a usage error,
        # the lane dies before the turn runs, and the remedy ("run `agy login`") is wrong because
        # auth was never the question. Route the captured output through the same verdict as the
        # exit-0 path: a probe the CLI rejected is `unverifiable` and non-blocking; anything the
        # verdict calls a real error — or nothing recognizable at all — keeps the old fatal branch,
        # because a non-zero exit WITH no usage/TTY shape is still the conservative failure.
        severity, detail = agy_auth_output_verdict(out_file)
        if severity == "unverifiable":
            _record_auth_unverified(detail)
            print(f"agy-turn: NOTE — agy auth is unverifiable headless (expected, probe exited "
                  f"{e.returncode} on a usage error); proceeding. {_AUTH_PROBE_FINDING}",
                  file=sys.stderr)
            if os.path.exists(out_file): os.remove(out_file)
            return True
        if severity:
            print(f"agy-turn: agy auth pre-flight failed (exit {e.returncode}); {detail}. Run `agy login` in a normal terminal, then retry.", file=sys.stderr)
        else:
            print(f"agy-turn: agy auth pre-flight failed (exit {e.returncode}, no recognizable diagnostic). Run `agy login` in a normal terminal, then retry.", file=sys.stderr)
        rc = e.returncode
    except Exception as e:
        print(f"agy-turn: agy auth pre-flight failed. Run `agy login` in a normal terminal, then retry.", file=sys.stderr)
        rc = 5
    finally:
        # GH-426: remove the throwaway probe CWD on EVERY path, including the ones that `return True`
        # above. Kept non-fatal and reported rather than silent: if the probe wrote something in
        # there, that is the one signal that the agent binary touches its working directory, which is
        # the assumption this whole change exists to stop relying on.
        try:
            leftovers = os.listdir(probe_cwd)
            if leftovers:
                print(f"agy-turn: NOTE — the auth probe wrote {len(leftovers)} path(s) into its "
                      f"throwaway CWD ({', '.join(sorted(leftovers)[:5])}). Discarded. Before GH-426 "
                      f"this would have landed in the harness working tree.", file=sys.stderr)
            shutil.rmtree(probe_cwd, ignore_errors=True)
        except Exception:
            pass

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

    secs = int(os.environ.get("AGY_AUTH_TIMEOUT_S", AGY_AUTH_TIMEOUT_DEFAULT_S))
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
    if "-h" in sys.argv[1:] or "--help" in sys.argv[1:]:
        print("Usage: agy-turn.py")
        print("Required environment variables: RELAY_AGENT, RELAY_FILE, RELAY_TASK")
        sys.exit(0)

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
    # GH-113 proposed fix 1: prompt reinforcement. Prose is not a guarantee (that is why the
    # mechanical rtl_scratch_relocate half exists in relay-turn-lib.sh), but naming the failure
    # mode and the sanctioned location at the point of use removes the "I didn't know" shape.
    prompt = (
        "SCRATCH DISCIPLINE (hard requirement, GH-113): every probe script, test file, or temporary "
        "output you create must be written under $TMPDIR or the repo's .relay-scratch/ directory — "
        "NEVER the repository root. A root-level scratch file (tmp.json, fix_*.py, test_*.py, ...) is "
        "auto-relocated out of the tree by containment and reported; an off-lane edit to a TRACKED "
        "file still fails the whole turn at exit 6.\n\n" + prompt)
    drift_brief = rtl.drift_brief(me, tick_repo_root)
    if drift_brief:
        prompt = drift_brief + "\n" + prompt
    tick_repo_root, _tick_bin = claim_task_or_exit(root, xyz_root, f, allow_paths, t, me, "agy-turn")

    # GH-161 parity fix: codex-turn.py already uses rtl_default_log (persistent, gitignored
    # relay-system/logs/<day>/... — survives past the turn); this port was missed, the same gap
    # found and fixed in aider-turn.py/aider-turn.sh.
    agy_log = os.environ.get("AGY_LOG") or rtl_default_log(root, "agy-turn", t)
    
        # GH-320: this default MUST match the Bash twin's `${RELAY_TURN_TIMEOUT_S:-N}` and the
    # ceiling its header documents. It read 300 while the twin said 900, and since Python is the
    # executing lane every turn was silently capped at a fraction of the documented budget —
    # observed live as an exit-7 kill on a review turn that had 900s on paper.
    turn_timeout = int(os.environ.get("RELAY_TURN_TIMEOUT_S", 900))
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
    # GH-308 port: the Bash twin does `: "${TICK_REPO_ROOT:=$ROOT}"; export TICK_REPO_ROOT` at the top,
    # so the agy child (which runs `tick` mid-turn) ALWAYS inherits TICK_REPO_ROOT=root. Python only set
    # it inside the worktree-isolation branch, so on the default non-worktree lane a cross-repo run
    # (AGY_TURN_ROOT != CWD) left agy's mid-turn `tick` resolving against its CWD instead of the target.
    run_env["TICK_REPO_ROOT"] = tick_repo_root

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
    
    # Sample the turn while it runs so an exit-7 timeout can be attributed to a
    # cause. A reviewer turn hits the same modal-dialog hazard as a builder: it
    # reads the target's files and can trip a credential prompt just as easily.
    # RELAY_DIAG_INTERVAL_S is a test hook (tightens the sample cadence so an
    # idle kill is reachable in seconds, not at the 10s production cadence).
    diag = TurnDiagnostics(worktree=run_cwd,
                           interval=float(os.environ.get("RELAY_DIAG_INTERVAL_S", "0") or 10.0))
    diag.start()
    # GH-492: the wall cap alone cannot contain the observed failure. A 900s hang burned its
    # entire budget at cpu=0.02s/s with worktree-progress=no, and the verdict was unanimous
    # from the first samples — the run spent 900s to learn what it knew in 30. So the turn is
    # bounded by BOTH an idle threshold and the wall cap, and `subprocess.run(timeout=)` is
    # replaced by an explicit poll loop because a blocking call cannot consult the sampler it
    # is being measured by.
    #
    # RELAY_TURN_IDLE_S=0 disables the idle bound and restores pure wall-cap behaviour.
    # This host has no GNU `timeout`/`gtimeout`, so the bound is implemented in-process
    # rather than by wrapping the command — see the capture doc.
    idle_cap = int(os.environ.get("RELAY_TURN_IDLE_S", RELAY_TURN_IDLE_DEFAULT_S))
    idle_killed = False
    # GH-114: blocker evidence captured at the moment the idle bound fires, BEFORE the kill —
    # _probe_idle_blocker reads the transcript tail and the live process tree, and both stop
    # being readable once the group is signalled. (blocker, detail); None = probe never ran.
    idle_blocker = None
    # Hoisted out of the try: the exit-7 reporting below reads it, and a launch failure
    # would otherwise raise NameError inside the error path — turning a clean exit 5 into
    # a crash with no attribution, which is this issue's own complaint.
    started = time.monotonic()
    # GH-114: run `agy -p` under a pty by default. The CLI's bubbletea TUI opens /dev/tty (or
    # requires a TTY on stdin) even in -p mode; with pipes/DEVNULL it periodically wedged at
    # ~0 CPU until the idle watchdog killed it, and its own transcript said why: "bubbletea:
    # could not open TTY". AGY_PTY=0 restores the old pipe behaviour (the fallback the
    # attribution probe still names, for the case where a pty itself fails or is refused).
    use_pty = os.environ.get("AGY_PTY", "1") != "0"
    pty_master = None
    pty_slave = None
    pty_reader = None
    try:
        log_f = open(agy_log, "w")
        try:
            if use_pty:
                pty_master, pty_slave = pty.openpty()
                proc = subprocess.Popen(cmd, env=run_env, cwd=run_cwd,
                                        stdin=pty_slave, stdout=pty_slave, stderr=pty_slave,
                                        start_new_session=True, close_fds=True)
                os.close(pty_slave)
                pty_slave = None
                def _pty_drain(master=pty_master, sink=log_f):
                    # Drain the pty master into the transcript, normalizing the ONLCR \r\n
                    # the tty line discipline inserts back to \n so downstream greps and
                    # readers see byte-identical content to the old pipe path.
                    while True:
                        try:
                            chunk = os.read(master, 65536)
                        except (OSError, ValueError):
                            return
                        if not chunk:
                            return
                        sink.write(chunk.replace(b"\r\n", b"\n").decode("utf-8", "replace"))
                        sink.flush()
                pty_reader = threading.Thread(target=_pty_drain, name="agy-pty-drain", daemon=True)
                pty_reader.start()
            else:
                proc = subprocess.Popen(cmd, env=run_env, cwd=run_cwd, stdout=log_f,
                                        stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
                                        start_new_session=True)
            while True:
                rc = proc.poll()
                if rc is not None:
                    bounded_rc = rc if rc == 0 else rc
                    break
                elapsed = time.monotonic() - started
                if elapsed >= turn_timeout:
                    idle_blocker = _probe_idle_blocker(proc, agy_log)
                    _kill_turn_group(proc)
                    bounded_rc = 7
                    break
                if idle_cap > 0:
                    _idle = diag.idle_seconds()
                    # `None` is "not measured yet", never "not idle" — see idle_seconds().
                    if _idle is not None and _idle >= idle_cap:
                        idle_blocker = _probe_idle_blocker(proc, agy_log)
                        _kill_turn_group(proc)
                        bounded_rc = 7
                        idle_killed = True
                        break
                time.sleep(TURN_POLL_S)
        finally:
            # Close the master FIRST: the drain thread's blocking read then returns/raises
            # and the join below can reap it. Order matters — join-then-close deadlocks.
            if pty_master is not None:
                try:
                    os.close(pty_master)
                except OSError:
                    pass
            if pty_slave is not None:   # only non-None when Popen itself failed post-openpty
                try:
                    os.close(pty_slave)
                except OSError:
                    pass
            if pty_reader is not None:
                pty_reader.join(timeout=3)
            log_f.close()
    except Exception:
        bounded_rc = 5
    finally:
        diag.stop()

    if wt:
        off_lane = rtl.worktree_end(wt)
        if off_lane:
            print("agy-turn: agy made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)", file=sys.stderr)
            sys.exit(6)
        # GH-178 B1, narrowed by GH-410: this used to exit 5 and throw the turn away.
        #
        # The verdict is `worktree_end` above — it diffs the worktree's git state, so it observes
        # writes that actually happened, and every shim enforces it identically. What follows only
        # observes whether the transcript NAMED the root, which is a different question: an agent
        # that quietly touched the real tree without naming it was never caught here, and one that
        # merely cited a path in a finding was failed for it. Measured in a single run, same builder
        # and isolation settings: the phase with TEN repo-root mentions was Approved, the one with
        # NINE failed three times running.
        #
        # The cost was asymmetric. A builder losing a turn loses regenerable work; a reviewer losing
        # one loses a VERDICT — in the reported case a review that had already written
        # `STATUS: Approved` was discarded and the chain halted. A heuristic that destroys completed
        # work must fail toward keeping it.
        #
        # It is now advisory: recorded on the transcript and stderr so an operator still sees it,
        # and it never changes the turn's outcome.
        # Deliberately NOT gated on `bounded_rc == 0` (agy QA, GH-410): the old check ran only on a
        # successful turn, so an agent that timed out or errored *after* citing the root produced no
        # signal at all — withholding the note from exactly the runs most likely to need explaining.
        # The advisory changes no outcome, so there is nothing to gate.
        mentions, first_line = narration_mentions_root(agy_log, root)
        if mentions:
            print(f"agy-turn: ADVISORY — agy's transcript names the real repo root ({root}) on "
                  f"{mentions} line(s); first: {first_line[:120] if first_line else ''}. This is "
                  "NOT a containment verdict: naming a path is not accessing one, and the "
                  "harness's own retry preamble renders absolute paths into the relay file. "
                  "Out-of-worktree WRITES are enforced separately and did not occur (GH-410).",
                  file=sys.stderr)
            try:
                with open(agy_log, "a") as log_f:
                    log_f.write(
                        f"\n[ADVISORY] transcript names the real repo root on {mentions} line(s). "
                        "Not a containment failure — out-of-worktree writes are checked against the "
                        "worktree's git state and none were found (GH-410).\n")
            except OSError:
                pass

    if bounded_rc == 7:
        # Exit code stays 7 for callers; the reason names WHY. GH-492: the BOUND that fired is
        # now stated separately from the CAUSE the sampler attributes, because they answer
        # different questions — "why did the harness stop it" vs "what was it doing". Three
        # causes and two bounds stay independently readable, as GH-390 established.
        _reason, _detail = diag.classify()
        if idle_blocker is not None:
            _blk, _blk_detail = idle_blocker
            _blk_line = (f"agy-turn: idle-blocker attribution: blocker={_blk} — {_blk_detail}")
            print(_blk_line, file=sys.stderr)
            try:
                with open(agy_log, "a") as log_f:
                    log_f.write(f"\n[GH-114 idle-blocker] blocker={_blk} — {_blk_detail}\n")
            except OSError:
                pass
        if idle_killed:
            print(f"agy-turn: agy -p was IDLE for >={idle_cap}s (no CPU, no worktree progress) — "
                  f"killed early at ~{int(time.monotonic() - started)}s of a {turn_timeout}s wall cap "
                  f"[{_reason}]", file=sys.stderr)
            print("agy-turn: this is an EXTERNAL condition the harness detected and contained, not one "
                  "it prevented — agy stopped making progress and the harness stopped waiting. "
                  "Nothing here fixes agy; the observed 2026-08-10 hang recovered on its own.",
                  file=sys.stderr)
        else:
            print(f"agy-turn: agy -p exceeded {turn_timeout}s wall-clock cap — killed [{_reason}]", file=sys.stderr)
        print(f"agy-turn: timeout attribution: {_detail}", file=sys.stderr)
    elif bounded_rc != 0:
        print(f"agy-turn: agy -p failed (exit {bounded_rc})", file=sys.stderr)

    if bounded_rc != 0 and _AUTH_UNVERIFIED_DETAIL:
        # GH-492 criterion 3: the same fact, at the level it has earned. On a healthy turn this was
        # a NOTE nobody needed; on a FAILED turn it is a live hypothesis, because an expired agy
        # session is exactly what the pre-flight could not rule out — and on 2026-08-10 that is what
        # it turned out to be, twice. Only reachable on failure, so it can never be tuned out.
        print(f"agy-turn: auth was NEVER VERIFIED for this turn, and the turn failed — {_AUTH_UNVERIFIED_DETAIL}",
              file=sys.stderr)
        print(f"agy-turn: {_AUTH_PROBE_FINDING}", file=sys.stderr)

    if bounded_rc == 0 and (not os.path.exists(agy_log) or os.path.getsize(agy_log) == 0):
        print("agy-turn: agy -p exited 0 but produced NO output — likely a blocked backend (run sandbox-OFF). Failing the turn.", file=sys.stderr)
        # GH-432 (agy review): set the failure instead of exiting on it. This branch is the harness
        # DECLARING the turn failed, so it leaks exactly what the crash path leaked — it just reached
        # the leak by a different route. Falling through to enforce below is what makes the fix
        # complete; an early exit here would have left a blocked backend still stalling the relay.
        bounded_rc = 5
        
    # GH-432: a failed turn still reaches rtl_enforce, so its work is committed and its token handed
    # off instead of leaking. See utils/py/claude-turn.py for the full rationale. Exit 5 is unchanged.
    rc = rtl.enforce(t, me, agy_log, "agy")

    try:
        from harness_turn_logger import HarnessTurnLogger
        with HarnessTurnLogger(
            harness_id="agy",
            shim="agy-turn.py",
            task_scope=t,
            model_id=os.environ.get("AGY_MODEL", "antigravity/gemini-2.5-pro"),
            gateway=os.environ.get("AGY_GATEWAY", "google"),
            reasoning_effort=os.environ.get("AGY_REASONING_EFFORT", "high"),
            cli_flags=os.environ.get("AGY_FLAGS", "").split(),
            repo_root=xyz_root,
        ) as logger:
            logger.exit_code = bounded_rc or rc
    except Exception:
        pass

    if bounded_rc == 7:
        sys.exit(7)
    if bounded_rc != 0:
        sys.exit(5)

    sys.exit(rc)

if __name__ == "__main__":
    main()
