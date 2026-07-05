import argparse
import os
import sys
import subprocess
import time
import re
import shutil
import pathlib
from contextlib import contextmanager

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
    parser.add_argument("--help", action="store_true")
    
    args, unknown = parser.parse_known_args()
    if args.help:
        print("Usage: relay-automation/relay-drive.sh --relay-file PATH --agent-cmd CMD [options]")
        sys.exit(0)

    if not args.relay_file:
        die("--relay-file is required")
    if not args.agent_cmd and not args.dry_run:
        die("--agent-cmd is required")

    if args.review_once:
        args.round_cap = 1

    here = os.path.dirname(os.path.abspath(__file__))
    # ROOT_DIR is the harness root, not necessarily git root.
    # We are in utils/py, so ROOT_DIR is the parent of utils
    root_dir = os.path.abspath(os.path.join(here, "..", ".."))

    tick_bin = get_env("TICK_BIN", os.path.join(root_dir, "bin", "tick"))
    consult_sh = get_env("CONSULT_SH", os.path.join(root_dir, "relay-automation", "consult.sh"))
    xyz_append_bin = get_env("XYZ_APPEND_BIN", os.path.join(root_dir, "utils", "telemetry", "append-xyz-completion.sh"))

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

    # check lane attempt
    if not args.dry_run and not args.review_once:
        tick_repo_root = get_env("TICK_REPO_ROOT", root_dir)
        lane_attempt_gate(tick_repo_root, args.relay_task, args.force)

    if "RELAY_WORKTREE_ISOLATION" not in os.environ:
        os.environ["RELAY_WORKTREE_ISOLATION"] = "1"

    def warn_if_relay_file_untracked():
        if get_env("RELAY_WORKTREE_ISOLATION", "1") == "0": return
        rdir = os.path.dirname(os.path.abspath(relay_file))
        if not os.path.isdir(rdir): return
        
        try:
            prefix = subprocess.check_output(["git", "-C", rdir, "rev-parse", "--show-prefix"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
        except:
            return
        rel = prefix + os.path.basename(relay_file)
        try:
            subprocess.run(["git", "-C", rdir, "cat-file", "-e", f"HEAD:{rel}"], stderr=subprocess.DEVNULL, check=True)
            return
        except subprocess.CalledProcessError:
            pass
        eprint(f"relay-drive: WARNING — relay file is not committed at HEAD: {rel}")
        eprint("  RELAY_WORKTREE_ISOLATION=1 runs the turn-taker in a worktree at HEAD, so this untracked")
        eprint("  file is INVISIBLE to the reviewer (it will find nothing and do no work). Remedy: commit")
        eprint("  the relay file first, or re-run with RELAY_WORKTREE_ISOLATION=0.")

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

    def terminal_status(s):
        return s in ["Approved", "Closed"]

    def escalated_status(s):
        return s == "Escalated"

    def token_state():
        try:
            out = subprocess.check_output([tick_bin, "info", args.relay_task], stderr=subprocess.DEVNULL).decode('utf-8').splitlines()
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
        if os.path.isdir(os.path.join(root_dir, ".git")):
            lock_dir = os.path.join(root_dir, ".git", "relay-driver.lock")
            lock_label = ".git/relay-driver.lock"
        else:
            lock_dir = os.path.join(root_dir, ".relay-driver.lock")
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
        def cleanup_lock():
            try: shutil.rmtree(lock_dir)
            except: pass
        import atexit
        atexit.register(cleanup_lock)

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
            eprint(f"relay-drive: {args.relay_task} has no actor (token {tstatus or 'missing'}) but STATUS={s} — escalating")
            if tstatus == "done":
                eprint(f"  → '{args.relay_task}' is spent from a prior relay; seed + drive with a fresh --relay-task (e.g. RELAY-{os.path.splitext(os.path.basename(relay_file))[0]})")
            sys.exit(4)
            
        if args.dry_run:
            print(f"relay-drive: WOULD drive turn for agent: {actor} (token {tstatus}, STATUS: {s})")
            sys.exit(0)
            
        prev = f"{tstatus}:{actor}"
        os.environ["RELAY_FILE"] = relay_file
        os.environ["RELAY_TASK"] = args.relay_task
        os.environ["RELAY_AGENT"] = actor
        
        # Execute agent-cmd
        if os.access(args.agent_cmd, os.X_OK):
            res = subprocess.run([args.agent_cmd])
        else:
            res = subprocess.run(args.agent_cmd, shell=True)
            
        if res.returncode != 0:
            sys.exit(res.returncode)
            
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
            today = datetime.datetime.utcnow().strftime("%Y-%m-%d")
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
        
        if escalated_status(ns):
            eprint(f"relay-drive: relay escalated to human by design (STATUS: {ns}, token {ntstatus}:{nactor}) after {round_idx} turn(s)")
            xyz_relay_emit("orange")
            sys.exit(4)
            
        if args.review_once:
            if terminal_status(ns):
                print(f"relay-drive: review-once — reviewer approved/closed (STATUS: {ns}) after 1 turn")
                xyz_relay_emit("green")
                sys.exit(0)
            if f"{ntstatus}:{nactor}" != prev or ns != s:
                print(f"relay-drive: review-once — reviewer completed a turn (STATUS: {ns}, token {ntstatus}:{nactor}); non-approval handback, not a stall")
                xyz_relay_emit("orange")
                sys.exit(5)
            eprint(f"relay-drive: review-once — reviewer took no action (STATUS unchanged: {ns}, token still {prev}) — genuine stall")
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
