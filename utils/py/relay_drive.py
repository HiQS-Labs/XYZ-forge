import argparse
import os
import sys
import subprocess
import time
import re
import shutil
import pathlib
from contextlib import contextmanager

# GH-376: resolve the driver lock through the ONE shared resolver rather than reimplementing it.
# Imported relative to this file (utils/py/), independent of CWD/PYTHONPATH — some callers load this
# module via importlib.util.spec_from_file_location rather than `python3 <path>`, which does NOT put
# the script's own directory on sys.path. Same pattern, and the same reason, as marathon_drive.py:19.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rtl import driver_lock_path, resolve_turn_root  # noqa: E402

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def get_env(key, default=None):
    return os.environ.get(key, default)

def die(msg):
    eprint(f"relay-drive: {msg}")
    sys.exit(2)

def main():
    parser = argparse.ArgumentParser(description="relay-drive", add_help=False)
    parser.add_argument("--relay-file", dest="relay_file")
    parser.add_argument("--agent-cmd", dest="agent_cmd")
    parser.add_argument("--relay-task", dest="relay_task", default="RELAY-TURN")
    parser.add_argument("--round-cap", dest="round_cap", type=int, default=6)
    parser.add_argument("--target-root", dest="target_root")
    parser.add_argument("--consult-verify", dest="consult_verify", action="store_true")
    parser.add_argument("--artifact-file", dest="artifact_file")
    parser.add_argument("--review-once", dest="review_once", action="store_true")
    parser.add_argument("--force", dest="force", action="store_true")
    parser.add_argument("--dry-run", dest="dry_run", action="store_true")
    parser.add_argument("--tool-mode", dest="tool_mode", default=get_env("RELAY_TOOL_MODE", "standard"), choices=["standard", "programmatic"])
    parser.add_argument("--help", action="store_true")
    
    args, unknown = parser.parse_known_args()
    if args.help:
        print("Usage: relay-automation/relay-drive.sh --relay-file PATH --agent-cmd CMD [options]")
        sys.exit(0)

    # GH-322: `unknown` was captured and never read, so ANY unrecognised flag was silently
    # discarded. Because Python is the executing lane (GH-264), that made `--log-github` — the
    # headline feature of GH-284 Phase 2, which exists only in the Bash twin — a no-op: the marathon
    # ran, exited 0, reported success, and never posted a run log. All three Bash twins `die
    # "unknown argument: $1"`; this restores that contract byte-for-byte (same prefix, same exit 2).
    # Checked AFTER --help so `--help` still works alongside a bad flag.
    if unknown:
        die(f"unknown argument: {unknown[0]}")

    if not args.relay_file:
        die("--relay-file is required")
    if not args.agent_cmd and not args.dry_run:
        die("--agent-cmd is required")

    if args.tool_mode == "programmatic":
        has_sandbox = bool(shutil.which("sandbox-exec") or shutil.which("bwrap"))
        if not has_sandbox:
            die("Containment failure (fail-closed): OS sandbox backend (sandbox-exec or bwrap) unavailable for --tool-mode programmatic")
        os.environ["XYZ_TOOL_MODE"] = "programmatic"
        os.environ["RELAY_TOOL_MODE"] = "programmatic"

    if args.review_once:
        args.round_cap = 1

    here = os.path.dirname(os.path.abspath(__file__))
    # ROOT_DIR is the harness root, not necessarily git root.
    # We are in utils/py, so ROOT_DIR is the parent of utils
    root_dir = os.path.abspath(os.path.join(here, "..", ".."))

    tick_bin = get_env("TICK_BIN", os.path.join(root_dir, "bin", "tick"))
    consult_sh = get_env("CONSULT_SH", os.path.join(root_dir, "relay-automation", "consult.sh"))
    xyz_append_bin = get_env("XYZ_APPEND_BIN", os.path.join(root_dir, "utils", "telemetry", "append-xyz-completion.sh"))

    # GH-331 (mirrors relay-drive.sh GH-152): auto-surface the `tick analyze` cost block at end-of-run
    # so a driven run stops needing a manual `tick analyze` pull to see what it cost. This lived only in
    # the Bash twin, so on the default Python lane (GH-264) it never ran — zero end-of-run cost
    # visibility. Only fires once a turn was actually about to be driven (cost_summary_state["started"]
    # — never on --help/usage/lock-contention/lane-parked/--dry-run exits), opts out with
    # RELAY_COST_SUMMARY=0, and is best-effort: a failed/forced `tick analyze` is swallowed so it can
    # NEVER change the driven run's own exit code (wired into the same atexit as the lock cleanup;
    # atexit does not alter the process exit status).
    cost_summary_state = {"started": False}

    def xyz_relay_cost_summary():
        if not cost_summary_state["started"]:
            return
        if get_env("RELAY_COST_SUMMARY", "1") == "0":
            return
        try:
            report = subprocess.check_output([tick_bin, "analyze", "--format", "human"],
                                             stderr=subprocess.DEVNULL).decode("utf-8")
        except Exception:
            eprint("relay-drive: tick analyze failed — end-of-run cost summary unavailable (RELAY_COST_SUMMARY=0 to silence)")
            return
        # Extract from the '--- cost ---' line to EOF (matches `sed -n '/^--- cost ---$/,$p'`).
        block_lines = []
        capturing = False
        for ln in report.splitlines():
            if ln == "--- cost ---":
                capturing = True
            if capturing:
                block_lines.append(ln)
        if not block_lines:
            return
        eprint("\nrelay-drive: end-of-run cost summary (tick analyze) —\n" + "\n".join(block_lines))

    if args.target_root:
        try:
            subprocess.run(["git", "-C", args.target_root, "rev-parse", "--show-toplevel"], 
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        except subprocess.CalledProcessError:
            die(f"invalid target root (not a git repo): {args.target_root}")
        os.environ["RELAY_TARGET_ROOT"] = args.target_root

    # Resolve relay file path
    relay_file = args.relay_file
    if not os.path.isfile(relay_file) and args.target_root and not relay_file.startswith("/") and os.path.isfile(os.path.join(args.target_root, relay_file)):
        relay_file = os.path.join(args.target_root, relay_file)
    if not os.path.isfile(relay_file):
        die(f"relay file does not exist: {relay_file}")

    # GH-304: absolutize relay_file before it is exported to the turn-taker. As passed it is relative to
    # the driver's CWD — which, for a same-repo vendored `.xyz/` install driven per the relay-xyz skill's
    # documented `cd "$HARNESS"`, is `.xyz/`, a subdir of the true repo root the turn-taker's worktree
    # checks out. A CWD-relative string then resolves wrong from the worktree root and the relay fails
    # for Codex. An absolute path resolves identically from any CWD (see the Bash driver for the full
    # rationale). Mirrors the artifact_file absolutization below.
    if not relay_file.startswith("/"):
        relay_file = os.path.abspath(relay_file)

    # GH-289: a review turn (ALLOW_PATHS="") can only write the relay file; the same isolation-root
    # mismatch discards a BUILD turn's Log after full cost. Under --target-root the turn's worktree is
    # based on the TARGET repo, so if the relay file resolves OUTSIDE that target root the turn
    # physically cannot append its findings (codex rejects the out-of-project write). Refuse fast at
    # startup instead of spending the turn — this guard lived only in the Bash twin, so on the default
    # Python lane the build turn ran and discarded its Log after full cost (see relay-drive.sh:275).
    # Fires for build turns AND --review-once (kind flips the diagnostic), before the lane-attempt gate.
    if args.target_root:
        tr = os.path.realpath(args.target_root) if os.path.isdir(args.target_root) else ""
        rf = os.path.join(os.path.realpath(os.path.dirname(relay_file)), os.path.basename(relay_file))
        if tr and rf != tr and not rf.startswith(tr + os.sep):
            turn_kind = "review" if args.review_once else "build"
            die(f"--target-root {turn_kind} turn cannot report: relay file '{relay_file}' resolves "
                f"outside the target root '{args.target_root}', so a {turn_kind} turn (ALLOW_PATHS=\"\") "
                "has no writable path for its findings and the turn would be discarded after full cost. "
                f"Vendor the harness into the target repo (relay-automation/xyz-vendor.sh '{args.target_root}') "
                "and drop --target-root, or move the relay thread under the target root.")

    def _lane_key(raw):
        return re.sub(r'[^A-Za-z0-9._-]', '_', raw)

    def lane_attempt_gate(root, raw, force):
        if get_env("LANE_ATTEMPT_COUNTED"): return 0
        if not raw: return 0
        
        max_attempts = get_env("LANE_MAX_ATTEMPTS", "2")
        try: max_attempts = int(max_attempts)
        except ValueError: max_attempts = 2

        key = _lane_key(raw)
        attempts_dir = os.path.join(root, ".tick", "attempts")
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

    def lane_attempt_reset(root, raw):
        if get_env("LANE_ATTEMPT_COUNTED"): return
        if not raw: return
        attempts_file = os.path.join(root, ".tick", "attempts", _lane_key(raw))
        if os.path.exists(attempts_file):
            try: os.remove(attempts_file)
            except: pass

    # #129/#136: resolve TICK_REPO_ROOT ONCE, here, silently. The lane-attempt gate just below
    # is the first consumer — with the env unset on a vendored-.xyz drive it used to count
    # attempts in the HARNESS root's .tick while the token lives in the caller repo's log, so
    # LANE_MAX_ATTEMPTS enforcement fragmented across two locations (the #129 family: the two
    # halves of one coordination disagreeing about where state lives). An explicit TICK_REPO_ROOT
    # still wins, unchanged. The NOTE announcing a self-resolution prints later, after the
    # driver lock — gh376's twin-parity pin requires a held lock to stay the first printable
    # line — which is why resolution (side-effect-free, ahead of every consumer) and
    # announcement are split.
    tick_repo_root = get_env("TICK_REPO_ROOT")
    self_resolved = not tick_repo_root
    if self_resolved:
        try:
            tick_repo_root = resolve_turn_root(None, root_dir)
        except RuntimeError:
            tick_repo_root = root_dir
        os.environ["TICK_REPO_ROOT"] = tick_repo_root

    # check lane attempt
    if not args.dry_run and not args.review_once:
        lane_attempt_gate(tick_repo_root, args.relay_task, args.force)

    if "RELAY_WORKTREE_ISOLATION" not in os.environ:
        os.environ["RELAY_WORKTREE_ISOLATION"] = "1"

    def warn_if_relay_file_untracked():
        if get_env("RELAY_WORKTREE_ISOLATION", "1") == "0":
            return
        rdir = os.path.dirname(os.path.abspath(relay_file))
        if not os.path.isdir(rdir):
            return

        try:
            prefix = subprocess.check_output(["git", "-C", rdir, "rev-parse", "--show-prefix"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
        except Exception:
            return
        rel = prefix + os.path.basename(relay_file)
        try:
            subprocess.run(["git", "-C", rdir, "cat-file", "-e", f"HEAD:{rel}"], stderr=subprocess.DEVNULL, check=True)
            return
        except subprocess.CalledProcessError:
            pass

        try:
            relay_toplevel = subprocess.check_output(["git", "-C", rdir, "rev-parse", "--show-toplevel"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
            effective_root = get_env("RELAY_TARGET_ROOT", root_dir)
            effective_toplevel = subprocess.check_output(["git", "-C", effective_root, "rev-parse", "--show-toplevel"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
        except Exception:
            relay_toplevel = ""
            effective_toplevel = ""

        if relay_toplevel and relay_toplevel == effective_toplevel:
            eprint(f"relay-drive: NOTE — relay file is not committed at HEAD: {rel}")
            eprint("  RELAY_WORKTREE_ISOLATION=1 runs the turn-taker in a worktree at HEAD, but its own")
            eprint("  worktree-seeding step copies this file's current content in regardless — this is")
            eprint("  usually fine. Commit it for a clean paper trail, or re-run with")
            eprint("  RELAY_WORKTREE_ISOLATION=0 if you want to rule out isolation entirely; neither is required.")
        else:
            eprint(f"relay-drive: WARNING — relay file is not committed at HEAD: {rel}")
            eprint("  It lives in a DIFFERENT repo than the turn-taker's root (archive-routed?), so the")
            eprint("  usual worktree-seeding fallback does NOT cover it — it may be genuinely INVISIBLE to")
            eprint("  the reviewer (it will find nothing and do no work). Remedy: commit the relay file")
            eprint("  first, or re-run with RELAY_WORKTREE_ISOLATION=0.")

    warn_if_relay_file_untracked()

    if args.artifact_file:
        if not os.path.isfile(args.artifact_file):
            die(f"artifact file not found: {args.artifact_file}")
        if not args.artifact_file.startswith("/"):
            args.artifact_file = os.path.abspath(args.artifact_file)
        os.environ["RELAY_ARTIFACT_FILE"] = args.artifact_file
        if get_env("RELAY_WORKTREE_ISOLATION", "1") == "0":
            eprint("relay-drive: WARNING — --artifact-file needs worktree isolation to seed the artifact; with RELAY_WORKTREE_ISOLATION=0 the reviewer will not see it.")

    def file_status():
        try:
            with open(relay_file, 'r') as f:
                for line in f:
                    if line.startswith("STATUS:"):
                        return line.split(":", 1)[1].strip()
        except: pass
        return ""

    def next_pointer():
        try:
            with open(relay_file, 'r') as f:
                for line in f:
                    if line.startswith("NEXT:"):
                        return line.split(":", 1)[1].strip()
        except: pass
        return ""

    def relay_content_sig():
        try:
            return subprocess.check_output(["git", "hash-object", relay_file], stderr=subprocess.DEVNULL).decode('utf-8').strip()
        except Exception:
            pass
        try:
            out = subprocess.check_output(["cksum", relay_file], stderr=subprocess.DEVNULL).decode('utf-8').split()
            return out[0] if out else "?"
        except Exception:
            return "?"

    def terminal_status(s):
        return s in ["Approved", "Closed"]

    def escalated_status(s):
        return s == "Escalated"

    def token_state():
        try:
            env = os.environ.copy()
            env["TICK_REPO_ROOT"] = get_env("TICK_REPO_ROOT", root_dir)
            out = subprocess.check_output([tick_bin, "info", args.relay_task], env=env, stderr=subprocess.DEVNULL).decode('utf-8').splitlines()
        except:
            out = []
        status, claimer, handoff = "", "", ""
        for line in out:
            if line.startswith("status:"): status = line.split(":", 1)[1].strip()
            elif line.startswith("claimer:"): claimer = line.split(":", 1)[1].strip()
            elif line.startswith("handoff-to:"): handoff = line.split(":", 1)[1].strip()
        
        if status == "claimed": actor = claimer
        elif status == "open": actor = handoff
        else: actor = ""
        return status, actor

    def relay_setup_section_lines():
        # Lines under a "## Setup" header, up to the next "## " section header.
        lines = []
        in_setup = False
        try:
            with open(relay_file, 'r') as f:
                for raw in f:
                    line = raw.rstrip("\n")
                    if re.match(r'^##[ \t]+Setup[ \t]*$', line):
                        in_setup = True
                        continue
                    if in_setup and re.match(r'^##[ \t]+', line):
                        break
                    if in_setup:
                        lines.append(line)
        except: pass
        return lines

    def relay_extract_markdown_paths(line):
        out = []
        for m in re.findall(r'`[^`]+`|\*\*[^*]+\*\*', line):
            s = m
            if s.startswith("`") and s.endswith("`"):
                s = s[1:-1]
            elif s.startswith("**") and s.endswith("**"):
                s = s[2:-2]
            out.append(s)
        return out

    def relay_is_worktree_artifact_path(candidate):
        if not candidate: return False
        if candidate.startswith("http://") or candidate.startswith("https://"): return False
        if candidate.startswith(".relay-artifacts/"): return False
        if "embedded below" in candidate: return False
        if " " in candidate or "\t" in candidate: return False
        if "{" in candidate or "}" in candidate or "," in candidate: return False
        return (candidate.startswith("/") or "/" in candidate
                or candidate.startswith(".") or "." in candidate)

    def preflight_setup_artifact_paths():
        worktree_root = get_env("RELAY_TARGET_ROOT")
        if not worktree_root:
            try:
                worktree_root = subprocess.check_output(
                    ["git", "-C", os.path.dirname(relay_file), "rev-parse", "--show-toplevel"],
                    stderr=subprocess.DEVNULL).decode('utf-8').strip()
            except Exception:
                worktree_root = root_dir
            if not worktree_root:
                worktree_root = root_dir
        try:
            worktree_root = os.path.realpath(worktree_root) if os.path.isdir(worktree_root) else worktree_root
        except Exception:
            pass
        for setup_line in relay_setup_section_lines():
            if "Artifact under review:" not in setup_line:
                continue
            if "embedded below" in setup_line:
                continue
            for candidate in relay_extract_markdown_paths(setup_line):
                if not relay_is_worktree_artifact_path(candidate):
                    continue
                if candidate.startswith("/"):
                    resolved = candidate
                else:
                    resolved = os.path.join(worktree_root, candidate)
                if not os.path.exists(resolved):
                    die(f"artifact path not found in worktree: {candidate}")

    def xyz_relay_emit(health):
        if get_env("XYZ_HARNESS_CONTEXT", "relay") != "relay": return
        if not os.access(xyz_append_bin, os.X_OK): return
        slug = os.path.splitext(os.path.basename(relay_file))[0]
        title = slug
        try:
            with open(relay_file, 'r') as f:
                for line in f:
                    if line.startswith("# "):
                        title = line[2:].strip()
                        break
        except: pass
        if not title: title = slug
        s = file_status()
        desc = f"Relay session ended: STATUS {s or 'unknown'} (health {health})."
        subprocess.run([xyz_append_bin, "relay", slug, health, title, desc], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    if get_env("RELAY_DRIVER_LOCKED", "0") != "1":
        # GH-376: this was a 2-branch guess (.git is a dir -> .git/relay-driver.lock, ELSE a hidden
        # lock beside the scripts) with no case for a linked worktree, where .git is a FILE. That
        # topology is not exotic — it is the one swarm-preflight's own recommended invocation creates
        # via RELAY_WORKTREE_ISOLATION=1. The marathon driver already followed .git to the git COMMON
        # dir, so the two drivers resolved DIFFERENT paths from the same tree and each held what it
        # believed was the one mutex, invisible to the other. marathon-drive.sh:195-196 asserts in
        # prose that they mutually exclude; this call is what makes that true.
        #
        # driver_lock_path is #448's shared resolver (Bash twin: relay-automation/driver-lock-lib.sh).
        # Reused, never reimplemented — a fourth inline copy is the bug class, not the fix.
        lock_dir, lock_label = driver_lock_path(root_dir)


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
                eprint(f"relay-drive: another driver is active in this repo (pid {holder}, lock: {lock_label}).")
                eprint("relay-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).")
                sys.exit(1)
            
            eprint(f"relay-drive: reclaiming stale relay-driver.lock (holder pid {holder or 'none'} not running).")
            try:
                shutil.rmtree(lock_dir)
                os.mkdir(lock_dir)
            except:
                eprint("relay-drive: could not acquire relay-driver.lock after reclaiming a stale one.")
                sys.exit(1)
        
        with open(os.path.join(lock_dir, "pid"), 'w') as f:
            f.write(str(os.getpid()) + "\n")
        
        os.environ["RELAY_DRIVER_LOCKED"] = "1"
        # GH-331: the cost summary is wired into the SAME atexit as the lock cleanup (the one place
        # every exit path funnels through), mirroring relay-drive.sh's GH-152 EXIT trap. The summary
        # runs FIRST, then the lock is removed. Skipped entirely when nested (RELAY_DRIVER_LOCKED=1):
        # the outer driver owns this exit hook, exactly as the Bash trap is only armed by the lock owner.
        def _relay_drive_on_exit():
            xyz_relay_cost_summary()
            try: shutil.rmtree(lock_dir)
            except: pass
        import atexit
        atexit.register(_relay_drive_on_exit)

    # #129/#136: the announcement half of the self-resolution computed above the lane gate.
    # Printed HERE, after the lock, because a held lock must stay the FIRST thing this driver
    # can print, byte-identical to the frozen Bash twin — gh376's twin-parity pin, observed live
    # in the Wave-1 run when the NOTE printed first and parity went red.
    #
    # BASH/PYTHON DIVERGENCE, deliberate and pinned (#138): the frozen twin
    # (relay-automation/relay-drive.sh, GH-308) has none of this — no self-resolution, and its
    # not-found diagnostic still reads "token missing". The twin is not to be taught this fix
    # without a `Frozen-twin-exception:` trailer; recorded here so a `XYZ_PYTHON=0` run is not
    # misread as a regression (the #379/#380 lesson: undocumented divergences generate false
    # bug reports against the dead half).
    if self_resolved:
        eprint(f"relay-drive: NOTE — TICK_REPO_ROOT unset; self-resolved to {tick_repo_root} (#129)")

    round_idx = 0
    while round_idx < args.round_cap:
        s = file_status()
        tstatus, actor = token_state()

        if terminal_status(s):
            if actor:
                eprint(f"relay-drive: STATUS {s} but {args.relay_task} still live ({tstatus}/{actor}) — close mismatch, escalating")
                sys.exit(4)
            print(f"relay-drive: relay terminated (STATUS: {s}, token done) after {round_idx} turn(s)")
            tick_repo_root = get_env("TICK_REPO_ROOT", root_dir)
            lane_attempt_reset(tick_repo_root, args.relay_task)
            xyz_relay_emit("green")
            sys.exit(0)
        
        if escalated_status(s):
            eprint(f"relay-drive: relay escalated to human by design (STATUS: {s}, token {actor or 'done'}) after {round_idx} turn(s)")
            xyz_relay_emit("orange")
            sys.exit(4)
        
        if not actor:
            # #129: "token missing" sent operators to inspect the token when the usual cause is
            # that THIS run resolved a different tick log than whoever seeded the token. An
            # empty tstatus means the task was not found in the resolved log at all — name the
            # root actually used and the event dir actually searched, so the misdiagnosis is a
            # one-line read instead of a twenty-minute hunt.
            if not tstatus:
                eprint(f"relay-drive: {args.relay_task} not found in the resolved tick log")
                eprint(f"  TICK_REPO_ROOT: {tick_repo_root}")
                eprint(f"  searched:       {os.path.join(tick_repo_root, '.tick', 'events')}/")
                eprint("  hint: if you seeded the token in another shell, export the same env —")
                eprint('        eval "$(find-harness.sh --env)"')
            else:
                eprint(f"relay-drive: {args.relay_task} has no actor (token {tstatus}) but STATUS={s} — escalating")
            if tstatus == "done":
                eprint(f"  → '{args.relay_task}' is spent from a prior relay; seed + drive with a fresh --relay-task (e.g. RELAY-{os.path.splitext(os.path.basename(relay_file))[0]})")
            sys.exit(4)

        preflight_setup_artifact_paths()

        if args.dry_run:
            print(f"relay-drive: WOULD drive turn for agent: {actor} (token {tstatus}, STATUS: {s})")
            sys.exit(0)

        cost_summary_state["started"] = True   # GH-331: past here a turn is really being driven — arm the summary
        prev = f"{tstatus}:{actor}"
        rfsig = relay_content_sig()   # GH-245: relay-file content signature BEFORE the turn
        nextp = next_pointer()        # GH-245: NEXT: handoff pointer BEFORE the turn
        os.environ["RELAY_FILE"] = relay_file
        os.environ["RELAY_TASK"] = args.relay_task
        os.environ["RELAY_AGENT"] = actor
        
        # Execute agent-cmd with RSS measurement (GH-382)
        peak_turn_rss_mb = 0
        if os.access(args.agent_cmd, os.X_OK):
            proc = subprocess.Popen([args.agent_cmd], start_new_session=True)
        else:
            proc = subprocess.Popen(args.agent_cmd, shell=True, executable="/bin/bash", start_new_session=True)
        while proc.poll() is None:
            try:
                out = subprocess.run(["ps", "-axo", "pgid=,rss="], capture_output=True, text=True, timeout=5).stdout
                total_kb = 0
                for line in out.splitlines():
                    parts = line.split()
                    if len(parts) == 2 and int(parts[0]) == proc.pid:
                        total_kb += int(parts[1])
                rss_mb = total_kb // 1024
                if rss_mb > peak_turn_rss_mb:
                    peak_turn_rss_mb = rss_mb
            except Exception:
                pass
            time.sleep(0.1)

        res_code = proc.returncode
        if peak_turn_rss_mb > 0 and tick_bin:
            try:
                env = os.environ.copy()
                env["TICK_REPO_ROOT"] = tick_repo_root
                subprocess.run([tick_bin, "cost", args.relay_task, "--agent", actor, "--peak-rss-mb", str(peak_turn_rss_mb)], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception:
                pass
        if res_code != 0:
            sys.exit(res_code)
            
        round_idx += 1
        
        if args.consult_verify:
            # We skip this port since it relies on bashisms in consult_verify and it's long. Wait, I should port it.
            # I will just write a small stub here or actually port it if it's strictly needed.
            # actually I will port it fully.
            pass
            # consult_verify logic
            taker_verdict = ""
            try:
                # Get the last VERDICT
                with open(relay_file, 'r') as f:
                    content = f.read()
                log_idx = content.find("## Log")
                if log_idx != -1:
                    verdicts = re.findall(r'^VERDICT:\s*(.*)$', content[log_idx:], re.MULTILINE)
                    if verdicts: taker_verdict = verdicts[-1]
            except: pass
            
            cv_label = f"consult-verify-{os.path.splitext(os.path.basename(relay_file))[0]}-r{round_idx}"
            
            # call rtl_transcript_root via python
            # well, actually we can just source it in bash and echo, or we can use the same logic:
            cv_out_base = os.path.join(root_dir, "relay-system")
            if get_env("XYZ_ARCHIVE_ROOT"):
                cv_out_base = get_env("XYZ_ARCHIVE_ROOT")
                if not os.path.isabs(cv_out_base): cv_out_base = os.path.join(root_dir, cv_out_base)
            
            import datetime
            today = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d")   # #140: utcnow() deprecated
            cv_out_dir = os.path.join(cv_out_base, today)
            
            import tempfile
            fd, cv_prompt_file = tempfile.mkstemp(prefix="cv-prompt-")
            with os.fdopen(fd, 'w') as f:
                f.write("Review the most recent log block in this relay file. Does the turn-taker's VERDICT match their stated evidence in the Basis: line? Reply with exactly one of: AGREE-PASS (verdict supported), AGREE-FAIL (verdict supported), or DISAGREE (verdict not supported by evidence). One token only.\n\n=== RELAY FILE ===\n")
                with open(relay_file, 'r') as rf:
                    f.write(rf.read())
            
            env = os.environ.copy()
            env["CONSULT_ROOT"] = root_dir
            try:
                cv_out = subprocess.check_output([consult_sh, "--prompt-file", cv_prompt_file, "--label", cv_label, "--out", cv_out_dir], env=env, stderr=subprocess.DEVNULL).decode('utf-8')
            except subprocess.CalledProcessError as e:
                cv_out = e.output.decode('utf-8') if e.output else ""
            except:
                cv_out = ""
            
            os.remove(cv_prompt_file)
            
            cv_diverged = False
            cv_advisor_summary = ""
            
            for cv_line in cv_out.splitlines():
                if "->" not in cv_line: continue
                parts = cv_line.split("->")
                cv_path = parts[1].strip()
                if not cv_path or not os.path.isfile(cv_path): continue
                
                model = parts[0].split("[ok]")[-1].strip()
                cv_response = "(no verdict found)"
                try:
                    with open(cv_path, 'r') as f:
                        content = f.read()
                        match = re.search(r'(AGREE-PASS|AGREE-FAIL|DISAGREE)', content)
                        if match: cv_response = match.group(1)
                except: pass
                cv_advisor_summary += f"{model or 'advisor'}: {cv_response}\n"
                if cv_response == "DISAGREE": cv_diverged = True
                
            if cv_diverged:
                eprint(f"relay-drive: consult-verify DIVERGENCE after {actor} turn (taker: {taker_verdict})\n{cv_advisor_summary}")
                with open(relay_file, 'a') as f:
                    f.write(f"\n### consult-verify advisory — divergence detected (round {round_idx})\n\nVERDICT: FAIL\nBasis: consult disagreed with turn-taker verdict \"{taker_verdict}\" (see transcripts)\n{cv_advisor_summary}\nTurn-taker self-reported: {taker_verdict}\n")
                
                # set STATUS: Escalated
                with open(relay_file, 'r') as f:
                    content = f.read()
                content = re.sub(r'^STATUS:\s*.*$', 'STATUS: Escalated', content, flags=re.MULTILINE)
                with open(relay_file, 'w') as f:
                    f.write(content)
                
                try:
                    cv_relay_repo = subprocess.check_output(["git", "-C", os.path.dirname(os.path.abspath(relay_file)), "rev-parse", "--show-toplevel"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
                except:
                    cv_relay_repo = root_dir
                    
                subprocess.run(["git", "-C", cv_relay_repo, "add", relay_file], stderr=subprocess.DEVNULL)
                subprocess.run(["git", "-C", cv_relay_repo, "commit", "-m", f"relay-drive: consult-verify divergence escalation (round {round_idx})"], stderr=subprocess.DEVNULL)
                
                eprint(f"relay-drive: relay escalated by consult-verify (STATUS: Escalated) after {round_idx} turn(s)")
                sys.exit(4)
            else:
                eprint(f"relay-drive: consult-verify AGREED after {actor} turn (taker: {taker_verdict})")

        ntstatus, nactor = token_state()
        ns = file_status()
        nrfsig = relay_content_sig()   # GH-245: relay-file content signature AFTER the turn
        nnextp = next_pointer()        # GH-245: NEXT: handoff pointer AFTER the turn

        if escalated_status(ns):
            eprint(f"relay-drive: relay escalated to human by design (STATUS: {ns}, token {ntstatus}:{nactor}) after {round_idx} turn(s)")
            xyz_relay_emit("orange")
            sys.exit(4)
            
        if args.review_once:
            if terminal_status(ns):
                print(f"relay-drive: review-once — reviewer approved/closed (STATUS: {ns}) after 1 turn")
                xyz_relay_emit("green")
                sys.exit(0)
            # GH-245 defect 2: classify on EVIDENCE OF A TURN — the relay file's content changed
            # (findings appended), the NEXT: pointer flipped, or the STATUS word changed — NOT on token
            # movement alone. Token state is deliberately dropped from the oracle here.
            if nrfsig != rfsig or nnextp != nextp or ns != s:
                print(f"relay-drive: review-once — reviewer completed a turn (STATUS: {ns}, token {ntstatus}:{nactor}; relay-file/NEXT changed); non-approval handback, not a stall")
                xyz_relay_emit("orange")
                sys.exit(5)
            eprint(f"relay-drive: review-once — reviewer took no action (relay file unchanged, NEXT unchanged, STATUS still {ns}, token {ntstatus}:{nactor}) — genuine stall")
            xyz_relay_emit("red")
            sys.exit(3)
            
        if not terminal_status(ns) and f"{ntstatus}:{nactor}" == prev:
            eprint(f"relay-drive: no progress after {actor} turn (token still {prev}) — escalating")
            xyz_relay_emit("red")
            sys.exit(3)

    s = file_status()
    tstatus, actor = token_state()
    if terminal_status(s) and not actor:
        print(f"relay-drive: relay terminated (STATUS: {s})")
        xyz_relay_emit("green")
        sys.exit(0)
        
    eprint(f"relay-drive: round cap ({args.round_cap}) exceeded (STATUS: {s}, token actor: {actor or 'none'}) — escalating")
    xyz_relay_emit("red")
    sys.exit(4)

if __name__ == "__main__":
    main()
