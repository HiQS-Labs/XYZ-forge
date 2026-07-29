import argparse
import os
import sys
import subprocess
import time
import re
import shlex
import shutil
import json
import tempfile
import threading
import datetime as _dt

# GH-284 Phase 2 / GH-322: hooks run on EVERY terminal path with the driver's real exit code — the
# Python equivalent of marathon-drive.sh's `trap _marathon_drive_on_exit EXIT`. Same contract as
# that trap: the code is captured FIRST and re-exited explicitly, so nothing a hook does can
# overwrite the driven run's real status.
_ON_EXIT = []


# GH-333: the run log used to carry a `driver still running` line that could only ever say
# "running". Dropping it left `driver exit: `3`` as the sole disposition signal — a bare number the
# reader has to look up. Naming it is the half of that field which was actually worth keeping.
#
# Codes 1, 2 and 8 are mapped defensively but cannot appear in a posted run log: lock contention,
# `die()` and the lane-attempt cap all exit BEFORE the run log arms (drive_started).
_EXIT_MEANINGS = {
    0: "approved, gate passed",
    1: "driver lock contention",
    2: "usage or configuration error",
    3: "no-progress escalation",
    4: "round-cap or close-mismatch escalation",
    5: "pre-advance gate failed",
    6: "containment violation — off-lane edit reverted",
    7: "turn timeout / hang",
    8: "lane parked at the attempt cap",
    9: "post-approve command failed, approval preserved",
}


def _exit_meaning(code):
    """Plain-language gloss for a marathon-drive exit code, for the run log.

    Deliberately total: an unmapped code must still render, and must say plainly that it is
    unrecognised rather than silently printing an empty parenthetical that reads like a meaning.
    """
    try:
        code = int(code)
    except (TypeError, ValueError):
        return "unrecognised exit code"
    return _EXIT_MEANINGS.get(code, "unrecognised exit code")


def runlog_find_comment_id(payload_text, marker):
    """Return the id of the run-log comment carrying <marker>, or "" if there is none.

    `gh api --paginate --slurp` yields an ARRAY OF PAGES ([[c,...],[c,...]]); a single page, or a
    non-slurp fallback, yields a flat [c,...]. Accept both — a miss here POSTs a duplicate comment
    instead of updating in place, which is the one property this feature is defined by.

    Deliberately at module scope, not nested in main(): in the Bash twin the equivalent parser could
    only be reached by shipping it to a python3 subprocess, and the INVOCATION shape (`python3 -
    <<EOF` while also piping data in — shellcheck SC2259) silently broke it. The comments JSON was
    prepended to the program text, python died with a SyntaxError, the id came back empty, and the
    run log POSTed a duplicate every single time. test/gh284-runlog-heartbeat.sh missed that for a
    release because it exercised the parser from a FILE, which is not how the driver ran it. Running
    in-process kills the whole failure class, and keeping it importable means a test can exercise the
    real function rather than a reimplementation of it.
    """
    try:
        payload = json.loads(payload_text)
    except Exception:
        payload = []
    comments = []
    if isinstance(payload, list):
        for entry in payload:
            if isinstance(entry, list):
                comments.extend(entry)
            elif isinstance(entry, dict):
                comments.append(entry)
    for comment in comments:
        if isinstance(comment, dict) and marker in str(comment.get("body", "")):
            return str(comment.get("id", ""))
    return ""

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def get_env(key, default=None):
    return os.environ.get(key, default)

def die(msg):
    eprint(f"marathon-drive: {msg}")
    sys.exit(2)

def log(msg):
    print(f"marathon-drive: {msg}")

def _probe_bin(bin_name, role_label, agent_id):
    if shutil.which(bin_name):
        return
    die(f"{role_label} binary '{bin_name}' not found on PATH (--{role_label} agent '{agent_id}')")

def _probe_claude_bin(role_label):
    claude_bin = get_env("CLAUDE_BIN")
    if claude_bin:
        if shutil.which(claude_bin):
            return
    else:
        if shutil.which("claude"):
            return
        local_claude = os.path.join(os.path.expanduser("~"), ".claude", "local", "claude")
        if os.access(local_claude, os.X_OK):
            return
    die(f"{role_label} binary 'claude' not found on PATH (set CLAUDE_BIN or use a codex/agy --{role_label} agent)")

def _probe_agent_bin(agent_id, role_label):
    # GH-117: fail before any tick mutation or clean-workspace scan if the lane's
    # builder/reviewer binary would be undispatchable.
    if agent_id.startswith("claude"):
        _probe_claude_bin(role_label)
    elif agent_id.startswith("codex"):
        _probe_bin(get_env("CODEX_BIN", "codex"), role_label, agent_id)
    elif agent_id.startswith("agy"):
        _probe_bin(get_env("AGY_BIN", "agy"), role_label, agent_id)
    elif agent_id.startswith("aider"):
        _probe_bin(get_env("AIDER_BIN", "aider"), role_label, agent_id)

def main():
    parser = argparse.ArgumentParser(description="marathon-drive", add_help=False)
    parser.add_argument("--phase-brief", dest="phase_brief_file")
    parser.add_argument("--builder", dest="builder", default="codex")  # GH-212: no per-call API charge
    parser.add_argument("--reviewer", dest="reviewer")
    parser.add_argument("--round-cap", dest="round_cap", type=int, default=5)
    parser.add_argument("--pre-advance-cmd", dest="pre_advance_cmd")
    parser.add_argument("--post-approve-cmd", dest="post_approve_cmd")
    parser.add_argument("--phases-dir", dest="phases_dir")
    parser.add_argument("--phase-id", dest="phase_id", default="p1")
    parser.add_argument("--relay-task", dest="relay_task")
    parser.add_argument("--artifact", dest="artifact_paths")
    parser.add_argument("--target-root", dest="target_root")
    parser.add_argument("--require-clean", dest="require_clean", action="store_true")
    parser.add_argument("--requires-test", dest="requires_test")  # GH-249: nominated test must change
    parser.add_argument("--force", dest="force", action="store_true")
    parser.add_argument("--dry-run", dest="dry_run", action="store_true")
    parser.add_argument("--log-github", dest="log_github", action="store_true")  # GH-284 P2 / GH-322
    parser.add_argument("--help", action="store_true")

    args, unknown = parser.parse_known_args()
    if args.help:
        print("Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]")
        print("  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh).")
        print("  --post-approve-cmd CMD  Optional command after phase.approved + green telemetry (default: unset).")
        print("                           Failure preserves approval, writes reason post-approve-failed, and exits 9.")
        print("  --log-github            GH-284 opt-in run log (default OFF). Updates the lane's EXISTING GitHub")
        print("                          issue in place via a marker comment — never creates an issue, never closes")
        print("                          one. A missing/unauthenticated gh degrades to local telemetry only.")
        sys.exit(0)

    # GH-322: `unknown` was captured and never read, so ANY unrecognised flag was silently
    # discarded. Because Python is the executing lane (GH-264), that made `--log-github` — the
    # headline feature of GH-284 Phase 2, which existed only in the Bash twin — a no-op: the marathon
    # ran, exited 0, reported success, and never posted a run log. All three Bash twins `die
    # "unknown argument: $1"`; this restores that contract byte-for-byte (same prefix, same exit 2).
    # Checked AFTER --help so `--help` still works alongside a bad flag.
    # (--log-github is now a real flag on this lane too — see marathon_run_github_log below. The
    # temporary "re-run with XYZ_PYTHON=0" message this branch used to carry is gone with the port.)
    if unknown:
        die(f"unknown argument: {unknown[0]}")

    if not args.phase_brief_file:
        eprint("Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]")
        die("--phase-brief FILE required")
    if not os.path.isfile(args.phase_brief_file):
        die(f"phase brief not found: {args.phase_brief_file}")
    if not args.reviewer:
        eprint("Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]")
        die("--reviewer AGENT required")
    if not args.builder:
        die("--builder cannot be empty")
    if not args.phase_id:
        die("--phase-id cannot be empty")

    if args.target_root:
        try:
            subprocess.run(["git", "-C", args.target_root, "rev-parse", "--show-toplevel"], 
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        except subprocess.CalledProcessError:
            die(f"invalid --target-root (not a git repo): {args.target_root}")

    here = os.path.dirname(os.path.abspath(__file__))
    xyz_harness = os.path.abspath(os.path.join(here, "..", ".."))
    if os.path.basename(xyz_harness) == ".xyz":
        default_root = os.path.abspath(os.path.join(xyz_harness, ".."))
    else:
        default_root = xyz_harness
    
    root = get_env("MARATHON_ROOT", default_root)
    tick_bin = get_env("TICK_BIN", os.path.join(xyz_harness, "bin", "tick"))
    relay_drive_bin = get_env("MARATHON_RELAY_DRIVE", os.path.join(xyz_harness, "relay-automation", "relay-drive.sh"))
    agent_cmd = get_env("MARATHON_AGENT_CMD", os.path.join(xyz_harness, "relay-automation", "marathon-agent.sh"))

    def _lane_key(raw):
        return re.sub(r'[^A-Za-z0-9._-]', '_', raw)

    def lane_attempt_gate(root_dir, raw, force):
        if get_env("LANE_ATTEMPT_COUNTED"): return 0
        if not raw: return 0
        max_attempts = get_env("LANE_MAX_ATTEMPTS", "2")
        try: max_attempts = int(max_attempts)
        except ValueError: max_attempts = 2

        key = _lane_key(raw)
        attempts_dir = os.path.join(root_dir, ".tick", "attempts")
        os.makedirs(attempts_dir, exist_ok=True)
        attempts_file = os.path.join(attempts_dir, key)

        count = 0
        if os.path.isfile(attempts_file):
            try:
                with open(attempts_file, "r") as f:
                    count = len(f.readlines())
            except Exception:
                pass
        
        if force:
            eprint(f"lane-attempt-cap: --force override — lane {key} at {count} attempt(s) (cap {max_attempts}), proceeding.")
        elif count >= max_attempts:
            eprint(f"lane-attempt-cap: lane {key} PARKED after {count} attempt(s) (cap {max_attempts}) — no relay token seeded.")
            eprint(f"  Re-anchor to the committed QUEUE lanes (AGENTS.md) or re-fire with --force. Attempts log: {attempts_file}")
            sys.exit(8)

        # append fire
        ts = "fire"
        try:
            ts = subprocess.check_output(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
        except:
            pass
        with open(attempts_file, "a") as f:
            f.write(f"{ts} fire\n")
        return 0

    def lane_attempt_reset(root_dir, raw):
        if get_env("LANE_ATTEMPT_COUNTED"): return
        if not raw: return
        attempts_file = os.path.join(root_dir, ".tick", "attempts", _lane_key(raw))
        if os.path.exists(attempts_file):
            try: os.remove(attempts_file)
            except: pass

    def debug_mantra_prior_attempts(root_dir, raw):
        # GH-162: READ-ONLY peek at the .tick/attempts/<lane> file GH-45 maintains — how many prior
        # fires on this lane did not reach Approved. Never writes.
        f = os.path.join(root_dir, ".tick", "attempts", _lane_key(raw))
        if os.path.isfile(f):
            try:
                with open(f) as fh:
                    return sum(1 for _ in fh)
            except Exception:
                return 0
        return 0

    def debug_mantra_note(prior, phase_dir_, mantra_file):
        # GH-162: the note injected into the relay when a prior attempt exists; empty on a first fire
        # (prior=0) so a normal first-fire relay file stays byte-identical to before this feature.
        if not prior or prior < 1:
            return ""
        reason = ""
        esc = os.path.join(phase_dir_, "ESCALATION.md")
        if os.path.isfile(esc):
            try:
                with open(esc) as fh:
                    for line in fh:
                        if line.startswith("reason:"):
                            reason = line.split(":", 1)[1].strip()
                            break
            except Exception:
                pass
        out = (f"\n## Debug mantra (auto-triggered — {prior} prior attempt(s) on this phase did not reach Approved)\n\n"
               f"Before trying again, read {mantra_file} and follow its four-step discipline: reproduce reliably, "
               f"know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.\n")
        if reason:
            out += f"Last recorded reason ({phase_dir_}/ESCALATION.md): `{reason}`. Read it before re-guessing.\n"
        return out

    if get_env("RELAY_DRIVER_LOCKED", "0") != "1":
        # GH-49b/GH-207: the lock lives in .git/ (never committed) for a normal clone. In a linked
        # worktree .git is a FILE pointing at the shared gitdir, so resolve the real common dir and put
        # the lock there — otherwise --require-clean sees the driver's own lock as untracked dirt inside
        # the worktree. A vendored .xyz/ copy (no .git) falls back to a hidden lock beside the scripts.
        git_path = os.path.join(root, ".git")
        if os.path.isdir(git_path):
            lock_dir = os.path.join(root, ".git", "relay-driver.lock")
            lock_label = ".git/relay-driver.lock"
        elif os.path.isfile(git_path):
            common = ""
            try:
                common = subprocess.check_output(
                    ["git", "-C", root, "rev-parse", "--git-common-dir"],
                    stderr=subprocess.DEVNULL).decode('utf-8').strip()
            except Exception:
                common = ""
            if common:
                if not os.path.isabs(common):
                    common = os.path.join(root, common)
                lock_dir = os.path.join(common, "relay-driver.lock")
                lock_label = ".git/relay-driver.lock"
            else:
                lock_dir = os.path.join(root, ".relay-driver.lock")
                lock_label = ".relay-driver.lock"
        else:
            lock_dir = os.path.join(root, ".relay-driver.lock")
            lock_label = ".relay-driver.lock"
        
        try:
            os.mkdir(lock_dir)
        except OSError:
            holder = ""
            pid_file = os.path.join(lock_dir, "pid")
            if os.path.isfile(pid_file):
                try:
                    with open(pid_file, 'r') as f: holder = f.read().strip()
                except: pass
            
            is_running = False
            if holder:
                try:
                    os.kill(int(holder), 0)
                    is_running = True
                except: pass
            
            if is_running:
                eprint(f"marathon-drive: another driver is active in this repo (pid {holder}, lock: {lock_label}).")
                eprint("marathon-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).")
                sys.exit(1)
            
            eprint(f"marathon-drive: reclaiming stale relay-driver.lock (holder pid {holder or 'none'} not running).")
            try:
                shutil.rmtree(lock_dir)
                os.mkdir(lock_dir)
            except:
                eprint("marathon-drive: could not acquire relay-driver.lock after reclaiming a stale one.")
                sys.exit(1)
        
        with open(os.path.join(lock_dir, "pid"), 'w') as f:
            f.write(str(os.getpid()) + "\n")
        
        os.environ["RELAY_DRIVER_LOCKED"] = "1"
        def cleanup_lock():
            try: shutil.rmtree(lock_dir)
            except: pass
        import atexit
        atexit.register(cleanup_lock)

    xyz_append_bin = get_env("XYZ_APPEND_BIN", os.path.join(xyz_harness, "utils", "telemetry", "append-xyz-completion.sh"))

    def xyz_marathon_emit(health, desc):
        ctx = get_env("XYZ_HARNESS_CONTEXT", "")
        if ctx == "marathon-phase": return
        if not os.access(xyz_append_bin, os.X_OK): return
        
        harness = "swarm" if ctx == "swarm" else "marathon"
        title = os.path.splitext(os.path.basename(args.phase_brief_file))[0]
        if not title: title = args.phase_id
        
        sid = get_env("XYZ_SESSION_ID", args.phase_id)
        subprocess.run([xyz_append_bin, harness, sid, health, title, desc], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # GH-75/GH-249 lifecycle heartbeat: write operational liveness before driving the relay and clear
    # it on any terminal path (registered via atexit right after the write, so every success/failure
    # branch clears it). Best-effort — never changes marathon-drive's exit code. Mirrors Bash
    # xyz_marathon_heartbeat_write/clear (relay-automation/marathon-drive.sh).
    xyz_heartbeat_bin = get_env("XYZ_HEARTBEAT_BIN", os.path.join(xyz_harness, "utils", "telemetry", "write-xyz-heartbeat.sh"))

    def _heartbeat(clear):
        if not os.access(xyz_heartbeat_bin, os.X_OK):
            return
        ctx = get_env("XYZ_HARNESS_CONTEXT", "")
        harness = "swarm" if ctx == "swarm" else "marathon"
        sid = get_env("XYZ_SESSION_ID", args.phase_id)
        env = os.environ.copy()
        if clear:
            env["XYZ_HEARTBEAT_CLEAR"] = "1"
        try:
            subprocess.run([xyz_heartbeat_bin, harness, sid], env=env,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass

    def xyz_marathon_heartbeat_write():
        _heartbeat(clear=False)

    def xyz_marathon_heartbeat_clear():
        _heartbeat(clear=True)

    phases_dir = args.phases_dir or os.path.join(root, "phases")
    # GH-319: the default gate is interpolated into a string that run_pre_advance_gate() hands to
    # `bash -c`, so an UNQUOTED root word-splits on any space in the repo path. Observed live: a
    # clone at ".../Documents/GH Repos/xyz-3-agents-swarm" produced `bash /Users/.../Documents/GH
    # Repos/.../validate.sh`, bash executed the unrelated 0-byte file `/Users/.../Documents/GH`, and
    # the gate returned 0 in 0.0s. Every phase of a 4-lane marathon reported "gate passed" while
    # validate.sh was in fact RED. shlex.quote is the fix; the preflight below already knew to strip
    # quotes off the script arg, it was just never given a quoted default to strip.
    # GH-268 item 8: a cross-repo lane had NO GATE. The default gate is this repo's validate.sh, and
    # a foreign --target-root usually has none, so GH-238's runnability preflight refused the whole
    # lane ("script file does not exist") — leaving the operator to either pass an explicit
    # --pre-advance-cmd or run ungated. The beta report is what that costs: a Producer/Reviewer loop
    # reached "Approved" while an independent audit of the same branch found 20 issues (1 critical,
    # 4 high) in the file the relay built on. relay-automation/target-checks.sh knows how to ask a
    # foreign repo for its OWN checks (php -l, phpcs, npm lint/test, pytest, ruff, make test), so a
    # cross-repo lane gets a real gate by default instead of no gate. An explicit --pre-advance-cmd
    # always wins.
    #
    # Codex cross-vendor consult (GH-268 item 9) found the first draft claimed "a target that HAS its
    # own validate.sh keeps using it" while the code did the opposite — that case fell to the else
    # branch and ran the HARNESS's validate.sh against a foreign repo. Both branches below now use
    # the target's own path when --target-root is set.
    #
    # target_root is absolutised first: run_pre_advance_gate() executes with cwd=target_root, so a
    # RELATIVE --target-root would be resolved twice — once to set cwd, then again from inside it.
    _target_root = os.path.abspath(args.target_root) if args.target_root else None
    if args.pre_advance_cmd:
        pre_advance_cmd = args.pre_advance_cmd
    elif _target_root and os.path.isfile(os.path.join(_target_root, "validate.sh")):
        pre_advance_cmd = f"bash {shlex.quote(os.path.join(_target_root, 'validate.sh'))}"
        log(f"--target-root has its own validate.sh — gating on it: {pre_advance_cmd}")
    elif _target_root:
        _tc = os.path.join(os.environ.get("XYZ_ROOT", root), "relay-automation", "target-checks.sh")
        if not os.path.isfile(_tc):
            die(f"--target-root has no validate.sh and target-checks.sh is missing at {_tc}. "
                f"Pass --pre-advance-cmd explicitly rather than running this lane ungated.")
        # --strict: a DETECTED tool that is missing fails the gate instead of silently reducing
        # coverage. Codex's consult named the case — phpcs detected, absent, php -l passes, exit 0
        # "because one check ran" — so the WordPress-security ruleset never runs and the lane still
        # reads green. Strict only here, where the harness CHOSE this gate: an operator who passes
        # --pre-advance-cmd by hand keeps the lenient default and can decide for themselves.
        pre_advance_cmd = f"bash {shlex.quote(_tc)} run --strict --root {shlex.quote(_target_root)}"
        log(f"--target-root has no validate.sh — gating on the target's own checks: {pre_advance_cmd}")
        log("  (--strict: a detected-but-missing tool FAILS rather than silently narrowing the gate;\n   exits 3 when it detects nothing, so 'no checks found' fails rather than passes)")
    else:
        pre_advance_cmd = f"bash {shlex.quote(os.path.join(root, 'validate.sh'))}"
    relay_task = args.relay_task or f"MARATHON-{args.phase_id.upper()}-TURN"
    # GH-207: a marathon lane namespaces its phase paths + attempt state so two lanes sharing a bare
    # phase id (p1) don't collide. Defaults to the phase id when no lane namespace is set.
    lane_state_key = get_env("MARATHON_LANE_NS") or args.phase_id

    # ── GH-284 Phase 2, ported (GH-322) ────────────────────────────────────────────────────────
    # BOTH halves of Phase 2 — the driver heartbeat AND the --log-github run log — existed only in
    # relay-automation/marathon-drive.sh. That twin `exec`s this file at its own line 18, long before
    # it installs the EXIT trap that runs them, so on the default lane (XYZ_PYTHON unset, GH-264)
    # neither one ever executed. #322 scoped this as "the run-log half only, the heartbeat is already
    # in the Python twin (12 references)"; those 12 matches are xyz_marathon_heartbeat_* — the GH-75
    # XYZ.heartbeat.json session record, a different file and a different feature. Before this change
    # `grep -c driver_heartbeat utils/py/marathon_drive.py` was 0, so the observability Phase 2 was
    # built to provide was absent from the lane that actually runs. Both halves are ported here.
    run_gate_result = ["not-run"]
    drive_started = [False]

    def _cmd_out(cmd, cwd=None):
        # Best-effort stdout capture: a missing binary, a non-zero exit, or a crash all yield "".
        # Every probe in the run log is advisory, and none of them may raise into the exit path.
        try:
            res = subprocess.run(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        except Exception:
            return ""
        if res.returncode != 0:
            return ""
        return res.stdout.decode("utf-8", "replace").strip()

    def _utc_now():
        return _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    hb_interval = get_env("MARATHON_DRIVER_HEARTBEAT_INTERVAL", "30")
    try:
        hb_interval = int(hb_interval)
    except (TypeError, ValueError):
        hb_interval = 30
    if hb_interval <= 0:
        hb_interval = 30
    # MARATHON_DRIVER_HEARTBEAT_STALE_AFTER is deliberately not read here (GH-333). Staleness is a
    # question only a READER of the heartbeat file asks, and this lane is the writer; the reader
    # (rtl_driver_heartbeat_status, relay-turn-lib.sh) still honors the variable. The one consumer
    # this file had was the dropped constant field.

    def driver_heartbeat_path():
        # RTL_DRIVER_HEARTBEAT_FILE is the same override relay-turn-lib.sh honors, so an observer (or
        # a test) can point both twins at one file and get one answer.
        return get_env("RTL_DRIVER_HEARTBEAT_FILE") or os.path.join(root, ".tick", "driver-heartbeat.json")

    hb_state = {"started": "", "plan": "", "stop": None, "live": False}

    def driver_heartbeat_write():
        # Same record and the same atomic mkstemp+os.replace as rtl_driver_heartbeat_write, so a
        # heartbeat written by either twin is byte-compatible with readers of the other.
        path = driver_heartbeat_path()
        record = {
            "pid": os.getpid(),
            "started_utc": hb_state["started"],
            "updated_utc": _utc_now(),
            "plan": hb_state["plan"],
            "phase_id": args.phase_id,
            "relay_task": relay_task,
        }
        directory = os.path.dirname(path) or "."
        try:
            os.makedirs(directory, exist_ok=True)
            fd, tmp = tempfile.mkstemp(dir=directory, prefix=".driver-heartbeat.", suffix=".tmp")
            try:
                with os.fdopen(fd, "w") as f:
                    json.dump(record, f, sort_keys=True)
                    f.write("\n")
                os.replace(tmp, path)
            except Exception:
                try:
                    os.unlink(tmp)
                except OSError:
                    pass
                raise
        except Exception:
            return False
        return True

    def driver_heartbeat_clear():
        try:
            os.remove(driver_heartbeat_path())
        except OSError:
            pass

    # GH-333: there is deliberately NO driver_heartbeat_status() here. Its only caller was the run
    # log's `driver still running` field, which could only ever answer "running" — the exit hook
    # asked before clearing the heartbeat, and the PID it tested belonged to the process asking. The
    # field is gone, so the reader would be dead code.
    #
    # The heartbeat FILE is the real deliverable and is unchanged: this lane still writes and clears
    # it, and the reader that observers actually use lives in relay-automation/relay-turn-lib.sh
    # (`rtl_driver_heartbeat_status`), which is a shared runtime dependency, not a frozen twin.
    # Writer here, reader there — which is also why dropping this costs nothing.

    def driver_heartbeat_start():
        hb_state["started"] = _utc_now()
        hb_state["plan"] = get_env("MARATHON_PLAN_NAME") or \
            os.path.splitext(os.path.basename(args.phase_brief_file))[0]
        if not driver_heartbeat_write():
            log("driver heartbeat unavailable — continuing without liveness record")
            return
        hb_state["live"] = True
        # A daemon thread is the Python analogue of the Bash `( while kill -0 $$; do sleep; write;
        # done ) &` subshell: it cannot outlive the driver, and it can never block interpreter exit.
        stop = threading.Event()
        hb_state["stop"] = stop

        def _refresh():
            while not stop.wait(hb_interval):
                driver_heartbeat_write()

        threading.Thread(target=_refresh, daemon=True).start()

    def driver_heartbeat_stop():
        if hb_state["stop"] is not None:
            hb_state["stop"].set()
        if hb_state["live"]:
            driver_heartbeat_clear()

    # The run log is deliberately restricted to comments on an ALREADY-EXISTING lane issue: no
    # `gh issue create`, no close/reopen, and no mutation at all unless --log-github was passed.
    # Every failing gh probe is swallowed so external reporting can never alter the marathon result.
    def lane_issue_number():
        for candidate in (lane_state_key, relay_task, os.path.basename(args.phase_brief_file)):
            m = re.search(r'GH-?([0-9]+)', str(candidate or ""))
            if m:
                return m.group(1)
        return ""

    def trunk_ref():
        ref = _cmd_out(["git", "-C", root, "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD"])
        if ref and ref != "origin/HEAD":
            return ref
        return _cmd_out(["git", "-C", root, "symbolic-ref", "--quiet", "--short", "HEAD"])

    def marathon_run_github_log(driver_exit):
        if not (args.log_github and drive_started[0]):
            return
        if not shutil.which("gh") or subprocess.run(
                ["gh", "auth", "status"], stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL).returncode != 0:
            log("--log-github requested, but gh is unavailable or unauthenticated — local telemetry only")
            return
        issue = lane_issue_number()
        if not issue:
            log(f"--log-github requested, but no GH issue number is derivable for lane {lane_state_key} — local telemetry only")
            return
        # Every gh call MUST be scoped to $root's repository. A bare `gh repo view` / `gh pr view`
        # resolves whatever repo the ambient CWD happens to be in, so a --target-root run, or any
        # invocation from a foreign directory, could post THIS lane's run log into the WRONG
        # repository's issue #N. Derive the slug from root's own remote (no gh call, no CWD
        # dependency); fall back to a gh lookup explicitly executed inside root.
        url = _cmd_out(["git", "-C", root, "remote", "get-url", "origin"])
        repo = re.sub(r'\.git$', '', re.sub(r'^https?://[^/]+/', '', re.sub(r'^git@[^:]+:', '', url)))
        # A local-path remote (file:///…/remote.git — common in tests and vendored clones) survives
        # those substitutions with slashes intact and would otherwise be accepted as a bogus slug,
        # sending every gh call to a repo that does not exist.
        if not re.fullmatch(r'[A-Za-z0-9._-]+/[A-Za-z0-9._-]+', repo):
            repo = _cmd_out(["gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"], cwd=root)
        if not repo:
            log("--log-github requested, but repository lookup failed — local telemetry only")
            return
        branch = _cmd_out(["git", "-C", root, "symbolic-ref", "--quiet", "--short", "HEAD"]) or "(detached)"
        trunk = trunk_ref()
        landed = "no"
        if trunk and subprocess.run(["git", "-C", root, "merge-base", "--is-ancestor", "HEAD", trunk],
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
            landed = "yes"
        pr_url = _cmd_out(["gh", "pr", "view", "--repo", repo, "--head", branch, "--json", "url", "--jq", ".url"]) \
            or "NO PR OPENED"
        plan = hb_state["plan"] or os.path.splitext(os.path.basename(args.phase_brief_file))[0]
        marker = f"<!-- xyz-marathon-run-log:{issue}:{lane_state_key} -->"
        body = (f"{marker}\n"
                f"### Marathon run log\n"
                f"- plan: `{plan}`\n"
                f"- phase: `{args.phase_id}`\n"
                f"- branch: `{branch}`\n"
                f"- trunk (derived): `{trunk}`\n"
                f"- landed on trunk: **{landed}**\n"
                f"- PR: {pr_url}\n"
                f"- per-phase gate: **{run_gate_result[0]}**\n"
                f"- driver exit: `{driver_exit}` ({_exit_meaning(driver_exit)})\n"
                f"- recorded: {_utc_now()}")
        comments = _cmd_out(["gh", "api", "--paginate", "--slurp",
                             f"repos/{repo}/issues/{issue}/comments?per_page=100"])
        comment_id = runlog_find_comment_id(comments, marker)
        if comment_id:
            ok = subprocess.run(["gh", "api", "--method", "PATCH",
                                 f"repos/{repo}/issues/comments/{comment_id}", "-f", f"body={body}"],
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
            log(f"updated GitHub run-log comment on issue #{issue}" if ok
                else "GitHub run-log update failed — local telemetry only")
        else:
            ok = subprocess.run(["gh", "api", "--method", "POST",
                                 f"repos/{repo}/issues/{issue}/comments", "-f", f"body={body}"],
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
            log(f"posted GitHub run-log comment on issue #{issue}" if ok
                else "GitHub run-log post failed — local telemetry only")

    def _marathon_drive_on_exit(code):
        # Same order as the Bash EXIT trap: log first (so the run log can still read a live
        # heartbeat), then stop the heartbeat. Each half is independently guarded — external
        # reporting must never be able to change the driven run's exit code.
        try:
            marathon_run_github_log(code)
        except Exception as exc:
            log(f"GitHub run log raised ({exc.__class__.__name__}) — local telemetry only")
        try:
            driver_heartbeat_stop()
        except Exception:
            pass

    _ON_EXIT.append(_marathon_drive_on_exit)

    # GH-238: a vendored consumer normally has no root-level validate.sh. Do NOT spend a builder and
    # reviewer turn only to discover the default gate can't start after approval. A deliberately
    # non-executing probe (gates like `test -f build/output` only become true after the builder runs):
    # prove the gate is *runnable*, not that it currently passes. Runs before any render/tick/dispatch.
    _gate_root = args.target_root or root
    def _pre_advance_not_runnable(reason):
        die(f"pre-advance gate not runnable: '{pre_advance_cmd}' ({reason}). "
            f"Pass --pre-advance-cmd '<runnable command>' to override it.")
    def _preflight_pre_advance_gate():
        if subprocess.run(["bash", "-n", "-c", pre_advance_cmd],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
            _pre_advance_not_runnable("shell syntax is invalid")
        # GH-319: tokenize the way the shell will. A regex `(\S+)` capture cannot see a quoted path
        # that contains a space — it grabs the leading fragment, which on this machine happened to be
        # a real 0-byte file, so the "is the gate runnable?" check passed on the WRONG file. shlex
        # splits `bash '/a b/validate.sh'` into two tokens, so the same check now inspects the file
        # the shell would actually execute. Fall back to naive split only if the string is unparsable
        # (unbalanced quotes) — that case is caught by the `bash -n` syntax check just above anyway.
        try:
            tokens = shlex.split(pre_advance_cmd)
        except ValueError:
            tokens = pre_advance_cmd.split()
        if tokens and re.fullmatch(r'bash|/\S*/bash', tokens[0]) and len(tokens) > 1:
            gate_shell, script_arg = tokens[0], tokens[1]
            if not shutil.which(gate_shell):
                _pre_advance_not_runnable(f"interpreter '{gate_shell}' is not on PATH")
            if script_arg.startswith("-"):
                return
            gate_path = script_arg if os.path.isabs(script_arg) else os.path.join(_gate_root, script_arg)
            if not os.path.isfile(gate_path):
                _pre_advance_not_runnable(f"script file does not exist: {gate_path}")
            return
        parts = tokens
        command_name = parts[0] if parts else ""
        if not command_name:
            _pre_advance_not_runnable("command is empty")
        if "/" in command_name:
            gate_path = command_name if os.path.isabs(command_name) else os.path.join(_gate_root, command_name)
            if not (os.path.isfile(gate_path) and os.access(gate_path, os.X_OK)):
                _pre_advance_not_runnable(f"executable does not exist or is not executable: {gate_path}")
        else:
            if not shutil.which(command_name):
                _pre_advance_not_runnable(f"command '{command_name}' is not on PATH")

    os.environ["MARATHON_BUILDER"] = args.builder
    os.environ["MARATHON_REVIEWER"] = args.reviewer
    os.environ["CLAUDE_AGENT"] = ""
    os.environ["CODEX_AGENT"] = ""
    os.environ["AGY_AGENT"] = ""
    os.environ["AIDER_AGENT"] = ""

    def route_agent(agent_id):
        if agent_id.startswith("claude"): os.environ["CLAUDE_AGENT"] = agent_id
        elif agent_id.startswith("codex"): os.environ["CODEX_AGENT"] = agent_id
        elif agent_id.startswith("agy"): os.environ["AGY_AGENT"] = agent_id
        elif agent_id.startswith("aider"): os.environ["AIDER_AGENT"] = agent_id
        else: die(f"agent '{agent_id}' not recognized — must start with claude/codex/agy/aider")
        
    if args.builder == args.reviewer:
        die(f"builder and reviewer must be different agent ids (got '{args.builder}' for both)")
        
    route_agent(args.builder)
    route_agent(args.reviewer)
    
    if not (args.reviewer.startswith("codex") or args.reviewer.startswith("gemini") or args.reviewer.startswith("agy")):
        die(f"reviewer '{args.reviewer}' must start with codex/gemini/agy")

    _probe_agent_bin(args.builder, "builder")
    _probe_agent_bin(args.reviewer, "reviewer")

    # GH-238 preflight runs AFTER the binary probes (missing builder/reviewer binary fails first, via
    # shutil.which with no subprocess) but BEFORE any render/tick/dispatch — so a non-runnable default
    # gate still halts with exit 2 before spending a turn.
    if args.dry_run:
        # dry-run never dispatches a turn, so surface the problem but keep going (matches Bash).
        try:
            _preflight_pre_advance_gate()
        except SystemExit as _e:
            if _e.code not in (0, None):
                eprint("marathon-drive: (dry-run continues; a live run would halt here)")
    else:
        _preflight_pre_advance_gate()

    if args.artifact_paths:
        os.environ["ALLOW_PATHS"] = args.artifact_paths
    else:
        if "ALLOW_PATHS" in os.environ:
            del os.environ["ALLOW_PATHS"]

    # GH-249: snapshot HEAD in the repo the artifact lands in (TARGET_ROOT when set, else ROOT) BEFORE
    # this phase's first commit, so requires_test_delta has a true "before this phase" baseline. Captured
    # unconditionally (cheap); unused unless --requires-test is set.
    pre_phase_head = ""
    try:
        pre_phase_head = subprocess.check_output(
            ["git", "-C", (args.target_root or root), "rev-parse", "HEAD"],
            stderr=subprocess.DEVNULL).decode("utf-8").strip()
    except Exception:
        pre_phase_head = ""

    phase_dir = os.path.join(phases_dir, lane_state_key)
    relay_file = os.path.join(phase_dir, "RELAY.md")
    
    # repo-root-relative path
    if relay_file.startswith(root + "/"):
        rel_relay = relay_file[len(root)+1:]
    else:
        rel_relay = relay_file

    # Bound early (moved ahead of Step 3's own copy below) so the GH-274 satisfied-lane check
    # just below — and the escalate/complete_phase_success defs it may call — read/write tick
    # state against the right repo even when a caller invoked us without pre-exporting it.
    os.environ["TICK_REPO_ROOT"] = root

    # escalate/save_transcript/run_pre_advance_gate/file_status/terminal_status/token_state/
    # requires_test_delta/complete_phase_success are defined here (ahead of the render below)
    # instead of beside their original later call sites, so the GH-274 satisfied-lane
    # short-circuit just below — which must run BEFORE the render — can call
    # complete_phase_success directly rather than duplicating its gate/requires-test/telemetry
    # logic.
    def escalate(reason, rexit):
        esc_file = os.path.join(phase_dir, "ESCALATION.md")
        with open(esc_file, 'w') as f:
            f.write(f"""# ESCALATION — Marathon Phase {args.phase_id}

phase: {args.phase_id}
task: {relay_task}
relay-drive-exit: {rexit}
reason: {reason}
relay-file: {rel_relay}
""")
        subprocess.run(["git", "-C", root, "add", "--", esc_file], check=True)
        # GH-207: an identical escalation record must not HALT on nothing-to-commit.
        if subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet", "--", esc_file]).returncode != 0:
            subprocess.run(["git", "-C", root, "commit", "-q", "-m", f"marathon: phase {args.phase_id} escalation ({reason})"], check=True)
        subprocess.run([tick_bin, "log", "marathon.phase.escalated", relay_task, "--agent", "marathon"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        log(f"escalation written: {esc_file} (reason: {reason})")

    def save_transcript():
        try:
            # We must use relay-turn-lib.sh to resolve rtl_transcript_root
            ts_base = subprocess.check_output(f"source \"{os.path.join(xyz_harness, 'relay-automation', 'relay-turn-lib.sh')}\" && rtl_transcript_root \"{root}\"", shell=True, executable="/bin/bash").decode('utf-8').strip()
        except subprocess.CalledProcessError:
            return False

        import datetime
        now = datetime.datetime.utcnow()
        date_dir = os.path.join(ts_base, now.strftime("%Y-%m-%d"))
        os.makedirs(date_dir, exist_ok=True)
        dest = os.path.join(date_dir, f"marathon-{args.phase_id}-{now.strftime('%H%M%S')}.md")
        shutil.copy2(relay_file, dest)
        subprocess.run(["git", "-C", root, "add", "--", dest], check=True)
        # GH-207: an identical transcript (same-second re-render) must not HALT on nothing-to-commit.
        if subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet", "--", dest]).returncode == 0:
            log(f"transcript unchanged: {dest}")
        else:
            subprocess.run(["git", "-C", root, "commit", "-q", "-m", f"marathon: phase {args.phase_id} transcript saved ({relay_task})"], check=True)
            log(f"transcript saved: {dest}")
        return True

    # GH-307: the gate is a correctness check on the REPO — it is not part of this run's
    # provenance, and it must not be able to see who is driving it. These tags otherwise leak
    # into the gate subprocess and break tests that legitimately assert on them
    # (test/xyz-harness-hooks.sh reads XYZ_HARNESS_CONTEXT / XYZ_SESSION_ID;
    # test/debug-mantra.sh reads MARATHON_LANE_NS), which made `bash validate.sh` — the
    # DOCUMENTED DEFAULT GATE — impossible to pass inside a marathon: every phase 1 escalated
    # with reason `pre-advance-failed` while its own change was correct and approved.
    # Scrubbing is deliberately narrow: only the run-identity tags, never repo/config inputs
    # like MARATHON_ROOT, TICK_BIN or TICK_REPO_ROOT, which a gate may legitimately need.
    GATE_SCRUBBED_ENV = ("XYZ_HARNESS_CONTEXT", "XYZ_SESSION_ID", "MARATHON_LANE_NS")

    def _gate_env():
        env = os.environ.copy()
        for var in GATE_SCRUBBED_ENV:
            env.pop(var, None)
        return env

    def run_pre_advance_gate():
        cwd = args.target_root if args.target_root else None
        rc = subprocess.run(pre_advance_cmd, shell=True, executable="/bin/bash",
                            cwd=cwd, env=_gate_env()).returncode
        # GH-284 P2: the run log reports this lane's gate outcome; mirrors RUN_GATE_RESULT in the
        # Bash twin (green/red, "not-run" until the gate is first invoked).
        run_gate_result[0] = "green" if rc == 0 else "red"
        return rc

    def run_post_approve_cmd():
        cwd = args.target_root if args.target_root else None
        return subprocess.run(args.post_approve_cmd, shell=True, executable="/bin/bash", cwd=cwd).returncode

    def file_status():
        try:
            with open(relay_file) as f:
                for line in f:
                    if line.startswith("STATUS:"):
                        return line.split(":", 1)[1].strip()
        except Exception:
            pass
        return ""

    def terminal_status(s):
        return s in ("Approved", "Closed")

    def token_state():
        try:
            info = subprocess.check_output([tick_bin, "info", relay_task], stderr=subprocess.DEVNULL).decode('utf-8').splitlines()
        except Exception:
            return ("", "")
        status = claimer = handoff = ""
        for line in info:
            if line.startswith("status:"): status = line.split(":", 1)[1].strip()
            elif line.startswith("claimer:"): claimer = line.split(":", 1)[1].strip()
            elif line.startswith("handoff-to:"): handoff = line.split(":", 1)[1].strip()
        actor = claimer if status == "claimed" else (handoff if status == "open" else "")
        return (status, actor)

    def path_has_nonempty_phase_delta(path):
        # True iff <path> exists, is non-empty, AND changed since pre_phase_head (committed diff)
        # or is newly untracked/added. Shared by --requires-test and artifact recovery: an empty or
        # unchanged artifact is no evidence that a builder turn made progress.
        rroot = args.target_root or root
        abs_p = path if os.path.isabs(path) else os.path.join(rroot, path)
        if not (os.path.isfile(abs_p) and os.path.getsize(abs_p) > 0):
            return False
        git_path = path
        if os.path.isabs(path) and os.path.commonpath([os.path.abspath(path), os.path.abspath(rroot)]) == os.path.abspath(rroot):
            git_path = os.path.relpath(path, rroot)
        if pre_phase_head:
            out = subprocess.run(["git", "-C", rroot, "diff", "--name-only", pre_phase_head, "--", git_path],
                                 stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).stdout.decode("utf-8", "replace")
            if out.strip():
                return True
        st = subprocess.run(["git", "-C", rroot, "status", "--porcelain", "--", git_path],
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).stdout.decode("utf-8", "replace")
        for line in st.splitlines():
            if line.startswith("??") or line.startswith("A "):
                return True
        return False

    def requires_test_delta(path):
        # GH-249: --requires-test preserves its existing non-empty phase-delta contract.
        return path_has_nonempty_phase_delta(path)

    def complete_phase_success(success_mode="approved"):
        log(f"relay approved — running pre-advance gate: {pre_advance_cmd}")
        gate_exit = run_pre_advance_gate()
        if gate_exit != 0:
            log(f"pre-advance gate FAILED (exit {gate_exit}) — escalating")
            escalate("pre-advance-failed", 0)
            xyz_marathon_emit("red", f"halted at phase {args.phase_id} — pre-advance gate failed")
            sys.exit(5)
        if args.requires_test and not requires_test_delta(args.requires_test):
            log(f"requires-test FAILED — no new/updated test detected at: {args.requires_test}")
            escalate("requires-test-missing", 0)
            xyz_marathon_emit("red", f"halted at phase {args.phase_id} — required test not added/updated: {args.requires_test}")
            sys.exit(5)
        if success_mode == "already-satisfied":
            success_text = f"phase {args.phase_id} complete — lane_already_satisfied, reviewer approved, gate passed"
        else:
            success_text = f"phase {args.phase_id} complete — STATUS: Approved, gate passed"
        subprocess.run([tick_bin, "log", "marathon.phase.approved", relay_task, "--agent", "marathon"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        lane_attempt_reset(get_env("TICK_REPO_ROOT", root), lane_state_key)
        save_transcript()
        log(success_text)
        xyz_marathon_emit("green", success_text)
        if args.post_approve_cmd:
            log(f"phase approved — running post-approve command: {args.post_approve_cmd}")
            post_approve_exit = run_post_approve_cmd()
            if post_approve_exit != 0:
                log(f"post-approve command FAILED (exit {post_approve_exit}) — phase remains approved; escalating closeout")
                escalate("post-approve-failed", 0)
                sys.exit(9)
        sys.exit(0)

    # GH-274: has this phase's relay ALREADY reached a terminal state (RELAY_FILE's STATUS is
    # Approved/Closed) with its tick token ALREADY `done`? If so there is nothing left to
    # (re)build or (re)review — the only reason to re-invoke marathon-drive for it is to retry a
    # flaky --pre-advance-cmd without touching the phase's own record. A `done` tick token can
    # never be reopened (reconcile_relay_task's correct, existing behavior), so re-rendering +
    # re-seeding here would only clobber the accurate terminal RELAY.md before failing anyway.
    # Checked before the render (below); extends GH-207's already-satisfied detection
    # (recover_already_satisfied_lane, triggered mid-relay on a no-progress reroute) to this
    # separate post-terminal-gate-retry trigger. DRY_RUN is exempted: its whole point is to
    # render + show the tick seed for inspection, and there is nothing to commit or seed here.
    def satisfied_lane_terminal():
        if not os.path.isfile(relay_file):
            return False
        s = file_status()
        if not terminal_status(s):
            return False
        tstatus, _actor = token_state()
        return tstatus == "done"

    if not args.dry_run and satisfied_lane_terminal():
        log(f"phase {args.phase_id} already reached a terminal relay (STATUS: {file_status()}, token done) — skipping render/reseed, re-running only the pre-advance gate")
        complete_phase_success("already-satisfied")

    if not args.dry_run:
        try:
            out = subprocess.check_output(["git", "-C", root, "status", "--porcelain"], stderr=subprocess.DEVNULL).decode('utf-8')
            dirty = []
            for line in out.splitlines():
                if len(line) >= 4:
                    p = line[3:]
                    if not p.startswith("phases/") and not p.startswith(".tick/"):
                        dirty.append(p)
            if dirty:
                log("WARNING: workspace is not clean — an autonomous builder can be distracted by stray files.")
                for p in dirty:
                    if p: log(f"  • {p}")
                if args.require_clean:
                    die("--require-clean set and the workspace has pre-existing changes (above)")
        except Exception: pass

    os.makedirs(phase_dir, exist_ok=True)
    with open(args.phase_brief_file, "r") as f:
        brief_text = f.read()

    # GH-162: peek at prior attempts BEFORE rendering so a re-fired phase carries the debug-mantra note.
    debug_mantra_prior = debug_mantra_prior_attempts(get_env("TICK_REPO_ROOT", root), lane_state_key)
    debug_mantra_text = debug_mantra_note(
        debug_mantra_prior, phase_dir, os.path.join(xyz_harness, "relay-automation", "DEBUG-MANTRA.md"))

    tick_cli = tick_bin if tick_bin.startswith("/") else os.path.join(root, tick_bin)

    if args.artifact_paths:
        claim_paths = f"{rel_relay},{args.artifact_paths}"
        builder_impl_line = f"Implement the brief by creating/editing the artifact file(s): {args.artifact_paths}"
        builder_scope_line = f"Edit ONLY these paths: {rel_relay} and {args.artifact_paths}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
        reviewer_read_line = (
            f"Read the latest builder block above AND review the artifact file(s) on disk: {args.artifact_paths}. "
            "REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two "
            "rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of "
            "them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you "
            "are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review "
            "block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a "
            "reviewer that skipped the sweep is indistinguishable in the transcript from one that did "
            "it and found nothing, which is exactly how those 20 issues stayed invisible."
        )
        reviewer_scope_line = f"Edit ONLY {rel_relay} (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git."
    else:
        claim_paths = rel_relay
        builder_impl_line = "Record your work directly in this relay file (relay-only phase — no source file to edit)."
        builder_scope_line = f"Edit ONLY {rel_relay}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
        reviewer_read_line = "Read the latest builder block above."
        reviewer_scope_line = "Do NOT run git. Do NOT touch any other file."

    relay_content = f"""# Marathon Phase {args.phase_id}
STATUS: Open
NEXT: {args.builder}

<!-- marathon-drive: task={relay_task} builder={args.builder} reviewer={args.reviewer} round-cap={args.round_cap} -->

## Phase Brief

{brief_text}
{debug_mantra_text}
---

▶ TAKE YOUR TURN ({args.builder} — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. {builder_impl_line}
2. Append a build block to this relay file: `### Round N · Builder · {args.builder}` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): {tick_cli}
   - {tick_cli} claim {relay_task} --agent {args.builder} --paths "{claim_paths}"
   - {tick_cli} ping {relay_task} --agent {args.builder}
   - {tick_cli} release {relay_task} --agent {args.builder} --to {args.reviewer}
4. {builder_scope_line}
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to {args.reviewer} — {args.reviewer}, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first.

---

▶ TAKE YOUR TURN ({args.reviewer} — REVIEWER role)

You are the REVIEWER for this phase. {reviewer_read_line}
1. Append a review block: `### Round N · Reviewer · {args.reviewer}` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: {tick_cli} release {relay_task} --agent {args.reviewer} --to {args.builder}
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: {tick_cli} done {relay_task} --agent {args.reviewer}
4. Use this exact tick binary (run it from any directory) for all token operations: {tick_cli}
   {reviewer_scope_line}
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to {args.builder} —
   {args.builder}, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.
"""

    with open(relay_file, 'w') as f:
        f.write(relay_content)

    if args.dry_run:
        log(f"dry-run: relay file rendered at {relay_file}")
        print(f"tick seed: log task.created {relay_task} + claim --agent marathon + release --to {args.builder}")
        sys.exit(0)

    subprocess.run(["git", "-C", root, "add", "--", relay_file], check=True)
    # GH-207: only commit when the render actually changed — a byte-identical re-render must not HALT on
    # a "nothing to commit" git error; treat it as unchanged and continue.
    if subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet", "--", relay_file]).returncode == 0:
        log(f"relay file unchanged: {relay_file}")
    else:
        subprocess.run(["git", "-C", root, "commit", "-q", "-m", f"marathon: render phase {args.phase_id} relay ({relay_task})"], check=True)
        log(f"relay file committed: {relay_file}")

    os.environ["TICK_REPO_ROOT"] = root

    def reconcile_relay_task():
        try:
            info = subprocess.check_output([tick_bin, "info", relay_task], stderr=subprocess.DEVNULL).decode('utf-8').splitlines()
        except:
            return
        
        status, claimer, handoff = "", "", ""
        for line in info:
            if line.startswith("status:"): status = line.split(":", 1)[1].strip()
            elif line.startswith("claimer:"): claimer = line.split(":", 1)[1].strip()
            elif line.startswith("handoff-to:"): handoff = line.split(":", 1)[1].strip()
            
        if status == "claimed":
            die(f"relay task {relay_task} already has a live claim by {claimer or 'unknown'}; refusing to reap a live claim")
        elif status == "open":
            if not handoff: return
            if handoff in [args.builder, args.reviewer]:
                _run_tick_loud([tick_bin, "claim", relay_task, "--agent", handoff, "--paths", rel_relay])
                _run_tick_loud([tick_bin, "release", relay_task, "--agent", handoff])
                log(f"reconciled leaked open handoff: {relay_task} (cleared stale reservation for {handoff})")
            else:
                die(f"relay task {relay_task} is open but reserved for unexpected agent '{handoff}'")

    # The outer marathon-drive invocation owns this lane's attempt count. A parent relay-drive
    # process may have set this flag to suppress its nested accounting; do not let that inherited
    # value skip this invocation's own gate. The child relay-drive environment sets it explicitly
    # below to avoid double-counting, matching the Bash implementation.
    os.environ.pop("LANE_ATTEMPT_COUNTED", None)
    lane_attempt_gate(get_env("TICK_REPO_ROOT", root), lane_state_key, args.force)
    def _run_tick_loud(cmd_args):
        res = subprocess.run(cmd_args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if res.returncode != 0:
            sys.exit(res.returncode)

    reconcile_relay_task()

    _run_tick_loud([tick_bin, "log", "task.created", relay_task, "--agent", "marathon"])
    _run_tick_loud([tick_bin, "claim", relay_task, "--agent", "marathon", "--paths", rel_relay])
    _run_tick_loud([tick_bin, "release", relay_task, "--agent", "marathon", "--to", args.builder])
    log(f"tick token seeded: {relay_task} → {args.builder}")

    _run_tick_loud([tick_bin, "log", "marathon.phase.start", relay_task, "--agent", "marathon"])
    log(f"phase start: running relay-drive --round-cap {args.round_cap}")
    # Past this point a phase is really being driven — arm the run log and start the driver
    # heartbeat. Same placement as MARATHON_DRIVE_STARTED=1 + marathon_driver_heartbeat_start in the
    # Bash twin, so --help / usage / lock contention / a parked lane / --dry-run never post a run log
    # or leave a liveness record behind.
    drive_started[0] = True
    driver_heartbeat_start()

    def _run_relay_drive(review_once=False):
        cmd2 = [relay_drive_bin, "--relay-file", relay_file, "--relay-task", relay_task,
                "--agent-cmd", agent_cmd]
        if review_once:
            cmd2.append("--review-once")   # GH-207: one approval pass, no round-cap
        else:
            cmd2.extend(["--round-cap", str(args.round_cap)])
        if args.target_root:
            cmd2.extend(["--target-root", args.target_root])
        env2 = os.environ.copy()
        env2["RELAY_FILE"] = relay_file
        env2["LANE_ATTEMPT_COUNTED"] = "1"
        env2["XYZ_HARNESS_CONTEXT"] = "marathon-phase"
        env2["RELAY_COST_SUMMARY"] = "0"
        return subprocess.run(cmd2, env=env2).returncode

    # GH-75: write liveness before the drive; clear it on ANY terminal path via atexit (registered only
    # here, so early exits before a live phase never register a spurious clear).
    xyz_marathon_heartbeat_write()
    import atexit as _atexit
    _atexit.register(xyz_marathon_heartbeat_clear)
    relay_exit = _run_relay_drive()

    # escalate/save_transcript/run_pre_advance_gate/file_status/terminal_status/token_state/
    # requires_test_delta/complete_phase_success are defined earlier (ahead of the render) —
    # see the GH-274 comment there — but still called from below as before.

    def artifacts_exist():
        if not args.artifact_paths:
            return False
        aroot = args.target_root or root
        for p in args.artifact_paths.split(","):
            p = p.strip()
            if not p:
                continue
            if not path_has_nonempty_phase_delta(p):
                return False
        return True

    def recover_already_satisfied_lane():
        # GH-207: a stalled builder (exit 3) whose declared artifact is already built AND gate-green gets
        # ONE routed reviewer pass instead of a false no-progress escalation. Returns 0 to route to
        # complete_phase_success(already-satisfied); 3 to fall through to the ordinary no-progress halt.
        if not args.artifact_paths or not artifacts_exist():
            return 3
        log(f"relay stalled (exit 3) with declared artifact(s) already present — probing the pre-advance gate: {pre_advance_cmd}")
        if run_pre_advance_gate() != 0:
            log("already-satisfied probe: pre-advance gate FAILED — treating it as real no-progress")
            return 3
        s = file_status()
        tstatus, actor = token_state()
        if terminal_status(s) and not actor:
            log(f"already-satisfied probe: relay already reached terminal agreement (STATUS: {s}, token done)")
            return 0
        if tstatus == "claimed" and actor == args.builder:
            subprocess.run([tick_bin, "release", relay_task, "--agent", args.builder, "--to", args.reviewer], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif tstatus == "open" and actor == args.builder:
            subprocess.run([tick_bin, "claim", relay_task, "--agent", args.builder, "--paths", claim_paths], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run([tick_bin, "release", relay_task, "--agent", args.builder, "--to", args.reviewer], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            log(f"already-satisfied probe: artifact + gate are green, but current actor is {actor or 'none'} (token {tstatus or 'missing'}) — cannot auto-route to review")
            return 3
        log(f"already-satisfied probe: routed the stalled builder turn to reviewer {args.reviewer} for one approval pass")
        review_exit = _run_relay_drive(review_once=True)
        if review_exit == 0:
            return 0
        if review_exit == 5:
            log("already-satisfied probe: reviewer declined approval — lane remains unsatisfied")
            return 3
        return review_exit

    timeout_reason = ["turn-timeout-or-hang"]
    timeout_emit = [f"halted at phase {args.phase_id} — turn timeout / hang"]

    def recover_timeout_exit():
        # GH-205: a relay timeout (exit 7) whose declared artifact already landed AND is gate-green AND
        # left a live reviewer handoff is resumed with one more relay-drive pass instead of a false hang.
        if not artifacts_exist():
            timeout_reason[0] = "timeout-no-artifact"
            timeout_emit[0] = f"halted at phase {args.phase_id} — timed-out builder produced no declared artifact"
            log("relay timed out (exit 7) before any declared artifact landed — treating it as a real hang")
            return 7
        log(f"relay timed out (exit 7) after declared artifact(s) appeared — probing the pre-advance gate: {pre_advance_cmd}")
        if run_pre_advance_gate() != 0:
            timeout_reason[0] = "timeout-gate-failed"
            timeout_emit[0] = f"halted at phase {args.phase_id} — timed-out builder artifact failed the pre-advance gate"
            log("timeout probe: pre-advance gate FAILED — treating it as a real halt")
            return 5
        s = file_status()
        tstatus, actor = token_state()
        if terminal_status(s) and not actor:
            log(f"timeout probe: relay already reached terminal agreement (STATUS: {s}, token done) — continuing")
            return 0
        if not actor:
            timeout_reason[0] = "timeout-no-live-actor"
            timeout_emit[0] = f"halted at phase {args.phase_id} — timed-out builder left no live reviewer handoff"
            log(f"timeout probe: artifact + gate were green, but {relay_task} has no live actor (STATUS: {s}) — cannot continue")
            return 7
        if actor == args.builder:
            timeout_reason[0] = "timeout-builder-still-owned-turn"
            timeout_emit[0] = f"halted at phase {args.phase_id} — timed-out builder never handed the relay to review"
            log(f"timeout probe: builder still owns {relay_task} (STATUS: {s}) — treating this as a real hang")
            return 7
        log(f"timeout probe: artifact + gate were green and {relay_task} moved to {actor} — resuming relay-drive from the post-timeout state")
        r = _run_relay_drive()
        if r == 7:
            timeout_reason[0] = "timeout-during-review-recovery"
            timeout_emit[0] = f"halted at phase {args.phase_id} — relay timed out again during review recovery"
        return r

    if relay_exit == 7:
        _r = recover_timeout_exit()
        relay_exit = 0 if _r == 0 else _r

    if relay_exit == 0:
        complete_phase_success()
    elif relay_exit == 3:
        if recover_already_satisfied_lane() == 0:
            complete_phase_success("already-satisfied")
        log("relay escalated: no-progress (relay-drive exit 3)")
        escalate("no-progress", 3)
        xyz_marathon_emit("red", f"halted at phase {args.phase_id} — relay no-progress")
        sys.exit(3)
    elif relay_exit == 4:
        log("relay escalated: cap/close-mismatch (relay-drive exit 4)")
        escalate("cap-or-close-mismatch", 4)
        xyz_marathon_emit("red", f"halted at phase {args.phase_id} — relay cap/close-mismatch")
        sys.exit(4)
    elif relay_exit == 5:
        log("relay escalated: pre-advance gate failed")
        escalate(timeout_reason[0] if timeout_reason[0] != "turn-timeout-or-hang" else "pre-advance-failed", 5)
        xyz_marathon_emit("red", timeout_emit[0] if timeout_reason[0] != "turn-timeout-or-hang" else f"halted at phase {args.phase_id} — pre-advance gate failed")
        sys.exit(5)
    elif relay_exit == 6:
        log("relay escalated: containment violation — a turn-taker reverted an off-lane edit (exit 6)")
        escalate("containment-violation (off-lane edit reverted by a turn-taker)", 6)
        xyz_marathon_emit("red", f"halted at phase {args.phase_id} — containment violation (off-lane edit reverted)")
        sys.exit(6)
    elif relay_exit == 7:
        log("relay escalated: timeout / hang (relay-drive exit 7)")
        escalate(timeout_reason[0], 7)
        xyz_marathon_emit("red", timeout_emit[0])
        sys.exit(7)
    else:
        die(f"relay-drive exited with unexpected code {relay_exit}")

if __name__ == "__main__":
    # GH-284 P2 / GH-322: the Bash twin runs its run log + heartbeat stop from an EXIT trap that
    # captures `$?` first and re-exits with it explicitly, precisely so a failing reporting step can
    # never overwrite the driven run's real status. This is the same shape: the code is resolved
    # first, hooks run in a `finally` (so an exception path still clears the heartbeat), and the
    # original code is what we exit with. `die()` and every `sys.exit(N)` land in the SystemExit arm.
    _exit_code = 0
    try:
        try:
            main()
        except SystemExit as _e:
            _exit_code = _e.code if isinstance(_e.code, int) else (0 if _e.code is None else 1)
        except BaseException:
            _exit_code = 1
            raise
    finally:
        for _hook in _ON_EXIT:
            try:
                _hook(_exit_code)
            except Exception:
                pass
    sys.exit(_exit_code)
